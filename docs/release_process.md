# Release Process

RadioWave uses manual GitHub Actions releases. Tags are not required locally.
The release workflow creates the GitHub Release from the version you type in the
Actions UI.

## 1. Update App Version

Edit `pubspec.yaml`:

```yaml
version: 1.0.1+2
```

The format is:

```text
versionName+versionCode
```

- `versionName` is the public version, for example `1.0.1`
- `versionCode` is the Android build number and must increase every release

## 2. Run Local Checks

```powershell
.\tool\flutter.cmd pub get
.\tool\flutter.cmd analyze
.\tool\flutter.cmd test
.\tool\flutter.cmd build appbundle --release
```

## 3. Commit and Push

```powershell
git add pubspec.yaml
git commit -m "chore: release 1.0.1"
git push origin main
```

## 4. Create Release in GitHub

1. Open GitHub.
2. Go to **Actions**.
3. Open **Release**.
4. Click **Run workflow**.
5. Enter the version, for example `1.0.1`.
6. Run the workflow.

The workflow will:

- verify that `pubspec.yaml` matches the entered version
- run `flutter analyze`
- run `flutter test`
- configure Android signing from GitHub Secrets
- build `app-release.apk`
- build `app-release.aab` for Google Play
- create a GitHub Release
- upload the APK and AAB as release assets

## 5. APK Artifact Builds

For non-release testing, use the **Build APK** workflow. It builds an APK from
`main` or a manual run and stores it as a GitHub Actions artifact without
creating a release.

## Signing Note

Release builds require Android signing secrets. Add these GitHub repository
secrets before using the release workflows:

- `ANDROID_UPLOAD_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`

Create the base64 value from the upload keystore file:

```bash
base64 -w 0 android/upload-keystore.jks
```

Use the generated AAB for Google Play:

```text
build/app/outputs/bundle/release/app-release.aab
```
