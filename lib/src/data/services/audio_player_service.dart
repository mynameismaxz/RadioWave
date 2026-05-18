import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../models/station.dart';
import 'radio_audio_handler.dart';

class AudioPlayerService {
  AudioPlayerService({RadioAudioHandler? handler})
      : _handler = handler ?? radioAudioHandler;

  final RadioAudioHandler _handler;

  AudioPlayer get _player => _handler.player;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Stream<PlaybackEvent> get playbackEventStream => _player.playbackEventStream;

  Future<void> playStation(Station station) async {
    await _player.stop();
    await _handler.setMediaItem(_mediaItemFor(station));
    await _player
        .setAudioSource(AudioSource.uri(Uri.parse(station.url)))
        .timeout(const Duration(seconds: 10));
    await _player.play();
  }

  Future<void> play() => _handler.play();

  Future<void> pause() => _player.pause();

  Future<void> stop() => _handler.stop();

  Future<void> setVolume(double value) => _player.setVolume(value);

  Future<void> dispose() => _handler.dispose();

  MediaItem _mediaItemFor(Station station) {
    return MediaItem(
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
    );
  }

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
