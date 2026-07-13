Commit de xuat: fix(ai): chan retry StateError khi AI chat thieu runtime key

# Worklog - Fix AI Chat missing runtime client

## Thoi gian

- Ngay: 2026-07-13
- Bat dau: 12:02
- Ket thuc: 12:08
- Timezone: Asia/Saigon

## Pham vi

- Loai task: bugfix
- Module chinh: M05 AI / AI Chat / runtime configuration
- Yeu cau goc: Tiep tuc fix log AI Chat bi `StateError` va fallback local khi gui tin nhan.

## Da lam

- Xac nhan log `StateError` den tu flow AI Chat thieu `_geminiClient` tai runtime.
- Them guard som trong `sendMessage()` va `sendMessageStream()` de missing runtime key tra fallback ngay.
- Doi log sang warning `MISSING_API_KEY` voi `reason: missing_api_key`, khong retry model sai ngu canh.
- Them regression tests cho sendMessage va sendMessageStream missing-key path.

## File code/docs da sua

- `lib/app_versions/v1/services/ai/ai_chat_service.dart` - sua - chan retry khi khong co runtime text source.
- `test/services/ai/ai_service_test.dart` - sua - regression missing-key AI Chat khong log `StateError`.
- `docs/fixbug/gemini-ai-connection/004-fixbug-ai-chat-missing-runtime-client.md` - tao - ghi nhan bugfix.
- `docs/worklog/2026-07-13/004-worklog-ai-chat-missing-runtime-client.md` - tao - ghi nhan phien.

## Tai lieu lien quan

- `.codex/workflows/bugfix.md`
- `.codex/task-skills/bugfix.md`
- `.codex/domains/ai-service.md`
- `docs/fixbug/gemini-ai-connection/003-fixbug-gemini-main-v2-runtime-key.md`

## Commands

- `dart format lib/app_versions/v1/services/ai/ai_chat_service.dart test/services/ai/ai_service_test.dart`: PASS.
- `flutter analyze lib/app_versions/v1/services/ai/ai_chat_service.dart test/services/ai/ai_service_test.dart`: PASS.
- `flutter test test/services/ai/ai_service_test.dart`: PASS - 42 tests passed.
- `powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1 -ValidateOnly`: PASS - xac nhan runtime env co auth + Gemini config ma khong in secret.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS - refresh `.codex/history` va task-skills.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: PASS.
- `git diff --check`: PASS - exit code 0; chi co line-ending warnings tu working tree hien huu.

## Loi/Rui ro

- Da fix: AI Chat thieu runtime key khong con retry ca danh sach model va khong con log `StateError`.
- Chua fix/khong thuoc code: neu app duoc chay khong co Dart defines, AI Chat van fallback local vi khong co key.
- Can kiem tra tiep: smoke AI Chat tren device bang launch config `NanoBio - V2 App (Auth + AI)` hoac script runtime co defines.

## Ty le hoan thanh

- Hoan thanh: source fix, regression tests, docs bugfix/worklog.
- Dang do: live Gemini chat smoke tren device chua chay trong phien nay.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - loi log runtime duoc map dung thanh missing-key path.
- Muc do hoan thanh task: hoan tat code/test/docs trong pham vi bug.
- Bang chung kiem chung: analyzer PASS va AI service targeted tests PASS.
- Diem ton token/chua toi uu: can tiep tuc tranh doc rong vi working tree co nhieu thay doi san.
- Cach toi uu cho phien sau: neu con fallback, kiem tra bootstrap log `Gemini config present` truoc khi debug chat logic.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
