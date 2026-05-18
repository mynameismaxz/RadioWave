import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radio_app_flutter/src/app/theme/theme_notifier.dart';
import 'package:radio_app_flutter/src/data/models/station.dart';
import 'package:radio_app_flutter/src/features/radio/domain/radio_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('creates a custom station favorite payload', () {
    final station =
        Station.custom('Local FM', 'https://example.com/stream.mp3');

    expect(station.name, 'Local FM');
    expect(station.url, 'https://example.com/stream.mp3');
    expect(station.tags, contains('custom'));
    expect(station.toFavoriteJson()['name'], 'Local FM');
  });

  test('radio tabs expose user-facing labels', () {
    expect(RadioTab.discover.label, 'Discover');
    expect(RadioTab.favorites.label, 'Favorites');
    expect(RadioTab.add.label, 'Add Station');
  });

  test('theme notifier restores and persists the selected mode', () async {
    SharedPreferences.setMockInitialValues({
      'radiowave_theme_mode': ThemeMode.light.name,
    });

    final notifier = ThemeNotifier();
    await notifier.init();

    expect(notifier.value, ThemeMode.light);

    await notifier.setMode(ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();

    expect(prefs.getString('radiowave_theme_mode'), ThemeMode.dark.name);
  });
}
