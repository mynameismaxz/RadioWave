import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radio_app_flutter/src/app/theme/theme_notifier.dart';
import 'package:radio_app_flutter/src/data/models/station.dart';
import 'package:radio_app_flutter/src/data/services/equalizer_settings_store.dart';
import 'package:radio_app_flutter/src/data/services/playback_state_store.dart';
import 'package:radio_app_flutter/src/features/radio/domain/radio_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('creates a custom station favorite payload', () {
    final station =
        Station.custom('Local FM', 'https://example.com/stream.mp3');

    expect(station.name, 'Local FM');
    expect(station.url, 'https://example.com/stream.mp3');
    expect(station.tags, contains('custom'));
    expect(station.lastCheckOk, isTrue);
    expect(station.toFavoriteJson()['name'], 'Local FM');
  });

  test('reads Radio Browser station health from lastcheckok', () {
    final station = Station.fromRadioBrowser({
      'stationuuid': 'station-1',
      'name': 'Healthy FM',
      'url': 'https://example.com/stream.mp3',
      'lastcheckok': 1,
    });

    expect(station.lastCheckOk, isTrue);

    final brokenStation = Station.fromRadioBrowser({
      'stationuuid': 'station-2',
      'name': 'Broken FM',
      'url': 'https://example.com/broken.mp3',
      'lastcheckok': 0,
    });

    expect(brokenStation.lastCheckOk, isFalse);
  });

  test('persists the last playback station state', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PlaybackStateStore();
    await store.init();

    final station = Station.custom('Saved FM', 'https://example.com/saved.mp3');
    await store.save(station: station, wasPlaying: true);

    final restored = store.load();

    expect(restored, isNotNull);
    expect(restored!.station.name, 'Saved FM');
    expect(restored.station.url, 'https://example.com/saved.mp3');
    expect(restored.wasPlaying, isTrue);
  });

  test('persists equalizer settings', () async {
    SharedPreferences.setMockInitialValues({});
    final store = EqualizerSettingsStore();
    await store.init();

    await store.save(
      enabled: true,
      preset: 'Rock',
      gains: <double>[3, 2, -1, -1, 1, 4],
    );

    final restored = store.load();

    expect(restored, isNotNull);
    expect(restored!.enabled, isTrue);
    expect(restored.preset, 'Rock');
    expect(restored.gains, <double>[3, 2, -1, -1, 1, 4]);
  });

  test('radio tabs expose user-facing labels', () {
    expect(RadioTab.discover.label, 'Discover');
    expect(RadioTab.favorites.label, 'Favorites');
    expect(RadioTab.equalizer.label, 'Equalizer');
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
