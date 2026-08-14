# NanoBio AI Chat Fix — Patch Manifest

Baseline: `daovanhung-dev/NanoBioAI`, branch `main`, inspected 2026-08-14.

## Files to apply

| Path | Action | Purpose |
|---|---|---|
| `android/app/build.gradle.kts` | Replace | Make Gemini native fallback work for all Android build types and robust dotenv syntax. |
| `test/core/config/android_private_runtime_config_contract_test.dart` | Add | Regression contract for runtime key injection. |
| `lib/app_versions/v1/services/ai/README_FIX.md` | Replace | Document root cause, runtime resolution and rebuild requirement. |
| `docs/worklog/2026-08-14/001-worklog-fix-ai-chat-android-runtime-config.md` | Add | Engineering evidence/worklog. |

`NanoBioAI_ai_chat_fix.patch` contains the same source changes as a unified patch.
No `.env`, API key, token, raw Gemini payload or user health data is included.
