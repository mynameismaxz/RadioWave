import 'package:flutter/material.dart';

/// Global theme-mode notifier.
/// Widgets that need to toggle the theme call [toggle()] or [setMode()].
class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark);

  bool get isDark => value == ThemeMode.dark;

  void toggle() {
    value = isDark ? ThemeMode.light : ThemeMode.dark;
  }

  void setMode(ThemeMode mode) => value = mode;
}

/// A single global instance so any widget can access the notifier
/// without an InheritedWidget. For a larger app you'd use Provider / Riverpod.
final themeNotifier = ThemeNotifier();
