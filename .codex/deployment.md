# Deployment

## Trạng thái
**Chưa có cấu hình deployment.** Dự án đang ở giai đoạn phát triển local.

## Không có
- CI/CD pipeline (GitHub Actions, Bitrise, Codemagic, etc.)
- Docker configuration
- Fastlane scripts
- App Store / Play Store configuration
- Build flavors (dev/staging/prod)

## Build thủ công

### Android Debug APK
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Android Release APK
```bash
flutter build apk --release
# Cần signing config trong android/app/build.gradle.kts
```

### iOS
```bash
flutter build ios --release
# Cần provisioning profile và certificate
```

## Package name
- Android: xem `android/app/build.gradle.kts`
- iOS: xem `ios/Runner/Info.plist`
- Package tool: `rename` package (dev dependency)

## Versioning
Hiện tại: `version: 1.0.0+1` trong `pubspec.yaml`

## Notes
- Không có environment separation (dev/prod) — dùng chung `.env` cho mọi environment
- Supabase project URL hardcode trong `.env` — cần tách ra khi có multi-environment
