# Handoff Prompt For Future Codex Sessions

Use this as the first message/context instruction for future work:

```txt
You are working in D:\Project\NanoBio\nano_app, a Flutter health app named BioAI / nano_app.

Before changing code, read these context files in order:
1. .codex/README.md
2. .codex/project_context.md
3. .codex/architecture.md
4. .codex/features_and_workflows.md
5. .codex/data_and_storage.md
6. .codex/api_reference.md
7. .codex/design_system.md
8. .codex/testing_and_quality.md
9. .codex/known_gaps_and_refactor_notes.md

Source-of-truth rule:
- Current code beats stale docs when they conflict.
- README/current code describe 7-day meal plan.
- docs/DD describes 30-day product vision.
- architecture_preservation_property_test.dart captures behavior to preserve during refactors.
- architecture_violation_exploration_test.dart is intentionally failing until architecture debt is fixed.

Key flows:
- main.dart loads .env, initializes Supabase, runs BioAIApp in ProviderScope.
- Splash reads AppPrefs.onboarding_completed and routes to /menu or /onboarding.
- Onboarding saves profile to multiple SQLite tables, then calls onboardingCompletionCallbackProvider; main.dart overrides it to generate 21 meal records and 28 daily health tasks before onboarding_completed is set.
- Dashboard fetches latest local user/profile and displays real health data mixed with mock stats.
- Meal generation uses Gemini via AIService.generateMealPlan(HealthDataInterface), parses JSON into MealPlanModel including cookingInstructions/cooking_instructions, saves with MealPlansDao.insertMany.
- Daily health task generation after onboarding uses AIService.generateDailyHealthTasks(DailyHealthProfileEntity, startDate tomorrow), normalizes to 7 days x water/body/mind/brain, and saves with DailyHealthTasksDao.upsertMany.
- MealPlanPage reads meal_plans from SQLite and groups by date.
- AI Chat uses Gemini chat session, in-memory history only, route /ai-chat is auth-guarded.

Be careful with:
- Do not read/write .env secrets into docs.
- Do not break onboarding -> meal generation + daily task generation -> saved local data -> completed flag behavior.
- Provider duplication was mostly cleaned up on 2026-06-16; still run rg before changing onboarding/meal plan provider names.
- MealPlanModel is feature-specific under features/meal_plan/data/models.
- meal_plan folder is flat under features/meal_plan.
- Settings has interfaces/datasources but no repository implementation/controller; UI is mostly hardcoded.

Preferred workflow:
- Use rg to inspect before editing.
- Keep changes scoped.
- Use apply_patch for manual edits.
- For architecture refactor, run `flutter test test/architecture_preservation_property_test.dart` before/after.
- Run targeted tests and `flutter analyze` when feasible.
```
