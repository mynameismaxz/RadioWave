import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_color_scheme.dart';
import '../../../../app/theme/theme_notifier.dart';
import '../../domain/radio_tab.dart';
import '../../state/radio_controller.dart';
import 'glass.dart';
import 'logo.dart';

class AppHeader extends StatefulWidget {
  const AppHeader({required this.controller, super.key});

  final RadioController controller;

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;

  @override
  void didUpdateWidget(covariant AppHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller.searchQuery != _searchController.text) {
      _searchController.text = widget.controller.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;
    final c = AppColorScheme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: <Widget>[
          if (!compact) const Logo(),
          if (!compact) const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: c.textPrimary,
              ),
              cursorColor: c.textPrimary,
              decoration: glassInputDecoration(
                context: context,
                hintText: compact ? 'Search...' : 'What do you want to listen to?',
                prefixIcon: compact ? Icons.radio_rounded : Icons.search_rounded,
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () => unawaited(_clearSearch()),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: c.textTertiary,
                        ),
                      ),
              ),
              onChanged: _onSearchChanged,
              onSubmitted: (_) => unawaited(_runSearch()),
            ),
          ),
          const SizedBox(width: 10),
          _ThemeToggleButton(),
        ],
      ),
    );
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchTimer?.cancel();
    _searchTimer = Timer(
      const Duration(milliseconds: 400),
      () => unawaited(_runSearch()),
    );
  }

  Future<void> _runSearch() async {
    await widget.controller.setSearchQuery(_searchController.text.trim());
    if (widget.controller.currentTab != RadioTab.discover) {
      await widget.controller.switchTab(RadioTab.discover);
    } else {
      await widget.controller.loadDiscover();
    }
  }

  Future<void> _clearSearch() async {
    _searchTimer?.cancel();
    _searchController.clear();
    setState(() {});
    await widget.controller.setSearchQuery('');
    if (widget.controller.currentTab != RadioTab.discover) {
      await widget.controller.switchTab(RadioTab.discover);
    } else {
      await widget.controller.loadDiscover();
    }
  }
}

/// Animated dark / light mode toggle button.
class _ThemeToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final isDark = themeNotifier.isDark;

    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: c.surfaceHighlight,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: themeNotifier.toggle,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) {
                return RotationTransition(
                  turns: Tween<double>(begin: 0.75, end: 1.0).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                );
              },
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey(isDark),
                size: 20,
                color: isDark ? const Color(0xFFFFC107) : const Color(0xFF5C6BC0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
