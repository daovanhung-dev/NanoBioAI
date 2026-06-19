Commit de xuat: fix(ai-chat): fallback khi dotenv chua khoi tao

# AI Chat fallback khi dotenv chua khoi tao

## Trieu chung
- `AIChatService(apiKeyOverride: '')` nem `NotInitializedError` neu dotenv chua duoc load.
- Test `missing API key does not crash and returns local fallback` fail truoc khi sua.

## Nguyen nhan goc
- Constructor dung `_cleanEnv(apiKeyOverride) ?? dotenv.env['GEMINI_API_KEY']`.
- Chuoi override rong bi clean thanh `null`, nen service van doc `dotenv.env`.
- Cac env chat model/fallback cung doc truc tiep tu dotenv khi khong co `textGenerator`.

## Cach sua
- Phan biet `apiKeyOverride != null` voi khong truyen override.
- Neu override la chuoi rong, coi do la missing key hop le va khong doc dotenv.
- Them helper doc dotenv an toan, tra `null` khi dotenv chua khoi tao.
- Dung helper an toan cho `GEMINI_API_KEY`, `GEMINI_CHAT_MODEL`, `GEMINI_MODEL`, va `GEMINI_CHAT_FALLBACK_MODELS`.
- Them regression test cho truong hop khong truyen `modelNames`.

## Files
- `lib/services/ai/ai_chat_service.dart` - sua logic resolve API key/env chat model an toan.
- `test/services/ai/ai_service_test.dart` - them regression test constructor khong co dotenv/model override.
- `docs/todo/ai-chat-dotenv-uninitialized/001-todo-ai-chat-dotenv-uninitialized.md` - danh dau todo da xong.

## Kiem chung
- Command: `flutter test test/services/ai/ai_service_test.dart --plain-name "missing API key does not crash and returns local fallback"`
- Ket qua: PASS
- Command: `flutter test test/services/ai/ai_service_test.dart`
- Ket qua: PASS

## Lien ket
- Worklog: ../../worklog/2026-06-19/011-worklog-fix-ai-chat-dotenv-uninitialized.md
- Todo: ../../todo/ai-chat-dotenv-uninitialized/001-todo-ai-chat-dotenv-uninitialized.md
- Issue: ../../issues/ai-chat-dotenv-uninitialized/001-issue-ai-chat-dotenv-uninitialized.md

## Regression can de y
- `apiKeyOverride: null` van doc env neu dotenv san sang.
- `apiKeyOverride: ''` ep local fallback va khong crash.
- Khong log API key hoac raw env value.
