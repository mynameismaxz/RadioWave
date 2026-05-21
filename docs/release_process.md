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
.\tool\flutter.cmd build apk --release
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
- build `app-release.apk`
- create a GitHub Release
- upload the APK as a release asset

## 5. APK Artifact Builds

For non-release testing, use the **Build APK** workflow. It builds an APK from
`main` or a manual run and stores it as a GitHub Actions artifact without
creating a release.

## Signing Note

The current pipeline builds a standard Flutter release APK. For Play Store or
production distribution, add Android signing secrets and configure Gradle
signing before publishing.
