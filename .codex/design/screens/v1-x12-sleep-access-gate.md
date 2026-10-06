# V1-X12 — Sleep Safety Access Gate

- Classification: `gate` · Group: `07_health_tracking`
- Source: `lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_safety_access_gate.dart`
- Entry: wraps the authenticated `/sleep-tracking` route before its protected child is shown.
- Job: explain the current trusted access state and the next valid action.
- States: access loading, permitted, locked/denied, retryable failure and navigation to existing upgrade/support flow.
- Design: preserve page context during checks, use clear text/icon status, no protected-content flash, no celebration on denied or pending access.
- Guardrail: access must continue to come from existing provider/backend state; preserve route and guard behavior.
- Verification: source mapping refreshed 2026-10-06; fixture/render evidence pending.
