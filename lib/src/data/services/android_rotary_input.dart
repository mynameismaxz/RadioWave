import 'dart:async';

import 'package:flutter/services.dart';

class AndroidRotaryInput {
  AndroidRotaryInput._();

  static const MethodChannel _channel = MethodChannel(
    'com.example.radio_app_flutter/rotary',
  );
  static final StreamController<RotaryInputEvent> _events =
      StreamController<RotaryInputEvent>.broadcast();
  static bool _initialized = false;

  static Stream<RotaryInputEvent> get events => _events.stream;

  static void init() {
    if (_initialized) {
      return;
    }

    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      final args = call.arguments;
      if (args is! Map) {
        return;
      }

      switch (call.method) {
        case 'rotate':
          final delta = args['delta'];
          if (delta is int && delta != 0) {
            _events.add(RotaryInputEvent.rotate(delta));
          }
          break;
        case 'key':
          final key = args['key'];
          if (key is String) {
            _events.add(RotaryInputEvent.key(key));
          }
          break;
      }
    });
  }
}

class RotaryInputEvent {
  const RotaryInputEvent._({
    required this.type,
    this.delta = 0,
    this.key = '',
  });

  factory RotaryInputEvent.rotate(int delta) {
    return RotaryInputEvent._(
      type: RotaryInputEventType.rotate,
      delta: delta,
    );
  }

  factory RotaryInputEvent.key(String key) {
    return RotaryInputEvent._(
      type: RotaryInputEventType.key,
      key: key,
    );
  }

  final RotaryInputEventType type;
  final int delta;
  final String key;
}

enum RotaryInputEventType { rotate, key }
