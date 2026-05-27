import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radio_app_flutter/src/data/models/radio_country.dart';
import 'package:radio_app_flutter/src/data/models/station.dart';
import 'package:radio_app_flutter/src/data/services/android_auto_media_library.dart';
import 'package:radio_app_flutter/src/data/services/favorites_store.dart';
import 'package:radio_app_flutter/src/data/services/radio_audio_handler.dart';
import 'package:radio_app_flutter/src/data/services/radio_browser_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FavoritesStore', () {
    test('loads only valid persisted favorites as an immutable list', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        FavoritesStore.storageKey: jsonEncode(<Object?>[
          testStation(uuid: 'valid', name: 'Valid FM').toFavoriteJson(),
          <String, Object?>{
            'uuid': 'missing-url',
            'name': 'Missing URL',
            'url': '',
          },
          'not-a-station',
        ]),
      });
      final store = FavoritesStore();

      await store.init();

      expect(store.getUuids(), <String>['valid']);
      expect(
        () => store.getAll().add(testStation(uuid: 'other', name: 'Other')),
        throwsUnsupportedError,
      );
    });

    test('adds, toggles, updates, and refreshes favorites immutably', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = FavoritesStore();
      await store.init();

      final alpha = testStation(uuid: 'alpha', name: 'Alpha');
      final beta = testStation(uuid: 'beta', name: 'Beta');

      expect(await store.add(alpha), isTrue);
      expect(await store.add(alpha), isFalse);
      expect(await store.toggle(beta), isTrue);
      expect(await store.toggle(beta), isFalse);
      expect(await store.remove('missing'), isFalse);

      await store.update(
        'alpha',
        testStation(uuid: 'alpha', name: 'Alpha Updated'),
      );
      await store.update('missing', testStation(uuid: 'missing', name: 'Nope'));
      await store.updateAll(<String, Station>{
        'alpha': testStation(uuid: 'alpha', name: 'Alpha Fresh'),
      });

      expect(store.getUuids(), <String>['alpha']);
      expect(store.getAll().single.name, 'Alpha Fresh');

      final prefs = await SharedPreferences.getInstance();
      expect(
          prefs.getString(FavoritesStore.storageKey), contains('Alpha Fresh'));
    });

    test('falls back to an empty list when persisted JSON is malformed',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        FavoritesStore.storageKey: '{bad json',
      });
      final store = FavoritesStore();

      await store.init();

      expect(store.getAll(), isEmpty);
    });
  });

  test('RadioCountry parses API JSON values safely', () {
    final country = RadioCountry.fromJson(<String, dynamic>{
      'name': 'Thailand',
      'iso_3166_1': 'TH',
      'stationcount': '123',
    });

    expect(country.name, 'Thailand');
    expect(country.code, 'TH');
    expect(country.stationCount, 123);
  });

  group('RadioBrowserApi', () {
    test('loads and caches country responses', () async {
      var calls = 0;
      final client = Dio()
        ..httpClientAdapter = _RecordingAdapter((uri) {
          calls += 1;
          expect(uri.path, '/json/countries');
          return <Map<String, dynamic>>[
            <String, dynamic>{
              'name': 'Thailand',
              'iso_3166_1': 'TH',
              'stationcount': 120,
            },
            <String, dynamic>{
              'name': 'Empty',
              'iso_3166_1': 'ZZ',
              'stationcount': 0,
            },
            <String, dynamic>{
              'name': 'No Code',
              'iso_3166_1': '',
              'stationcount': 10,
            },
          ];
        });
      final api = RadioBrowserApi(client: client);

      final first = await api.getCountries();
      final second = await api.getCountries();

      expect(calls, 1);
      expect(identical(first, second), isTrue);
      expect(first.map((country) => country.code), <String>['TH']);
    });

    test('returns no station lookup calls for an empty UUID list', () async {
      var calls = 0;
      final client = Dio()
        ..httpClientAdapter = _RecordingAdapter((uri) {
          calls += 1;
          return const <Map<String, dynamic>>[];
        });
      final api = RadioBrowserApi(client: client);

      expect(await api.getStationsByUuid(const <String>[]), isEmpty);
      expect(calls, 0);
    });

    test('deduplicates in-flight station requests by request key', () async {
      var calls = 0;
      final client = Dio()
        ..httpClientAdapter = _RecordingAdapter((uri) async {
          calls += 1;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return <Map<String, dynamic>>[
            <String, dynamic>{
              'stationuuid': 'popular',
              'name': 'Popular FM',
              'url': 'https://example.com/popular.mp3',
              'lastcheckok': 1,
            },
          ];
        });
      final api = RadioBrowserApi(client: client);

      final results = await Future.wait(<Future<List<Station>>>[
        api.getTopStations(limit: 1),
        api.getTopStations(limit: 1),
      ]);

      expect(calls, 1);
      expect(results.first.single.uuid, 'popular');
      expect(results.last.single.uuid, 'popular');
    });
  });

  group('AndroidAutoMediaLibrary', () {
    test('builds browsable station items and resolves stream URLs safely',
        () async {
      final favorites = _FakeFavoritesStore(<Station>[
        testStation(uuid: 'favorite', name: 'Favorite FM'),
        testStation(
          uuid: 'broken',
          name: 'Broken FM',
          lastCheckOk: false,
        ),
        testStation(
          uuid: 'custom-1',
          name: 'Custom FM',
          tags: const <String>['custom'],
          lastCheckOk: false,
        ),
      ]);
      final api = _FakeRadioBrowserApi(
        topStations: <Station>[testStation(uuid: 'popular', name: 'Popular')],
        searchStations: <Station>[testStation(uuid: 'search', name: 'Search')],
      );
      final library = AndroidAutoMediaLibrary(api: api, favorites: favorites);

      final roots = await library.getChildren(AudioService.browsableRootId);
      final favoriteItems =
          await library.getChildren(AndroidAutoMediaLibrary.favoritesRootId);
      final popularItems =
          await library.getChildren(AndroidAutoMediaLibrary.popularRootId);
      final emptySearch = await library.search('   ');
      final searchItems = await library.search(' rock ');
      final item = library.mediaItemFor(testStation(
        uuid: 'album',
        name: 'Album FM',
        country: 'Thailand',
        favicon: 'https://example.com/icon.png',
      ));

      expect(roots.map((root) => root.id), <String>[
        AndroidAutoMediaLibrary.favoritesRootId,
        AndroidAutoMediaLibrary.popularRootId,
      ]);
      expect(favoriteItems.map((favorite) => favorite.title), <String>[
        'Favorite FM',
        'Custom FM',
      ]);
      expect(popularItems.single.title, 'Popular');
      expect(emptySearch, isEmpty);
      expect(api.lastSearchQuery, 'rock');
      expect(searchItems.single.title, 'Search');
      expect(item.album, 'Thailand - MP3 - 128 kbps');
      expect(item.artUri, Uri.parse('https://example.com/icon.png'));
      expect(library.streamUrlFor(item), 'https://example.com/album.mp3');
      expect(
        library.streamUrlFor(const MediaItem(
          id: 'https://example.com/live.mp3',
          title: 'Direct URL',
        )),
        'https://example.com/live.mp3',
      );
      expect(
        library.streamUrlFor(const MediaItem(
          id: 'radiowave:station:no-url',
          title: 'No URL',
        )),
        isNull,
      );
    });

    test('returns empty browse results for recent and unknown roots', () async {
      final library = AndroidAutoMediaLibrary(
        api: _FakeRadioBrowserApi(),
        favorites: _FakeFavoritesStore(const <Station>[]),
      );

      expect(await library.getChildren(AudioService.recentRootId), isEmpty);
      expect(await library.getChildren('unknown'), isEmpty);
      expect(await library.getMediaItem('missing'), isNull);
    });
  });

  test('RadioAudioHandler delegates browse and search requests', () async {
    const item = MediaItem(
      id: 'radiowave:station:test',
      title: 'Handler FM',
      extras: <String, dynamic>{'url': 'https://example.com/handler.mp3'},
    );
    final library = _FakeAndroidAutoMediaLibrary(item);
    final handler = RadioAudioHandler(mediaLibrary: library);
    addTearDown(handler.dispose);

    await handler.setMediaItem(item);

    expect(handler.mediaItem.value?.id, item.id);
    expect(await handler.getChildren('root'), <MediaItem>[item]);
    expect(await handler.getMediaItem(item.id), item);
    expect(await handler.search('handler'), <MediaItem>[item]);
  });
}

