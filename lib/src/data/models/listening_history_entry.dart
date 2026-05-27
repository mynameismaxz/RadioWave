import '../../core/utils/json_value.dart';
import 'station.dart';

class ListeningHistoryEntry {
  const ListeningHistoryEntry({
    required this.station,
    required this.playCount,
    required this.lastPlayedAt,
  });

  final Station station;
  final int playCount;
  final DateTime lastPlayedAt;

  String get stationKey => listeningStationKey(station);

  ListeningHistoryEntry copyWith({
    Station? station,
    int? playCount,
    DateTime? lastPlayedAt,
  }) {
    return ListeningHistoryEntry(
      station: station ?? this.station,
      playCount: playCount ?? this.playCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'station': station.toFavoriteJson(),
      'playCount': playCount,
      'lastPlayedAt': lastPlayedAt.toUtc().millisecondsSinceEpoch,
    };
  }

  static ListeningHistoryEntry? fromJson(Map<String, dynamic> json) {
    final stationJson = json['station'];
    if (stationJson is! Map<String, dynamic>) {
      return null;
    }

    final station = Station.fromFavoriteJson(stationJson);
    if (listeningStationKey(station).isEmpty || station.url.isEmpty) {
      return null;
    }

    final playCount = intValue(json['playCount']);
    if (playCount <= 0) {
      return null;
    }

    final lastPlayedAtMillis = intValue(json['lastPlayedAt']);
    final lastPlayedAt = lastPlayedAtMillis > 0
        ? DateTime.fromMillisecondsSinceEpoch(
            lastPlayedAtMillis,
            isUtc: true,
          )
        : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    return ListeningHistoryEntry(
      station: station,
      playCount: playCount,
      lastPlayedAt: lastPlayedAt,
    );
  }
}

String listeningStationKey(Station station) {
  if (station.uuid.isNotEmpty) {
    return station.uuid;
  }

  return station.url;
}
