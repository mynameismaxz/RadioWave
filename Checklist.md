# Production Readiness Checklist - RadioWave Flutter

Current status as of 2026-05-27. This checklist tracks what is already done and what remains before App Store / Play Store submission.

## Done

- [x] Android package is no longer `com.example.*`.
  - `android/app/build.gradle.kts` uses `namespace = "com.cs6636291.radiowave"`.
  - `android/app/build.gradle.kts` uses `applicationId = "com.cs6636291.radiowave"`.
  - Kotlin package and Android method channels use `com.cs6636291.radiowave`.
- [x] Android media notification channel id is aligned with the package:
  - `lib/main.dart`: `com.cs6636291.radiowave.playback`.
- [x] Android release signing is wired in Gradle.
  - `android/app/build.gradle.kts` reads `android/key.properties`.
  - Missing signing files fail release builds clearly.
  - `android/key.properties` and `*.jks` are ignored by git.
- [x] Branded app icons are generated.
  - Source assets live in `assets/icons/`.
  - Android mipmaps, iOS AppIcon, and web icons exist.
  - `pubspec.yaml` uses `icons_launcher`.
- [x] Web metadata has `lang`, description, theme color, manifest, favicon, and maskable icons.
- [x] GitHub Actions exist for CI, APK builds, manual releases, and Cloudflare Pages deploys.
- [x] `flutter analyze` passes.
- [x] `flutter test` passes.
- [x] Privacy/data-safety drafts mention local favorites, playback state, equalizer settings, and listening history.

## Blockers Before Store Submission

### iOS Bundle and Signing

- [ ] Replace remaining iOS bundle identifiers:
  - `ios/Runner.xcodeproj/project.pbxproj`: `com.example.radioAppFlutter`
  - `ios/Runner.xcodeproj/project.pbxproj`: `com.example.radioAppFlutter.RunnerTests`
- [ ] Add `DEVELOPMENT_TEAM` and App Store distribution signing settings in Xcode.
- [ ] Create the app record in App Store Connect.
- [ ] Add `UIBackgroundModes` with `audio` in `ios/Runner/Info.plist` if background playback is required on iOS.
- [ ] Add a `PrivacyInfo.xcprivacy` privacy manifest before App Store submission.

### Store Metadata

- [ ] Host the privacy policy at a public HTTPS URL.
- [ ] Replace the placeholder contact section in `docs/privacy_policy.md` with a real support email.
- [ ] Fill Google Play Data Safety using `docs/play_store_data_safety.md`.
- [ ] Prepare short description, full description, category, screenshots, feature graphic, and content rating answers.
- [ ] Prepare App Store screenshots, subtitle, description, keywords, category, support URL, marketing URL, and review notes.

### Signing Secrets

- [ ] Confirm the upload keystore is backed up in a secure vault.
- [ ] Confirm GitHub release secrets are present:
  - `ANDROID_UPLOAD_KEYSTORE_BASE64`
  - `ANDROID_KEYSTORE_PASSWORD`
  - `ANDROID_KEY_PASSWORD`
  - `ANDROID_KEY_ALIAS`
- [ ] Never commit `android/key.properties`, keystores, provisioning profiles, or API tokens.

## Security and Compliance

### Network Security

- [ ] Review Android `android:usesCleartextTraffic="true"` in `android/app/src/main/AndroidManifest.xml`.
  - Plain HTTP is still needed for many public radio streams.
  - If tightened later, use `network_security_config.xml` and verify HTTP stations still work.
- [ ] Review iOS `NSAllowsArbitraryLoads=true` in `ios/Runner/Info.plist`.
  - Prepare App Review notes explaining public HTTP radio streams.
  - Prefer a narrower media-only or per-domain policy if feasible without breaking stations.

### Local Data

- [x] Favorites/custom stations are local-only.
- [x] Listening history for For You is local-only.
- [x] Theme, playback state, and equalizer settings are local-only.
- [ ] Add in-app controls for clearing listening history if required by store review or privacy policy scope.

## Product QA

- [ ] Search stations through Radio Browser.
- [ ] Use For You with no history and with populated listening history.
- [ ] Filter stations by country.
- [ ] Play HTTP and HTTPS streams.
- [ ] Save/remove favorites and verify persistence after restart.
- [ ] Add custom station and verify it appears in favorites.
- [ ] Use sleep timer.
- [ ] Switch light/dark/system theme.
- [ ] Adjust equalizer settings on Android and web.
- [ ] Verify offline/error UI.
- [ ] Verify layout on phone, tablet, desktop web, and Android Automotive landscape.
- [ ] Verify D-pad, rotary input, media keys, and Android Auto browse roots.
- [ ] Verify lock-screen/notification play-pause behavior.

## Build Verification

- [x] `.\tool\flutter.cmd analyze`
- [x] `.\tool\flutter.cmd test`
- [ ] `.\tool\flutter.cmd build apk --debug`
- [ ] `.\tool\flutter.cmd build apk --release`
- [ ] `.\tool\flutter.cmd build appbundle --release`
- [ ] `.\tool\flutter.cmd build web --release`
- [ ] `flutter build ipa --release` on macOS with Xcode signing configured.

## Release Steps

- [ ] Update `pubspec.yaml` version when preparing the next release.
  - Current version: `1.0.1+2`.
- [ ] Update `CHANGELOG.md`.
- [ ] Run local checks:
  - `.\tool\flutter.cmd pub get`
  - `.\tool\flutter.cmd analyze`
  - `.\tool\flutter.cmd test`
- [ ] Push to `main`.
- [ ] Run the manual GitHub `Release` workflow.
- [ ] Upload the generated AAB to Play Console.
- [ ] Deploy web from `main` through the `Deploy Web` workflow.
