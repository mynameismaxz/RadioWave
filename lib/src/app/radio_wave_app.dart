import 'package:flutter/material.dart';

import '../features/radio/presentation/radio_wave_home.dart';
import 'theme/app_theme.dart';

class RadioWaveApp extends StatelessWidget {
  const RadioWaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RadioWave',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const RadioWaveHome(),
    );
  }
}
