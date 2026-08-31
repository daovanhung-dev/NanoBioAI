Commit de xuat: fix(ai-voice): dong bo model va generation config voi backend

# Fixbug — Voice tuần tự lệch model và generation config

## Trạng thái

- Ngày thực thi: 2026-08-31
- Module: M07 `AI_CHAT` / Sequential AI Voice
- Baseline: `main@696172ac95b0dd3f0e5f4685d8b47f8f22277379`
- Trạng thái: Đã sửa code, deploy remote và smoke backend PASS; Android physical-device verification pending.

## Hiện tượng và nguyên nhân

Voice mặc định gửi `gemini-3.5-flash` cùng `thinkingConfig.thinkingLevel`.
Edge Function có thể đổi model không nằm trong allowlist về
`gemini-2.5-flash` nhưng trước đây forward nguyên generation config. Request
đến provider vì vậy có thể chứa option không tương thích với model cuối cùng,
khiến Voice nhận lỗi 502 sau bước Thinking.

## Hướng sửa

- Chọn `gemini-2.5-flash` làm default canonical cho Voice và `.env.example`.
- Voice không còn gửi `thinkingLevel` trong generation config.
- Edge resolve model và normalize config trong cùng một provider request.
- Với model Gemini 2.5, chỉ loại `thinkingLevel`; các field sinh chung và
  `thinkingBudget` tương thích được giữ lại.
- Không thay đổi transport `NabiAiBackendClient`, access gate, STT lifecycle,
  TTS, history bounds hoặc Android permissions.

## Files thay đổi

- `lib/app_versions/v1/features/ai_voice/data/datasources/voice_chat_turn_datasource.dart`
- `test/app_versions/v1/features/ai_voice/voice_chat_turn_datasource_test.dart`
- `supabase/functions/nabi-ai-generate/handler.ts`
- `supabase/functions/nabi-ai-generate/index.ts`
- `supabase/functions/nabi-ai-generate/handler_test.ts`
- `.env.example`
- `tools/validate_docs_source_truth.py`

## Kiểm chứng

- `deno test --no-lock supabase/functions/nabi-ai-generate/handler_test.ts`:
-  PASS, 10/10; toàn bộ Edge handler tests PASS, 40/40.
- `deno check --no-lock` trên 9 Edge entrypoints: PASS.
- `supabase functions deploy nabi-ai-generate --project-ref rnwohifdnylqfofkydfl
  --no-verify-jwt --use-api`: PASS; remote function ACTIVE version 5.
- Generic smoke với model canonical và `maxOutputTokens=256`: HTTP 200, response
  `OK`, trace `codex-explicit-25-256-20260831`.
- Voice-shaped smoke với model không nằm trong allowlist, `thinkingLevel` và
  `maxOutputTokens=256`: HTTP 200, trace `codex-voice-smoke-20260831`.
- `deno check --no-lock supabase/functions/nabi-ai-generate/index.ts`: PASS.
- `deno fmt --check ...`: PASS.
- `git diff --check`: PASS.
- `python3 -m py_compile tools/validate_docs_source_truth.py`: PASS.
- Flutter/Dart targeted tests, analyze, format và Android build: chưa chạy vì
  môi trường không có Flutter/Dart.
- Source-truth validator: chưa đạt do baseline thiếu
  `docs/audit/source_truth_manifest.json`; không phải lỗi do patch này.

## Chưa xác minh

- Đã xác nhận tên các secret cần thiết remote; CLI chỉ trả hash nên không đọc
  giá trị secret. Các secret không được ghi vào repo/log.
- Hai smoke thử nghiệm với `maxOutputTokens=16/32` trả HTTP 502; chạy lại theo
  cấu hình Voice `maxOutputTokens=256` đã PASS HTTP 200.
- Chưa có physical Android device trong ADB và chưa có tài khoản Plus/FamilyPlus
  thật để chạy E2E. Do đó chưa thể xác nhận STT → backend → TTS, 10 lượt liên
  tục, Stop/background, network recovery hoặc paid gate trên thiết bị.
