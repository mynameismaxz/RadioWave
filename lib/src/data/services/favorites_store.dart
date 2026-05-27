import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/station.dart';

class FavoritesStore {
  static const String storageKey = 'radiowave_favorites';

  SharedPreferences? _prefs;
  List<Station> _favorites = <Station>[];

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _favorites = _load();
  }

  List<Station> _load() {
    try {
      final raw = _prefs?.getString(storageKey);
      if (raw == null || raw.isEmpty) {
        return <Station>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <Station>[];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Station.fromFavoriteJson)
          .where((station) => station.uuid.isNotEmpty && station.url.isNotEmpty)
          .toList();
    } catch (_) {
      return <Station>[];
    }
  }

  Future<void> _save() async {
    await _prefs?.setString(
      storageKey,
      jsonEncode(
          _favorites.map((station) => station.toFavoriteJson()).toList()),
    );
  }

  List<Station> getAll() => List<Station>.unmodifiable(_favorites);

  List<String> getUuids() => _favorites.map((station) => station.uuid).toList();

  bool isFavorite(String uuid) {
    return _favorites.any((station) => station.uuid == uuid);
  }

  Future<bool> add(Station station) async {
    if (station.uuid.isEmpty || isFavorite(station.uuid)) {
      return false;
    }

    _favorites = <Station>[..._favorites, station];
    await _save();
    return true;
  }

  Future<bool> remove(String uuid) async {
    final before = _favorites.length;
    _favorites = _favorites.where((station) => station.uuid != uuid).toList();

    if (_favorites.length == before) {
      return false;
    }

    await _save();
    return true;
  }

  Future<bool> toggle(Station station) async {
    if (isFavorite(station.uuid)) {
      await remove(station.uuid);
      return false;
    }

    await add(station);
    return true;
  }

  Future<void> update(String uuid, Station station) async {
    if (!isFavorite(uuid)) {
      return;
    }

    _favorites = <Station>[
      for (final favorite in _favorites)
        if (favorite.uuid == uuid) station else favorite,
    ];
    await _save();
  }

  Future<void> updateAll(Map<String, Station> stationsByUuid) async {
    var changed = false;

    _favorites = _favorites.map((favorite) {
      final freshStation = stationsByUuid[favorite.uuid];
      if (freshStation == null) {
        return favorite;
      }

      changed = true;
      return freshStation;
    }).toList();

    if (changed) {
      await _save();
    }
  }
}
