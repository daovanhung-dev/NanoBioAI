Commit de xuat: fix(ai): load Gemini config for VS Code AI chat

# Fix AI Chat khong nhan Gemini config trong VS Code

## Trieu chung

- Binary chay tu VS Code/CodeLens ghi `Gemini config present: false`.
- Moi tin nhan dung o `MISSING_API_KEY`, khong co request Gemini hop le.
- Man hinh luu loi trong controller nhung khong hien loi cho nguoi dung.
- Preflight co the bao sai voi model reasoning khi chi cap 16 output tokens va
  chi doc text part dau tien.

## Nguyen nhan xac nhan

- CodeLens Run/Debug theo entrypoint khong tim thay launch profile vi cac profile
  chua khai bao `templateFor`.
- Khi runtime client bi thieu, service cu tra fallback local. Repository khong
  phan biet fallback cau hinh voi AI response nen van co nguy co commit quota.
- Preflight khong du token output cho model reasoning va khong ghep moi text part.

## Cach sua

- Them `templateFor` cho `lib/main.dart`, `lib/main_v2.dart` va
  `lib/main_admin.dart`; giu pre-launch task va
  `--dart-define-from-file=.dart_tool/nanobio_defines.json` cho tung profile.
- Them `AIConfigurationUnavailableException`. `AIChatService.sendMessage()` va
  stream nem loi nay ngay khi thieu runtime client; khong retry va khong fallback
  local cho loi cau hinh.
- Repository map sang `AIChatUnavailableException` truoc diem commit quota;
  controller map thanh thong bao Nabi tieng Viet.
- Hien banner loi co dinh phia tren composer, co nut dong; composer dung loading
  sau khi request fail.
- Preflight dung toi thieu 512 output tokens va ghep tat ca text part.
- Sua contract test PowerShell bi Dart noi suy `$settings` sai ngu canh.

## Bao mat va pham vi

- Khong sua noi dung `.env`, khong commit `.env` hoac file defines tam.
- Khong ghi API key, prompt hay response ra log/tai lieu.
- Fix nay danh cho local/debug qua VS Code va terminal launcher; chua chuyen
  credential sang backend proxy.
- Loi mang/model van giu retry va fallback hien co.

## Bang chung

- 63 targeted tests PASS, gom service, repository quota, widget banner va
  launcher/preflight contracts.
- Targeted `flutter analyze` PASS.
- `tools/run_v2.ps1 -ValidateOnly`, prepare defines va Gemini live preflight PASS.
- Rebuild tren device `12b304f9` ghi `Gemini config present: true`.
- UI smoke nhan response voi `source: AI_GEN`, co `RETRY_ATTEMPT_SUCCESS` va
  `SUCCESS`; khong co `MISSING_API_KEY`.
