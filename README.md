# RadioWave

[![CI](https://github.com/cs6636291/RadioWave/actions/workflows/ci.yml/badge.svg)](https://github.com/cs6636291/RadioWave/actions/workflows/ci.yml)
[![Build APK](https://github.com/cs6636291/RadioWave/actions/workflows/build-apk.yml/badge.svg)](https://github.com/cs6636291/RadioWave/actions/workflows/build-apk.yml)
[![Deploy Web](https://github.com/cs6636291/RadioWave/actions/workflows/deploy.yml/badge.svg)](https://github.com/cs6636291/RadioWave/actions/workflows/deploy.yml)

RadioWave is a responsive Flutter internet radio app for web, mobile, desktop,
and Android Automotive. It discovers public stations through Radio Browser,
plays live streams with `just_audio`, and includes favorites, custom stations,
personalized "For You" discovery, equalizer controls, Android Auto media
browsing, and car rotary input support.

Live web app: [radiowave.pages.dev](https://radiowave.pages.dev/)

## Highlights

- Discover and search stations from Radio Browser
- Start from a personalized For You station feed based on local listening history
- Filter stations by country
- Save favorites locally with `shared_preferences`
- Add custom stream URLs
- Stream audio with `just_audio`
- Use `audio_service` for native media controls and Android Auto browsing
- Windows and Linux audio support with `just_audio_media_kit`
- Responsive web-style player and Android Automotive landscape layout
- Android Auto media library integration
- Car rotary and D-pad navigation support
- Branded launcher icons generated with `icons_launcher`
- Cloudflare Pages web deployment
- GitHub Actions CI, APK artifact builds, and manual releases

## Tech Stack

- Flutter 3.27+
- Dart 3.4+
- `just_audio`
- `audio_service`
- `dio`
- `shared_preferences`
- `icons_launcher`
- Cloudflare Pages / Wrangler
- GitHub Actions

## Project Structure

```text
lib/
  main.dart
  src/
    app/                  App shell, theme, and startup wiring
    core/                 Shared utilities
    data/
      models/             Station, country, and toast models
      services/           Radio Browser, audio, storage, Android Auto
    features/radio/
      domain/             Tabs, view states, and personalized station sorting
      state/              RadioController app state
      presentation/       Screens, responsive layouts, and widgets

android/                  Android and Android Automotive integration
docs/                     Platform and release documentation
scripts/                  Cloudflare build scripts
test/                     Unit and widget tests
tool/                     Local Flutter helper scripts for Windows
web/                      Flutter web shell
```

## Getting Started

This repository includes Windows helper scripts because local Flutter may not be
available in `PATH`.

```powershell
cd C:\tmp\radio_app_flutter_run
.\tool\flutter.cmd pub get
.\tool\flutter.cmd analyze
.\tool\flutter.cmd test
```

Run on web:

```powershell
.\tool\run_web.cmd
```

Run on Android or Android Automotive:

```powershell
.\tool\flutter.cmd run -d emulator-5554
```

Build a debug APK:

```powershell
.\tool\flutter.cmd build apk --debug
```

Build a release APK:

```powershell
.\tool\flutter.cmd build apk --release
```

Build the signed Android App Bundle for Google Play:

```powershell
.\tool\flutter.cmd build appbundle --release
```

Release signing setup is documented in [docs/play_store_release.md](docs/play_store_release.md).

## Android Automotive

RadioWave declares Android Auto media support and exposes browseable media roots
for favorites and popular stations. The app also supports system media controls,
landscape layouts, D-pad navigation, media keys, and rotary events on Android
Automotive emulators.

Typical local install flow:

```powershell
.\tool\flutter.cmd build apk --debug
adb install -r build\app\outputs\flutter-apk\app-debug.apk
adb shell am start -n com.cs6636291.radiowave/.MainActivity
```

## CI/CD

The repository uses three workflow types:

- `ci.yml` validates every pull request and push to `main`
- `build-apk.yml` builds downloadable APK artifacts from `main` or manual runs
- `release.yml` creates signed APK and AAB release assets manually from the Actions tab
- `deploy.yml` deploys Flutter web to Cloudflare Pages from `main`

Release documentation is in [docs/release_process.md](docs/release_process.md).

## Versioning

Flutter versioning is controlled by `pubspec.yaml`:

```yaml
version: 1.0.2+3
```

Use this format:

```text
versionName+versionCode
```

Example:

```yaml
version: 1.0.2+3
```

Increase `versionCode` for every Android build intended for release.

## Documentation

- [Platform setup](docs/platform_setup.md)
- [Release process](docs/release_process.md)
- [Play Store release checklist](docs/play_store_release.md)
- [Play Store data safety draft](docs/play_store_data_safety.md)
- [Privacy policy draft](docs/privacy_policy.md)
- [Production readiness checklist](Checklist.md)
- [Contributing](CONTRIBUTING.md)
