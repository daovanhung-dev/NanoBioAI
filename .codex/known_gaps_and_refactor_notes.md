# Known Gaps And Refactor Notes

## High-priority architecture debt

### 1. Onboarding -> Dashboard direct dependency

Current:

- `OnboardingController` imports `features/dashboard/presentation/controllers/dashboard_controller.dart`.
- `saveOnboarding()` calls `dashboardControllerProvider.notifier.genMealByWeeksToDB()`.

Problem:

- Cross-feature controller dependency.
- Harder to test onboarding independently.

Refactor direction:

- Move orchestration to provider/app layer or a use-case/service.
- Possible callback/event approach.
- Preserve: onboarding completion must still generate meal plan and set onboarding flag.

### 2. Meal plan nested feature structure

Current:

```txt
lib/features/meal_plan/dashboard/
├── data/
├── domain/
├── presentation/
└── providers/
```

Preferred:

```txt
lib/features/meal_plan/
├── data/
├── domain/
├── presentation/
└── providers/
```

Refactor requires import updates in router, menu page, dashboard, tests/docs.

### 3. MealPlanModel placement

Current:

- `core/storage/localdb/models/meal_plan_model.dart`

Problem:

- Feature-specific model in core.
- Presentation and services import core storage model directly.

Possible direction:

- Move model to `features/meal_plan/data/models/meal_plan_model.dart`.
- Or create domain `MealPlanEntity` and keep storage model in feature data layer.
- Preserve all fields and serialization methods.

### 4. MealPlan presentation imports data layer

Current:

- `MealPlanController` imports `data/datasources/meal_datasource.dart`.
- Providers for datasource/repository are declared inside controller file.

Better:

- Move datasource/repository providers to `features/meal_plan/providers`.
- Controller should depend on repository abstraction.

### 5. Duplicate providers

Duplicates:

- `onboardingProvider` in both controller and providers folder.
- `mealDataSource` and `mealPlanRepositoryProvider` in both meal plan providers file and controller file.

Refactor carefully because imports may reference either one. Use `rg "onboardingProvider|mealDataSource|mealPlanRepositoryProvider" lib test`.

## Data correctness gaps

### Missing IDs in many inserts

Most table schemas use `id TEXT PRIMARY KEY`, but onboarding datasource inserts many rows without `id`.

Check on real SQLite before shipping:

- `health_profiles`
- `health_goals`
- `health_conditions`
- `lifestyle_habits`
- `food_allergies`
- `medical_treatments`
- `survey_answers`

If insert fails, generate ids consistently. If SQLite permits null primary key in non-rowid TEXT cases, still risky and should be explicit.

### `concernText` is not persisted

`OnboardingState` and `OnboardingEntity` include `concernText`, and `DashboardLocalDatasource` reads `surveyAnswers['concern_text']`, but `_surveyRows` does not write `concern_text`.

Fix direction:

- Add survey row for `concern_text`, or create dedicated column/table if product requires.

### User id type mismatch

`users.id` is TEXT. `DashboardEntity.userId` is `int`. Current generated ids are numeric timestamp strings, so parsing works. If ids change to UUID or Supabase ids, dashboard userId becomes 0.

Fix direction:

- Change `DashboardEntity.userId` to `String`, or add separate `localUserId`.

### Foreign keys disabled

`DatabaseService` turns foreign keys off. This reduces constraint errors but also hides referential problems.

If enabling foreign keys later:

- Make sure every inserted child row has valid `id` and `user_id`.
- Add migration and tests.

## Product scope gaps

### 7-day vs 30-day meal plan

Code/README:

- 7-day meal plan.

Docs/DD:

- 30-day personalized meal plan and refresh cycle.

Before changing:

- Confirm intended scope.
- If upgrading to 30 days, update prompt, tests, UI copy, storage assumptions, and DD/context docs.

### Settings feature not wired

`SettingsRepository` contract exists, local/remote datasource exist, but no implementation/provider/controller. `SettingsView` hardcodes user data and no-op actions.

Suggested path:

1. Add `SettingsRepositoryImpl`.
2. Add providers.
3. Add controller/state.
4. Wire profile/preferences to UI.
5. Reuse validators and device services.

### Auth is login-only

- Login works through Supabase.
- Register route placeholder.
- Forgot password button no-op.
- Login UI has inline validators and hardcoded styles.

`docs/todo/login_ui_refactor_todo.md` has detailed component split plan.

### Dashboard has mock data

Dashboard reads health profile but many stats/insights/timeline/goals are from `DashboardMockStats`.

If implementing real tracking:

- Use `health_tracking_logs`, `nutrition_logs`, `ai_insights`, `ai_recommendations`.
- Fill TODO DAOs or create feature datasources.

### Chat history not persisted

AI chat repository keeps history in memory. This is documented as privacy-first in feature docs, but if user expects history after restart, add encrypted/local persistence deliberately.

## Stale docs/tests notes

`docs/issues/bug_architecture.md` says AI circular dependency is resolved. That matches code.

`test/ARCHITECTURE_VIOLATIONS_COUNTEREXAMPLES.md` and parts of exploration tests still mention old state where AI service imported DashboardEntity and onboarding datasource was remote. Treat these as historical counterexamples, not exact current truth.

## Env/config gaps

`.env.example` includes:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `GEMINI_API_KEY`

Code also references:

- `GEMINI_MODEL`
- `GEMINI_BASE_URL`
- `OPENAI_BASE_URL`

If these providers become active, update `.env.example`.

## Code hygiene gaps

- `DashboardController` contains raw `print()` debug steps.
- AI services debug-print raw AI response; be careful with privacy.
- Onboarding debug-prints SQLite snapshot; useful during dev, risky in production logs.
- Many DAOs have TODO only.
- Migration manager empty.
- Some UI files are huge (`MealPlanPage`, onboarding steps, AI chat screen).

## Suggested refactor order

1. Add/adjust tests or run preservation baseline.
2. Fix data IDs and `concernText` persistence if onboarding save is failing or needed.
3. Remove onboarding -> dashboard controller dependency by orchestration service/callback.
4. Flatten meal_plan folder.
5. Move/introduce MealPlan entity/model in feature layer.
6. Consolidate duplicate providers.
7. Wire Settings repository/controller if settings work is next.
8. Replace mock dashboard data with real logs when tracking features start.

Keep each refactor small. Run preservation tests after each architectural boundary change.
