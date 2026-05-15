import 'package:flutter/material.dart';

import '../../../../app/theme/app_color_scheme.dart';

InputDecoration glassInputDecoration({
  required BuildContext context,
  String? hintText,
  IconData? prefixIcon,
  Widget? suffixIcon,
}) {
  final c = AppColorScheme.of(context);
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
    fillColor: c.surfaceHighlight,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide(color: c.textSecondary, width: 1),
    ),
  );
}

InputDecoration compactGlassInputDecoration(BuildContext context) {
  final c = AppColorScheme.of(context);
  return InputDecoration(
    filled: true,
    fillColor: c.surfaceHighlight,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c.textSecondary, width: 1),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  );
}

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        splashColor: c.accent.withValues(alpha: 0.08),
        highlightColor: c.accent.withValues(alpha: 0.04),
        child: Ink(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? c.surfaceHighlight : Colors.transparent,
            border: Border.all(
              color: active ? c.border : c.borderSubtle,
              width: active ? 1 : 0.5,
            ),
            borderRadius: BorderRadius.circular(999),
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
    );
  }
}
