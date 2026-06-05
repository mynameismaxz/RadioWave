package com.cs6636291.radiowave

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import android.media.audiofx.Equalizer
import android.util.Log
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.InputDevice
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Android Auto imports (available on API 29+)
// Note: Android Auto connection detection requires different API on newer versions
// For now, relying on ACTION_AUDIO_BECOMING_NOISY for headphone/Bluetooth events
// import androidx.car.app.CarContext
// import androidx.car.app.CarConnectionCallback
// import androidx.car.app.CarConnection

class MainActivity : AudioServiceActivity() {
    private var equalizer: Equalizer? = null
    private var equalizerSessionId: Int? = null
    private var rotaryChannel: MethodChannel? = null
    private var audioFocusChannel: MethodChannel? = null

    // Audio focus and disconnection listeners
    private var audioManager: AudioManager? = null
    private var audioFocusListener: AudioManager.OnAudioFocusChangeListener? = null
    private var becomingNoisyReceiver: BroadcastReceiver? = null
    private var bluetoothReceiver: BroadcastReceiver? = null
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var carConnectionCallback: Any? = null  // TODO: Fix Android Auto
    private var carContext: Any? = null  // TODO: Fix Android Auto

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.cs6636291.radiowave/equalizer"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setEqualizer" -> {
                    try {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        val audioSessionId = call.argument<Int>("audioSessionId")
                        val gains = call.argument<List<Double>>("gains") ?: emptyList()
                        setEqualizer(enabled, audioSessionId, gains)
                        result.success(true)
                    } catch (error: Throwable) {
                        Log.w("RadioWaveEqualizer", "Could not apply equalizer", error)
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        rotaryChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.cs6636291.radiowave/rotary"
        )

        // Audio focus channel for receiving native audio events
        audioFocusChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.cs6636291.radiowave/audio_focus"
        )

