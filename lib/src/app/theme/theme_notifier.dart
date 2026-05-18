import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global theme-mode notifier.
/// Widgets that need to toggle the theme call [toggle()] or [setMode()].
class ThemeNotifier extends ValueNotifier<ThemeMode> {
  static const _storageKey = 'radiowave_theme_mode';

  ThemeNotifier() : super(ThemeMode.dark);

  bool get isDark => value == ThemeMode.dark;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final storedMode = _decodeThemeMode(prefs.getString(_storageKey));
    if (storedMode != null) {
      value = storedMode;
    }
  }

  void toggle() {
    setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setMode(ThemeMode mode) async {
    if (value == mode) {
      return;
    }

    value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, mode.name);
  }

  ThemeMode? _decodeThemeMode(String? value) {
    if (value == null) {
      return null;
    }

    for (final mode in ThemeMode.values) {
      if (mode.name == value) {
        return mode;
      }
    }

    return null;
  }
}

/// A single global instance so any widget can access the notifier
/// without an InheritedWidget. For a larger app you'd use Provider / Riverpod.
final themeNotifier = ThemeNotifier();
