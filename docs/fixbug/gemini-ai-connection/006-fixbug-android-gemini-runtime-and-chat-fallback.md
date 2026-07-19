Commit de xuat: fix(ai): restore Android Gemini runtime config and chat fallback

# Fix Android Gemini runtime config va chat fallback

## Trieu chung

- APK Android ghi `MISSING_API_KEY` trong `AIChatService` du quota RPC van cho phep.
- Chat chi thu `gemini-3.1-flash-lite` va `gemini-2.5-flash-lite`, trong khi
  preflight xac nhan `gemini-3.5-flash` la model kha dung.

## Nguyen nhan

- Profile Android Studio `main.dart` khong co
  `--dart-define-from-file=.dart_tool/nanobio_defines.json`. File `.env` co chu
  y nam ngoai Flutter assets, nen APK chay tu profile nay khong the tu doc key.
- Danh sach fallback cua Chat khac danh sach da duoc dung cho tao lich va bo qua
  `gemini-3.5-flash`.

## Cach sua

- Them shared Android Studio profile `NanoBio - Authenticated App`; cap nhat
  profile local hien tai cung chuyen Dart defines. README huong dan tao lai file
  defines sau khi doi `.env`; file nay van bi git ignore va khong in secret.
- Them log bootstrap chi bao nguon cau hinh (`dartDefine`, `dotEnv`, public
  config hoac missing), khong bao gio log gia tri key.
- Them `gemini-3.5-flash` vao fallback mac dinh cua Chat truoc cac model lite,
  dong bo voi luong tao lich. Chat van fail-closed neu tat ca model loi; khong
  tra loi local gia de commit quota.

## Bang chung

- APK moi tren Android `12b304f9` ghi `Gemini config present: true` va
  `Gemini config source: dartDefine`.
- Gemini preflight thanh cong voi `gemini-3.5-flash`.
- 60 targeted AI/config/launcher tests PASS va targeted `flutter analyze` PASS.

## Bao mat va gioi han

- Khong sua, ghi, commit hay hien thi `GEMINI_API_KEY`.
- Chua thay the acceptance UI thu cong cho chat va tao lich; can thuc hien tren
  tai khoan co quota de xac nhan response va luu lich end-to-end.
