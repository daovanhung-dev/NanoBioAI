# M31 — SLEEP_SAFETY_MONITORING

> **Source BD:** `docs/BD/sleep_safety/BD_NanoBio_Sleep_Safety_M31_v1.3.md`
> **BD ID:** `BD-NANOBIO-SLEEP-SAFETY-001`
> **Current decision:** Explicit help requests use an on-device phone call.
> Automatic escalation after 15 seconds without a response uses voice/SMS.
> **Verification:** Source tests, QA migration, and physical-device call evidence
> are tracked separately. Production remains unchanged.
> **Route:** `/sleep-tracking`
> **Access:** authenticated Plus / FamilyPlus + server rollout enabled

## Purpose

Implementation contract for NanoBio M31 Sleep Safety Monitoring. M31 keeps the
user-started on-device microphone safety detector, a persistent Android safety
alarm, and post-session analysis that works offline. AI analysis is optional and
user-triggered; local analysis never depends on a network response.

The `Tôi cần hỗ trợ` action calls the highest-priority active contact that
allows phone calling. This explicit help action does not invoke server dispatch.
The +15-second no-response route uses the authenticated voice/SMS dispatch flow.
After the operating system accepts a manual call or dialer handoff, the alert
sound and notification are silenced while the monitoring session remains active.
If handoff fails, the alert remains audible and actionable. The app records OS
call initiation or dialer handoff, never a connected call.

## Read order

1. `Overall.md`
2. `List_Features.md`
3. `Function_List.md`
4. `Views.md`
5. `Import_File.md`
6. `diagrams/README.md`
7. `docs/BD/sleep_safety/BD_NanoBio_Sleep_Safety_M31_v1.3.md`

## Source boundaries

- Flutter feature root: `lib/app_versions/v1/features/sleep_tracking/`
- Night analysis domain: `domain/services/sleep_night_analysis_service.dart`
- Night analysis UI: `presentation/pages/sleep_night_analysis_page.dart`
- AI adapter: `data/services/sleep_analysis_ai_service.dart`
- Local database: `lib/core/storage/localdb/` — SQLite v28
- Android native: `android/app/src/main/kotlin/com/example/nano_app/sleep_safety/`
- iOS native bridge/runtime: `ios/Runner/AppDelegate.swift`
- Supabase canonical rebuild source: `docs/supabase/01_build_system.sql`
- Forward migration history: `supabase/migrations/20261006090000`,
  `20261006100000`, `20261006110000`, and `20261006120000`.
- Edge Functions: `supabase/functions/sleep-safety-*`
- M09 notification bootstrap is reused only for scheduled arming navigation;
  sleep-safety alert actions do not mutate M09 task state.
- Gemini calls reuse `lib/app_versions/v1/services/ai/gemini_rest_client.dart`.

## Direct help-call behavior

- `phone_fallback_enabled` defaults to false and gates automatic calling after
  no-response. It does not block an explicit `Tôi cần hỗ trợ` action.
- Android requests `CALL_PHONE` before monitoring if an eligible contact and the
  automatic-call flag are present. With permission, help uses `ACTION_CALL`;
  denial or call-launch failure opens the system dialer with the number prefilled.
- Android silences its looping tone and clears the alert notification only after
  the OS accepts a call/dialer handoff; failed handoff keeps the alert active.
- iOS opens `tel:` and may require operating-system confirmation.
- No eligible contact leaves the local alert active and shows the user how to
  continue. A disabled automatic-call flag does not block a manual call.
- The OS result only confirms that a call action or dialer handoff was started;
  the app cannot confirm that the other person answered.

## Automatic no-response boundary

- The native response timer emits automatic escalation at 15 seconds only if
  the user has not answered; there is no intermediate reminder.
- The Edge Function accepts `noResponse` events only and routes voice/SMS by
  contact priority. Unverified contacts need separate default-off voice consent;
  SMS requires verification.
- Offline retries store event/idempotency metadata only and stop at the
  server-configured freshness limit.
- QA migrations and temporary phone-call settings are scoped to the confirmed
  QA project. Production remains unchanged.

## Analysis and safety boundary

- Formula version: `m31_sleep_wellness_v1_2026_08`.
- More than 30 deterministic acoustic/wellness metrics are calculated locally.
- Seven-night trend uses the user's own local baseline; it is not a clinical
  reference range.
- Morning check-in values are self-reported and are never inferred from silence.
- Gemini receives sanitized JSON only. No raw audio, transcript, contact phone,
  user id, session id, token, or API key is included in the AI payload.
- No raw audio persistence/upload, medical diagnosis, automatic 115 call, local
  paid-access inference, silent schedule-triggered microphone start, or
  fabricated REM/N1/N2/N3/deep-sleep data.
