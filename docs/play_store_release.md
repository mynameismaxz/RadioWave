# Google Play Release Checklist

## Package

- Android application id: `com.cs6636291.radiowave`
- Android namespace: `com.cs6636291.radiowave`
- Notification channel id: `com.cs6636291.radiowave.playback`

If you own a domain and want a domain-based package name, change this before the first Play Console upload. Google Play package names are effectively permanent after publishing.

## Release Signing

Create an upload keystore outside git:

```powershell
keytool -genkey -v -keystore android\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties` from `android/key.properties.example`:

```properties
storePassword=your-keystore-password
keyPassword=your-key-password
keyAlias=upload
storeFile=../upload-keystore.jks
```

`android/key.properties` and keystore files are ignored by git. Back them up in a password manager or secure vault.

## Build

```powershell
.\tool\flutter.cmd clean
.\tool\flutter.cmd pub get
.\tool\flutter.cmd analyze
.\tool\flutter.cmd test
.\tool\flutter.cmd build appbundle --release
```

Upload this file to Play Console:

```text
build\app\outputs\bundle\release\app-release.aab
```

## Store Listing Draft

Short description:

```text
Discover, stream, and save live internet radio stations with RadioWave.
```

Full description:

```text
RadioWave is a simple internet radio player for discovering live stations from around the world. Search public Radio Browser stations, filter by country, save favorites, add custom streams, and keep playback controls close at hand.

Features:
- Discover live public radio stations
- Search and filter stations by country
- Save favorites locally on your device
- Add custom stream URLs
- Sleep timer, theme settings, and equalizer controls
- Background audio controls on supported Android devices
```

Category suggestion: Music & Audio.

## Network Security Note

Some public radio stations still serve streams over HTTP. The Android app keeps cleartext media playback enabled so those streams can play. Do not remove this without replacing HTTP stream support or many stations will fail.
