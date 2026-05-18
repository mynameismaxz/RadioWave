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
    // Liquid Glass extras
    required this.glassBase,
    required this.glassHighlight,
    required this.glassShine,
    required this.glassEdge,
    required this.glassDeep,
    required this.liquidTint,
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

  // ── Liquid Glass ──
  final Color glassBase;      // main fill
  final Color glassHighlight; // top-edge highlight stripe
  final Color glassShine;     // specular inner glow
  final Color glassEdge;      // rim/border prismatic tint
  final Color glassDeep;      // darker bottom fill
  final Color liquidTint;     // subtle color cast (accent-based)

  // ─────────────────────────────────────────────────────────
  // Presets
  // ─────────────────────────────────────────────────────────

  static const dark = AppColorScheme(
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    surfaceElevated: Color(0xFF141414),
    surfaceHighlight: Color(0xFF1A1A1A),
    card: Color(0xFF181818),
    cardHover: Color(0xFF282828),
    border: Color(0xFF2A2A2A),
    borderSubtle: Color(0xFF1F1F1F),
    divider: Color(0xFF242424),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB3B3B3),
    textTertiary: Color(0xFF999999),
    textDisabled: Color(0xFF5A5A5A),
    accent: Color(0xFFFFFFFF),
    accentDim: Color(0xFFE0E0E0),
    accentSurface: Color(0xFF282828),
    pink: Color(0xFFE8618C),
    green: Color(0xFF1DB954),
    red: Color(0xFFE85C5C),
    amber: Color(0xFFC8A861),
    glass: Color(0x0DFFFFFF),
    glassActive: Color(0x1AFFFFFF),
    glassBorder: Color(0x14FFFFFF),
    glassBase: Color(0xFF181818),
    glassHighlight: Color(0xFF222222),
    glassShine: Color(0x08FFFFFF),
    glassEdge: Color(0xFF333333),
    glassDeep: Color(0xFF0A0A0A),
    liquidTint: Color(0x00000000),
  );

  static const light = AppColorScheme(
    background: Color(0xFFF0F4FA),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFAFCFF),
    surfaceHighlight: Color(0xFFE8EFF8),
    card: Color(0xFFF5F8FF),
    cardHover: Color(0xFFE0E8F5),
    border: Color(0xFFCCD5E4),
    borderSubtle: Color(0xFFDDE4F0),
    divider: Color(0xFFD5DFF0),
    textPrimary: Color(0xFF0F1828),
    textSecondary: Color(0xFF4A5A72),
    textTertiary: Color(0xFF8A9AB2),
    textDisabled: Color(0xFFB8C4D8),
    accent: Color(0xFF1DB954),
    accentDim: Color(0xFF1AA34A),
    accentSurface: Color(0x1A1DB954),
    pink: Color(0xFFE8618C),
    green: Color(0xFF1DB954),
    red: Color(0xFFE85C5C),
    amber: Color(0xFFD4A842),
    glass: Color(0x14FFFFFF),
    glassActive: Color(0x22FFFFFF),
    glassBorder: Color(0x30FFFFFF),
    // Liquid Glass
    glassBase: Color(0x55FFFFFF),
    glassHighlight: Color(0x70FFFFFF),
    glassShine: Color(0x40FFFFFF),
    glassEdge: Color(0x50A8C8FF),
    glassDeep: Color(0x18C0D8FF),
    liquidTint: Color(0x0A1DB954),
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
    Color? glassBase,
    Color? glassHighlight,
    Color? glassShine,
    Color? glassEdge,
    Color? glassDeep,
    Color? liquidTint,
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
      glassBase: glassBase ?? this.glassBase,
      glassHighlight: glassHighlight ?? this.glassHighlight,
      glassShine: glassShine ?? this.glassShine,
      glassEdge: glassEdge ?? this.glassEdge,
      glassDeep: glassDeep ?? this.glassDeep,
      liquidTint: liquidTint ?? this.liquidTint,
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
      glassBase: Color.lerp(glassBase, other.glassBase, t)!,
      glassHighlight: Color.lerp(glassHighlight, other.glassHighlight, t)!,
      glassShine: Color.lerp(glassShine, other.glassShine, t)!,
      glassEdge: Color.lerp(glassEdge, other.glassEdge, t)!,
      glassDeep: Color.lerp(glassDeep, other.glassDeep, t)!,
      liquidTint: Color.lerp(liquidTint, other.liquidTint, t)!,
    );
  }
}
