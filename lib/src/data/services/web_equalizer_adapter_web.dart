import 'dart:js_interop';

@JS('radioWaveEqualizer.apply')
external void _applyEqualizer(bool enabled, JSArray<JSNumber> gains);

Future<void> setWebEqualizer({
  required bool enabled,
  required List<double> gains,
}) async {
  _applyEqualizer(
    enabled,
    gains.map((gain) => gain.toJS).toList().toJS,
  );
}
