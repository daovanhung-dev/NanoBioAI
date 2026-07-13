Commit de xuat: fix(ai): nap Gemini runtime key cho main_v2

# Worklog - Fix Gemini API key runtime cho main_v2

## Thoi gian

- Ngay: 2026-07-13
- Bat dau: 11:53
- Ket thuc: 12:05
- Timezone: Asia/Saigon

## Pham vi

- Loai task: bugfix
- Module chinh: M05 AI / runtime configuration / onboarding
- Yeu cau goc: Fix loi ung dung khong nhan `GEMINI_API_KEY` khi chay `lib/main_v2.dart` du `.env` hop le va test/preflight pass.

## Da lam

- Xac nhan loi runtime den tu `AIService` constructor throw khi `AppEnv.maybeString('GEMINI_API_KEY')` null.
- Them VS Code launch config rieng cho `lib/main_v2.dart`, dung `NanoBio: prepare runtime defines` va `.dart_tool/nanobio_defines.json`.
- Doi `AIService` de thieu key khong crash provider; `checkConnection()` tra failure an toan va meal generation fallback local.
- Them bootstrap log chi bao `Gemini config present: true/false`, khong in gia tri key.
- Them regression tests cho missing-key fallback va launch config contract.
- Tao fixbug doc chi tiet cho loi `main_v2` runtime key.

## File code/docs da sua

- `lib/app_versions/v1/services/ai/ai_service.dart` - sua - missing key khong con crash constructor, checkConnection fail an toan.
- `lib/main.dart` - sua - log trang thai Gemini config an toan.
- `lib/main_v2.dart` - sua - log trang thai Gemini config an toan.
- `.vscode/launch.json` - sua - them launch config `lib/main_v2.dart`.
- `test/services/ai/ai_service_test.dart` - sua - regression missing-key check/fallback.
- `test/tools/run_v2_contract_test.dart` - sua - contract test VS Code launch config main_v2.
- `docs/fixbug/gemini-ai-connection/003-fixbug-gemini-main-v2-runtime-key.md` - tao - ghi nhan bugfix.
- `docs/worklog/2026-07-13/003-worklog-gemini-main-v2-runtime-key.md` - tao - ghi nhan phien.

## Tai lieu lien quan

- `.codex/workflows/bugfix.md`
- `.codex/task-skills/bugfix.md`
- `.codex/domains/ai-service.md`
- `docs/fixbug/gemini-ai-connection/001-fixbug-gemini-ai-connection.md`
- `docs/fixbug/gemini-ai-connection/002-fixbug-gemini-authentication-key.md`

## Commands

- `powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1 -ValidateOnly`: PASS - xac nhan `.env` co auth + Gemini config ma khong in secret.
- `dart format lib/app_versions/v1/services/ai/ai_service.dart lib/main.dart lib/main_v2.dart test/services/ai/ai_service_test.dart test/tools/run_v2_contract_test.dart`: PASS.
- `flutter analyze lib/app_versions/v1/services/ai/ai_service.dart lib/main.dart lib/main_v2.dart test/services/ai/ai_service_test.dart test/tools/run_v2_contract_test.dart`: PASS.
- `flutter test test/services/ai/ai_service_test.dart test/core/config/app_env_test.dart test/tools/run_v2_contract_test.dart`: PASS - 49 tests passed.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS - refresh `.codex/history` va task-skills.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: PASS.
- `git diff --check`: PASS - exit code 0; chi co line-ending warnings tu working tree hien huu.

## Loi/Rui ro

- Da fix: `AIService()` khong con throw khi thieu runtime key; app co the fallback local thay vi crash provider.
- Da fix: VS Code co launch config ro rang cho `lib/main_v2.dart` voi runtime defines.
- Chua fix/khong thuoc code: neu chay bang "Run current file" hoac lenh Flutter khong co Dart defines, device van khong co key, nhung app khong con crash.
- Can kiem tra tiep: smoke onboarding tren device bang `NanoBio - V2 App (Auth + AI)` hoac `tools/run_v2.ps1 -EntryPoint lib/main_v2.dart`.

## Ty le hoan thanh

- Hoan thanh: source fix, launch config, regression tests, fixbug doc.
- Dang do: live device/Gemini smoke chua chay trong phien nay.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - root cause duoc xu ly o ca launch path va runtime fallback.
- Muc do hoan thanh task: hoan tat code/test/docs theo plan; con thieu device smoke.
- Bang chung kiem chung: ValidateOnly PASS, analyzer PASS, targeted Flutter tests PASS.
- Diem ton token/chua toi uu: worktree dang co nhieu thay doi nen can gioi han doc/diff vao file trong plan.
- Cach toi uu cho phien sau: chay app bang launch config main_v2 moi truoc khi dieu tra cac bug AI tiep theo.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
