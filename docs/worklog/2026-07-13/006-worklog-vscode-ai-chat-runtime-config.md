Commit de xuat: fix(ai): load Gemini config for VS Code AI chat

# Worklog - Fix VS Code AI Chat runtime config

## Thoi gian

- Ngay: 2026-07-13
- Ket thuc: 12:58
- Timezone: Asia/Saigon

## Pham vi

- Loai task: bugfix
- Module chinh: M05 AI / AI Chat / runtime configuration
- Yeu cau goc: Hoan thien fix AI Chat khong nhan Gemini config khi chay tu VS
  Code, bao loi ro rang va khong tru quota khi thieu cau hinh.

## Da lam

- Xac nhan key va model live hoat dong; root cause nam o VS Code Run/CodeLens
  khong match launch profile co Dart defines.
- Them `templateFor` cho ba entrypoint app, V2 va admin.
- Them typed missing-config failure tu service den repository/controller.
- Chan retry, local fallback va quota commit cho rieng loi thieu runtime client.
- Them banner loi co nut dong phia tren composer; sua dispose notifier de widget
  teardown an toan.
- Sua Gemini preflight de cap 512 output tokens va ghep moi text part.
- Them/cap nhat focused tests cho service, quota, widget, launcher va preflight.
- Rebuild va smoke AI Chat that tren device.

## File code/docs chinh da sua

- `.vscode/launch.json` - them `templateFor` va bao ve runtime defines cho ba
  entrypoint.
- `lib/app_versions/v1/services/ai/ai_exceptions.dart` - them typed config error.
- `lib/app_versions/v1/services/ai/ai_chat_service.dart` - fail fast khi thieu
  runtime client.
- `lib/app_versions/v1/features/ai_chat/domain/repositories/ai_chat_repository_impl.dart`
  - map domain error truoc quota commit.
- `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart`
  - banner loi va lifecycle fix.
- `tools/test_gemini_connection.ps1` - 512 tokens va multi-part parser.
- `test/services/ai/ai_service_test.dart` - missing-config typed failure.
- `test/app_versions/v1/features/ai_chat/ai_chat_quota_test.dart` - no-commit
  contract.
- `test/app_versions/v1/features/ai_chat/ai_chat_screen_error_test.dart` - banner,
  dismiss va composer state.
- `test/tools/run_v2_contract_test.dart` va
  `test/tools/gemini_connection_contract_test.dart` - launcher/preflight contract.
- `docs/fixbug/gemini-ai-connection/005-fixbug-vscode-ai-chat-runtime-config.md`
  - tai lieu bugfix.

## Commands va bang chung

- `dart format <cac Dart file da sua>`: PASS.
- `flutter test test/services/ai/gemini_rest_client_test.dart test/services/ai/ai_service_test.dart test/app_versions/v1/features/ai_chat/ai_chat_quota_test.dart test/app_versions/v1/features/ai_chat/ai_chat_screen_error_test.dart test/core/config/app_env_test.dart test/tools/run_v2_contract_test.dart test/tools/prepare_dart_defines_contract_test.dart test/tools/gemini_connection_contract_test.dart`: PASS - 63 tests.
- `flutter analyze lib/app_versions/v1/services/ai lib/app_versions/v1/features/ai_chat test/services/ai test/app_versions/v1/features/ai_chat test/core/config/app_env_test.dart test/tools/run_v2_contract_test.dart test/tools/prepare_dart_defines_contract_test.dart test/tools/gemini_connection_contract_test.dart`: PASS - no issues.
- `powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1 -ValidateOnly`: PASS.
- `powershell -ExecutionPolicy Bypass -File tools/prepare_dart_defines.ps1`: PASS.
- `powershell -ExecutionPolicy Bypass -File tools/test_gemini_connection.ps1`: PASS
  voi model chinh.
- Rebuild `lib/main_v2.dart` bang file defines tam tren device `12b304f9`: PASS;
  bootstrap ghi `Gemini config present: true`.
- UI device smoke: model chinh timeout mot lan; fallback model cho response
  `source: AI_GEN`, log co `RETRY_ATTEMPT_SUCCESS` va `SUCCESS`, khong co
  `MISSING_API_KEY`.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`:
  PASS - refresh history/task-skills tu 80 worklogs.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`:
  PASS.
- `git diff --check`: PASS - exit code 0; chi co line-ending warnings cua working
  tree hien huu.

## Loi/Rui ro

- Da fix: VS Code profile/CodeLens load runtime defines cho ca ba entrypoint.
- Da fix: missing config co typed failure, banner ro rang va khong commit quota.
- Con lai: Gemini credential van nam o client cho local/debug; backend proxy nam
  ngoai pham vi task.
- Hanh vi mong doi: timeout model chinh van retry/fallback sang model thu hai.

## Ty le hoan thanh

- Hoan thanh: code, tests, analyzer, launcher validation, live preflight, rebuild
  va UI device smoke.
- Khong thay doi: schema, Supabase RPC, quota contract va noi dung `.env`.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - fix dung root cause va phan tach loi cau hinh khoi loi
  mang/model.
- Muc do hoan thanh task: hoan tat tat ca hang muc trong ke hoach.
- Bang chung kiem chung: 63 tests, analyzer, scripts, live preflight va device
  smoke deu PASS.
- Diem ton token/chua toi uu: device UI khong cung cap semantics dump on dinh nen
  phai dinh vi bang screenshot tap trung.
- Cach toi uu cho phien sau: kiem tra bootstrap `Gemini config present` truoc,
  sau do tach logcat ngay truoc request de rut ngan smoke test.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
