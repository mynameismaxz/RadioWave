import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/radio_tab.dart';
import '../../state/radio_controller.dart';
import 'glass.dart';

class CountryFilter extends StatelessWidget {
  const CountryFilter({required this.controller, super.key});

  final RadioController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.public_rounded,
            size: 18,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: controller.selectedCountry,
              isExpanded: true,
              decoration: compactGlassInputDecoration(),
              dropdownColor: AppColors.surfaceElevated,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('All Countries'),
                ),
                ...controller.countries.map((country) {
                  return DropdownMenuItem<String>(
                    value: country.code,
                    child: Text(
                      '${country.name} (${country.stationCount})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: controller.countriesReady
                  ? (value) => unawaited(_changeCountry(value))
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 78,
            child: Text(
              controller.stationCount > 0 ? '${controller.stationCount} stations' : '',
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
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
