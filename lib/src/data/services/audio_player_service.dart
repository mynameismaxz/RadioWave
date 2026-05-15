import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/station.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Stream<PlaybackEvent> get playbackEventStream => _player.playbackEventStream;

  Future<void> playStation(Station station) async {
    await _player.stop();
    await _player
        .setAudioSource(AudioSource.uri(
          Uri.parse(station.url),
          tag: MediaItem(
            id: station.uuid.isNotEmpty ? station.uuid : station.url,
            album: _stationAlbum(station),
            title: station.name,
            artUri: _artUri(station.favicon),
            extras: <String, dynamic>{
              'url': station.url,
              'country': station.country,
              'codec': station.codec,
              'bitrate': station.bitrate,
            },
          ),
        ))
        .timeout(const Duration(seconds: 10));
    await _player.play();
  }

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> stop() => _player.stop();

  Future<void> setVolume(double value) => _player.setVolume(value);

  Future<void> dispose() => _player.dispose();

  String _stationAlbum(Station station) {
    final parts = <String>[
      if (station.country.isNotEmpty) station.country,
      if (station.codec.isNotEmpty) station.codec,
      if (station.bitrate > 0) '${station.bitrate} kbps',
    ];

    return parts.isEmpty ? 'RadioWave' : parts.join(' - ');
  }

  Uri? _artUri(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme) {
      return null;
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return null;
    }

    return uri;
  }
}
