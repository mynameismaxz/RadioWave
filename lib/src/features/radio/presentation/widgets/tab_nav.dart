import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_color_scheme.dart';
import '../../domain/radio_tab.dart';
import '../../state/radio_controller.dart';

class TabNav extends StatelessWidget {
  const TabNav({required this.controller, super.key});

  final RadioController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: RadioTab.values.map((tab) {
          final active = controller.currentTab == tab;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _TabChip(
                tab: tab,
                active: active,
                badgeCount: tab == RadioTab.favorites
                    ? controller.favoriteCount
                    : 0,
                onTap: () => unawaited(controller.switchTab(tab)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.tab,
    required this.active,
    required this.badgeCount,
    required this.onTap,
  });

  final RadioTab tab;
  final bool active;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);

    return Material(
      color: active ? c.accentSurface : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                tab.icon,
                size: 16,
                color: active ? c.textPrimary : c.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? c.textPrimary : c.textSecondary,
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (badgeCount > 0) ...<Widget>[
                const SizedBox(width: 6),
                FavoriteCountBadge(count: badgeCount),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class FavoriteCountBadge extends StatelessWidget {
  const FavoriteCountBadge({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: c.textPrimary,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Center(
        child: Text(
          '$count',
          style: TextStyle(
            color: c.background,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