Station testStation({
  required String uuid,
  required String name,
  String country = '',
  String favicon = '',
  List<String> tags = const <String>[],
  bool lastCheckOk = true,
}) {
  return Station(
    uuid: uuid,
    name: name,
    url: 'https://example.com/$uuid.mp3',
    homepage: '',
    favicon: favicon,
    tags: tags,
    country: country,
    countryCode: country.isEmpty ? '' : 'TH',
    language: '',
    codec: 'MP3',
    bitrate: 128,
    votes: 0,
    clickCount: 0,
    lastCheckOk: lastCheckOk,
    raw: const <String, dynamic>{},
  );
}

class _RecordingAdapter implements HttpClientAdapter {
  const _RecordingAdapter(this.responseFor);

  final FutureOr<List<Map<String, dynamic>>> Function(Uri uri) responseFor;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = await responseFor(options.uri);
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeRadioBrowserApi extends RadioBrowserApi {
  _FakeRadioBrowserApi({
    this.topStations = const <Station>[],
    this.searchStations = const <Station>[],
  }) : super(client: Dio()..httpClientAdapter = _RecordingAdapter((_) => []));

  final List<Station> topStations;
  final List<Station> searchStations;
  String? lastSearchQuery;

  @override
  Future<List<Station>> getTopStations({int limit = 50}) async {
    return topStations.take(limit).toList();
  }

  @override
  Future<List<Station>> search(
    String query,
    String countryCode, {
    int limit = 50,
  }) async {
    lastSearchQuery = query;
    return searchStations.take(limit).toList();
  }

  @override
  void dispose() {}
}

class _FakeFavoritesStore extends FavoritesStore {
  _FakeFavoritesStore(this.stations);

  final List<Station> stations;

  @override
  Future<void> init() async {}

  @override
  List<Station> getAll() {
    return stations;
  }
}

class _FakeAndroidAutoMediaLibrary extends AndroidAutoMediaLibrary {
  _FakeAndroidAutoMediaLibrary(this.item)
      : super(
          api: _FakeRadioBrowserApi(),
          favorites: _FakeFavoritesStore(const <Station>[]),
        );

  final MediaItem item;

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId) async {
    return <MediaItem>[item];
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) async {
    return mediaId == item.id ? item : null;
  }

  @override
  Future<List<MediaItem>> search(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    return <MediaItem>[item];
  }

  @override
  void dispose() {}
}
