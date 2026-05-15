import 'package:flutter/material.dart';

import 'app_color_scheme.dart';

class AppTheme {
  static ThemeData dark() {
    const c = AppColorScheme.dark;
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.accent,
        brightness: Brightness.dark,
        surface: c.surface,
        onSurface: c.textPrimary,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: c.background,
      fontFamily: 'Roboto',
      textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: c.textPrimary,
            displayColor: c.textPrimary,
            fontFamily: 'Roboto',
          ),
      iconTheme: IconThemeData(
        color: c.textSecondary,
      ),
      dividerTheme: DividerThemeData(
        color: c.divider,
        thickness: 0.5,
        space: 0,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.accent,
        inactiveTrackColor: c.surfaceHighlight,
        thumbColor: c.textPrimary,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        trackHeight: 3,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        overlayColor: c.accent.withValues(alpha: 0.12),
      ),
      extensions: const <ThemeExtension<dynamic>>[c],
    );
  }

  static ThemeData light() {
    const c = AppColorScheme.light;
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.accent,
        brightness: Brightness.light,
        surface: c.surface,
        onSurface: c.textPrimary,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: c.background,
      fontFamily: 'Roboto',
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: c.textPrimary,
            displayColor: c.textPrimary,
            fontFamily: 'Roboto',
          ),
      iconTheme: IconThemeData(
        color: c.textSecondary,
      ),
      dividerTheme: DividerThemeData(
        color: c.divider,
        thickness: 0.5,
        space: 0,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.accent,
        inactiveTrackColor: c.surfaceHighlight,
        thumbColor: c.textPrimary,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        trackHeight: 3,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        overlayColor: c.accent.withValues(alpha: 0.12),
      ),
      extensions: const <ThemeExtension<dynamic>>[c],
    );
  }
}
