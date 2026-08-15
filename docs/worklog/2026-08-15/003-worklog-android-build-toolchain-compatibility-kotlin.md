Commit de xuat: docs(worklog): ghi nhan fix Kotlin Android toolchain

# Worklog - Android build toolchain Kotlin compatibility

## Thoi gian

- Ngay: 2026-08-15
- Bat dau: 17:08
- Ket thuc: 17:38
- Timezone: Asia/Saigon

## Pham vi

- Loai task: bugfix
- Module chinh: Android build toolchain
- Yeu cau goc: Fix `flutter run` va `flutter build apk` bi chan do Kotlin `2.1.0` thap hon muc Flutter yeu cau `2.2.20`.

## Da lam

- Doc objective va xac nhan loi Kotlin tu log runtime.
- Bao toan cac thay doi co san: Gradle Wrapper `8.14` va AGP `8.11.1`.
- Nang Kotlin Android plugin tu `2.1.0` len `2.2.20` trong `android/settings.gradle.kts`.
- Xac nhan JDK 17, Flutter 3.47.0 va thiet bi Android `220333QPG`.
- Ghi nhan lan build dau bi cham do stale Kotlin incremental cache tren hai o dia khac nhau; lan chay tiep theo da build thanh cong.

## File code/docs da sua

- `android/settings.gradle.kts` - sua - Kotlin `2.1.0` -> `2.2.20`.
- `docs/fixbug/android-build-toolchain-compatibility/001-fixbug-android-build-toolchain-compatibility.md` - cap nhat - ghi nhan day du ba muc toolchain.
- `PATCH_MANIFEST.md` - cap nhat - phan anh patch cumulative.
- `README_APPLY.md` - cap nhat - huong dan ap dung hai file Android.

## Commands

- `flutter analyze --suggestions`: PASS - Java/Gradle/AGP/KGP compatible.
- `flutter build apk --debug`: TIMEOUT - lan chay dau cham trong native setup va Kotlin cache.
- `flutter build apk --debug --no-pub`: PASS - tao `build/app/outputs/flutter-apk/app-debug.apk`.
- `flutter run`: PASS - app `com.example.nano_app` da chay, `MainActivity` resumed tren `220333QPG`.
- `git diff --check`: PASS.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL - validator bao stale backticked Supabase paths da co san trong `.codex`; khong lien quan Android patch.

## Loi/Rui ro

- Da fix: Flutter khong con chan do Kotlin `2.1.0`.
- Chua fix: Khong co loi build blocking nao sau khi build lai.
- Can kiem tra tiep: Flutter se som bo canh bao ho tro cac phien ban toolchain cu hon; nang len major tiep theo trong mot dot rieng.

## Ty le hoan thanh

- Hoan thanh: 100% yeu cau runtime.
- Dang do: 0%.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - patch nho, giu nguyen pham vi Android va co bang chung build/device.
- Muc do hoan thanh task: hoan tat.
- Bang chung kiem chung: `flutter analyze --suggestions`, `flutter build apk --debug --no-pub`, va Android activity resumed.
- Diem ton token/chua toi uu: Lan build dau bi keo dai do cache va hai tien trinh Flutter song song.
- Cach toi uu cho phien sau: Kiem tra tien trinh build hien co truoc khi chay native build va dung `flutter build --no-pub` sau lan build dau.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
