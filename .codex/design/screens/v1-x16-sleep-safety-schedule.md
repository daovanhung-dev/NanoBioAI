# V1-X16 — Sleep Safety Schedule

- Classification: `source-sub-surface` · Group: `07_health_tracking`
- Source: `lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_safety_schedule_page.dart`
- Entry: Sleep Tracking schedule action.
- Job: review and save the user's safety monitoring schedule.
- States: loaded preference, enabled/disabled, time/day selection, validation, saving, success and error.
- Design: responsive bounded column with one schedule toggle, paired start/end time, compact day selection, privacy note and one primary save action.
- Guardrail: keep `copyWith` fields, defaults, schedule intervals, persistence and save completion navigation unchanged.
- Verification: layout source redesigned; focused theme tests pass; saved-preference device proof pending.
