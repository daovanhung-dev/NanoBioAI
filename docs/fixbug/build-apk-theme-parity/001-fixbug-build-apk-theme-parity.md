Commit de xuat: fix(theme): dong bo palette APK release voi flutter run

# Fixbug - Dong bo palette APK release voi flutter run

## Van de

`flutter run` mac dinh tao debug build, trong khi `flutter build apk` mac dinh tao release build. Co `STITCH_GREEN_UI_ENABLED` truoc day bat Green o debug/profile nhung mac dinh Blue o release, nen hai ban cung `lib/main.dart` hien thi hai palette khac nhau.

## Nguyen nhan

`AppThemeFlags.stitchGreenUiEnabled` dung `defaultValue: !kReleaseMode`. Day la mot dieu kien compile-time, nen APK release khong co Dart define se chon Blue rollback.

## Cach sua

- Dat `STITCH_GREEN_UI_ENABLED` mac dinh la `true` o moi build mode.
- Giu `--dart-define=STITCH_GREEN_UI_ENABLED=false` lam rollback Blue trong mot release.
- Khong thay doi entrypoint, Android application ID, flavor, manifest, Auth hoac AI runtime config.

## Kiem chung

- Theme contract test PASS o cau hinh mac dinh Green va cau hinh rollback Blue.
- `flutter build apk` PASS, tao APK release Green.
- APK release da duoc cai va smoke tren Android; man hinh onboarding hien palette Green Wellness.
- `flutter build apk --dart-define=STITCH_GREEN_UI_ENABLED=false` PASS va tao artifact rollback khac hash voi APK Green.

## Gioi han

Thay doi nay chi dong bo presentation palette. Debug-only tools/logging va Gemini runtime config cua release van theo chinh sach hien co. Cac bang chung visual, accessibility, privacy, license va release-ready khac van dang mo.
