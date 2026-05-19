import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'src/app/radio_wave_app.dart';
import 'src/app/theme/theme_notifier.dart';
import 'src/data/services/radio_audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _lockMobilePortrait();
  JustAudioMediaKit.ensureInitialized();
  await themeNotifier.init();
  radioAudioHandler = await _initAudioHandler();
  runApp(const RadioWaveApp());
}

Future<void> _lockMobilePortrait() async {
  if (kIsWeb) {
    return;
  }

  const mobilePlatforms = <TargetPlatform>{
    TargetPlatform.android,
    TargetPlatform.iOS,
  };

  if (!mobilePlatforms.contains(defaultTargetPlatform)) {
    return;
  }

  await SystemChrome.setPreferredOrientations(
    <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  );
}

Future<RadioAudioHandler> _initAudioHandler() async {
  const supportedNativePlatforms = <TargetPlatform>{
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.macOS,
  };

  final useAudioService =
      kIsWeb || supportedNativePlatforms.contains(defaultTargetPlatform);

  if (!useAudioService) {
    return RadioAudioHandler();
  }

  return AudioService.init(
    builder: RadioAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.radio_app_flutter.playback',
      androidNotificationChannelName: 'RadioWave Playback',
      androidNotificationOngoing: true,
    ),
  );
}
