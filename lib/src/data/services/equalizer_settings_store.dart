import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class EqualizerSettingsStore {
  static const storageKey = 'radiowave_equalizer_settings';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  EqualizerSettings? load() {
    final raw = _prefs?.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final gains = decoded['gains'];
      if (gains is! List) {
        return null;
      }

      return EqualizerSettings(
        enabled: decoded['enabled'] == true,
        preset: decoded['preset'] as String? ?? 'Flat',
        gains: gains
            .whereType<num>()
            .map((value) => value.toDouble().clamp(-12.0, 12.0))
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save({
    required bool enabled,
    required String preset,
    required List<double> gains,
  }) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(<String, dynamic>{
        'enabled': enabled,
        'preset': preset,
        'gains': gains,
      }),
    );
  }
}

class EqualizerSettings {
  const EqualizerSettings({
    required this.enabled,
    required this.preset,
    required this.gains,
  });

  final bool enabled;
  final String preset;
  final List<double> gains;
}
