import 'package:flutter/services.dart';

class AndroidEqualizerAdapter {
  static const MethodChannel _channel = MethodChannel(
    'com.cs6636291.radiowave/equalizer',
  );

  static Future<void> setEqualizer({
    required bool enabled,
    required int? audioSessionId,
    required List<double> gains,
  }) async {
    if (audioSessionId == null || audioSessionId <= 0) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('setEqualizer', <String, Object?>{
        'enabled': enabled,
        'audioSessionId': audioSessionId,
        'gains': gains,
      });
    } catch (_) {
      // Equalizer support varies by Android device/audio backend. Playback must
      // keep working even when the native effect cannot attach to this session.
    }
  }
}

Future<void> setAndroidEqualizer({
  required bool enabled,
  required int? audioSessionId,
  required List<double> gains,
}) {
  return AndroidEqualizerAdapter.setEqualizer(
    enabled: enabled,
    audioSessionId: audioSessionId,
    gains: gains,
  );
}
