Commit de xuat: fix(android): cho phep debug build khi thieu release keystore

# Worklog - Android debug build without release keystore

## Thoi gian

- Ngay: 2026-11-13
- Bat dau: 11:38
- Ket thuc: 11:52
- Timezone: Asia/Bangkok

## Pham vi

- Loai task: bugfix
- Module chinh: Android Gradle signing config
- Yeu cau goc: `flutter run` dung tai `android/app/build.gradle.kts` voi loi cast `null` sang `kotlin.String`.

## Da lam

- Xac nhan `android/key.properties` khong co tren may local va duoc ignore boi Git.
- Chi tao va gan release signing config khi du ca bon truong keystore.
- Xac nhan debug APK build duoc khi khong co release keystore.

## File code/docs da sua

- `android/app/build.gradle.kts` - sua - chi cau hinh ky release khi day du thong tin keystore.
- `docs/fixbug/android-debug-keystore/001-fixbug-android-debug-build-without-keystore.md` - tao - ghi lai hien tuong, nguyen nhan, va ket qua xac minh.
- `docs/worklog/2026-11-13/002-worklog-android-debug-build-without-keystore.md` - tao - ghi lai pham vi va bang chung.

## Tai lieu lien quan

- `docs/fixbug/android-debug-keystore/001-fixbug-android-debug-build-without-keystore.md`
- `.codex/workflows/bugfix.md`
- `.codex/task-skills/bugfix.md`

## Commands

- `flutter build apk --debug --no-pub`: PASS - tao `build/app/outputs/flutter-apk/app-debug.apk`; 832.1 giay.
- `git diff --check`: PASS.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: SKIPPED - PowerShell khong co trong moi truong.

## Loi/Rui ro

- Da fix: debug build khong con ep cast cac truong release signing khi may local chua co `key.properties`.
- Chua fix: khong co.
- Can kiem tra tiep: can `android/key.properties` day du de tao release artifact duoc ky.

## Ty le hoan thanh

- Hoan thanh: 100%.
- Dang do: 0%.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - patch hep va debug APK build thanh cong.
- Muc do hoan thanh task: hoan tat; da xac nhan tren cung Gradle path gap loi.
- Bang chung kiem chung: `flutter build apk --debug --no-pub` tao APK va `git diff --check` PASS.
- Diem ton token/chua toi uu: build Android lan dau mat hon 13 phut do compile; khong co Android cache san.
- Cach toi uu cho phien sau: neu Android build da duoc cache, chay build debug targeted; domain registry hien chua co domain rieng cho Android build config.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
