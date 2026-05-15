import 'dart:async';

import 'package:flutter/material.dart';

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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              cursorColor: Colors.white,
              decoration: glassInputDecoration(
                hintText: 'What do you want to listen to?',
                prefixIcon: compact ? Icons.radio_rounded : Icons.search_rounded,
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () => unawaited(_clearSearch()),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                        ),
                      ),
              ),
              onChanged: _onSearchChanged,
              onSubmitted: (_) => unawaited(_runSearch()),
            ),
          ),
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
