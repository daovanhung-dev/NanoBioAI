# V1-23 — Goal Review

- Classification: `active-route` — `V1RoutePaths.goalReview`
- Group: `08_features_care`
- Source: `lib/app_versions/v1/features/goal_review/presentation/pages/goal_review_page.dart`
- Primary job: review and confirm the user's proposed goals.
- Presentation order: review context → goal summary → edit/review choices → explicit confirmation.
- States: loading, retryable error, empty only where source supports it, ready, validation, saving and confirmed/error. Do not suggest a save succeeded before the existing controller confirms it.
- Design: calm single-column form at compact width; split related summary/detail only when space allows; make primary confirmation distinct from navigation and editing.
- Guardrails: keep source goal ordering, values, route arguments, controller methods and persistence semantics unchanged.
- Verification: current-source mapping refreshed 2026-10-06; render/device certification pending.
