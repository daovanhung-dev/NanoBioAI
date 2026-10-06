# V1-25 — Fitness Training

- Classification: `active-route` — `V1RoutePaths.fitnessTraining`
- Group: `06_schedule_proof`
- Source: `lib/app_versions/v1/features/fitness_training/presentation/pages/fitness_training_page.dart`
- Primary job: view and manage the currently available workout schedule and workout detail.
- Presentation order: schedule context → today's next workout → week/date controls → session detail and safe action.
- States: loading, empty, error/retry, ready, locked/access, schedule conflict, pending, and completed only when the source confirms them.
- Design: share the MedicalPageScaffold and semantic Blue Wellness tokens; keep video controls and workout actions clear; avoid decorative animation around health values; fit 320 dp width and large text.
- Guardrails: preserve M32 time-resolution/consent behavior, workout data, quota ordering, provider calls and video lifecycle.
- Verification: shell migration completed in source; full flow/device certification pending.
