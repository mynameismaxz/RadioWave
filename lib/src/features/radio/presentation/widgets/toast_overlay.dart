import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
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
    final color = switch (toast.type) {
      ToastType.error => AppColors.red,
      ToastType.success => AppColors.accent,
      ToastType.info => AppColors.textSecondary,
    };
    final icon = switch (toast.type) {
      ToastType.error => Icons.error_outline_rounded,
      ToastType.success => Icons.check_circle_outline_rounded,
      ToastType.info => Icons.info_outline_rounded,
    };

    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                toast.message,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
