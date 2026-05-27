import 'dart:convert';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radio_app_flutter/src/app/theme/theme_notifier.dart';
import 'package:radio_app_flutter/src/data/models/listening_history_entry.dart';
import 'package:radio_app_flutter/src/data/models/station.dart';
import 'package:radio_app_flutter/src/data/services/android_auto_media_library.dart';
import 'package:radio_app_flutter/src/data/services/equalizer_settings_store.dart';
import 'package:radio_app_flutter/src/data/services/listening_history_store.dart';
import 'package:radio_app_flutter/src/data/services/playback_state_store.dart';
import 'package:radio_app_flutter/src/data/services/radio_browser_api.dart';
import 'package:radio_app_flutter/src/data/services/radio_audio_handler.dart';
import 'package:radio_app_flutter/src/features/radio/domain/personalized_station_sorter.dart';
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

  test('persists station listening history and increments play count',
      () async {
    SharedPreferences.setMockInitialValues({});
    var now = DateTime.utc(2026, 1, 1, 10);
    final store = ListeningHistoryStore(now: () => now);
    await store.init();

    final station = testStation(
      uuid: 'rock-fm',
      name: 'Rock FM',
      tags: const <String>['rock', 'indie'],
    );
    await store.recordPlay(station);
    now = DateTime.utc(2026, 1, 1, 11);
    await store.recordPlay(station);

    final restoredStore = ListeningHistoryStore(now: () => now);
    await restoredStore.init();
    final entries = restoredStore.getEntries();

    expect(entries, hasLength(1));
    expect(entries.single.station.uuid, 'rock-fm');
    expect(entries.single.playCount, 2);
    expect(entries.single.lastPlayedAt, DateTime.utc(2026, 1, 1, 11));
  });

  test('selects the top ten listening entries by user play count', () {
    final history = <ListeningHistoryEntry>[
      for (var index = 0; index < 12; index += 1)
        ListeningHistoryEntry(
          station: testStation(
            uuid: 'station-$index',
            name: 'Station $index',
            tags: <String>['tag-$index'],
          ),
          playCount: index + 1,
          lastPlayedAt: DateTime.utc(2026, 1, index + 1),
        ),
    ];

    final entries = topListeningEntries(history, limit: 10);

    expect(
      entries.map((entry) => entry.station.uuid),
      <String>[
        'station-11',
        'station-10',
        'station-9',
        'station-8',
        'station-7',
        'station-6',
        'station-5',
        'station-4',
        'station-3',
        'station-2',
      ],
    );
  });

  test('requests popular API stations by user genre tag', () async {
    final requestedUris = <Uri>[];
    final client = Dio()
      ..httpClientAdapter = _RecordingAdapter((uri) {
        requestedUris.add(uri);
        return <Map<String, dynamic>>[
          <String, dynamic>{
            'stationuuid': 'rock-popular',
            'name': 'Rock Popular',
            'url': 'https://example.com/rock.mp3',
            'tags': 'rock',
            'clickcount': 900,
            'lastcheckok': 1,
          },
        ];
      });
    final api = RadioBrowserApi(client: client);

    final stations = await api.getTopStationsByTag('rock', limit: 4);

    expect(stations.map((station) => station.uuid), <String>['rock-popular']);
    expect(requestedUris.single.path, '/json/stations/search');
    expect(requestedUris.single.queryParameters['tag'], 'rock');
    expect(requestedUris.single.queryParameters['order'], 'clickcount');
    expect(requestedUris.single.queryParameters['reverse'], 'true');
    expect(requestedUris.single.queryParameters['limit'], '4');
  });

  test('builds For You from top ten plus four recommendations each', () {
    final entries = <ListeningHistoryEntry>[
      for (var index = 0; index < 10; index += 1)
        ListeningHistoryEntry(
          station: testStation(
            uuid: 'seed-$index',
            name: 'Seed $index',
            tags: <String>['tag-$index'],
          ),
          playCount: 100 - index,
          lastPlayedAt: DateTime.utc(2026, 1, index + 1),
        ),
    ];
    final recommendationsBySeed = <List<Station>>[
      for (var seed = 0; seed < 10; seed += 1)
        <Station>[
          for (var rec = 0; rec < 4; rec += 1)
            testStation(
              uuid: 'seed-$seed-rec-$rec',
              name: 'Seed $seed Recommendation $rec',
              tags: <String>['tag-$seed'],
            ),
        ],
    ];

    final stations = buildForYouStations(
      entries,
      recommendationsBySeed,
    );

    expect(
      stations.map((station) => station.uuid).take(10),
      <String>[
        'seed-0',
        'seed-1',
        'seed-2',
        'seed-3',
        'seed-4',
        'seed-5',
        'seed-6',
        'seed-7',
        'seed-8',
        'seed-9',
      ],
    );
    expect(stations, hasLength(50));
    expect(stations.skip(10).take(4).map((station) => station.uuid), <String>[
      'seed-0-rec-0',
      'seed-0-rec-1',
      'seed-0-rec-2',
      'seed-0-rec-3'
    ]);
    expect(stations.skip(46).map((station) => station.uuid), <String>[
      'seed-9-rec-0',
      'seed-9-rec-1',
      'seed-9-rec-2',
      'seed-9-rec-3'
    ]);
  });

  test('radio tabs expose user-facing labels', () {
    expect(RadioTab.discover.label, 'Discover');
    expect(RadioTab.favorites.label, 'Favorites');
    expect(RadioTab.equalizer.label, 'Equalizer');
    expect(RadioTab.add.label, 'Add Station');
  });

  test('android auto library exposes browse roots and playable station items',
      () async {
    SharedPreferences.setMockInitialValues({});
    final library = AndroidAutoMediaLibrary();
    addTearDown(library.dispose);

    final roots = await library.getChildren(AudioService.browsableRootId);
    expect(
      roots.map((item) => item.id),
      <String>[
        AndroidAutoMediaLibrary.favoritesRootId,
        AndroidAutoMediaLibrary.popularRootId,
      ],
    );
    expect(roots.every((item) => item.playable == false), isTrue);

    final station = Station.custom('Car FM', 'https://example.com/car.mp3');
    final item = library.mediaItemFor(station);

    expect(item.playable, isTrue);
    expect(item.isLive, isTrue);
    expect(item.title, 'Car FM');
    expect(library.streamUrlFor(item), 'https://example.com/car.mp3');
    expect(await library.getMediaItem(item.id), item);
  });

  test('radio notification uses one play pause control without stop action',
      () {
    final playingControls = radioNotificationControls(playing: true);
    final idleControls = radioNotificationControls(playing: false);

    expect(playingControls, <MediaControl>[MediaControl.pause]);
    expect(idleControls, <MediaControl>[MediaControl.play]);
    expect(playingControls, isNot(contains(MediaControl.stop)));
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

Station testStation({
  required String uuid,
  required String name,
  List<String> tags = const <String>[],
  int clickCount = 0,
}) {
  return Station(
    uuid: uuid,
    name: name,
    url: 'https://example.com/$uuid.mp3',
    homepage: '',
    favicon: '',
    tags: tags,
    country: '',
    countryCode: '',
    language: '',
    codec: 'MP3',
    bitrate: 128,
    votes: 0,
    clickCount: clickCount,
    lastCheckOk: true,
    raw: const <String, dynamic>{},
  );
}

class _RecordingAdapter implements HttpClientAdapter {
  const _RecordingAdapter(this.responseFor);

  final List<Map<String, dynamic>> Function(Uri uri) responseFor;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(responseFor(options.uri)),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
