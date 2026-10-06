# V1-X13 — Sleep Night Analysis

- Classification: `source-sub-surface` · Group: `07_health_tracking`
- Source: `lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_night_analysis_page.dart`
- Entry: selected session from Sleep Tracking or Safety History.
- Job: inspect an existing sleep-safety recording/analysis for the selected session.
- States: loading, unavailable/deleted session, retryable error and ready; show only values present in source data.
- Design: lead with session date and actual result, separate interpretation from actions, use chart labels and text equivalents, limit motion for safety-related content.
- Guardrail: preserve `sessionId`, repositories, calculations and privacy/permission requirements; do not manufacture sample values.
- Verification: source mapping refreshed 2026-10-06; session-state fixture/render evidence pending.
