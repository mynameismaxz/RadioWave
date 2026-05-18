import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_color_scheme.dart';
import '../../../../app/theme/theme_notifier.dart';
import '../../domain/radio_tab.dart';
import '../../state/radio_controller.dart';
import 'glass.dart';
import 'logo.dart';

class AppHeader extends StatefulWidget {
  const AppHeader({
    required this.controller,
    this.wide = false,
    super.key,
  });

  final RadioController controller;
  final bool wide;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final searchField = TextField(
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
        hintText: compact ? 'Search stations' : 'What do you want to listen to?',
        prefixIcon: Icons.search_rounded,
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
    );

    if (widget.wide) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 16),
        child: Row(
          children: <Widget>[
            const SizedBox(width: 72),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: searchField,
              ),
            ),
            const Spacer(),
            _ThemeToggleButton(isDark: isDark),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: <Widget>[
          if (!compact) const Logo(),
          if (!compact) const SizedBox(width: 12),
          Expanded(child: searchField),
          const SizedBox(width: 8),
          _ThemeToggleButton(isDark: isDark),
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

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);

    return IconButton(
      tooltip: isDark ? 'Light mode' : 'Dark mode',
      onPressed: themeNotifier.toggle,
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        color: c.textSecondary,
        size: 22,
      ),
    );
  }
}
