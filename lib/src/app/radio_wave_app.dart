import 'package:flutter/material.dart';

import '../features/radio/presentation/radio_wave_home.dart';
import 'theme/app_theme.dart';
import 'theme/theme_notifier.dart';

class RadioWaveApp extends StatelessWidget {
  const RadioWaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'RadioWave',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: const RadioWaveHome(),
        );
      },
    );
  }
}
