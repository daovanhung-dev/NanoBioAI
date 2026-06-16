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
- Onboarding saves profile to multiple SQLite tables, then currently calls DashboardController.genMealByWeeksToDB(), then sets onboarding_completed true.
- Dashboard fetches latest local user/profile and displays real health data mixed with mock stats.
- Meal generation uses Gemini via AIService.generateMealPlan(HealthDataInterface), parses JSON into MealPlanModel, saves with MealPlansDao.insertMany.
- MealPlanPage reads meal_plans from SQLite and groups by date.
- AI Chat uses Gemini chat session, in-memory history only, route /ai-chat is auth-guarded.

Be careful with:
- Do not read/write .env secrets into docs.
- Do not break onboarding -> meal generation -> saved meal plan behavior.
- Watch duplicate providers: onboardingProvider and meal plan providers.
- MealPlanModel is currently in core storage though feature-specific.
- meal_plan folder is nested under meal_plan/dashboard.
- Settings has interfaces/datasources but no repository implementation/controller; UI is mostly hardcoded.

Preferred workflow:
- Use rg to inspect before editing.
- Keep changes scoped.
- Use apply_patch for manual edits.
- For architecture refactor, run `flutter test test/architecture_preservation_property_test.dart` before/after.
- Run targeted tests and `flutter analyze` when feasible.
```
