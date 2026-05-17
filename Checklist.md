# Production Readiness Checklist — RadioWave Flutter

Checklist สำหรับตรวจสอบก่อน build ขึ้น production (Mobile / Web)

---

## 🔴 Blocker — ต้องแก้ก่อน Submit Store

### 1. Application ID / Bundle Identifier
- [ ] เปลี่ยน Android `applicationId` จาก `com.example.radio_app_flutter`
  - File: `android/app/build.gradle.kts:24`
- [ ] เปลี่ยน Android `namespace`
  - File: `android/app/build.gradle.kts:9`
- [ ] เปลี่ยน iOS `PRODUCT_BUNDLE_IDENTIFIER` จาก `com.example.radioAppFlutter`
  - File: `ios/Runner.xcodeproj/project.pbxproj` (และ `RunnerTests`)
- [ ] เปลี่ยน `androidNotificationChannelId` ให้ตรงกับ applicationId ใหม่
  - File: `lib/main.dart:27`
- [ ] ลบ TODO ใน `android/app/build.gradle.kts:23` หลังตั้งค่าเสร็จ

### 2. Android Release Signing
- [ ] สร้าง upload keystore (`keytool -genkey -v -keystore upload-keystore.jks ...`)
- [ ] สร้าง `android/key.properties` (อย่าลืม add ใน `.gitignore`)
- [ ] กำหนด `signingConfigs.release` ใน `android/app/build.gradle.kts`
- [ ] เปลี่ยน `buildTypes.release.signingConfig` จาก `debug` → `release`
  - File: `android/app/build.gradle.kts:35-38`
- [ ] เพิ่ม ProGuard / R8 rules ถ้าเปิด minify
- [ ] เก็บ keystore + รหัสผ่านอย่างปลอดภัย (อย่าให้หาย — เปลี่ยนไม่ได้)

### 3. iOS Code Signing
- [ ] เพิ่ม `DEVELOPMENT_TEAM` ใน Xcode project
- [ ] ตั้งค่า Provisioning Profile (App Store distribution)
- [ ] เปิด Capabilities: Background Modes → Audio, AirPlay, and Picture in Picture
- [ ] สร้าง App Record ใน App Store Connect

### 4. App Icons (ตอนนี้ยังเป็น Flutter default logo)
- [ ] เพิ่ม `flutter_launcher_icons` ใน `dev_dependencies`
- [ ] สร้าง icon source (1024x1024) + adaptive icon foreground/background
- [ ] Generate icons สำหรับทุก density (Android `mipmap-*`, iOS `AppIcon.appiconset`)
- [ ] ตรวจสอบ web `favicon.png`, `apple-touch-icon.png`, `icons/Icon-*.png` ให้เป็น brand จริง

---

## 🟠 ความปลอดภัย / Compliance

### 5. Network Security
- [ ] ทบทวน `android:usesCleartextTraffic="true"` ใน `AndroidManifest.xml:11`
  - ถ้าจำเป็น (radio HTTP streams) → ใช้ `network_security_config.xml` จำกัดเฉพาะ domain
- [ ] ทบทวน `NSAllowsArbitraryLoads=true` ใน `ios/Runner/Info.plist:28-31`
  - เตรียมเหตุผล `NSAllowsArbitraryLoadsForMedia` หรือ exception per-domain
  - **เตรียมคำชี้แจงให้ App Review** ว่าทำไมต้อง allow cleartext

### 6. Privacy / Legal
- [ ] เตรียม **Privacy Policy URL** (จำเป็นสำหรับ App Store + Play Store)
- [ ] เตรียม Privacy Manifest (`PrivacyInfo.xcprivacy`) — iOS บังคับตั้งแต่ 2024
- [ ] กรอก Data Safety form ใน Play Console (เก็บ favorites ใน local เท่านั้น)
- [ ] ถ้าจะใส่ analytics/crash reporting → ระบุใน privacy policy

### 7. Permissions
- [ ] ทบทวน Android permissions ใน `AndroidManifest.xml` (INTERNET, WAKE_LOCK, FOREGROUND_SERVICE*) — ✅ ครบและสมเหตุสมผลแล้ว
- [ ] iOS background audio: ต้องเพิ่ม `UIBackgroundModes` → `audio` ใน `Info.plist` (ยังไม่มี!)

---

## 🟡 Metadata / Store Assets

