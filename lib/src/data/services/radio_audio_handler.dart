import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import 'android_auto_media_library.dart';

/// Shared handler instance initialized from `main.dart` before `runApp`.
late final RadioAudioHandler radioAudioHandler;

/// Audio handler tailored for live radio: the system notification exposes one
/// play/pause action. Pause still stops the live stream internally.
class RadioAudioHandler extends BaseAudioHandler {
  RadioAudioHandler({AndroidAutoMediaLibrary? mediaLibrary})
      : _mediaLibrary = mediaLibrary ?? AndroidAutoMediaLibrary() {
    _player.playbackEventStream.listen(_broadcastState);
  }

  final AudioPlayer _player = AudioPlayer();
  final AndroidAutoMediaLibrary _mediaLibrary;

  AudioPlayer get player => _player;

  Future<void> setMediaItem(MediaItem item) async {
    mediaItem.add(item);
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    final url = _mediaLibrary.streamUrlFor(mediaItem);
    if (url == null) {
      return;
    }

    await _player.stop();
    this.mediaItem.add(mediaItem);
    await _player
        .setAudioSource(AudioSource.uri(Uri.parse(url)))
        .timeout(const Duration(seconds: 10));
    unawaited(_player.play());
  }

  @override
  Future<void> play() async {
    unawaited(_player.play());
  }

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

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    final item = await getMediaItem(mediaId);
    if (item == null) {
      return;
    }

    await playMediaItem(item);
  }

  @override
  Future<void> playFromSearch(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    final results = await search(query, extras);
    if (results.isEmpty) {
      return;
    }

    await playMediaItem(results.first);
  }

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) {
    return _mediaLibrary.getChildren(parentMediaId);
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) {
    return _mediaLibrary.getMediaItem(mediaId);
  }

  @override
  Future<List<MediaItem>> search(
    String query, [
    Map<String, dynamic>? extras,
  ]) {
    return _mediaLibrary.search(query);
  }

  Future<void> dispose() async {
    _mediaLibrary.dispose();
    await _player.dispose();
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: radioNotificationControls(playing: playing),
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

List<MediaControl> radioNotificationControls({required bool playing}) {
  return <MediaControl>[
    if (playing) MediaControl.pause else MediaControl.play,
  ];
}
