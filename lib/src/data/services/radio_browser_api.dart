import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/radio_country.dart';
import '../models/station.dart';

class RadioBrowserApi {
  RadioBrowserApi({
    http.Client? client,
    Duration? requestTimeout,
    DateTime Function()? now,
  })  : _client = client ?? http.Client(),
        _requestTimeout = requestTimeout ?? const Duration(seconds: 4),
        _now = now ?? DateTime.now;

  final http.Client _client;
  final Duration _requestTimeout;
  final DateTime Function() _now;
  final List<String> _servers = const <String>[
    'https://all.api.radio-browser.info',
    'https://de1.api.radio-browser.info',
    'https://de2.api.radio-browser.info',
    'https://at1.api.radio-browser.info',
  ];
  static const Duration _mirrorStartDelay = Duration(milliseconds: 700);
  static const Duration _stationCacheTtl = Duration(minutes: 3);
  static const Duration _countryCacheTtl = Duration(hours: 12);

  int _currentServer = 0;
  List<RadioCountry>? _countriesCache;
  final Map<String, _CacheEntry<dynamic>> _cache =
      <String, _CacheEntry<dynamic>>{};
  final Map<String, Future<dynamic>> _inFlight = <String, Future<dynamic>>{};

  Future<dynamic> _fetch(
    String endpoint, [
    Map<String, Object?> params = const <String, Object?>{},
    Duration? cacheTtl,
  ]) async {
    final requestKey = _requestKey(endpoint, params);
    final cached = _cache[requestKey];
    final now = _now();

    if (cacheTtl != null && cached != null && cached.isFresh(now)) {
      return cached.value;
    }

    final inFlight = _inFlight[requestKey];
    if (inFlight != null) {
      return inFlight;
    }

    final request = _fetchFromNetwork(endpoint, params).then((data) {
      if (cacheTtl != null) {
        _cache[requestKey] = _CacheEntry<dynamic>(
          data,
          _now().add(cacheTtl),
        );
      }
      return data;
    });

    _inFlight[requestKey] = request;

    try {
      return await request;
    } finally {
      if (identical(_inFlight[requestKey], request)) {
        _inFlight.remove(requestKey);
      }
    }
  }

  Future<dynamic> _fetchFromNetwork(
    String endpoint,
    Map<String, Object?> params,
  ) {
    final errors = <String>[];
    final completer = Completer<dynamic>();
    var pending = _servers.length;
    final queryParameters = _queryParameters(params);

    for (var attempt = 0; attempt < _servers.length; attempt++) {
      final serverIndex = (_currentServer + attempt) % _servers.length;
      final startDelay = _mirrorStartDelay * attempt;
      unawaited(
        _fetchFromMirror(
          endpoint: endpoint,
          queryParameters: queryParameters,
          serverIndex: serverIndex,
          startDelay: startDelay,
          errors: errors,
          completer: completer,
        ).whenComplete(() {
          pending -= 1;
          if (pending == 0 && !completer.isCompleted) {
            completer.completeError(
              Exception('All API servers failed:\n${errors.join('\n')}'),
            );
          }
        }),
      );
    }

    return completer.future;
  }

  Future<void> _fetchFromMirror({
    required String endpoint,
    required Map<String, String> queryParameters,
    required int serverIndex,
    required Duration startDelay,
    required List<String> errors,
    required Completer<dynamic> completer,
  }) async {
    if (startDelay > Duration.zero) {
      await Future<void>.delayed(startDelay);
    }

    if (completer.isCompleted) {
      return;
    }

    final baseUrl = _servers[serverIndex];
    final uri = Uri.parse(
      '$baseUrl$endpoint',
    ).replace(queryParameters: queryParameters);

    try {
      final response = await _client.get(uri).timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }

      if (completer.isCompleted) {
        return;
      }

      final decoded = jsonDecode(response.body);
      _currentServer = serverIndex;
      completer.complete(decoded);
    } catch (error) {
      errors.add('$baseUrl: $error');
    }
  }

  Map<String, String> _queryParameters(Map<String, Object?> params) {
    return <String, String>{
      for (final entry in params.entries)
        if (entry.value != null && entry.value.toString().isNotEmpty)
          entry.key: entry.value.toString(),
    };
  }

  String _requestKey(String endpoint, Map<String, Object?> params) {
    final queryParameters = _queryParameters(params);
    final sortedKeys = queryParameters.keys.toList()..sort();
    final sortedParams = <String, String>{
      for (final key in sortedKeys) key: queryParameters[key]!,
    };

    return Uri(path: endpoint, queryParameters: sortedParams).toString();
  }

  Future<List<Station>> search(
    String query,
    String countryCode, {
    int limit = 50,
  }) async {
    final data = await _fetch(
        '/json/stations/search',
        <String, Object?>{
          'name': query,
          'limit': limit,
          'hidebroken': true,
          'order': 'clickcount',
          'reverse': true,
          if (countryCode.isNotEmpty) 'countrycode': countryCode,
        },
        _stationCacheTtl);

    return _stationList(data);
  }

  Future<List<Station>> getTopStations({int limit = 50}) async {
    final data = await _fetch(
        '/json/stations/topclick',
        <String, Object?>{
          'limit': limit,
          'hidebroken': true,
        },
        _stationCacheTtl);

    return _stationList(data);
  }

  Future<List<RadioCountry>> getCountries() async {
    if (_countriesCache != null) {
      return _countriesCache!;
    }

    final data = await _fetch(
        '/json/countries',
        <String, Object?>{
          'order': 'stationcount',
          'reverse': true,
          'hidebroken': true,
        },
        _countryCacheTtl);

    final countries = (data is List ? data : const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(RadioCountry.fromJson)
        .where((country) => country.stationCount > 0 && country.code.isNotEmpty)
        .toList();

    _countriesCache = countries;
    return countries;
  }

  Future<List<Station>> getStationsByUuid(List<String> uuids) async {
    if (uuids.isEmpty) {
      return const <Station>[];
    }

    final data = await _fetch(
        '/json/stations/byuuid',
        <String, Object?>{
          'uuids': uuids.join(','),
        },
        _stationCacheTtl);

    return _stationList(data);
  }

  List<Station> _stationList(dynamic data) {
    return (data is List ? data : const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(Station.fromRadioBrowser)
        .where((station) => station.uuid.isNotEmpty && station.url.isNotEmpty)
        .toList();
  }

  void dispose() {
    _client.close();
  }
}

class _CacheEntry<T> {
  const _CacheEntry(this.value, this.expiresAt);

  final T value;
  final DateTime expiresAt;

  bool isFresh(DateTime now) => now.isBefore(expiresAt);
}