### 8. App Metadata
- [ ] อัพเดท `pubspec.yaml` → `description` ให้เป็น marketing copy (ตอนนี้เขียนว่า "A Flutter conversion of...")
- [ ] กำหนด `version` semver ที่จะ release (ตอนนี้ `1.0.0+1`)
- [ ] ตรวจสอบ `CFBundleDisplayName` และ `android:label` = "RadioWave" ✅
- [ ] เตรียม screenshots (Android: phone/tablet, iOS: 6.7"/6.5"/5.5"/iPad)
- [ ] เตรียม Feature graphic (Play Store) + App preview video (optional)
- [ ] เขียน Short description + Full description
- [ ] เลือก Category + Content rating questionnaire

### 9. Web / PWA
- [ ] ตรวจสอบ `web/manifest.json` — ✅ ครบ
- [ ] ตรวจสอบ `web/index.html` description / theme-color — ✅ มี
- [ ] เพิ่ม `lang` attribute ใน `<html>` tag ของ `web/index.html`
- [ ] ทดสอบ Lighthouse PWA score
- [ ] กำหนด custom domain ใน Cloudflare Workers (ถ้ามี)

---

## 🟢 คุณภาพโค้ด / Testing

### 10. Tests
- [ ] เพิ่ม widget tests สำหรับหน้าจอหลัก (Home, Player, Favorites)
- [ ] เพิ่ม integration test สำหรับ flow: ค้นหา → เล่น → add favorite
- [ ] Mock `RadioBrowserApi` ใน test (ตอนนี้ใน `test/widget_test.dart` มีแค่ 2 unit tests)
- [ ] รัน `flutter test --coverage` ตั้ง target ≥ 50%

### 11. Build Verification
- [ ] `flutter analyze` → no issues ✅
- [ ] `flutter test` → all pass ✅
- [ ] `flutter build apk --release` → สำเร็จ + ทดสอบบนเครื่องจริง
- [ ] `flutter build appbundle --release` → สำหรับ Play Store
- [ ] `flutter build ipa --release` → สำหรับ App Store
- [ ] `flutter build web --release` → ทดสอบ deploy

### 12. Manual QA บนเครื่องจริง
- [ ] เล่นสถานี HTTP / HTTPS ทั้งสอง
- [ ] Background playback (ล็อกหน้าจอ → ยังเล่นต่อ)
- [ ] Lock screen / notification controls (play/pause/next/prev)
- [ ] เปลี่ยนสถานีระหว่างเล่น (ไม่ค้าง / leak audio)
- [ ] โทรเข้าระหว่างเล่น (audio interruption handling)
- [ ] Add custom station + favorite persistence หลังปิดแอป
- [ ] Sleep timer ทำงานครบ
- [ ] Dark / Light mode + system theme follow
- [ ] Offline state (ไม่มี internet → error UI ถูกต้อง)
- [ ] Rotate / resize (iPad / tablet / web)

---

## 🔵 Operations

### 13. Monitoring / Crash Reporting (optional แต่แนะนำ)
- [ ] เพิ่ม `firebase_crashlytics` หรือ `sentry_flutter`
- [ ] ตั้ง alert สำหรับ crash rate
- [ ] เก็บ analytics event (เล่นสถานี / favorite) — ระวัง privacy

### 14. CI/CD
- [ ] เพิ่ม GitHub Actions workflow: `flutter analyze` + `flutter test` ทุก PR
- [ ] (Optional) Auto build APK/IPA ตอน tag release
- [ ] Cloudflare Workers deploy preview สำหรับ PR

### 15. Documentation
- [ ] อัพเดท `README.md` (ตอนนี้ยังเขียนเชิง dev setup, แก้ trailing `# RadioWave` ซ้ำที่บรรทัด 101)
- [ ] เพิ่ม `CHANGELOG.md`
- [ ] เพิ่มไฟล์ `LICENSE`

---

## 📝 Pre-Release Checklist สุดท้าย

- [ ] `flutter clean && flutter pub get && flutter analyze && flutter test`
- [ ] ทดสอบ release build บนเครื่องจริง (ไม่ใช่ debug/profile)
- [ ] Commit ทุกอย่าง + tag version (`git tag v1.0.0`)
- [ ] Backup keystore + provisioning profile ในที่ปลอดภัย
- [ ] Submit Android (Internal testing → Closed → Production)
- [ ] Submit iOS (TestFlight → App Store)
- [ ] Deploy web (`bash scripts/cloudflare_build.sh && npx wrangler deploy`)
- [ ] ตรวจสอบ store listing สด ๆ หลัง approve
