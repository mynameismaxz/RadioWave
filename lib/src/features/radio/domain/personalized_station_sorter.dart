import '../../../data/models/listening_history_entry.dart';
import '../../../data/models/station.dart';

List<ListeningHistoryEntry> topListeningEntries(
  List<ListeningHistoryEntry> history, {
  int limit = 10,
}) {
  if (limit <= 0 || history.isEmpty) {
    return <ListeningHistoryEntry>[];
  }

  final entries = history
      .where((entry) =>
          listeningStationKey(entry.station).isNotEmpty &&
          entry.station.url.isNotEmpty &&
          entry.playCount > 0)
      .toList()
    ..sort(_compareHistoryEntries);

  return entries.take(limit).toList();
}

String? primaryListeningTag(Station station) {
  for (final tag in station.tags) {
    final normalizedTag = _normalizeTag(tag);
    if (normalizedTag.isNotEmpty) {
      return normalizedTag;
    }
  }

  return null;
}

List<Station> buildForYouStations(
  List<ListeningHistoryEntry> history,
  List<List<Station>> recommendationsBySeed, {
  List<Station> fallbackStations = const <Station>[],
  int seedLimit = 10,
  int recommendationsPerSeed = 4,
  int limit = 50,
}) {
  if (limit <= 0) {
    return <Station>[];
  }

  final topEntries = topListeningEntries(history, limit: seedLimit);
  final stationByKey = <String, Station>{};

  void addStation(Station station) {
    if (stationByKey.length >= limit) {
      return;
    }

    final stationKey = listeningStationKey(station);
    if (stationKey.isEmpty ||
        station.url.isEmpty ||
        stationByKey.containsKey(stationKey)) {
      return;
    }

    stationByKey[stationKey] = station;
  }

  for (final entry in topEntries) {
    addStation(entry.station);
  }

  for (var seedIndex = 0; seedIndex < topEntries.length; seedIndex += 1) {
    if (seedIndex >= recommendationsBySeed.length) {
      break;
    }

    var addedForSeed = 0;
    for (final station in recommendationsBySeed[seedIndex]) {
      final before = stationByKey.length;
      addStation(station);
      if (stationByKey.length > before) {
        addedForSeed += 1;
      }

      if (addedForSeed >= recommendationsPerSeed ||
          stationByKey.length >= limit) {
        break;
      }
    }
  }

  for (final station in fallbackStations) {
    addStation(station);
  }

  return stationByKey.values.toList();
}

int _compareHistoryEntries(
  ListeningHistoryEntry a,
  ListeningHistoryEntry b,
) {
  final playCountCompare = b.playCount.compareTo(a.playCount);
  if (playCountCompare != 0) {
    return playCountCompare;
  }

  return b.lastPlayedAt.compareTo(a.lastPlayedAt);
}

String _normalizeTag(String tag) {
  final normalized = tag.trim().toLowerCase();
  if (normalized == 'custom') {
    return '';
  }

  return normalized;
}
