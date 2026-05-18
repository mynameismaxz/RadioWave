import '../../core/utils/json_value.dart';

class Station {
  const Station({
    required this.uuid,
    required this.name,
    required this.url,
    required this.homepage,
    required this.favicon,
    required this.tags,
    required this.country,
    required this.countryCode,
    required this.language,
    required this.codec,
    required this.bitrate,
    required this.votes,
    required this.clickCount,
    required this.lastCheckOk,
    required this.raw,
  });

  final String uuid;
  final String name;
  final String url;
  final String homepage;
  final String favicon;
  final List<String> tags;
  final String country;
  final String countryCode;
  final String language;
  final String codec;
  final int bitrate;
  final int votes;
  final int clickCount;
  final bool lastCheckOk;
  final Map<String, dynamic> raw;

  factory Station.fromRadioBrowser(Map<String, dynamic> raw) {
    final name = stringValue(raw['name']).trim();
    final resolvedUrl = stringValue(raw['url_resolved']);

    return Station(
      uuid: stringValue(raw['stationuuid']),
      name: name.isEmpty ? 'Unknown Station' : name,
      url: resolvedUrl.isNotEmpty ? resolvedUrl : stringValue(raw['url']),
      homepage: stringValue(raw['homepage']),
      favicon: stringValue(raw['favicon']),
      tags: tagList(raw['tags']),
      country: stringValue(raw['country']),
      countryCode: stringValue(raw['countrycode']),
      language: stringValue(raw['language']),
      codec: stringValue(raw['codec']),
      bitrate: intValue(raw['bitrate']),
      votes: intValue(raw['votes']),
      clickCount: intValue(raw['clickcount']),
      lastCheckOk: intValue(raw['lastcheckok']) == 1,
      raw: raw,
    );
  }

  factory Station.fromFavoriteJson(Map<String, dynamic> json) {
    final name = stringValue(json['name']).trim();

    return Station(
      uuid: stringValue(json['uuid']),
      name: name.isEmpty ? 'Unknown Station' : name,
      url: stringValue(json['url']),
      homepage: stringValue(json['homepage']),
      favicon: stringValue(json['favicon']),
      tags: tagList(json['tags']),
      country: stringValue(json['country']),
      countryCode: stringValue(json['countrycode']),
      language: stringValue(json['language']),
      codec: stringValue(json['codec']),
      bitrate: intValue(json['bitrate']),
      votes: intValue(json['votes']),
      clickCount: intValue(json['clickcount']),
      lastCheckOk: !json.containsKey('lastcheckok') ||
          intValue(json['lastcheckok']) == 1,
      raw: const <String, dynamic>{},
    );
  }

  factory Station.custom(String name, String url) {
    return Station(
      uuid: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      url: url,
      homepage: '',
      favicon: '',
      tags: const ['custom'],
      country: '',
      countryCode: '',
      language: '',
      codec: '',
      bitrate: 0,
      votes: 0,
      clickCount: 0,
      lastCheckOk: true,
      raw: const <String, dynamic>{},
    );
  }

  Map<String, dynamic> toFavoriteJson() {
    return <String, dynamic>{
      'uuid': uuid,
      'name': name,
      'url': url,
      'homepage': homepage,
      'favicon': favicon,
      'tags': tags,
      'country': country,
      'countrycode': countryCode,
      'language': language,
      'codec': codec,
      'bitrate': bitrate,
      'votes': votes,
      'clickcount': clickCount,
      'lastcheckok': lastCheckOk ? 1 : 0,
      'addedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  bool get isCustom => uuid.startsWith('custom-');
}
