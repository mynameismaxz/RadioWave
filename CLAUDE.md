# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter port of a Vue/Vite internet radio app (RadioWave). Targets mobile + web first; Android, iOS, macOS, Windows, and Linux are also supported. Streams from the public [Radio Browser](https://www.radio-browser.info/) API.

## Commands

```bash
flutter pub get
flutter analyze        # CI gate — lint config in analysis_options.yaml is strict (prefer_const_*)
flutter test
flutter test test/widget_test.dart --plain-name 'creates a custom station favorite payload'  # single test
flutter run -d chrome  # web
flutter run -d ios     # iOS (macOS + Xcode required)
flutter run -d android
flutter build web --release
```

On Windows, use the `tool/*.cmd` wrappers (e.g. `tool\flutter.cmd analyze`) — they invoke the Flutter at `C:\flutter\bin\flutter.bat` and bypass PowerShell execution policy. On macOS/Linux just call `flutter` directly.

The web build deploys to Cloudflare Workers via Wrangler static assets — see `scripts/cloudflare_build.sh` (clones Flutter stable on every CI build) and `wrangler.jsonc` (serves `build/web` with SPA fallback).

## Architecture

### State management — single ChangeNotifier, no Provider/Riverpod

`lib/src/features/radio/state/radio_controller.dart` is the **only** app state container. It extends `ChangeNotifier` and owns: API client, favorites store, audio player, tab state, station list, search/country filter, player state, sleep timer, and toast queue. `RadioWaveHome` constructs it once in `initState`, wires it with `AnimatedBuilder`, and disposes it. Every widget below receives `controller` as a constructor arg — there is no `InheritedWidget`, no `Provider`, no `Riverpod`. Add new state to `RadioController` and call `_safeNotify()`; do not introduce a DI framework without discussing it.

Theme is the same pattern: `lib/src/app/theme/theme_notifier.dart` exports a top-level `themeNotifier` singleton (`ValueNotifier<ThemeMode>`), consumed by `RadioWaveApp` via `ValueListenableBuilder`.

### Data layer

- `RadioBrowserApi` (`lib/src/data/services/radio_browser_api.dart`) **races 4 mirrors in parallel** with a 700 ms stagger between starts; first success wins and updates `_currentServer` so subsequent requests prefer the fast mirror. Has request-key in-flight deduplication and TTL cache (3 min stations, 12 h countries). Keep the staggered-race behavior — replacing it with a sequential fallback regresses cold-start latency significantly.
- `FavoritesStore` persists to `SharedPreferences` under key `radiowave_favorites` as a JSON list. Always call `init()` before reading.
- `AudioPlayerService` wraps `just_audio`. Each `playStation` call attaches a `MediaItem` tag for lock-screen / notification metadata via `just_audio_background`.

### Audio platform matrix

`lib/main.dart` controls platform-specific init order. **Both calls matter:**

1. `JustAudioMediaKit.ensureInitialized()` — required on Windows/Linux (media_kit backend); no-op elsewhere.
2. `JustAudioBackground.init(...)` — only valid on Android, iOS, macOS, and web. The guard in `_initBackgroundPlayback()` skips it on Windows/Linux to avoid a crash.

If `androidNotificationChannelId` is changed, it must stay in sync with the Android `applicationId` (see `Checklist.md`).

### UI structure

`RadioWaveHome` is a stack: solid gradient background → centered content column (header, country filter, tab nav, station viewport) capped at 720px wide → bottom `PlayerBar` → `ToastOverlay`. Tabs (`Discover` / `Favorites` / `Add`) are an enum in `lib/src/features/radio/domain/radio_tab.dart`; the list area renders one of four `StationViewState`s (`loading`, `list`, `empty`, `error`) — keep those four states wired through any new flow.

## Network security (HTTP streams)

Many radio streams are plain HTTP. The Android manifest enables `usesCleartextTraffic="true"` and `ios/Runner/Info.plist` sets `NSAllowsArbitraryLoads`. Tightening these (per-domain exceptions, `network_security_config.xml`) is tracked in `Checklist.md` — don't silently remove them without a replacement, or HTTP streams stop playing.

## Production readiness

`Checklist.md` (Thai + English, mixed) tracks every blocker before store submission: bundle IDs are still `com.example.*`, Android release signing isn't configured, iOS background audio mode (`UIBackgroundModes`) is missing from `Info.plist`, and launcher icons are still the Flutter default. Consult it before touching `android/app/build.gradle.kts`, `ios/Runner/Info.plist`, or `pubspec.yaml` version metadata.
