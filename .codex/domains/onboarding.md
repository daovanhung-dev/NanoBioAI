# Domain - Onboarding

## Source

- `lib/app_versions/v1/features/onboarding/`
- `lib/main.dart`, `lib/main_v2.dart` when callback after onboarding changes.
- SQLite profile/goals/habits/conditions/allergies/treatments/survey DAO/models.
- Tests: `test/app_versions/v1/features/onboarding/` and related feature tests.

## Rules

- Validate before save; do not bypass required fields with nullable workarounds.
- Save enough profile data for dashboard, AI schedule, meal plan, health tasks, and notifications.
- Guest may generate the initial personal schedule once after onboarding; additional generation requires auth/quota gate.
- Error states must preserve user input and use Nabicopy.

## Search

```powershell
rg "Onboarding|onboarding|submit|complete|callback" lib/app_versions/v1/features/onboarding lib/main.dart lib/main_v2.dart test
rg "health_profiles|health_goals|lifestyle_habits|survey_answers|allergies|treatments" lib/core/storage/localdb lib/app_versions/v1/features/onboarding test
```
