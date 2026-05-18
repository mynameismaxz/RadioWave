import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_color_scheme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LiquidGlassContainer
//
// A frosted-glass card that works in both dark and light mode.
// Uses BackdropFilter blur + layered gradients to simulate liquid glass:
//   • Diffuse fill   – semi-transparent base
//   • Top highlight  – bright stripe along the top edge
//   • Inner shine    – soft specular oval in the upper-left
//   • Prismatic rim  – blue-tinted border
//   • Bottom shadow  – dark drop at the bottom
// ─────────────────────────────────────────────────────────────────────────────

class LiquidGlassContainer extends StatelessWidget {
  const LiquidGlassContainer({
    required this.child,
    this.borderRadius = 20,
    this.blurSigma = 28,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.elevation = true,
    super.key,
  });

  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool elevation;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: CustomPaint(
            painter: _LiquidGlassPainter(
              isDark: isDark,
              borderRadius: borderRadius,
              glassBase: c.glassBase,
              glassHighlight: c.glassHighlight,
              glassShine: c.glassShine,
              glassEdge: c.glassEdge,
              glassDeep: c.glassDeep,
              liquidTint: c.liquidTint,
            ),
            child: Container(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws all the liquid-glass layers directly onto the canvas so they sit
/// perfectly inside the clipped region without extra Container nesting.
class _LiquidGlassPainter extends CustomPainter {
  _LiquidGlassPainter({
    required this.isDark,
    required this.borderRadius,
    required this.glassBase,
    required this.glassHighlight,
    required this.glassShine,
    required this.glassEdge,
    required this.glassDeep,
    required this.liquidTint,
  });

  final bool isDark;
  final double borderRadius;
  final Color glassBase;
  final Color glassHighlight;
  final Color glassShine;
  final Color glassEdge;
  final Color glassDeep;
  final Color liquidTint;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    // 1 ── Diffuse base fill
    canvas.drawRRect(rr, Paint()..color = glassBase);

    // 2 ── Diagonal gradient (top-left bright, bottom-right dim)
    final diagGrad = ui.Gradient.linear(
      Offset.zero,
      Offset(size.width, size.height),
      [glassHighlight, Colors.transparent, glassDeep],
      [0.0, 0.45, 1.0],
    );
    canvas.drawRRect(rr, Paint()..shader = diagGrad);

    // 3 ── Liquid tint (accent cast)
    canvas.drawRRect(rr, Paint()..color = liquidTint);

    // 4 ── Top-edge highlight stripe
    final highlightH = size.height * 0.38;
    final topHighlight = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(0, highlightH),
      [glassHighlight, Colors.transparent],
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, size.width, highlightH),
        topLeft: Radius.circular(borderRadius),
        topRight: Radius.circular(borderRadius),
      ),
      Paint()..shader = topHighlight,
    );

    // 5 ── Specular inner shine (oval in upper-left)
    final shineRect = Rect.fromLTWH(
      size.width * 0.05,
      size.height * 0.04,
      size.width * 0.55,
      size.height * 0.30,
    );
    final shineGrad = ui.Gradient.radial(
      shineRect.center,
      shineRect.width * 0.5,
      [glassShine, Colors.transparent],
    );
    canvas.drawOval(shineRect, Paint()..shader = shineGrad);

    // 6 ── Bottom shadow (depth)
    final bottomShadow = ui.Gradient.linear(
      Offset(0, size.height * 0.65),
      Offset(0, size.height),
      [Colors.transparent, glassDeep],
    );
    canvas.drawRRect(rr, Paint()..shader = bottomShadow);

    // 7 ── Prismatic rim border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(size.width, size.height),
        [glassEdge, glassHighlight, glassEdge],
        [0.0, 0.5, 1.0],
      );
    canvas.drawRRect(rr, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassPainter old) =>
      old.isDark != isDark ||
      old.glassBase != glassBase ||
      old.glassHighlight != glassHighlight;
}

// ─────────────────────────────────────────────────────────────────────────────
// GlassButton — pill-shaped liquid glass tab / toggle button
// ─────────────────────────────────────────────────────────────────────────────

class GlassButton extends StatelessWidget {
  const GlassButton({
    required this.child,
    required this.onPressed,
    this.active = false,
    super.key,
  });

  final Widget child;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPressed,
            splashColor: c.accent.withValues(alpha: 0.10),
            highlightColor: c.accent.withValues(alpha: 0.06),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: active
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          (isDark ? Colors.white : c.accent)
                              .withValues(alpha: isDark ? 0.22 : 0.18),
                          (isDark ? Colors.white : c.accent)
                              .withValues(alpha: isDark ? 0.08 : 0.06),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          c.glassHighlight,
                          c.glassBase,
                        ],
                      ),
                border: Border.all(
                  color: active
                      ? (isDark ? Colors.white : c.accent)
                          .withValues(alpha: 0.35)
                      : c.glassEdge,
                  width: active ? 1.0 : 0.8,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: (isDark ? Colors.white : c.accent)
                              .withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: active ? c.textPrimary : c.textSecondary,
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0,
                ),
                child: IconTheme(
                  data: IconThemeData(
                    color: active ? c.textPrimary : c.textSecondary,
                    size: 16,
                  ),
                  child: Center(child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input Decorations — glass-styled text fields
// ─────────────────────────────────────────────────────────────────────────────

InputDecoration glassInputDecoration({
  required BuildContext context,
  String? hintText,
  IconData? prefixIcon,
  Widget? suffixIcon,
}) {
  final c = AppColorScheme.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(
      color: c.textTertiary,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, size: 20, color: c.textTertiary),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: isDark ? c.surfaceHighlight : c.surfaceElevated,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide(color: c.textTertiary.withValues(alpha: 0.5), width: 1),
    ),
  );
}

InputDecoration compactGlassInputDecoration(BuildContext context) {
  final c = AppColorScheme.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    filled: true,
    fillColor: isDark ? c.surfaceHighlight : c.surfaceElevated,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c.glassEdge, width: 0.8),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c.textSecondary.withValues(alpha: 0.5), width: 1),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );
}
