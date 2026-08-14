# 001 — Fix AI Chat Android runtime Gemini configuration

## Workflow

- Work type: `bugfix`
- Primary domain: AI service / AI Chat
- Date: 2026-08-14

## Symptom

AI Chat accepts the user message but displays:

> Nabi chưa sẵn sàng trò chuyện lúc này. Bạn thử lại sau một chút nhé.

The retry action reproduces the same failure.

## Root cause

The current `AIConfigurationUnavailableException` user message matches the UI
symptom exactly. `AIChatService.prepareMessage()` throws that exception before
calling Gemini when it has neither a fake text generator nor a runtime
`GeminiRestClient`.

`AppEnv` resolves `GEMINI_API_KEY` from Dart define, dotenv, or Android native
runtime config. The Android native channel reads `BuildConfig.GEMINI_API_KEY`.
Before this fix, `android/app/build.gradle.kts` populated that BuildConfig field
only for the `debug` build type. The default value was empty, so plain
profile/release runs or builds without `--dart-define` reached AI Chat with no
runtime client. The Gradle fallback also used `Properties.load`, which did not
mirror the dotenv syntax supported elsewhere in the repository (`export`, BOM,
quoted values).

## Scope

Changed:

- `android/app/build.gradle.kts`
- `test/core/config/android_private_runtime_config_contract_test.dart`
- `lib/app_versions/v1/services/ai/README_FIX.md`

Unchanged intentionally:

- AI Chat repository/quota flow.
- Gemini REST transport and error taxonomy.
- AI Chat history/idempotency behavior.
- AI Voice controller. It already resolves the same `aiChatRepositoryProvider`,
  so repairing shared runtime configuration also repairs the AI backend used by
  voice without adding a second client.
- `.env` and all secret values.

## Implementation

1. Added a small dotenv parser in Android Gradle matching the accepted project
   format: comments, optional `export`, BOM, and surrounding quotes.
2. Resolve the native Gemini key in this order:
   - Gradle property;
   - process environment variable;
   - local untracked root `.env`.
3. Populate `BuildConfig.GEMINI_API_KEY` in `defaultConfig`, making the fallback
   available to debug/profile/release instead of debug only.
4. Kept Dart defines authoritative because `AppEnv` checks Dart define before
   native BuildConfig.
5. Added a contract test preventing the fallback from becoming debug-only again.
6. Updated runtime configuration documentation. No real key or raw Gemini
   request/response is logged or included in the patch.

## Validation evidence

- Static trace: UI message -> `AIConfigurationUnavailableException` ->
  `AIChatService._throwMissingConfiguration()`.
- Static trace: `AppEnv` native source -> MethodChannel ->
  `MainActivity` -> `BuildConfig.GEMINI_API_KEY`.
- Static trace: AI Voice controller -> `aiChatRepositoryProvider`, confirming
  shared backend reuse.
- Kotlin helper functions were compiled with `kotlinc` and executed against a
  synthetic dotenv containing UTF-8 BOM, `export`, comments, double quotes and
  single quotes: PASS.
- Secret scan of the handoff package: required before ZIP creation.

### Environment limitation

The execution environment does not expose Flutter or Dart executables, and the
repository could not be cloned by local `git` because local DNS could not
resolve `github.com`. Current source was read through the connected GitHub
repository instead. Therefore this session does **not** claim `flutter analyze`,
`flutter test`, device smoke, or APK build success.

Recommended checks in a full NanoBio checkout:

```powershell
dart format test/core/config/android_private_runtime_config_contract_test.dart
flutter analyze test/core/config/android_private_runtime_config_contract_test.dart test/core/config/app_env_test.dart test/app_versions/v1/services/ai/ai_chat_service_test.dart
flutter test test/core/config/android_private_runtime_config_contract_test.dart test/core/config/app_env_test.dart test/app_versions/v1/services/ai/ai_chat_service_test.dart
powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1 -ValidateOnly
powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1
```

After changing `.env`, stop and rebuild the Android app; hot reload does not
regenerate `BuildConfig`.

## Session self-review

- Output quality: targeted fix at the configuration boundary that actually
  produces the reported UI error; no quota or presentation bypass.
- Completion: patch, regression contract, documentation and handoff package are
  included.
- Verification strength: current GitHub source inspection plus executable Kotlin
  parser check; Flutter/device verification blocked by environment.
- Token/context efficiency: read AI Chat, AppEnv, Android bootstrap, existing
  tests and AI Voice call path only; no broad source dump.
- Next-session optimization: run the targeted Flutter tests and one Android
  device smoke using the user's real local `.env`, then record the bootstrap
  line `Gemini config present: true` without exposing the key.
