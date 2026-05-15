import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'src/app/radio_wave_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  JustAudioMediaKit.ensureInitialized();
  await _initBackgroundPlayback();
  runApp(const RadioWaveApp());
}

Future<void> _initBackgroundPlayback() async {
  const supportedNativePlatforms = <TargetPlatform>{
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.macOS,
  };

  if (!kIsWeb && !supportedNativePlatforms.contains(defaultTargetPlatform)) {
    return;
  }

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.radio_app_flutter.playback',
    androidNotificationChannelName: 'RadioWave Playback',
    androidNotificationOngoing: true,
  );
}
