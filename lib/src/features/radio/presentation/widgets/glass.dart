import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

InputDecoration glassInputDecoration({
  String? hintText,
  IconData? prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(
      color: AppColors.textTertiary,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, size: 20, color: AppColors.textTertiary),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.surfaceHighlight,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: const BorderSide(color: AppColors.textSecondary, width: 1),
    ),
  );
}

InputDecoration compactGlassInputDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: AppColors.surfaceHighlight,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.textSecondary, width: 1),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        splashColor: AppColors.accent.withValues(alpha: 0.08),
        highlightColor: AppColors.accent.withValues(alpha: 0.04),
        child: Ink(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.surfaceHighlight : Colors.transparent,
            border: Border.all(
              color: active ? AppColors.border : AppColors.borderSubtle,
              width: active ? 1 : 0.5,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: 0,
            ),
            child: IconTheme(
              data: IconThemeData(
                color: active ? AppColors.textPrimary : AppColors.textSecondary,
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
