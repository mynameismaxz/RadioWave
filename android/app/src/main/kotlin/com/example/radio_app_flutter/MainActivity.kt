package com.example.radio_app_flutter

import android.media.audiofx.Equalizer
import android.util.Log
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private var equalizer: Equalizer? = null
    private var equalizerSessionId: Int? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.radio_app_flutter/equalizer"
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
        super.onDestroy()
    }
}
