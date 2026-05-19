import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/station.dart';

class PlaybackStateStore {
  static const String storageKey = 'radiowave_playback_state';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SavedPlaybackState? load() {
    try {
      final raw = _prefs?.getString(storageKey);
      if (raw == null || raw.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final stationJson = decoded['station'];
      if (stationJson is! Map<String, dynamic>) {
        return null;
      }

      final station = Station.fromFavoriteJson(stationJson);
      if (station.uuid.isEmpty || station.url.isEmpty) {
        return null;
      }

      return SavedPlaybackState(
        station: station,
        wasPlaying: decoded['wasPlaying'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save({
    required Station station,
    required bool wasPlaying,
  }) async {
    await _prefs?.setString(
      storageKey,
      jsonEncode(
        <String, dynamic>{
          'station': station.toFavoriteJson(),
          'wasPlaying': wasPlaying,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
      ),
    );
  }

  Future<void> clear() async {
    await _prefs?.remove(storageKey);
  }
}

class SavedPlaybackState {
  const SavedPlaybackState({
    required this.station,
    required this.wasPlaying,
  });

  final Station station;
  final bool wasPlaying;
}
