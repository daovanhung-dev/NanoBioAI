# M31 — SLEEP_SAFETY_MONITORING

> **Source BD:** `docs/BD/sleep_safety/BD_NanoBio_Sleep_Safety_M31_v1.1.md`  
> **BD ID:** `BD-NANOBIO-SLEEP-SAFETY-001`  
> **DD decision:** Approved — v1.1 extends the approved M31 runtime without changing paid access or escalation trust boundaries  
> **Implementation:** Source-ready for Android persistent alert + local nightly analysis + user-triggered Gemini analysis  
> **Verification:** Static checks only in agent environment; Runtime-unverified; Sandbox-unverified  
> **Route:** `/sleep-tracking`  
> **Access:** authenticated Plus / FamilyPlus + server rollout enabled

## Purpose

Implementation contract for NanoBio M31 Sleep Safety Monitoring. M31 keeps the
user-started on-device microphone safety detector and adds a separate persistent
Android safety alarm plus post-session analysis that remains useful offline.
AI analysis is optional and user-triggered; local analysis never depends on a
network response.

## Read order

1. `Overall.md`
2. `List_Features.md`
3. `Function_List.md`
4. `Views.md`
5. `Import_File.md`
6. `diagrams/README.md`
7. `docs/BD/sleep_safety/BD_NanoBio_Sleep_Safety_M31_v1.1.md`

## Source boundaries

- Flutter feature root: `lib/app_versions/v1/features/sleep_tracking/`
- Night analysis domain: `domain/services/sleep_night_analysis_service.dart`
- Night analysis UI: `presentation/pages/sleep_night_analysis_page.dart`
- AI adapter: `data/services/sleep_analysis_ai_service.dart`
- Local DB: `lib/core/storage/localdb/` — SQLite v23
- Android native: `android/app/src/main/kotlin/com/example/nano_app/sleep_safety/`
- iOS native bridge/runtime: `ios/Runner/AppDelegate.swift`
- Supabase authored component: `docs/supabase/01_build_system.sql` for the
  existing M31 access/dispatch runtime. v1.1 night analysis remains local-only.
- Edge Functions: `supabase/functions/sleep-safety-*`
- M09 notification bootstrap is reused only for scheduled arming navigation;
  sleep-safety alert actions are native and do not mutate M09 task state.
- Gemini calls reuse `lib/app_versions/v1/services/ai/gemini_rest_client.dart`.

## v1.1 analysis boundary

- Formula version: `m31_sleep_wellness_v1_2026_08`.
- More than 30 deterministic acoustic/wellness metrics are calculated locally.
- Seven-night trend uses the user's own local baseline; it is not a clinical
  reference range.
- Morning check-in values are explicitly self-reported and are never inferred
  from microphone silence.
- `Nabi Sleep Wellness Score` and `Safety Attention Score` are product wellness
  indicators, not medical scores.
- Gemini receives sanitized JSON only. No raw audio, transcript, contact phone,
  user id, session id, token or API key is included in the AI payload.

## Non-negotiable safety boundary

No raw audio persistence/upload, no medical diagnosis, no automatic 115 call,
no local paid-access inference, no silent schedule-triggered microphone start,
and no fabricated REM/N1/N2/N3/deep-sleep data. Keep the server kill switch
available. Device/provider/Supabase runtime verification remains a separate
evidence axis from source implementation.
