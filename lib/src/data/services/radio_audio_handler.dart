import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Shared handler instance initialized from `main.dart` before `runApp`.
late final RadioAudioHandler radioAudioHandler;

/// Audio handler tailored for live radio: the system notification exposes a
/// single Stop action while playing (no Pause), matching radio UX where the
/// stream cannot be resumed from the paused position.
class RadioAudioHandler extends BaseAudioHandler {
  RadioAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
  }

  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  Future<void> setMediaItem(MediaItem item) async {
    mediaItem.add(item);
  }

  @override
  Future<void> play() => _player.play();

  /// Live radio cannot resume from a pause position; treat pause as stop so any
  /// implicit pause (system audio focus loss, headset unplug, lock-screen) does
  /// not leave a stale notification.
  @override
  Future<void> pause() => stop();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  Future<void> dispose() => _player.dispose();

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: <MediaControl>[MediaControl.stop],
      systemActions: const <MediaAction>{},
      androidCompactActionIndices: const <int>[0],
      processingState: switch (event.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }
}
