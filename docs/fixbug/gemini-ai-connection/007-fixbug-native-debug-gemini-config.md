Commit de xuat: fix(ai): prevent Android debug runs from losing Gemini config

# Fix Chat AI mat Gemini config khi chay truc tiep Android debug

## Trieu chung va bang chung

- UI thong bao Nabi chua san sang tro chuyen; log cua process dang chay ghi
  `Gemini config source: missing` va `MISSING_API_KEY`.
- Quota `check_usage_quota` van `allowed`, nen day khong phai loi quota hoac
  phan hoi Gemini.
- APK build qua launcher co key, nhung run tu IDE/gutter hoac `flutter run` khong
  truyen Dart define va tai lap loi.

## Cach sua

- Android debug Gradle doc `GEMINI_API_KEY` tu `.env` local va ghi vao
  `BuildConfig` cua debug build; release van de trong field native va dung Dart
  define qua launcher nhu truoc.
- `MainActivity` chi tra key qua MethodChannel runtime private. `AppEnv` uu tien
  Dart define, dotenv, sau do moi den native debug config; chi bao log nguon, khong
  log key.
- Khong them `.env` vao asset hay source control.

## Xac minh

- `flutter run -d 12b304f9 -t lib/main.dart` (khong Dart define) boot voi
  `Gemini config source: nativeBuildConfig`.
- Smoke Chat tren Android `12b304f9`: quota check allowed, Gemini tra response
  duoc validate, va quota commit thanh cong.
- Unit AI/config va analyzer target PASS; Gradle debug build/cai APK PASS.

## Gioi han

- Day la fallback local cho Android debug de tranh IDE chay sai profile. API key
  production van can duoc cap qua launch/build pipeline hien co; backend proxy la
  huong tang cuong bao mat rieng neu san pham phat hanh cong khai.
