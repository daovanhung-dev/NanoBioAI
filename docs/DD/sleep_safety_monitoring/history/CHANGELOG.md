# M31 DD Changelog

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
