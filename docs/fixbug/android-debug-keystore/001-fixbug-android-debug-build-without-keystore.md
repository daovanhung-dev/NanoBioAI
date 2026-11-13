Commit de xuat: fix(android): cho phep debug build khi thieu release keystore

# Fixbug - Android debug build without release keystore

## Hien tuong

`flutter run` dung khi Gradle doc `android/app/build.gradle.kts`, voi loi cast `null` sang `kotlin.String` tai cau hinh release signing.

## Nguyen nhan goc

Build script tao release signing config trong moi lan evaluate va cast bat buoc cac gia tri trong `key.properties`. File nay khong co tren may local, vi no chua release keystore bi ignore boi Git.

## Ban va

- Chi tao va gan release signing config khi ca bon gia tri `keyAlias`, `keyPassword`, `storeFile`, va `storePassword` deu duoc cau hinh.
- Debug build khong can release keystore.
- Release build duoc ky khi cac gia tri keystore day du; neu thieu, artifact release khong duoc ky.

## Files

- `android/app/build.gradle.kts`

## Validation

- `git diff --check -- android/app/build.gradle.kts`: PASS.
- `flutter build apk --debug --no-pub`: PASS; tao `build/app/outputs/flutter-apk/app-debug.apk` in 832.1 seconds.
