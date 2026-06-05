import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../models/station.dart';
import 'android_equalizer_adapter_stub.dart'
    if (dart.library.io) 'android_equalizer_adapter.dart';
import 'radio_audio_handler.dart';
import 'web_equalizer_adapter_stub.dart'
    if (dart.library.html) 'web_equalizer_adapter_web.dart';

/// Method channel for receiving audio focus and disconnection events from native Android
const MethodChannel _audioFocusChannel =
    MethodChannel('com.cs6636291.radiowave/audio_focus');

class AudioPlayerService {
  AudioPlayerService({RadioAudioHandler? handler})
      : _handler = handler ?? radioAudioHandler {
    _setupAudioFocusListener();
  }

  final RadioAudioHandler _handler;
  bool _equalizerEnabled = false;
  List<double> _equalizerGains = const <double>[];

  AudioPlayer get _player => _handler.player;

  /// Set up listener for native Android audio focus and disconnection events
  void _setupAudioFocusListener() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _audioFocusChannel.setMethodCallHandler(_handleAudioFocusCall);
    }
  }

  /// Handle method calls from native Android audio focus listeners
  Future<dynamic> _handleAudioFocusCall(MethodCall call) async {
    switch (call.method) {
      case 'onAudioFocusLost':
        final int focusLoss = call.arguments as int? ?? 0;
        await _handleNativeAudioFocusLoss(focusLoss);
        break;
      case 'onHeadphoneUnplugged':
        await _handleHeadphoneUnplugged();
        break;
      case 'onBluetoothDisconnected':
        await _handleBluetoothDisconnected();
        break;
      case 'onAndroidAutoDisconnected':
        await _handleAndroidAutoDisconnected();
        break;
    }
  }

  /// Handle audio focus loss from native (AUDIOFOCUS_LOSS, AUDIOFOCUS_LOSS_TRANSIENT, etc.)
  Future<void> _handleNativeAudioFocusLoss(int focusLoss) async {
    // For live radio, any audio focus loss should stop playback
    // AUDIOFOCUS_LOSS = 1 (permanent loss)
    // AUDIOFOCUS_LOSS_TRANSIENT = 2 (transient loss)
    // AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK = 3 (transient, can duck volume)
    // We stop for any focus loss since we're live radio
    await _handler.stop();
  }

  /// Handle headphone/Bluetooth unplug event (ACTION_AUDIO_BECOMING_NOISY)
  Future<void> _handleHeadphoneUnplugged() async {
    await _handler.stop();
  }

  /// Handle explicit Bluetooth device disconnect
  Future<void> _handleBluetoothDisconnected() async {
    await _handler.stop();
  }

  /// Handle Android Auto disconnection
  Future<void> _handleAndroidAutoDisconnected() async {
    await _handler.stop();
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Stream<PlaybackEvent> get playbackEventStream => _player.playbackEventStream;

  Stream<int?> get androidAudioSessionIdStream =>
      _player.androidAudioSessionIdStream;

  Future<void> playStation(Station station) async {
    await _player.stop();
    if (kIsWeb) {
      await resetWebEqualizer();
    }
    await _handler.setMediaItem(_mediaItemFor(station));
    if (kIsWeb) {
      await _player.setWebCrossOrigin(
        _equalizerEnabled ? WebCrossOrigin.anonymous : null,
      );
    }
    await _player
        .setAudioSource(AudioSource.uri(Uri.parse(station.url)))
        .timeout(const Duration(seconds: 10));
    unawaited(_player.play());
    unawaited(syncEqualizerToCurrentPlayback());
  }

  /// Re-attach EQ after the audio source or Android session changes.
  Future<void> syncEqualizerToCurrentPlayback() async {
    if (kIsWeb) {
      await _applyWebEqualizerAfterPlaybackStarts();
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _applyAndroidEqualizerWhenReady();
    }
  }

  Future<void> play() async {
    await _applyEqualizerBands();
    unawaited(_handler.play());
  }

  Future<void> pause() => _player.pause();

  Future<void> stop() => _handler.stop();

  Future<void> setVolume(double value) => _player.setVolume(value);

  Future<void> setEqualizer({
    required bool enabled,
    required List<double> gains,
  }) async {
    _equalizerEnabled = enabled;
    _equalizerGains = List<double>.of(gains);

    if (kIsWeb) {
      await setWebEqualizer(enabled: enabled, gains: gains);
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      await setAndroidEqualizer(
        enabled: enabled,
        audioSessionId: _player.androidAudioSessionId,
        gains: gains,
      );
    }
  }

  Future<void> _applyEqualizerBands() async {
    if (kIsWeb) {
      await setWebEqualizer(
        enabled: _equalizerEnabled,
        gains: _equalizerGains,
      );
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      await setAndroidEqualizer(
        enabled: _equalizerEnabled,
        audioSessionId: _player.androidAudioSessionId,
        gains: _equalizerGains,
      );
    }
  }

  Future<void> _applyAndroidEqualizerWhenReady() async {
    for (var attempt = 0; attempt < 12; attempt += 1) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final sessionId = _player.androidAudioSessionId;
      if (sessionId != null && sessionId > 0) {
        await _applyEqualizerBands();
        return;
      }
    }
  }

  Future<void> _applyWebEqualizerAfterPlaybackStarts() async {
    for (var attempt = 0; attempt < 10; attempt += 1) {
      await Future<void>.delayed(
        Duration(milliseconds: 180 + attempt * 80),
      );
      await _applyEqualizerBands();
    }
  }

  Future<void> dispose() => _handler.dispose();

  MediaItem _mediaItemFor(Station station) {
    return MediaItem(
      id: station.uuid.isNotEmpty ? station.uuid : station.url,
      album: _stationAlbum(station),
      title: station.name,
      artUri: _artUri(station.favicon),
      extras: <String, dynamic>{
        'url': station.url,
        'country': station.country,
        'codec': station.codec,
        'bitrate': station.bitrate,
      },
    );
  }

  String _stationAlbum(Station station) {
    final parts = <String>[
      if (station.country.isNotEmpty) station.country,
      if (station.codec.isNotEmpty) station.codec,
      if (station.bitrate > 0) '${station.bitrate} kbps',
    ];

    return parts.isEmpty ? 'RadioWave' : parts.join(' - ');
  }

  Uri? _artUri(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme) {
      return null;
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return null;
    }

    return uri;
  }
}
