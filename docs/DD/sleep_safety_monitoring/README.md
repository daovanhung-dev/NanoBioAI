# M31 — SLEEP_SAFETY_MONITORING

> **Source BD:** `docs/BD/sleep_safety/BD_NanoBio_Sleep_Safety_M31_v1.0.md`  
> **BD ID:** `BD-NANOBIO-SLEEP-SAFETY-001`  
> **DD decision:** Approved — Product Owner decisions Q-M31-01..10 are closed  
> **Implementation:** Implemented/source-ready; active paid FeatureHub entry  
> **Verification:** Static checks only in agent environment; Runtime-unverified; Sandbox-unverified  
> **Route:** `/sleep-tracking`  
> **Access:** authenticated Plus / FamilyPlus + server rollout enabled

## Purpose

Implementation contract for NanoBio M31 Sleep Safety Monitoring. This DD replaces
the old `SleepTrackingPage` coming-soon-only behavior with an active paid
runtime while preserving the existing route and server-side kill switch.

## Read order

1. `Overall.md`
2. `List_Features.md`
3. `Function_List.md`
4. `Views.md`
5. `Import_File.md`
6. `diagrams/README.md`

## Source boundaries

- Flutter feature root: `lib/app_versions/v1/features/sleep_tracking/`
- Local DB: `lib/core/storage/localdb/` — SQLite v21
- Android native: `android/app/src/main/kotlin/com/example/nano_app/sleep_safety/`
- iOS native bridge/runtime: `ios/Runner/AppDelegate.swift`
- Supabase authored components: `docs/supabase/07_schema_sleep_safety.sql` + `docs/supabase/08_enable_sleep_safety_rollout.sql`
- Edge Functions: `supabase/functions/sleep-safety-*`
- M09 notification bootstrap is reused only for scheduled arming navigation;
  sleep-safety alert actions are native and do not mutate M09 task state.

## Non-negotiable safety boundary

No raw audio persistence/upload, no medical diagnosis, no automatic 115 call,
no local paid-access inference, no silent schedule-triggered microphone start,
and keep the server kill switch available and never infer paid access locally. The current
source rollout decision is enabled by SQL 08, while device/provider/Supabase runtime
verification remains a separate evidence axis.
