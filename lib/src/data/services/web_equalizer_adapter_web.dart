import 'dart:js_interop';

@JS('radioWaveEqualizer.apply')
external void _applyEqualizer(bool enabled, JSArray<JSNumber> gains);

@JS('radioWaveEqualizer.reset')
external void _resetEqualizer();

Future<void> resetWebEqualizer() async {
  try {
    _resetEqualizer();
  } catch (_) {
    // Web equalizer script may not be loaded yet.
  }
}

Future<void> setWebEqualizer({
  required bool enabled,
  required List<double> gains,
}) async {
  _applyEqualizer(
    enabled,
    gains.map((gain) => gain.toJS).toList().toJS,
  );
}
