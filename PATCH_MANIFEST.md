# NanoBio AI Chat Fix — Patch Manifest

## Runtime source

- `lib/app_versions/v1/services/ai/ai_exceptions.dart`
- `lib/app_versions/v1/services/ai/gemini_rest_client.dart`
- `lib/app_versions/v1/services/ai/ai_chat_service.dart`
- `lib/app_versions/v1/features/ai_chat/domain/repositories/ai_chat_repository_impl.dart`
- `lib/app_versions/v1/features/ai_chat/presentation/controllers/ai_chat_controller.dart`

## Secure launch/build tooling

- `tools/prepare_dart_defines.ps1`
- `tools/run_ai_chat.ps1`
- `tools/build_ai_chat_apk.ps1`
- `tools/test_gemini_connection.ps1`
- `.env.example`

## Tests and documentation

- `test/app_versions/v1/services/ai/gemini_rest_client_test.dart`
- `test/app_versions/v1/services/ai/ai_chat_service_test.dart`
- `docs/AI_CHAT_API_FIX.md`

`.env` thật không nằm trong gói bàn giao.
