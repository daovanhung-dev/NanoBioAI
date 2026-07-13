Commit de xuat: fix(ai): truyen Gemini runtime config tu dotenv

# Worklog - Fix Gemini API key sau onboarding

## Thoi gian

- Ngay: 2026-07-13
- Bat dau: 10:00
- Ket thuc: 10:20
- Timezone: Asia/Saigon

## Pham vi

- Loai task: bugfix
- Module chinh: M05 AI / runtime configuration / onboarding
- Yeu cau goc: Sua loi onboarding khong su dung duoc Gemini API key.

## Da lam

- Xac dinh `.env` dang bi truyen sai vao `--dart-define-from-file` (Flutter yeu cau JSON, `.env` la KEY=VALUE).
- Cap nhat launcher run/build de parse `.env` va truyen cac key bang `--dart-define`, khong in secret.
- Them script tao JSON tam trong `.dart_tool` cho VS Code launch, khong bundle `.env`.
- Cap nhat README, contract tests va header REST client.

## File code/docs da sua

- `tools/run_v2.ps1`, `tools/build_authenticated.ps1` - truyen runtime config bang Dart defines.
- `tools/prepare_dart_defines.ps1`, `.vscode/tasks.json`, `.vscode/launch.json` - ho tro VS Code bang file tam ignored.
- `lib/app_versions/v1/services/ai/gemini_rest_client.dart` - chuan hoa header HTTP.
- `test/tools/*_contract_test.dart`, `README.md` - regression va huong dan.

## Commands

- `powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1 -ValidateOnly`: PASS.
- `flutter test test/tools/run_v2_contract_test.dart test/tools/build_authenticated_contract_test.dart`: PASS.
- `flutter test test/services/ai/gemini_rest_client_test.dart test/services/ai/ai_service_test.dart`: PASS.
- `dart format --set-exit-if-changed ...`: PASS.
- `git diff --check`: PASS (chi co warning line ending tu working tree hien huu).
- Live device/Gemini smoke: CHUA CHAY - can thiet bi va mang that.

## Loi/Rui ro

- Da fix: API key tu `.env` duoc dua vao Dart compile-time config khi dung launcher/VS Code.
- Chua xac minh: onboarding va Gemini live tren device that.
- Khong ghi API key, prompt, response hoac payload nhay cam vao log/worklog.

## Ty le hoan thanh

- Hoan thanh: source fix, launcher, VS Code flow, regression tests.
- Dang do: live API/device acceptance.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - root cause duoc tai hien bang contract va sua dung tang runtime config.
- Muc do hoan thanh task: hoan tat code/test; con thieu smoke device.
- Bang chung kiem chung: launcher ValidateOnly va targeted Flutter tests PASS.
- Diem ton token/chua toi uu: phai theo doi working tree co san nhieu thay doi lien quan.
- Cach toi uu cho phien sau: chay preflight va device smoke truoc broad check.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
