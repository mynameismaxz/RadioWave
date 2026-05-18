import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_color_scheme.dart';
import '../../domain/radio_tab.dart';
import '../../state/radio_controller.dart';
import 'logo.dart';
import 'tab_nav.dart';

/// TIDAL-style left rail for wide layouts.
class SidebarNav extends StatelessWidget {
  const SidebarNav({required this.controller, super.key});

  final RadioController controller;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);

    return Container(
      width: 240,
      color: c.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Logo(compact: true),
              const SizedBox(height: 32),
              ...RadioTab.values.map((tab) {
                final active = controller.currentTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _SidebarItem(
                    tab: tab,
                    active: active,
                    badgeCount: tab == RadioTab.favorites
                        ? controller.favoriteCount
                        : 0,
                    onTap: () => unawaited(controller.switchTab(tab)),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
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
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              Icon(
                tab.icon,
                size: 22,
                color: active ? c.textPrimary : c.textSecondary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? c.textPrimary : c.textSecondary,
                    fontSize: 15,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (badgeCount > 0)
                FavoriteCountBadge(count: badgeCount),
            ],
          ),
        ),
      ),
    );
  }
}
