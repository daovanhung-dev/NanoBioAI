Commit de xuat: fix(ai-voice): ghi nhan dong bo model va generation config

# Worklog - AI Voice backend model/config regression

## Thoi gian

- Ngay: 2026-08-31
- Bat dau: 05:20
- Ket thuc: 05:35
- Timezone: Asia/Ho_Chi_Minh (UTC+07:00)

## Pham vi

- Loai task: bugfix
- Module chinh: M07 `AI_CHAT` / Sequential AI Voice
- Yeu cau goc: Đọc `docs/tasks/NanoBioAI_AI_Voice_Fix_Plan_GPT_LUNA_2026-08-30.md` và coding theo plan.

## Da lam

- Xác nhận baseline `main@696172ac95b0dd3f0e5f4685d8b47f8f22277379` và giữ nguyên file plan untracked có sẵn.
- Xác nhận static root cause: Voice gửi `gemini-3.5-flash`/`thinkingLevel`, Edge fallback model nhưng không normalize config.
- Thêm resolver dùng model cuối cùng và generation config tương thích trong `nabi-ai-generate`.
- Đổi default Voice và `.env.example` sang `gemini-2.5-flash`; bỏ `thinkingLevel` khỏi Voice request.
- Thêm regression tests cho fallback + config, model hỗ trợ thinking và `thinkingBudget`.
- Cập nhật source-truth validator theo canonical Voice model.
- Chạy toàn bộ Edge handler tests và type-check 9 Edge entrypoints.
- Deploy `nabi-ai-generate` lên đúng Supabase project, sau đó chạy generic và
  Voice-shaped smoke bằng dữ liệu giả an toàn.
- Không bypass paid access, không sửa STT/controller/TTS/manifest, không đưa provider key về client.

## File code/docs da sua

- `.env.example` - cập nhật model ví dụ về `gemini-2.5-flash`.
- `lib/app_versions/v1/features/ai_voice/data/datasources/voice_chat_turn_datasource.dart` - đồng bộ default model và generation config.
- `test/app_versions/v1/features/ai_voice/voice_chat_turn_datasource_test.dart` - cập nhật contract request/default model.
- `supabase/functions/nabi-ai-generate/handler.ts` - thêm resolve model/config tương thích.
- `supabase/functions/nabi-ai-generate/index.ts` - dùng provider request đã normalize.
- `supabase/functions/nabi-ai-generate/handler_test.ts` - thêm 3 regression tests cross-contract.
- `tools/validate_docs_source_truth.py` - cập nhật assertion model Voice.
- `docs/fixbug/ai-voice-sequential/002-fixbug-ai-voice-backend-model-config-regression.md` - ghi nhận fix và giới hạn kiểm chứng.
- `docs/test/edge-functions/001-test-edge-functions-2026-08-31.md` - ghi nhận Edge tests, deploy và remote smoke.

## Tai lieu lien quan

- `docs/tasks/NanoBioAI_AI_Voice_Fix_Plan_GPT_LUNA_2026-08-30.md`
- `docs/fixbug/ai-voice-sequential/001-fixbug-ai-voice-sequential-device-runtime.md`
- `.codex/domains/ai-service.md`
- `.codex/domains/access-membership-referral.md`

## Commands

- `find supabase/functions -name handler_test.ts | xargs deno test --no-lock`: PASS - 40/40 tests.
- `find supabase/functions -name index.ts | xargs deno check --no-lock`: PASS - 9/9 entrypoints.
- `supabase functions list --project-ref rnwohifdnylqfofkydfl`: PASS - 9/9 ACTIVE; `nabi-ai-generate` version 5.
- `supabase secrets list --project-ref rnwohifdnylqfofkydfl`: PASS - tên secret cần thiết tồn tại; chỉ nhận hash, không đọc giá trị.
- `supabase functions deploy nabi-ai-generate --project-ref rnwohifdnylqfofkydfl --no-verify-jwt --use-api`: PASS.
- Remote generic smoke (`codex-explicit-25-256-20260831`): PASS - HTTP 200, response ngắn an toàn.
- Remote Voice-shaped smoke (`codex-voice-smoke-20260831`): PASS - HTTP 200 với fallback model/config normalization.
- `deno fmt --check supabase/functions/nabi-ai-generate/...`: PASS.
- `python3 -m py_compile tools/validate_docs_source_truth.py`: PASS.
- `git diff --check`: PASS.
- `python3 tools/validate_docs_source_truth.py`: FAIL - baseline thiếu `docs/audit/source_truth_manifest.json`.
- `flutter test ...`: SKIPPED - Flutter chưa cài.
- `flutter analyze ...`: SKIPPED - Flutter chưa cài.
- `dart format ...`: SKIPPED - Dart chưa cài.
- `flutter build apk --debug`: SKIPPED - Flutter chưa cài.
- Hai smoke thử nghiệm với `maxOutputTokens=16/32`: FAIL HTTP 502 do giới hạn output quá thấp; không phải cấu hình Voice theo plan.
- `adb devices -l`: PASS - ADB có nhưng không có device.

## Loi/Rui ro

- Da fix: Edge không còn forward `thinkingLevel` vào model Gemini 2.5 sau fallback; Voice default đã khớp canonical backend.
- Chua fix: Flutter targeted suite, Android debug build và physical E2E bằng tài khoản Plus/FamilyPlus thật.
- Can kiem tra tiep: Flutter/Dart validation, Android physical acceptance và theo dõi trace remote nếu device gặp lỗi.

## Ty le hoan thanh

- Hoan thanh: code patch, regression test Edge, type-check/format/static review, remote deploy và backend smoke.
- Dang do: Flutter/Dart validation và toàn bộ physical-device acceptance; không được claim DONE.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - patch nhỏ, đúng layer, giữ nguyên access/STT architecture và có regression cho model/config contract.
- Muc do hoan thanh task: PARTIAL; phần code/static đã hoàn tất, các gate cần toolchain, remote và thiết bị thật còn pending.
- Bang chung kiem chung: Edge 40/40, 9 entrypoints type-check PASS, deploy PASS, 2 smoke HTTP 200, format/Python/diff checks PASS.
- Diem ton token/chua toi uu: plan dài và source context được đọc theo các phần bắt buộc; không đọc raw worklog không liên quan.
- Cach toi uu cho phien sau: chuẩn bị sẵn Flutter/Dart, physical Android và paid test account để chạy các gate cuối ngay sau backend smoke.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
