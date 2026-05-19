import 'package:flutter/material.dart';

import '../features/radio/presentation/radio_wave_home.dart';
import 'theme/app_color_scheme.dart';
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
          home: const _MobilePortraitGate(
            child: RadioWaveHome(),
          ),
        );
      },
    );
  }
}

class _MobilePortraitGate extends StatelessWidget {
  const _MobilePortraitGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobileWebLandscape =
        size.shortestSide < 600 && size.width > size.height;

    if (!isMobileWebLandscape) {
      return child;
    }

    final c = AppColorScheme.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.screen_rotation_rounded,
                  size: 48,
                  color: c.textSecondary,
                ),
                const SizedBox(height: 18),
                Text(
                  'Rotate your phone',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'RadioWave works best in portrait on mobile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.textTertiary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
