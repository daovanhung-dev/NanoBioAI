# BioAI Codex Context Ultra Compact

Last verified from local code/docs: 2026-06-17.

Purpose: single minimal context for Codex before tasks. Read this file first. Do not preload older `.codex/*.md` files unless the task needs deeper history. Current code is the source of truth when docs conflict.

This file summarizes repo-facing working rules only. It does not copy hidden/system/developer instructions.

## Token-Saving Protocol

1. Read this file first, then inspect only task-relevant files.
2. Use `rg` / `rg --files` for discovery before opening broad folders.
3. Prefer small scoped patches and targeted tests.
4. Do not broad-refactor unless the task explicitly asks.
5. The worktree may be dirty. Do not revert user changes.
6. Never read, print, copy, or document secrets from `.env`; use `.env.example` and safe docs.
7. Before renaming providers, routes, models, tables, or files, run `rg` for all usages.
8. For architecture-sensitive work, preserve public provider names and onboarding completion behavior unless the task explicitly changes them.

## Project

- App: BioAI, Flutter package `nano_app`.
- Workspace: `D:\Project\NanoBio\nano_app`.
- Product: offline-first personal health app for onboarding health profiles, dashboard, AI meal plans, lifestyle schedule, reminders, AI health chat, and settings.
- Stack: Flutter/Dart `sdk ^3.9.2`, Riverpod 3, GoRouter, SQLite `sqflite`, SharedPreferences, Supabase auth, Gemini via `google_generative_ai`, Dio legacy providers, local auth, image picker, local notifications.
- Entry: `lib/main.dart` loads `.env`, initializes Supabase, initializes local notifications, then runs `ProviderScope(child: BioAIApp())`.
- App shell: `lib/app/app.dart` uses `MaterialApp.router`, `AppTheme.lightTheme`, and `appRouter`.

## Architecture

Ideal flow:

```txt
UI -> Riverpod Provider/Controller -> Repository -> Datasource -> SQLite/Supabase/AI
```

Reality:

- Feature-first + partially Clean Architecture.
- Many repository implementations currently live in `domain/repositories/`; keep that convention for small tasks.
- Provider styles are mixed: `Provider`, `FutureProvider`, `NotifierProvider`, `AsyncNotifierProvider`, and legacy `StateNotifierProvider` in auth.
- AI/services still import some feature data models. This is known architecture debt, not a reason for incidental refactor.
- Existing UI usually imports `package:nano_app/core/theme/theme.dart`; new/refactored primitives may use `package:nano_app/core/theme/design_system.dart`.

Important folders:

```txt
lib/app
lib/core/constants
lib/core/router
lib/core/storage/localdb
lib/core/theme
lib/features/*
lib/services/ai
lib/services/notifications
lib/services/supabase
lib/shared/widgets
```

## Routes And Navigation

Core files: `core/constants/routes/route_names.dart`, `core/router/app_router.dart`, `route_guards.dart`.

Active routes include:

- `/` splash.
- `/login` login with guest guard.
- `/dashboard` dashboard, auth guard currently commented out.
- `/onboarding`.
- `/menu` `MainNavigationPage`.
- `/meal-plan`.
- `/health-tracking`.
- `/lifestyle-schedule`.
- `/ai-chat` with auth guard.
- `/nutrition` and `/profile` placeholders with auth guard.
- `/register` placeholder.

`SplashPage` routes from `AppPrefs.isOnboardingCompleted()`: completed -> `/menu`, otherwise `/onboarding`.

`MainNavigationPage` tabs are Dashboard, FeaturesHub, HealthInsightsView, SettingsView. `FeaturesHubPage` links to lifestyle schedule and meal plan; other tiles are mostly placeholders.

## Must-Preserve Flows

### Onboarding

Files: `features/onboarding/**`.

- Seven steps: Welcome, Basic Info, Goals, Conditions, Lifestyle, Extras, Review.
- `OnboardingController.saveOnboarding()` validates agreement/required fields, saves profile to SQLite through `OnboardingLocalDatasource`, calls `onboardingCompletionCallbackProvider`, then sets `AppPrefs.setOnboardingCompleted(true)`.
- If required generation/save inside the completion callback fails, onboarding must not be marked completed.
- The completion flag is navigation-critical.

### Onboarding Completion Callback

Defined as a `ProviderScope` override in `main.dart`.

Current code flow:

