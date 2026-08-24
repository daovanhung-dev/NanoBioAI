# M31 DD Changelog

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
