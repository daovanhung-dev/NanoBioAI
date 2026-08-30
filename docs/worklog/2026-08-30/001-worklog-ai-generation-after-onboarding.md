# Worklog: fix AI generation after onboarding

## Scope

- Điều tra lỗi tạo lịch đầu tiên sau onboarding và chuẩn bị xác minh member
  Plus.
- Giữ nguyên mọi thay đổi AI/backend chưa commit trước phiên làm việc.
- Không ghi credential, token, prompt, health data hoặc response riêng tư vào
  worklog.

## Evidence collected

1. Toolchain local:
   - Flutter 3.47.1 / Dart 3.13.1.
   - Supabase CLI 2.116.0.
   - Deno 2.9.6.
   - PowerShell Core 7.6.5.
   - ADB device `220333QPG`, serial `12b304f9`.
2. Supabase CLI:
   - linked project `rnwohifdnylqfofkydfl`, ACTIVE_HEALTHY;
   - `nabi-ai-generate` deployed with `verify_jwt=false`;
   - source downloaded to `/tmp` before and after deploy without overwriting
     worktree;
   - remote secret values were never read or printed.
3. Initial device reproduction before the fix:
   - local `meal_catalog`: 163 active rows, all `unclassified` and not plan
     eligible;
   - `personal_schedule_ai_requests`: `initial_guest`, `failed`,
     `invalid_generation`;
   - no meal plan or schedule rows;
   - failure matched `_ensureMealSlotsAvailable()`.
4. Supabase catalog read-only check:
   - 163 source-imported rows were intentionally not plan eligible;
   - the refresh implementation was deleting the separately seeded reviewed
     catalog.
5. Hosted provider checks:
   - one safe trace returned HTTP 502 with `provider_empty_response`;
   - after model configuration and deploy, safe smoke returned HTTP 200 and
     preserved the trace response header.

## Changes

- Changed Supabase meal catalog refresh from replacement to merge/upsert so
  reviewed built-in meal slots survive source catalog synchronization.
- Kept `MealCandidateSelector` safety filters unchanged.
- Aligned plan model candidates and remote model allowlist to the verified
  `gemini-2.5-flash` model.
- Added safe provider response metadata: candidate count, content/text/thought
  part counts, finish reason, block reason, provider status, duration and
  model fallback flag.
- Kept Edge Function JWT verification disabled for guest onboarding.
- Added/updated Edge Function, catalog DAO, model candidate and generated-plan
  auth tests.

## Device result after the fix

- Cleared the debug app data and repeated onboarding from a clean profile.
- Request ledger reached `succeeded` with `generation_source=ai`.
- SQLite contained 35 meals, 14 exercises and 77 schedule items.
- Dashboard displayed the generated schedule.
- The debug device account was guest/free; Plus membership could not be
  verified because reinstall/clear removed the prior session. No client-side
  Plus override was used.

## Validation

- Deno handler tests: 7 passed.
- Catalog merge tests: 8 passed.
- `generated_plan_service_auth_test.dart`: 13 passed.
- Targeted backend/model contract tests: passed.
- Targeted Flutter analyze: no issues.
- `flutter build apk --debug`: passed.
- Full `ai_service_test.dart` still has pre-existing logger-capture and stale
  message assertions; this was recorded in the fixbug report and not hidden.

## Follow-up / blockers

- Revoke/rotate the Gemini credential exposed in the original context. A new
  key must be entered through a hidden terminal/secret-manager flow; it must
  not be sent in chat or committed.
- Log in with a real Plus account on the device, verify backend
  `effective_user_access`, then test the 7-day member schedule and quota
  check/commit flow.
- Normalize AI test log capture around the current `dart:developer` sink.
