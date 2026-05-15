import 'package:flutter/material.dart';

/// Custom color scheme exposed as a [ThemeExtension] so every widget
/// can resolve the correct palette for the current brightness.
///
/// Usage:  `final c = AppColorScheme.of(context);`
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  const AppColorScheme({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceHighlight,
    required this.card,
    required this.cardHover,
    required this.border,
    required this.borderSubtle,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.accent,
    required this.accentDim,
    required this.accentSurface,
    required this.pink,
    required this.green,
    required this.red,
    required this.amber,
    required this.glass,
    required this.glassActive,
    required this.glassBorder,
  });

  // ── Backgrounds ──
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceHighlight;
  final Color card;
  final Color cardHover;

  // ── Borders & separators ──
  final Color border;
  final Color borderSubtle;
  final Color divider;

  // ── Text ──
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;

  // ── Accent ──
  final Color accent;
  final Color accentDim;
  final Color accentSurface;

  // ── Semantic ──
  final Color pink;
  final Color green;
  final Color red;
  final Color amber;

  // ── Glass ──
  final Color glass;
  final Color glassActive;
  final Color glassBorder;

  // ─────────────────────────────────────────────────────────
  // Presets
  // ─────────────────────────────────────────────────────────

  static const dark = AppColorScheme(
    background: Color(0xFF0A0A0A),
    surface: Color(0xFF121212),
    surfaceElevated: Color(0xFF1A1A1A),
    surfaceHighlight: Color(0xFF242424),
    card: Color(0xFF181818),
    cardHover: Color(0xFF282828),
    border: Color(0xFF2A2A2A),
    borderSubtle: Color(0xFF1E1E1E),
    divider: Color(0xFF282828),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB3B3B3),
    textTertiary: Color(0xFF6A6A6A),
    textDisabled: Color(0xFF404040),
    accent: Color(0xFF1DB954),
    accentDim: Color(0xFF1AA34A),
    accentSurface: Color(0x1A1DB954),
    pink: Color(0xFFE8618C),
    green: Color(0xFF1DB954),
    red: Color(0xFFE85C5C),
    amber: Color(0xFFD4A842),
    glass: Color(0x0DFFFFFF),
    glassActive: Color(0x1AFFFFFF),
    glassBorder: Color(0x14FFFFFF),
  );

  static const light = AppColorScheme(
    background: Color(0xFFF5F5F7),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceHighlight: Color(0xFFECECEE),
    card: Color(0xFFF0F0F2),
    cardHover: Color(0xFFE6E6EA),
    border: Color(0xFFD8D8DC),
    borderSubtle: Color(0xFFE4E4E8),
    divider: Color(0xFFE0E0E4),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF5C5C66),
    textTertiary: Color(0xFF9898A0),
    textDisabled: Color(0xFFBBBBC2),
    accent: Color(0xFF1DB954),
    accentDim: Color(0xFF1AA34A),
    accentSurface: Color(0x1A1DB954),
    pink: Color(0xFFE8618C),
    green: Color(0xFF1DB954),
    red: Color(0xFFE85C5C),
    amber: Color(0xFFD4A842),
    glass: Color(0x0D000000),
    glassActive: Color(0x1A000000),
    glassBorder: Color(0x14000000),
  );

  // ─────────────────────────────────────────────────────────
  // Convenience accessor
  // ─────────────────────────────────────────────────────────

  static AppColorScheme of(BuildContext context) {
    return Theme.of(context).extension<AppColorScheme>()!;
  }

  // ─────────────────────────────────────────────────────────
  // ThemeExtension overrides
  // ─────────────────────────────────────────────────────────

  @override
  AppColorScheme copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceHighlight,
    Color? card,
    Color? cardHover,
    Color? border,
    Color? borderSubtle,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? accent,
    Color? accentDim,
    Color? accentSurface,
    Color? pink,
    Color? green,
    Color? red,
    Color? amber,
    Color? glass,
    Color? glassActive,
    Color? glassBorder,
  }) {
    return AppColorScheme(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceHighlight: surfaceHighlight ?? this.surfaceHighlight,
      card: card ?? this.card,
      cardHover: cardHover ?? this.cardHover,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      accent: accent ?? this.accent,
      accentDim: accentDim ?? this.accentDim,
      accentSurface: accentSurface ?? this.accentSurface,
      pink: pink ?? this.pink,
      green: green ?? this.green,
      red: red ?? this.red,
      amber: amber ?? this.amber,
      glass: glass ?? this.glass,
      glassActive: glassActive ?? this.glassActive,
      glassBorder: glassBorder ?? this.glassBorder,
    );
  }

  @override
  AppColorScheme lerp(AppColorScheme? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceHighlight: Color.lerp(surfaceHighlight, other.surfaceHighlight, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardHover: Color.lerp(cardHover, other.cardHover, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentDim: Color.lerp(accentDim, other.accentDim, t)!,
      accentSurface: Color.lerp(accentSurface, other.accentSurface, t)!,
      pink: Color.lerp(pink, other.pink, t)!,
      green: Color.lerp(green, other.green, t)!,
      red: Color.lerp(red, other.red, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      glassActive: Color.lerp(glassActive, other.glassActive, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
    );
  }
}
