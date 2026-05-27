import 'package:audio_service/audio_service.dart';

import '../models/station.dart';
import 'favorites_store.dart';
import 'radio_browser_api.dart';

class AndroidAutoMediaLibrary {
  AndroidAutoMediaLibrary({
    RadioBrowserApi? api,
    FavoritesStore? favorites,
  })  : _api = api ?? RadioBrowserApi(),
        _favorites = favorites ?? FavoritesStore();

  static const String favoritesRootId = 'radiowave:favorites';
  static const String popularRootId = 'radiowave:popular';
  static const String _mediaIdPrefix = 'radiowave:station:';

  final RadioBrowserApi _api;
  final FavoritesStore _favorites;
  final Map<String, MediaItem> _mediaItemsById = <String, MediaItem>{};
  bool _favoritesReady = false;

  Future<List<MediaItem>> getChildren(String parentMediaId) async {
    switch (parentMediaId) {
      case AudioService.browsableRootId:
        return const <MediaItem>[
          MediaItem(
            id: favoritesRootId,
            title: 'Favorites',
            playable: false,
          ),
          MediaItem(
            id: popularRootId,
            title: 'Popular stations',
            playable: false,
          ),
        ];
      case AudioService.recentRootId:
        return const <MediaItem>[];
      case favoritesRootId:
        return _stationItems(await _loadFavorites());
      case popularRootId:
        return _stationItems(await _api.getTopStations(limit: 50));
      default:
        return const <MediaItem>[];
    }
  }

  Future<MediaItem?> getMediaItem(String mediaId) async {
    final cached = _mediaItemsById[mediaId];
    if (cached != null) {
      return cached;
    }

    for (final station in await _loadFavorites()) {
      final item = mediaItemFor(station);
      if (item.id == mediaId) {
        return item;
      }
    }

    return null;
  }

  Future<List<MediaItem>> search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return const <MediaItem>[];
    }

    return _stationItems(await _api.search(trimmedQuery, '', limit: 20));
  }

  MediaItem mediaItemFor(Station station) {
    final item = MediaItem(
      id: _mediaIdFor(station),
      album: _stationAlbum(station),
      title: station.name,
      artUri: _artUri(station.favicon),
      playable: true,
      isLive: true,
      extras: <String, dynamic>{
        'url': station.url,
        'stationUuid': station.uuid,
        'country': station.country,
        'codec': station.codec,
        'bitrate': station.bitrate,
      },
    );
    _mediaItemsById[item.id] = item;
    return item;
  }

  String? streamUrlFor(MediaItem item) {
    final extraUrl = item.extras?['url'];
    if (extraUrl is String && extraUrl.trim().isNotEmpty) {
      return extraUrl.trim();
    }

    final uri = Uri.tryParse(item.id);
    final scheme = uri?.scheme.toLowerCase();
    if (scheme == 'http' || scheme == 'https') {
      return item.id.trim();
    }

    return null;
  }

  Future<List<Station>> _loadFavorites() async {
    if (!_favoritesReady) {
      await _favorites.init();
      _favoritesReady = true;
    }

    return _favorites
        .getAll()
        .where((station) => station.isCustom || station.lastCheckOk)
        .toList();
  }

  List<MediaItem> _stationItems(List<Station> stations) {
    return stations.map(mediaItemFor).toList();
  }

  String _mediaIdFor(Station station) {
    final key = station.uuid.isNotEmpty ? station.uuid : station.url;
    return '$_mediaIdPrefix$key';
  }

  String _stationAlbum(Station station) {
    final parts = <String>[
      if (station.country.isNotEmpty) station.country,
      if (station.codec.isNotEmpty) station.codec,
      if (station.bitrate > 0) '${station.bitrate} kbps',
    ];

    return parts.isEmpty ? 'RadioWave' : parts.join(' - ');
  }

  Uri? _artUri(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme) {
      return null;
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return null;
    }

    return uri;
  }

  void dispose() {
    _api.dispose();
  }
}