        // Initialize audio focus and disconnection listeners
        initAudioFocusListeners()
    }

    override fun dispatchGenericMotionEvent(event: MotionEvent): Boolean {
        if (event.action == MotionEvent.ACTION_SCROLL &&
            event.isFromSource(InputDevice.SOURCE_ROTARY_ENCODER)
        ) {
            val scroll = event.getAxisValue(MotionEvent.AXIS_SCROLL)
            if (scroll != 0f) {
                val delta = if (scroll < 0f) 1 else -1
                sendRotaryEvent("rotate", mapOf("delta" to delta))
                return true
            }
        }

        return super.dispatchGenericMotionEvent(event)
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.action != KeyEvent.ACTION_DOWN) {
            return super.dispatchKeyEvent(event)
        }

        val key = when (event.keyCode) {
            KeyEvent.KEYCODE_DPAD_UP -> "up"
            KeyEvent.KEYCODE_DPAD_DOWN -> "down"
            KeyEvent.KEYCODE_DPAD_LEFT -> "left"
            KeyEvent.KEYCODE_DPAD_RIGHT -> "right"
            KeyEvent.KEYCODE_DPAD_CENTER,
            KeyEvent.KEYCODE_ENTER,
            KeyEvent.KEYCODE_NUMPAD_ENTER -> "select"
            KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE -> "playPause"
            KeyEvent.KEYCODE_MEDIA_STOP -> "stop"
            KeyEvent.KEYCODE_MEDIA_NEXT -> "next"
            KeyEvent.KEYCODE_MEDIA_PREVIOUS -> "previous"
            else -> null
        }

        if (key != null) {
            sendRotaryEvent("key", mapOf("key" to key))
            return true
        }

        return super.dispatchKeyEvent(event)
    }

    private fun sendRotaryEvent(method: String, args: Map<String, Any>) {
        rotaryChannel?.invokeMethod(method, args)
    }

    private fun setEqualizer(enabled: Boolean, audioSessionId: Int?, gains: List<Double>) {
        if (!enabled || audioSessionId == null || audioSessionId <= 0 || gains.isEmpty()) {
            try {
                equalizer?.enabled = false
            } catch (_: Throwable) {
            }
            return
        }

        val eq = ensureEqualizer(audioSessionId)
        val minLevel = eq.bandLevelRange[0].toInt()
        val maxLevel = eq.bandLevelRange[1].toInt()
        val bandCount = eq.numberOfBands.toInt()

        for (band in 0 until bandCount) {
            val sourceIndex = if (bandCount <= 1 || gains.size <= 1) {
                0
            } else {
                Math.round((band.toDouble() / (bandCount - 1)) * (gains.size - 1)).toInt()
            }
            val gainMb = Math.round(gains[sourceIndex].coerceIn(-12.0, 12.0) * 100.0)
                .toInt()
                .coerceIn(minLevel, maxLevel)
                .toShort()
            eq.setBandLevel(band.toShort(), gainMb)
        }

        eq.enabled = true
        Log.i(
            "RadioWaveEqualizer",
            "Applied equalizer session=$audioSessionId bands=$bandCount enabled=${eq.enabled}"
        )
    }

    private fun ensureEqualizer(audioSessionId: Int): Equalizer {
        val current = equalizer
        if (current != null && equalizerSessionId == audioSessionId) {
            return current
        }

        current?.release()
        return Equalizer(0, audioSessionId).also {
            equalizer = it
            equalizerSessionId = audioSessionId
        }
    }

    override fun onDestroy() {
        equalizer?.release()
        equalizer = null
        cleanupAudioFocusListeners()
        super.onDestroy()
    }

    private fun initAudioFocusListeners() {
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        // 1. Audio Focus Change Listener
        audioFocusListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
            Log.i("RadioWaveAudioFocus", "Audio focus change: $focusChange")
            audioFocusChannel?.invokeMethod("onAudioFocusLost", focusChange)
        }

        // Request audio focus for media playback
        val result = audioManager?.requestAudioFocus(
            audioFocusListener!!,
            AudioManager.STREAM_MUSIC,
            AudioManager.AUDIOFOCUS_GAIN
        )
        Log.i("RadioWaveAudioFocus", "Audio focus request result: $result")

        // 2. ACTION_AUDIO_BECOMING_NOISY (headphone/Bluetooth unplug)
        becomingNoisyReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action == AudioManager.ACTION_AUDIO_BECOMING_NOISY) {
                    Log.i("RadioWaveAudioFocus", "ACTION_AUDIO_BECOMING_NOISY received - headphone/Bluetooth unplugged")
                    audioFocusChannel?.invokeMethod("onHeadphoneUnplugged", null)
                }
            }
        }
        val noisyFilter = IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY)
        registerReceiver(becomingNoisyReceiver, noisyFilter, Context.RECEIVER_EXPORTED)

        // 3. Bluetooth device state changes
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter != null) {
            bluetoothReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    val action = intent.action
                    if (action == BluetoothDevice.ACTION_ACL_DISCONNECTED ||
                        action == BluetoothAdapter.ACTION_STATE_CHANGED) {
                        val state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)
                        val prevState = intent.getIntExtra(BluetoothAdapter.EXTRA_PREVIOUS_STATE, BluetoothAdapter.ERROR)

                        // Check if Bluetooth was turned off or a device disconnected while audio was playing
                        if (action == BluetoothDevice.ACTION_ACL_DISCONNECTED ||
                            (action == BluetoothAdapter.ACTION_STATE_CHANGED &&
                             state == BluetoothAdapter.STATE_OFF &&
                             prevState == BluetoothAdapter.STATE_ON)) {
                            Log.i("RadioWaveAudioFocus", "Bluetooth disconnected or turned off")
                            audioFocusChannel?.invokeMethod("onBluetoothDisconnected", null)
                        }
                    }
                }
            }
            val bluetoothFilter = IntentFilter().apply {
                addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED)
                addAction(BluetoothAdapter.ACTION_STATE_CHANGED)
            }
            registerReceiver(bluetoothReceiver, bluetoothFilter, Context.RECEIVER_EXPORTED)
        }

        // 4. Android Auto connection state changes (API 29+)
// Temporarily disabled - API changed in androidx.car.app 1.4+
// TODO: Re-enable with correct API
//        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
//            carContext = CarContext.getCarContext(this)
//            if (carContext != null) {
//                carConnectionCallback = object : CarConnectionCallback() {
//                    override fun onConnected(carConnection: CarConnection) {
//                        Log.i("RadioWaveAudioFocus", "Android Auto connected: ${carConnection.type}")
//                    }
//
//                    override fun onDisconnected(carConnection: CarConnection) {
//                        Log.i("RadioWaveAudioFocus", "Android Auto disconnected: ${carConnection.type}")
//                        audioFocusChannel?.invokeMethod("onAndroidAutoDisconnected", null)
//                    }
//
//                    override fun onConnectionFailed(carConnection: CarConnection, errorCode: Int) {
//                        Log.w("RadioWaveAudioFocus", "Android Auto connection failed: $errorCode")
//                    }
//                }
//                carContext?.carConnectionManager?.addConnectionCallback(carConnectionCallback!!)
//            }
//        }
    }

    private fun cleanupAudioFocusListeners() {
        // Abandon audio focus
        audioFocusListener?.let { listener ->
            audioManager?.abandonAudioFocus(listener)
        }

        // Unregister receivers
        becomingNoisyReceiver?.let { receiver ->
            try {
                unregisterReceiver(receiver)
            } catch (_: Throwable) {}
        }
        bluetoothReceiver?.let { receiver ->
            try {
                unregisterReceiver(receiver)
            } catch (_: Throwable) {}
        }

        // Remove car connection callback (temporarily disabled)
        // TODO: Re-enable with correct API
        // carConnectionCallback?.let { callback ->
        //     carContext?.carConnectionManager?.removeConnectionCallback(callback)
        // }
    }
}
