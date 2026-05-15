import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/utils/iterable_ext.dart';
import '../../../data/models/app_toast.dart';
import '../../../data/models/radio_country.dart';
import '../../../data/models/station.dart';
import '../../../data/services/audio_player_service.dart';
import '../../../data/services/favorites_store.dart';
import '../../../data/services/radio_browser_api.dart';
import '../domain/radio_tab.dart';
import '../domain/station_view_state.dart';

class RadioController extends ChangeNotifier {
  RadioController({
    RadioBrowserApi? api,
    FavoritesStore? favorites,
    AudioPlayerService? player,
  })  : api = api ?? RadioBrowserApi(),
        favorites = favorites ?? FavoritesStore(),
        player = player ?? AudioPlayerService() {
    _playerStateSub = this.player.playerStateStream.listen(_onPlayerState);
    _playbackEventSub = this.player.playbackEventStream.listen(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        _showPlaybackError('Stream error');
      },
    );
  }

  final RadioBrowserApi api;
  final FavoritesStore favorites;
  final AudioPlayerService player;
  final List<Timer> _toastTimers = <Timer>[];

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<PlaybackEvent>? _playbackEventSub;
  bool _hasLoadedStation = false;
  bool _disposed = false;
  int _toastId = 0;
  int _discoverLoadId = 0;
  int _favoritesLoadId = 0;
  String? _loadedDiscoverKey;
  Future<void> Function()? _retryFn;
  Timer? _loadingTimeout;

  // Sleep timer
  Timer? _sleepTimer;
  Timer? _sleepTickTimer;
  Duration? sleepTimerRemaining;
  Duration? sleepTimerTotal;

  RadioTab currentTab = RadioTab.discover;
  List<Station> stations = <Station>[];
  StationViewState viewState = StationViewState.loading;
  String emptyMessage = 'No stations found';
  String errorTitle = 'Connection Error';
  String errorDesc = 'Unable to reach radio directory.';

  String searchQuery = '';
  String selectedCountry = '';
  List<RadioCountry> countries = <RadioCountry>[];
  bool countriesReady = false;
  int stationCount = 0;

  Station? currentStation;
  bool playerIsPlaying = false;
  bool playerIsLoading = false;
  bool playerBarVisible = false;
  bool playerBarPaused = false;
  String playerStatus = 'Browse and tap a station to play';

  double volume = 80;
  bool isMuted = false;
  double preVolume = 80;

  Set<String> favoriteUuids = <String>{};
  List<AppToast> toasts = <AppToast>[];

  int get favoriteCount => favoriteUuids.length;

  bool isFavorite(String uuid) => favoriteUuids.contains(uuid);

  bool get hasSleepTimer => sleepTimerRemaining != null;

  /// Index of current station in the stations list (-1 if not found).
  int get _currentIndex {
    final station = currentStation;
    if (station == null) return -1;
    return stations.indexWhere((s) => s.uuid == station.uuid);
  }

  Future<void> init() async {
    await favorites.init();
    favoriteUuids = favorites.getUuids().toSet();
    await player.setVolume(volume / 100);
    _safeNotify();

    unawaited(_loadCountries());
    await loadDiscover();
  }

  Future<void> _loadCountries() async {
    try {
      countries = await api.getCountries();
      countriesReady = true;
      _safeNotify();
    } catch (_) {
      countriesReady = false;
      _safeNotify();
    }
  }

  Future<void> loadDiscover({bool forceRefresh = false}) async {
    final query = searchQuery.trim();
    final countryCode = selectedCountry;
    final requestKey = _discoverKey(query, countryCode);

    if (!forceRefresh &&
        _loadedDiscoverKey == requestKey &&
        (viewState == StationViewState.list ||
            viewState == StationViewState.empty)) {
      return;
    }

    final loadId = ++_discoverLoadId;
    _retryFn = null;

    if (stations.isEmpty) {
      viewState = StationViewState.loading;
      _safeNotify();
    }

    try {
      final nextStations = query.isEmpty && countryCode.isEmpty
          ? await api.getTopStations(limit: 50)
          : await api.search(query, countryCode, limit: 50);

      if (_disposed ||
          loadId != _discoverLoadId ||
          currentTab != RadioTab.discover) {
        return;
      }

      stations = nextStations;
      stationCount = stations.length;
      _loadedDiscoverKey = requestKey;

      if (stations.isEmpty) {
        emptyMessage = _emptyDiscoverMessage(query, countryCode);
        viewState = StationViewState.empty;
      } else {
        viewState = StationViewState.list;
      }

      _safeNotify();
    } catch (_) {
      if (_disposed ||
          loadId != _discoverLoadId ||
          currentTab != RadioTab.discover) {
        return;
      }

      errorTitle = 'Search Failed';
      errorDesc = 'Could not search the radio directory. Please try again.';
      _retryFn = () => loadDiscover(forceRefresh: true);

      if (stations.isEmpty) {
        viewState = StationViewState.error;
      } else {
        showToast(
          'Could not refresh stations. Showing the last results.',
          ToastType.error,
        );
        viewState = StationViewState.list;
      }

      _safeNotify();
    }
  }

  Future<void> loadFavorites() async {
    final loadId = ++_favoritesLoadId;
    final favoriteList = favorites.getAll();
    _loadedDiscoverKey = null;

    if (favoriteList.isEmpty) {
      emptyMessage =
          'No favorite stations yet. Tap the heart icon to save stations.';
      stationCount = 0;
      stations = <Station>[];
      viewState = StationViewState.empty;
      _safeNotify();
      return;
    }

    stations = favoriteList;
    stationCount = favoriteList.length;
    viewState = StationViewState.list;
    _safeNotify();

    unawaited(_refreshFavoriteStations(favorites.getUuids(), loadId));
  }

  Future<void> _refreshFavoriteStations(List<String> uuids, int loadId) async {
    try {
      final freshData = await api.getStationsByUuid(uuids);
      final freshByUuid = <String, Station>{
        for (final station in freshData) station.uuid: station,
      };

      await favorites.updateAll(freshByUuid);
      final favoriteList = favorites.getAll();
      final currentUuids = favorites.getUuids();

      if (_disposed ||
          loadId != _favoritesLoadId ||
          currentTab != RadioTab.favorites) {
        return;
      }

      favoriteUuids = currentUuids.toSet();
      stations = currentUuids
          .map((uuid) {
            return freshByUuid[uuid] ??
                favoriteList
                    .where((station) => station.uuid == uuid)
                    .firstOrNull;
          })
          .whereType<Station>()
          .toList();

      stationCount = stations.length;
      viewState =
          stations.isEmpty ? StationViewState.empty : StationViewState.list;
      _safeNotify();
    } catch (_) {
      // The local favorites have already been rendered; network refresh is best-effort.
    }
  }

  Future<void> playStation(Station station) async {
    if (station.url.isEmpty) {
      showToast('No stream URL available', ToastType.error);
      return;
    }

    currentStation = station;
    playerBarVisible = true;
    playerBarPaused = false;
    playerIsLoading = true;
    playerStatus = 'Connecting...';
    _hasLoadedStation = false;
    _safeNotify();

    // Safety timeout — if still loading after 12s, force stop
    _loadingTimeout?.cancel();
    _loadingTimeout = Timer(const Duration(seconds: 12), () {
      if (playerIsLoading && !_disposed) {
        _showPlaybackError('Connection timed out — try another station');
        unawaited(player.stop());
      }
    });

    try {
      await player.playStation(station);
      _hasLoadedStation = true;
      _loadingTimeout?.cancel();
    } on TimeoutException {
      _loadingTimeout?.cancel();
      _showPlaybackError(
          'Stream timed out - station may be offline or unreachable');
    } catch (_) {
      _loadingTimeout?.cancel();
      _showPlaybackError('Cannot play this station');
    }
  }

  /// Stop any current playback and reset to idle state.
  Future<void> stopPlayback() async {
    _loadingTimeout?.cancel();
    await player.stop();
    playerIsPlaying = false;
    playerIsLoading = false;
    playerBarPaused = true;
    playerStatus = 'Stopped';
    _hasLoadedStation = false;
    _safeNotify();
  }

  Future<void> togglePlayPause() async {
    final station = currentStation;
    if (station == null) {
      return;
    }

    // If loading — cancel/stop
    if (playerIsLoading) {
      await stopPlayback();
      return;
    }

    if (playerIsPlaying) {
      await player.pause();
      return;
    }

    if (_hasLoadedStation) {
      playerBarPaused = false;
      playerStatus = 'Connecting...';
      _safeNotify();
      await player.play();
    } else {
      await playStation(station);
    }
  }

  /// Play the next station in the current list.
  Future<void> playNextStation() async {
    if (stations.isEmpty) return;
    final idx = _currentIndex;
    final nextIdx = (idx + 1) % stations.length;
    await playStation(stations[nextIdx]);
  }

  /// Play the previous station in the current list.
  Future<void> playPreviousStation() async {
    if (stations.isEmpty) return;
    final idx = _currentIndex;
    final prevIdx = idx <= 0 ? stations.length - 1 : idx - 1;
    await playStation(stations[prevIdx]);
  }

  /// Start a sleep timer that stops playback after [duration].
  void startSleepTimer(Duration duration) {
    cancelSleepTimer();
    sleepTimerTotal = duration;
    sleepTimerRemaining = duration;
    _safeNotify();

    _sleepTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = sleepTimerRemaining;
      if (remaining == null || remaining.inSeconds <= 0) {
        cancelSleepTimer();
        return;
      }
      sleepTimerRemaining = remaining - const Duration(seconds: 1);
      _safeNotify();
    });

    _sleepTimer = Timer(duration, () {
      _stopPlaybackForSleep();
    });

    final minutes = duration.inMinutes;
    showToast('Sleep timer set for $minutes min', ToastType.info);
  }

  /// Cancel any active sleep timer.
  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTickTimer?.cancel();
    _sleepTimer = null;
    _sleepTickTimer = null;
    sleepTimerRemaining = null;
    sleepTimerTotal = null;
    _safeNotify();
  }

  Future<void> _stopPlaybackForSleep() async {
    cancelSleepTimer();
    if (playerIsPlaying) {
      await player.pause();
    }
    showToast('Sleep timer ended — playback stopped', ToastType.info);
  }

  Future<void> toggleFavoriteStation(Station station) async {
    final isNowFavorite = await favorites.toggle(station);
    favoriteUuids = favorites.getUuids().toSet();

    if (!isNowFavorite && currentTab == RadioTab.favorites) {
      stations = stations.where((item) => item.uuid != station.uuid).toList();
      stationCount = stations.length;

      if (stations.isEmpty) {
        emptyMessage =
            'No favorite stations yet. Tap the heart icon to save stations.';
        viewState = StationViewState.empty;
      }
    }

    showToast(
      isNowFavorite
          ? 'Added "${station.name}" to favorites'
          : 'Removed "${station.name}" from favorites',
      ToastType.success,
    );
    _safeNotify();
  }

  Future<void> switchTab(RadioTab tab) async {
    currentTab = tab;

    switch (tab) {
      case RadioTab.discover:
        await loadDiscover();
        break;
      case RadioTab.favorites:
        searchQuery = '';
        stationCount = 0;
        await loadFavorites();
        break;
      case RadioTab.add:
        searchQuery = '';
        stationCount = 0;
        _loadedDiscoverKey = null;
        emptyMessage = 'Enter a station name and stream URL above.';
        stations = <Station>[];
        viewState = StationViewState.empty;
        _safeNotify();
        break;
    }
  }

  Future<void> setSearchQuery(String query) async {
    final normalizedQuery = query.trim();
    if (searchQuery == normalizedQuery) {
      return;
    }

    searchQuery = normalizedQuery;
    _safeNotify();
  }

  Future<void> setCountry(String code) async {
    if (selectedCountry == code) {
      return;
    }

    selectedCountry = code;
    _safeNotify();
  }

  Future<void> setVolume(double value) async {
    volume = value.clamp(0, 100).toDouble();
    await player.setVolume(volume / 100);

    if (volume > 0 && isMuted) {
      isMuted = false;
    }

    _safeNotify();
  }

  Future<void> toggleMute() async {
    if (isMuted) {
      isMuted = false;
      volume = preVolume;
      await player.setVolume(preVolume / 100);
    } else {
      preVolume = volume;
      isMuted = true;
      volume = 0;
      await player.setVolume(0);
    }

    _safeNotify();
  }

  Future<void> addCustomStation(String name, String url) async {
    final station = Station.custom(name, url);
    await favorites.add(station);
    favoriteUuids = favorites.getUuids().toSet();
    showToast('Added "$name" - tap to play', ToastType.success);
    await switchTab(RadioTab.favorites);
  }

  Future<void> retry() async {
    final fn = _retryFn;
    if (fn != null) {
      await fn();
    }
  }

  void showToast(
    String message,
    ToastType type, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final toast = AppToast(id: ++_toastId, message: message, type: type);
    toasts = <AppToast>[...toasts, toast];
    _safeNotify();

    final timer = Timer(duration, () {
      toasts = toasts.where((item) => item.id != toast.id).toList();
      _safeNotify();
    });
    _toastTimers.add(timer);
  }

  void _onPlayerState(PlayerState state) {
    final processingState = state.processingState;
    final isConnecting = processingState == ProcessingState.loading ||
        processingState == ProcessingState.buffering;
    final hasStation = currentStation != null;

    playerIsLoading = isConnecting;
    playerIsPlaying = state.playing &&
        !isConnecting &&
        processingState != ProcessingState.completed;

    if (isConnecting && hasStation) {
      playerStatus = 'Connecting...';
      playerBarPaused = false;
    } else if (state.playing && processingState == ProcessingState.ready) {
      playerStatus = 'Now Playing';
      playerBarPaused = false;
    } else if (processingState == ProcessingState.completed) {
      playerIsPlaying = false;
      playerBarPaused = true;
      playerStatus = 'Paused';
    } else if (!state.playing && hasStation) {
      playerBarPaused = true;
      playerStatus = 'Paused';
    }

    _safeNotify();
  }

  void _showPlaybackError(String message) {
    showToast(message, ToastType.error, duration: const Duration(seconds: 5));
    playerIsPlaying = false;
    playerIsLoading = false;
    playerBarPaused = true;
    playerStatus = 'Paused';
    _hasLoadedStation = false;
    _safeNotify();
  }

  String _discoverKey(String query, String countryCode) {
    return '$query::$countryCode';
  }

  String _emptyDiscoverMessage(String query, String countryCode) {
    if (query.isNotEmpty && countryCode.isNotEmpty) {
      return 'No stations found for "$query" in this country.';
    }

    if (query.isNotEmpty) {
      return 'No stations found for "$query". Try a different search.';
    }

    if (countryCode.isNotEmpty) {
      return 'No stations found for this country.';
    }

    return 'No stations found';
  }

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _loadingTimeout?.cancel();
    _sleepTimer?.cancel();
    _sleepTickTimer?.cancel();
    for (final timer in _toastTimers) {
      timer.cancel();
    }
    _playerStateSub?.cancel();
    _playbackEventSub?.cancel();
    unawaited(player.dispose());
    api.dispose();
    super.dispose();
  }
}
