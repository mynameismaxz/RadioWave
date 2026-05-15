import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/radio_tab.dart';
import '../../state/radio_controller.dart';
import 'glass.dart';

class TabNav extends StatelessWidget {
  const TabNav({required this.controller, super.key});

  final RadioController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: RadioTab.values.map((tab) {
          final active = controller.currentTab == tab;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GlassButton(
                active: active,
                onPressed: () => unawaited(controller.switchTab(tab)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(tab.icon, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        tab.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tab == RadioTab.favorites && controller.favoriteCount > 0) ...<Widget>[
                      const SizedBox(width: 6),
                      FavoriteCountBadge(count: controller.favoriteCount),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class FavoriteCountBadge extends StatelessWidget {
  const FavoriteCountBadge({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
            color: AppColors.background,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
