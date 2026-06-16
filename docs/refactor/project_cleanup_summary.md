# Project Cleanup Summary

Date: 2026-06-16

## Deleted files

- `lib/services/ai/models/ai_meal_response_model.dart`
- `lib/features/ai_chat/presentation/pages/ai_chat_page.dart`
- `lib/shared/widgets/health_card.dart`

## Deleted models

- `MealPlanModelAI`

Reason: it duplicated the active `MealPlanModel`, was not imported by live Dart code, and lacked the preserved `cookingInstructions` / `cooking_instructions` field.

## Merged models

- None.

No model/entity/DTO consolidation was performed because active serialization and SQLite/AI parsing contracts are preservation-critical.

## Providers consolidated

- None.

Findings:

- `onboardingProvider` is no longer duplicated in current code; the public provider remains in `lib/features/onboarding/providers/onboarding_provider.dart`.
- Meal plan datasource/repository providers are already centralized in `lib/features/meal_plan/providers/meal_plan_provider.dart`.
- `dailyHealthTracking*Provider`, `aiServiceProvider`, and `aiChatServiceProvider` were left unchanged.

## Dependencies removed

- None.

Unused-looking dependencies remain `REVIEW_REQUIRED` because they may be project tooling or future-module commitments.

## Assets removed

- None.

Asset constants and translation assets remain `REVIEW_REQUIRED`, not deleted.

## Imports fixed

- Removed unused `dart:ui` import from `lib/features/ai_chat/presentation/ai_chat_screen.dart`.
- Removed unused `../../core/theme/app_theme.dart` import from `lib/shared/widgets/loading_genAI.dart`.

Note: `dart format` was run only on the two touched Dart files, per chosen cleanup scope.

## Tests run

- `flutter analyze`
  - Result: exits 1 with 249 existing info/warning findings.
  - Cleanup did not introduce analyzer errors; the two targeted unused/unnecessary import findings are gone.
- `flutter test test/architecture_preservation_property_test.dart`
  - Result: passed, 15 tests.
- `flutter test test/features/meal_plan/data/meal_plan_model_test.dart`
  - Result: passed, 2 tests.
- `flutter test test/features/daily_health_tracking`
  - Result: passed, 10 tests.
- `flutter test test/core/storage/localdb/migration_manager_test.dart`
  - Result: passed, 1 test.

## Remaining REVIEW_REQUIRED items

- `lib/services/ai/providers/ai_provider.dart` and `lib/core/network/dio_provider.dart`: unused duplicate `dioProvider` names, but documented env vars make deletion a separate config decision.
- `lib/features/auth/data/models/user_model.dart`: unused duplicate `UserModel`, but auth/product docs mention it.
- `lib/features/profile/presentation/profile_screen.dart` and profile/nutrition/sleep/stress/community placeholder pages: unreferenced or route-placeholder-adjacent, but product modules/routes are documented.
- Core SQLite placeholder models and TODO DAOs: incomplete, but tied to schema and future local storage surfaces.
- `lib/core/constants/app/app_assets.dart`: stale constants point to missing `assets/images/*`; no live code references found.
- `assets/translations/en.json` and `assets/translations/vi.json`: no direct code references found, but `pubspec.yaml` includes `assets/`.
- `connectivity_plus`, `cupertino_icons`, `rename`, `mockito`, `build_runner`: no removal in this pass.

## Remaining architecture debt

- Repository implementations still live under `domain/repositories`.
- `AIService` still returns feature-specific `MealPlanModel` and imports daily health feature models.
- `main.dart` still owns onboarding completion orchestration for meal generation and daily health task generation.
- Some repository/domain files still import data-layer classes.
- Cross-feature orchestration remains in dashboard/onboarding completion flow.
- AI and onboarding debug logging can print sensitive AI/user health payloads.
- Large UI files remain, especially meal plan, onboarding widgets, AI chat, splash, other, and daily health tracking.

## Risks needing human review

- Docs/DD still mention `MealPlanModelAI`; the code cleanup intentionally did not rewrite product docs outside the requested audit/summary files.
- Analyzer remains non-green because of pre-existing warnings and infos, mostly deprecated `withOpacity`, style lints, unused test imports, and large UI file warnings.
- The cleanup did not rename `loading_genAI.dart`; analyzer still reports its file-name lint, but renaming would require import-path changes outside this safe deletion pass.
