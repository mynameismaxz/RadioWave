import 'package:flutter_test/flutter_test.dart';
import 'package:radio_app_flutter/src/data/models/station.dart';
import 'package:radio_app_flutter/src/features/radio/domain/radio_tab.dart';

void main() {
  test('creates a custom station favorite payload', () {
    final station = Station.custom('Local FM', 'https://example.com/stream.mp3');

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
}