1. Set `days = 7` and `startDate = tomorrow`.
2. Generate and save meal plan via `DashboardController.genMealByWeeksToDB(requireComplete: true, startDate, days)`.
3. Fetch latest daily health profile.
4. Generate exercise tasks through `AIService.generateExerciseTasks(profile, startDate, days)`.
5. Fetch saved meal plans for the same date range.
6. Build lifestyle schedule via `LifestyleScheduleTimelineBuilder`.
7. Seed schedule with `requireComplete: true`.
8. Try scheduling reminder notifications. Notification scheduling errors are logged and must not fail onboarding after required data has been saved.

### Meal Plan

- Current scope: 7 days, 5 meals per day, 35 meal records total.
- Normalizer: `MealPlanAiNormalizer.mealsPerDay = 5`.
- Meal slots: breakfast, morning_snack, lunch, afternoon_snack, dinner.
- Stable IDs: `meal_${userId}_${date}_${slot.order}`.
- `DashboardController.genMealByWeeksToDB` fetches `DashboardEntity`, calls `AIService.generateMealPlan`, checks exact count when `requireComplete`, then saves through dashboard repository and `MealPlansDao.insertMany`.
- Product DD docs mention 30-day vision; do not upgrade from 7 days unless explicitly requested.

### Lifestyle Schedule

- Builder expects 5 meal items, 2 exercise items, and 3 routine items per day.
- Seven days produce 70 schedule items.
- Routine slots include wake, water, sleep.
- Schedule completion syncs linked meal completion and linked daily task completion when relevant, then updates daily score in `health_tracking_logs`.
- Items cannot be completed before their scheduled start time when a valid schedule time exists.

### Notifications

- `NotificationBootstrap.initialize()` initializes timezone and plugin scheduler.
- `ReminderScheduleService.scheduleGeneratedReminders()` schedules future incomplete lifestyle schedule items.
- Pending rows are stored in `notifications`.
- Payloads use stable notification IDs from `notification_id_generator.dart`.
- Action handler marks notification `done` or `skipped`; `done` can update linked schedule/source data.
- Scheduling failures and permission denial should not crash onboarding.

### AI Chat

- Route `/ai-chat`, opened through `AIChatFAB`.
- Uses Gemini chat session with Vietnamese health/lifestyle assistant behavior.
- History is in-memory only.
- Assistant must not diagnose or replace a doctor; serious symptoms should be referred to medical care.

## Data And Storage

- DB service: `core/storage/localdb/database_service.dart`.
- DB name: `bioai.db`.
- Current DB version: `DatabaseVersion.currentVersion = 6`.
- Foreign keys are disabled in `onConfigure` and `onOpen`.
- If schema changes, add a migration and bump DB version.

Main tables:

- `users`
- `health_profiles`
- `health_goals`
- `health_conditions`
- `lifestyle_habits`
- `food_allergies`
- `medical_treatments`
- `survey_answers`
- `meal_plans`
- `daily_health_tasks`
- `lifestyle_schedule_items`
- `health_tracking_logs`
- `nutrition_logs`
- `ai_insights`
- `ai_recommendations`
- `notifications`

Migration map:

- v2: `daily_health_tasks`, health tracking date/update columns and user/date index.
- v3: `meal_plans.cooking_instructions`.
- v4: notification scheduling/action columns and indexes.
- v5: `lifestyle_schedule_items` and indexes.
- v6: `meal_plans.start_time`, `meal_plans.end_time`, `health_tracking_logs.daily_score`.

Known caveats:

- Many localdb models/DAOs outside active meal/schedule/notification paths are placeholders or TODO.
- Some onboarding child table inserts historically lacked explicit text IDs; test real SQLite before changing save flow.
- `concernText` exists in onboarding/dashboard concepts; verify persistence before relying on it.
- `users.id` is text, but some domain surfaces still parse/represent user IDs as ints.

SharedPreferences:

- Onboarding flag key: `onboarding_completed`.
- Settings preferences include theme, language, biometric, push, reminders, AI personality, privacy mode.

## AI, Env, And Services

Safe env reference is `.env.example`, not `.env`.

Required env keys:

```env
SUPABASE_URL=
SUPABASE_ANON_KEY=
GEMINI_API_KEY=
```

Optional/referenced by code:

```env
GEMINI_MODEL=
GEMINI_BASE_URL=
OPENAI_BASE_URL=
```

Supabase:

- Initialized in `main.dart`.
- Current primary cloud scope is auth.

Gemini meal/exercise service:

