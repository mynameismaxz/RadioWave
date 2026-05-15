# Platform Setup

This source tree is structured for Flutter's six main targets:

- Android
- iOS
- Web
- macOS
- Windows
- Linux

The app is designed first for mobile and web, with a responsive layout that also scales to desktop.

## Generate Platform Folders

On a machine with Flutter installed, run this from the `radio_app_flutter` folder:

```powershell
flutter create --platforms=android,ios,web,windows,macos,linux .
flutter pub get
```

Run mobile or web:

```powershell
flutter run -d chrome
flutter run -d android
flutter run -d ios
```

Run desktop when enabled:

```powershell
flutter run -d windows
flutter run -d macos
flutter run -d linux
```

## Audio Notes

The project uses `just_audio` for Android, iOS, macOS, and web. Windows and Linux are enabled with `just_audio_media_kit`, `media_kit_libs_windows_audio`, and `media_kit_libs_linux`.

Some public radio streams are plain HTTP, have unusual codecs, or do not return complete server headers. That can still make individual stations fail on one platform while another platform plays them.

## Android

After `flutter create`, Android should include internet permission in the generated manifest. If you need to play plain HTTP streams, add cleartext traffic support to the generated Android app manifest:

```xml
<application
    android:usesCleartextTraffic="true"
    ...>
</application>
```

## iOS

For plain HTTP streams, add an App Transport Security exception in the generated `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

## macOS

For internet audio access, enable network client entitlement in generated macOS entitlements:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

For plain HTTP streams, use the same `NSAppTransportSecurity` exception in macOS `Info.plist`.

## Web

Web playback depends on browser codec support, CORS, and whether the stream server allows browser playback. HTTPS streams are the safest target for production web.
