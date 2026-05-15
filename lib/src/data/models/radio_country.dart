import '../../core/utils/json_value.dart';

class RadioCountry {
  const RadioCountry({
    required this.name,
    required this.code,
    required this.stationCount,
  });

  final String name;
  final String code;
  final int stationCount;

  factory RadioCountry.fromJson(Map<String, dynamic> json) {
    return RadioCountry(
      name: stringValue(json['name']),
      code: stringValue(json['iso_3166_1']),
      stationCount: intValue(json['stationcount']),
    );
  }
}