- File: `services/ai/ai_service.dart`.
- Uses `GenerativeModel`.
- Requires valid JSON array output.
- Retries up to 3 times.
- Throws `AIOverloadedException` for detected overload/quota/capacity style failures.
- Non-overload final failures return `[]`, and required-complete callers convert missing count into errors.

Prompts:

- `prompts/meal_plan_prompt.dart`: 7-day configurable meal plan, 5 meals/day, app assigns ID/user/date/time/order metadata.
- `prompts/exercise_tasks_prompt.dart`: 2 exercise tasks/day, safe Vietnamese health-coach wording.

Legacy Dio providers exist, but are not the primary Gemini/Supabase flow. Verify before using.

## Feature Status

- Auth: Supabase login works; register route is placeholder; forgot password is not fully wired.
- Onboarding: active local SQLite save plus required completion orchestration.
- Dashboard: reads real profile/dynamic local data; some sections still mix in mock or fallback UI.
- Features hub: real links to lifestyle schedule and meal plan; other tools are placeholders.
- Meal plan: SQLite-backed list/grouping by date, nutrition fields, time slots, cooking instructions.
- Daily health tracking: today tasks/progress exist; rule-based generation may fill missing today tasks.
- Lifestyle schedule: week view, date selection, completion, linked meal/daily-task sync.
- Notifications: local reminder scheduler/action handler exist and are integrated into app boot/completion flow.
- AI chat: Gemini chat, in-memory history only.
- Settings: interfaces/datasources/validators exist, but UI remains mostly hardcoded/no-op and lacks full repository/controller wiring.
- Profile, nutrition, sleep, stress, community, and several feature tiles are placeholders or partial.

## Design System

Theme root: `lib/core/theme`.

Backward-compatible layer used widely:

- `AppColors`
- `AppTextStyles`
- `AppTheme`
- `AppSpacing`
- `AppRadius`
- `AppShadows`
- `AppGradients`
- `AppAnimations`
- `AppDuration`
- `AppIcons`
- `AppDecoration`
- `AppTypography`

Newer design system exports foundation tokens, semantic tokens, and primitives:

- `AppButton`
- `AppCard`
- `AppChip`
- `AppInput`
- `AppBadge`
- `SectionHeader`
- `EmptyState`
- `LoadingState`
- `ErrorState`

Rules:

- For existing screens, follow the file's current import/pattern.
- For explicit UI refactors, prefer tokens/primitives and avoid new hardcoded styling.
- Do not change Riverpod/controller/navigation behavior just for visual cleanup.

## High-Priority Gaps

- Move onboarding completion orchestration into a named use-case/service later, preserving exact behavior.
- `AIService` importing feature models is architecture debt.
- Settings needs repository implementation, providers, controller/state, then UI wiring.
- Dashboard still has mocked/fallback areas; replace only when asked.
- Chat history persistence is intentionally absent unless requested.
- Production hardening should review debug logging from AI/onboarding/dashboard paths.

## Tests And Quality

Use targeted tests first:

```powershell
flutter test test/features/meal_plan/data/meal_plan_ai_normalizer_test.dart
flutter test test/features/lifestyle_schedule/data/lifestyle_schedule_timeline_builder_test.dart
flutter test test/services/notifications/reminder_schedule_service_test.dart
flutter test test/services/notifications/notification_action_handler_test.dart
flutter test test/core/storage/localdb/migration_manager_test.dart
flutter test test/features/daily_health_tracking
flutter test test/features/settings
flutter test test/core/theme
flutter analyze
```

Full suite:

```powershell
flutter test
```

Important test reality:

- `test/architecture_violation_exploration_test.dart` is architecture backlog/exploration and may intentionally fail or be stale.
- `test/architecture_preservation_property_test.dart` is partly stale as of 2026-06-17: it fails because it expects `AIService` to contain `MealPlanModel.fromJson`, while current code routes meal parsing through `MealPlanAiNormalizer`.
- Verified during context creation: meal plan normalizer test passed, lifestyle schedule timeline builder test passed, reminder scheduler test passed. The reminder scheduler test logs an expected fake scheduling error in one passing scenario.

## Safe Task Workflow

1. Parse the user task and identify the feature area.
2. Use this file to choose the narrowest files to inspect.
3. Run `rg` for relevant classes/providers/routes/tables.
4. Open only touched files plus immediate dependencies/tests.
5. Patch narrowly with `apply_patch`.
6. Run targeted format/test/analyze when feasible.
7. Report changed files, tests run, and any pre-existing/stale failures.
