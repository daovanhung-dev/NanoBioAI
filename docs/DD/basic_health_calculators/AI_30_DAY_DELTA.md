# M04 Delta — Personalized Body Metrics + 30-Day AI Wellness Interpretation

Status: Approved implementation delta from user request 2026-08-13.

## Scope

- Prefill M04 calculator inputs from the user's latest local profile.
- Prefer a newer weight tracking record over an older profile weight.
- Aggregate current NanoBio meal-plan energy and lifestyle schedule context for the next 30 calendar days.
- Keep BMI/BMR/RMR/TDEE/hydration deterministic and versioned by the existing M04 calculator.
- Build a deterministic 30-day scenario that classifies planned energy as below/near/above the current TDEE reference and records plan coverage.
- Use AI only to interpret current wellness context and the 30-day scenario in Vietnamese.

## Safety boundary

- AI must not invent or modify numeric health metrics.
- AI output contains no numeric values; app-owned metrics are displayed separately.
- AI must not diagnose disease, prescribe treatment/medication, or guarantee outcomes.
- Insufficient plan evidence skips AI instead of fabricating a forecast.
- Raw health profile and raw AI prompt/response are not persisted or logged by this feature.
- The AI call is user-initiated from the **Phân tích cơ thể** action and the UI discloses that aggregated wellness metrics/plan context are sent for AI interpretation; proof images and raw journals are excluded.

## Data flow

```text
BodyMetricsPage
  -> bodyMetricsPersonalContextProvider
  -> BodyMetricsRepository
  -> BodyMetricsLocalDatasource
  -> SQLite user/profile/tracking/meal/schedule read models

Manual/profile input
  -> BasicHealthCalculator (M04 deterministic source of truth)
  -> BodyMetricsProjectionPolicy (deterministic plan direction)
  -> BodyMetricsAiService (interpretation only)
  -> validated safe JSON narrative
```

## 30-day assumptions

- The currently available meal plan and lifestyle schedule are treated as the user's active NanoBio regimen.
- The feature describes a trend if that regimen is maintained; it does not promise a measured body change.
- No body-weight delta, body-fat delta, disease probability, or treatment result is generated.

## Acceptance

1. Existing profile data pre-fills the form without blocking manual correction.
2. Missing profile fields remain missing; production code does not create sample values.
3. A newer tracking weight supersedes an older profile weight.
4. Current metrics remain outputs of `BasicHealthCalculator`.
5. AI receives aggregated context only and is skipped when plan data is insufficient.
6. AI responses containing digits or diagnostic/treatment claims are rejected.
7. AI/network failure leaves deterministic current metrics visible.
8. User-facing copy states that the result is a wellness estimate, not diagnosis or guaranteed outcome.

## Reward rollout relation

This M04 delta does not change the global Wellness Rewards release gate. Reward rebuild sources remain disabled by default; the reward bug fix only guarantees that, when an eligible reward flow is enabled, camera completion cannot silently succeed with zero points. Rollout activation remains an explicit sandbox/device-approved operation.
