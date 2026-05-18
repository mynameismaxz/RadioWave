import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_color_scheme.dart';
import '../../../../data/models/app_toast.dart';

class ToastOverlay extends StatelessWidget {
  const ToastOverlay({required this.toasts, super.key});

  final List<AppToast> toasts;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 14,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: Column(
          children: toasts.map((toast) => ToastCard(toast: toast)).toList(),
        ),
      ),
    );
  }
}

class ToastCard extends StatelessWidget {
  const ToastCard({required this.toast, super.key});

  final AppToast toast;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final color = switch (toast.type) {
      ToastType.error => c.red,
      ToastType.success => c.accent,
      ToastType.info => c.textSecondary,
    };
    final icon = switch (toast.type) {
      ToastType.error => Icons.error_outline_rounded,
      ToastType.success => Icons.check_circle_outline_rounded,
      ToastType.info => Icons.info_outline_rounded,
    };

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  c.glassHighlight,
                  c.glassBase,
                  c.glassDeep,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: 0.35),
                width: 0.9,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    toast.message,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
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
