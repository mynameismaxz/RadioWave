import 'dart:async';

import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Stream<PlaybackEvent> get playbackEventStream => _player.playbackEventStream;

  Future<void> playUrl(String url) async {
    await _player.stop();
    await _player.setUrl(url).timeout(const Duration(seconds: 10));
    await _player.play();
  }

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> stop() => _player.stop();

  Future<void> setVolume(double value) => _player.setVolume(value);

  Future<void> dispose() => _player.dispose();
}
