# RadioWave Flutter

This is a structured Flutter conversion of the original Vue/Vite RadioWave app.
It targets mobile and web first, while keeping the source compatible with Android,
iOS, web, macOS, Windows, and Linux.

## Structure

```text
lib/
  main.dart
  src/
    app/                  App shell and theme
    core/                 Small shared utilities
    data/
      models/             Station, country, toast models
      services/           Radio Browser API, favorites, audio player
    features/radio/
      domain/             Tabs and view-state enums
      state/              RadioController app state
      presentation/       Screens and widgets
```

## Features

- Discover stations from Radio Browser
- Search by station name
- Country filter
- Favorites stored locally with `shared_preferences`
- Add custom stream URLs
- Streaming audio playback with `just_audio`
- Windows/Linux audio bridge with `just_audio_media_kit`
- Bottom player bar with play/pause, favorite, mute, and volume controls
- Loading, empty, and error states

## Run

This machine has Flutter at `C:\flutter\bin\flutter.bat`, but `flutter` may not be available in PATH. Use the included `.cmd` helpers because they are not blocked by PowerShell script execution policy:

```powershell
.\tool\flutter.cmd pub get
.\tool\flutter.cmd analyze
.\tool\flutter.cmd test
```

Generate platform folders:

```powershell
.\tool\create_platforms.cmd
```

Mobile and web:

```powershell
.\tool\run_web.cmd
.\tool\run_android.cmd
```

Or call Flutter directly with its full path:

```powershell
& "C:\flutter\bin\flutter.bat" run -d chrome
& "C:\flutter\bin\flutter.bat" run -d android
```

If you want the normal `flutter` command to work in every new terminal, add `C:\flutter\bin` to your user PATH, then restart PowerShell.

Or run:

```powershell
.\tool\add_flutter_to_user_path.cmd
```

Then close and reopen PowerShell.

iOS must be run from macOS with Xcode:

```powershell
flutter run -d ios
```

## Platform Notes

See [docs/platform_setup.md](docs/platform_setup.md) for Android/iOS/macOS network settings and web playback caveats.
# RadioWave
