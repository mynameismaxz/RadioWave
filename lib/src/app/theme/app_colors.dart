import 'package:flutter/material.dart';

/// Spotify-minimal inspired color palette.
/// Deep blacks, muted neutrals, single green accent.
class AppColors {
  // ── Backgrounds ──
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceElevated = Color(0xFF1A1A1A);
  static const Color surfaceHighlight = Color(0xFF242424);
  static const Color card = Color(0xFF181818);
  static const Color cardHover = Color(0xFF282828);

  // ── Borders & separators ──
  static const Color border = Color(0xFF2A2A2A);
  static const Color borderSubtle = Color(0xFF1E1E1E);
  static const Color divider = Color(0xFF282828);

  // ── Text ──
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textTertiary = Color(0xFF6A6A6A);
  static const Color textDisabled = Color(0xFF404040);

  // ── Accent ──
  static const Color accent = Color(0xFF1DB954);
  static const Color accentDim = Color(0xFF1AA34A);
  static const Color accentSurface = Color(0x1A1DB954);

  // ── Semantic ──
  static const Color pink = Color(0xFFE8618C);
  static const Color green = Color(0xFF1DB954);
  static const Color red = Color(0xFFE85C5C);
  static const Color amber = Color(0xFFD4A842);

  // ── Glass (legacy compat) ──
  static const Color glass = Color(0x0DFFFFFF);
  static const Color glassActive = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x14FFFFFF);
}
