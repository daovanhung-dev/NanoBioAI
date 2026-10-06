# M31 DD Changelog

## 1.8 — 2026-10-06

- Removed the server `phone_fallback_enabled` gate from local automatic
  no-response calling. The native timer receives an eligible saved contact
  whenever one has phone-call consent.
- Removed system-paused messaging; no-response still never invokes backend
  dispatch or creates a backend retry. No API or schema changed.

## 1.7 — 2026-10-06

- Replaced the +15-second no-response voice/SMS backend dispatch with a
  flag-gated local phone handoff to the highest-priority opted-in contact.
- Android uses `ACTION_CALL` with permission and otherwise opens the dialer;
  iOS hands off `tel:`. Failed/unavailable handoff keeps the alert actionable.
- Live timeout and restored native snapshots share event-ID dedupe; legacy
  no-response retry rows are retired instead of dispatched.
- No API, `escalation_status` enum, database schema, or production setting
  changed. Device and Flutter verification are tracked separately.

## 1.6 — 2026-10-06

- Shortened the no-response window to 15 seconds on Android and iOS and removed
  the former +30-second reminder; automatic escalation still uses voice/SMS.
- Added OS-accepted call handoff cleanup: silence the alert and clear its
  notification after success, while preserving both if call/dialer launch fails.
- Added Flutter state/countdown and native-platform regression coverage. No
  schema, RPC, Edge Function or production configuration changed.

## 1.5 — 2026-10-06

- Explicit `Tôi cần hỗ trợ` now starts an on-device call to the highest-priority
  active contact with phone opt-in; Android requests `CALL_PHONE` before
  monitoring and falls back to a prefilled dialer after denial/launch failure.
- Manual help never invokes server dispatch. The +60-second no-response flow
  remains voice/SMS; current Edge dispatch and callback contain no Zalo route.
- Added the forward Supabase migration and SQLite v28 migration to remove old
  Zalo settings while retaining contact data. Historical migrations remain
  unchanged.
- Focused Flutter tests 36/36, analyzer, Android debug build, Deno 7/7 and QA
  schema/Edge deployment pass. On Xiaomi 220333QPG, the user confirmed the QA
  call rang and was answered; the temporary contact was removed and QA flag
  restored to `false`. iOS physical-device acceptance remains pending.

## 1.4 — 2026-10-06

- Added explicit per-contact consent for voice calls while a phone number is
  unverified; default is off.
- Preserved legacy 5- and 7-argument contact RPCs and added an 8-argument
  overload plus a forward migration.
- Limited unverified contacts to voice-only alerts in immediate and provider
  callback cascades; verified contacts keep existing SMS/Zalo paths.
- Allowed explicit user-triggered dialer fallback for an active contact with
  phone fallback enabled, regardless of verification status.
- Added SQLite v27 and controller/widget/model/migration and Edge coverage. No
  live migration or phone call was performed.

## 1.3 — 2026-10-06

- Added per-contact Zalo and phone fallback preferences, both behind runtime
  kill switches defaulting off.
- Added Edge-only ZBS phone-template adapter. Zalo failure leaves the existing
  voice/SMS cascade available; `submitted` is not a delivery receipt.
- Added explicit Android `ACTION_DIAL` and iOS user-selected `tel:` fallback;
  dialer launch does not dismiss the persistent local alarm.
- Added a minimal SQLite v26 dispatch outbox with the same idempotency key,
  bounded retries and server freshness expiry.
- Added an additive Supabase migration for staging/production. Canonical
  build/seed scripts remain for disposable local/sandbox rebuilds only.
- Deno Edge tests pass 6/6. Flutter/Dart, native builds/devices, iOS and live
  Supabase acceptance remain unverified in the current environment.

## 1.2 — 2026-08-24

- Replaced the original high-threshold frame detector with Detector v2:
  robust baseline, rolling attack/energy features, calibration extreme-event
  bypass and a single native decision layer.
- Added RAM-only `audioMetrics` / `detectorCandidate` native events and a live
  Flutter sound-level meter that moves only from real microphone features.
- Added stale-signal handling so the meter returns to zero and reports missing
  microphone metrics instead of simulating activity.
- Allowed confirmed safety events during calibration and prevented calibration
  completion from dismissing an active alert/cooldown state.
- Android now prefers UNPROCESSED capture when supported, with safe
  VOICE_RECOGNITION/MIC fallbacks; EventChannel delivery is marshalled to the
  Android main thread.
- Kotlin detector source compiles against a pure JVM harness and synthetic PCM
  vectors cover quiet input, loud-burst confirmation, meter response,
  calibration bypass and robust baseline. Physical-device acceptance remains
  `UNVERIFIED`.

## 1.1 — 2026-08-24

- Promoted `Giám sát giấc ngủ` from FeatureHub planned surfaces to the active
  feature grid.
- Kept trusted Plus/FamilyPlus-only access; Free remains upgrade-gated.
- Added SQL 08 to enable the current server rollout while retaining the kill
  switch.
- Removed the duplicate rollout network fetch from `startMonitoring`; Start now
  consumes the fail-closed rollout state already resolved by Riverpod/gate.
- Runtime/device/provider evidence remains unverified until executed.

## 1.0 — 2026-08-24

- Created M31 from Product Owner decisions `1B 2A 3A 4A 5B 6A 7B 8A 9A 10A`.
- Approved non-medical on-device acoustic monitoring, 30/60s response state
  machine, SafetyContact verification and provider-neutral cloud escalation.
- Kept rollout OFF pending real Android/iOS/provider/Supabase evidence.
