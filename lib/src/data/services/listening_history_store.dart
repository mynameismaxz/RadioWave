import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/listening_history_entry.dart';
import '../models/station.dart';

class ListeningHistoryStore {
  ListeningHistoryStore({
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const String storageKey = 'radiowave_listening_history';
  static const int _maxEntries = 100;

  final DateTime Function() _now;

  SharedPreferences? _prefs;
  List<ListeningHistoryEntry> _entries = <ListeningHistoryEntry>[];

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _entries = _sortEntries(_load());
  }

  List<ListeningHistoryEntry> getEntries() {
    return List<ListeningHistoryEntry>.unmodifiable(_entries);
  }

  Future<void> recordPlay(Station station) async {
    final stationKey = listeningStationKey(station);
    if (stationKey.isEmpty || station.url.isEmpty) {
      return;
    }

    final now = _now().toUtc();
    final existingIndex = _entries.indexWhere(
      (entry) => entry.stationKey == stationKey,
    );
    final existingEntry = existingIndex == -1 ? null : _entries[existingIndex];
    final nextEntry = existingEntry == null
        ? ListeningHistoryEntry(
            station: station,
            playCount: 1,
            lastPlayedAt: now,
          )
        : existingEntry.copyWith(
            station: station,
            playCount: existingEntry.playCount + 1,
            lastPlayedAt: now,
          );

    final nextEntries = <ListeningHistoryEntry>[
      for (final entry in _entries)
        if (entry.stationKey != stationKey) entry,
      nextEntry,
    ];
    _entries = _sortEntries(nextEntries).take(_maxEntries).toList();
    await _save();
  }

  List<ListeningHistoryEntry> _load() {
    try {
      final raw = _prefs?.getString(storageKey);
      if (raw == null || raw.isEmpty) {
        return <ListeningHistoryEntry>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <ListeningHistoryEntry>[];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ListeningHistoryEntry.fromJson)
          .whereType<ListeningHistoryEntry>()
          .toList();
    } catch (_) {
      return <ListeningHistoryEntry>[];
    }
  }

  Future<void> _save() async {
    await _prefs?.setString(
      storageKey,
      jsonEncode(_entries.map((entry) => entry.toJson()).toList()),
    );
  }

  List<ListeningHistoryEntry> _sortEntries(
    List<ListeningHistoryEntry> entries,
  ) {
    final sorted = List<ListeningHistoryEntry>.of(entries);
    sorted.sort(_compareEntries);
    return sorted;
  }

  int _compareEntries(
    ListeningHistoryEntry a,
    ListeningHistoryEntry b,
  ) {
    final playCountCompare = b.playCount.compareTo(a.playCount);
    if (playCountCompare != 0) {
      return playCountCompare;
    }

    return b.lastPlayedAt.compareTo(a.lastPlayedAt);
  }
}
