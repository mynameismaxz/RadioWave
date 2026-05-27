# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with this repository.

## Project

RadioWave is a Flutter internet radio app for mobile, web, desktop, and Android Automotive. It streams public stations from the Radio Browser API and currently ships as `1.0.1+2`.

## Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter test test/widget_test.dart --plain-name 'creates a custom station favorite payload'
flutter run -d chrome
flutter run -d ios
flutter run -d android
flutter build web --release
```

On Windows, prefer the helper scripts in `tool/`, for example:

```powershell
.\tool\flutter.cmd pub get
.\tool\flutter.cmd analyze
.\tool\flutter.cmd test
.\tool\run_web.cmd
```

The web build deploys to Cloudflare Pages from `.github/workflows/deploy.yml`. `wrangler.jsonc` documents the static `build/web` output and SPA fallback for manual Wrangler usage.

## Architecture

### State Management

`lib/src/features/radio/state/radio_controller.dart` is the only app state container. It extends `ChangeNotifier` and owns the API client, favorites store, listening history store, playback state store, equalizer settings store, audio player, tab state, station list, search/country filters, player state, sleep timer, and toast queue.

`RadioWaveHome` constructs the controller once in `initState`, wires it with `AnimatedBuilder`, and disposes it. Widgets receive `controller` through constructors. Do not introduce Provider, Riverpod, or another DI/state framework without discussing it.

Theme follows the same simple pattern: `lib/src/app/theme/theme_notifier.dart` exports a top-level `themeNotifier` singleton consumed by `RadioWaveApp`.

### Data Layer

- `RadioBrowserApi` (`lib/src/data/services/radio_browser_api.dart`) uses `dio`.
- It races 4 Radio Browser mirrors with a 700 ms stagger; first success wins and updates `_currentServer`.
- It deduplicates in-flight requests by request key.
- It caches stations for 3 minutes and countries for 12 hours.
- Keep the staggered mirror race. A sequential fallback regresses cold-start latency.
- `FavoritesStore` persists to `SharedPreferences` under `radiowave_favorites`.
- `ListeningHistoryStore` persists to `SharedPreferences` under `radiowave_listening_history` and powers the local For You feed.
- Listening history must remain local-only unless privacy docs and store forms are updated.

### Audio

`lib/main.dart` controls platform-specific audio setup:

1. `JustAudioMediaKit.ensureInitialized()` is required for Windows/Linux media-kit support and is a no-op elsewhere.
2. `_initAudioHandler()` uses `AudioService.init(...)` on Android, iOS, macOS, and web. It returns a plain `RadioAudioHandler` on Windows/Linux.

`AudioPlayerService` wraps the shared `RadioAudioHandler` / `audio_service` player. Each `playStation` call sets a `MediaItem` for lock-screen, notification, and Android Auto metadata.

If `androidNotificationChannelId` changes, keep it aligned with Android package names and method-channel IDs:

- Android package: `com.cs6636291.radiowave`
- Playback channel: `com.cs6636291.radiowave.playback`
- Equalizer channel: `com.cs6636291.radiowave/equalizer`
- Rotary channel: `com.cs6636291.radiowave/rotary`

### UI

`RadioWaveHome` is a stack with gradient background, centered content, optional wide sidebar layout, bottom `PlayerBar`, and `ToastOverlay`.

Tabs are defined in `lib/src/features/radio/domain/radio_tab.dart`:

- `Discover`
- `Favorites`
- `Equalizer`
- `Add Station`

The list area renders one of four `StationViewState`s: `loading`, `list`, `empty`, or `error`. Keep these states wired through any new station flow.

Empty country selection is labeled `For You` and loads personalized stations when local listening history exists. If there is no history, it falls back to top Radio Browser stations.

## Network Security

Many radio streams are plain HTTP. Android currently enables `android:usesCleartextTraffic="true"` and iOS currently enables `NSAllowsArbitraryLoads`. Do not remove these without a tested replacement, or HTTP streams will stop playing.

If these are tightened later, use platform-specific network exceptions and update `Checklist.md`, `docs/privacy_policy.md`, and store review notes.

## Production Readiness

`Checklist.md` tracks current release blockers. As of this update:

- Android IDs are configured.
- Android release signing is wired, with local signing files ignored by git.
- Launcher icons are generated.
- iOS bundle identifiers still use `com.example.*`.
- iOS background audio mode is not yet declared in `Info.plist`.
- Store privacy URLs, support contact, screenshots, and final metadata still need completion.

Consult `Checklist.md` before touching `android/app/build.gradle.kts`, `ios/Runner/Info.plist`, iOS bundle identifiers, or `pubspec.yaml` version metadata.
