import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_color_scheme.dart';
import '../../../../data/models/radio_country.dart';
import '../../domain/radio_tab.dart';
import '../../state/radio_controller.dart';
import 'glass.dart';

class CountryFilter extends StatelessWidget {
  const CountryFilter({required this.controller, super.key});

  final RadioController controller;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final selectedCountry = _selectedCountryLabel();
    final countriesReady = controller.countriesReady;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.public_rounded,
            size: 18,
            color: c.textTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: countriesReady
                    ? () => unawaited(_showCountrySearch(context))
                    : null,
                child: InputDecorator(
                  isEmpty: false,
                  decoration: compactGlassInputDecoration(context).copyWith(
                    suffixIcon: Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: countriesReady
                          ? c.textSecondary
                          : c.textDisabled,
                    ),
                  ),
                  child: Text(
                    countriesReady ? selectedCountry : 'Loading countries...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: countriesReady
                          ? c.textPrimary
                          : c.textDisabled,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 78,
            child: Text(
              controller.stationCount > 0
                  ? '${controller.stationCount} stations'
                  : '',
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                color: c.textTertiary,
                fontSize: 11,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _selectedCountryLabel() {
    if (controller.selectedCountry.isEmpty) {
      return 'All Countries';
    }

    for (final country in controller.countries) {
      if (country.code == controller.selectedCountry) {
        return '${country.name} (${country.stationCount})';
      }
    }

    return controller.selectedCountry;
  }

  Future<void> _showCountrySearch(BuildContext context) async {
    final selectedCode = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black38,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _CountrySearchSheet(
          countries: controller.countries,
          selectedCountry: controller.selectedCountry,
        );
      },
    );

    if (selectedCode != null) {
      await _changeCountry(selectedCode);
    }
  }

  Future<void> _changeCountry(String? value) async {
    await controller.setCountry(value ?? '');
    if (controller.currentTab != RadioTab.discover) {
      await controller.switchTab(RadioTab.discover);
    } else {
      await controller.loadDiscover();
    }
  }
}

class _CountrySearchSheet extends StatefulWidget {
  const _CountrySearchSheet({
    required this.countries,
    required this.selectedCountry,
  });

  final List<RadioCountry> countries;
  final String selectedCountry;

  @override
  State<_CountrySearchSheet> createState() => _CountrySearchSheetState();
}

class _CountrySearchSheetState extends State<_CountrySearchSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = _searchController.text.trim().toLowerCase();
    final filteredCountries = widget.countries.where((country) {
      if (query.isEmpty) {
        return true;
      }
      return country.name.toLowerCase().contains(query) ||
          country.code.toLowerCase().contains(query);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.30)
                              : Colors.black.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Select Country',
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 14,
                ),
                cursorColor: c.textPrimary,
                decoration: glassInputDecoration(
                  context: context,
                  hintText: 'Search country',
                  prefixIcon: Icons.search_rounded,
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _CountryOptionTile(
                title: 'All Countries',
                subtitle: '${widget.countries.length} countries',
                selected: widget.selectedCountry.isEmpty,
                onTap: () => Navigator.of(context).pop(''),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: filteredCountries.isEmpty
                    ? Center(
                        child: Text(
                          'No countries found',
                          style: TextStyle(
                            color: c.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.separated(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: filteredCountries.length,
                        separatorBuilder: (_, __) => Divider(
                          color: c.divider,
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final country = filteredCountries[index];

                          return _CountryOptionTile(
                            title: country.name,
                            subtitle:
                                '${country.code} - ${country.stationCount} stations',
                            selected: country.code == widget.selectedCountry,
                            onTap: () =>
                                Navigator.of(context).pop(country.code),
                          );
                        },
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

class _CountryOptionTile extends StatelessWidget {
  const _CountryOptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    return Material(
      color: selected ? c.accentSurface : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.textTertiary,
                        fontSize: 11,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_rounded,
                  color: c.textPrimary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
