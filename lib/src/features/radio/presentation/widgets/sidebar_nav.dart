import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_color_scheme.dart';
import '../../domain/radio_tab.dart';
import '../../state/radio_controller.dart';
import 'logo.dart';
import 'tab_nav.dart';

/// TIDAL-style left rail for wide layouts.
class SidebarNav extends StatelessWidget {
  const SidebarNav({
    required this.controller,
    required this.collapsed,
    required this.onToggleCollapsed,
    this.dense = false,
    this.width = 240,
    super.key,
  });

  final RadioController controller;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final bool dense;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final compact = collapsed || width < 220;

    return Container(
      width: width,
      color: c.background,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 20,
            dense ? 12 : 24,
            compact ? 8 : 12,
            dense ? 12 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (collapsed)
                _CollapseButton(
                  collapsed: collapsed,
                  onPressed: onToggleCollapsed,
                )
              else
                Row(
                  children: <Widget>[
                    const Expanded(child: Logo(compact: true)),
                    _CollapseButton(
                      collapsed: collapsed,
                      onPressed: onToggleCollapsed,
                    ),
                  ],
                ),
              SizedBox(height: dense ? 12 : (compact ? 24 : 32)),
              ...RadioTab.values.map((tab) {
                final active = controller.currentTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _SidebarItem(
                    tab: tab,
                    active: active,
                    compact: compact,
                    collapsed: collapsed,
                    dense: dense,
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
    required this.compact,
    required this.collapsed,
    required this.dense,
    required this.badgeCount,
    required this.onTap,
  });

  final RadioTab tab;
  final bool active;
  final bool compact;
  final bool collapsed;
  final bool dense;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);

    return Tooltip(
      message: collapsed ? tab.label : '',
      child: Material(
        color: active ? c.accentSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: dense ? 8 : 10,
            ),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: <Widget>[
                Icon(
                  tab.icon,
                  size: compact ? 20 : 22,
                  color: active ? c.textPrimary : c.textSecondary,
                ),
                if (!collapsed) ...<Widget>[
                  SizedBox(width: compact ? 10 : 14),
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
                  if (badgeCount > 0) FavoriteCountBadge(count: badgeCount),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CollapseButton extends StatelessWidget {
  const _CollapseButton({
    required this.collapsed,
    required this.onPressed,
  });

  final bool collapsed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);

    return Tooltip(
      message: collapsed ? 'Expand menu' : 'Collapse menu',
      child: IconButton(
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        icon: Icon(
          collapsed
              ? Icons.keyboard_double_arrow_right_rounded
              : Icons.keyboard_double_arrow_left_rounded,
          color: c.textSecondary,
          size: 22,
        ),
      ),
    );
  }
}
