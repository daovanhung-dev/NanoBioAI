# Project Cleanup Audit

Date: 2026-06-16

Scope: safe cleanup audit for models, providers, feature placeholders, redundant services, dependencies, and architecture debt. Current code is treated as source of truth when it differs from older `.codex` notes.

Cleanup rule: only rows with risk `SAFE` and action `DELETE` or `MERGE` may be changed in this pass. Anything uncertain remains `REVIEW`.

| File path | Type | Why suspicious | Evidence from reference search | Risk | Action |
| --- | --- | --- | --- | --- | --- |
| `lib/services/ai/models/ai_meal_response_model.dart` | model | `MealPlanModelAI` duplicates the active meal plan data model and lacks `cookingInstructions` / `cooking_instructions`. | `rg "MealPlanModelAI\|ai_meal_response_model" lib test docs .codex` finds only the model itself plus docs/DD notes saying it duplicates `MealPlanModel`; no code import/export/test route. | SAFE | DELETE |
| `lib/features/ai_chat/presentation/pages/ai_chat_page.dart` | widget | Placeholder page overlaps with active AI chat screen. | `rg "AiChatPage\|ai_chat_page" lib test docs .codex` finds only this file; `app_router.dart` builds `AIChatScreen` for `RoutePaths.aiChat` with `RouteGuards.authGuard`. | SAFE | DELETE |
| `lib/shared/widgets/health_card.dart` | widget | Generic card not imported by active dashboard/settings/health flows. | `rg "HealthCard\|health_card" lib test docs .codex` finds only this file plus an unrelated dashboard TODO mentioning `_HeroHealthCard`. | SAFE | DELETE |
| `lib/features/ai_chat/presentation/ai_chat_screen.dart` | widget | Analyzer reports unnecessary `dart:ui` import. | First lines include `import 'dart:ui';`; `flutter analyze` reported `unnecessary_import` for this file. Active route and class must remain. | SAFE | MERGE |
| `lib/shared/widgets/loading_genAI.dart` | widget | Analyzer reports unused `app_theme.dart` import. File name casing is separate review item. | First lines include `import '../../core/theme/app_theme.dart';`; `flutter analyze` reported `unused_import`. `AIGeneratingPage` is imported by onboarding review step, so only import cleanup is safe. | SAFE | MERGE |
| `lib/features/onboarding/providers/onboarding_provider.dart` | provider | Older `.codex` notes mention duplicated `onboardingProvider`. | `rg "onboardingProvider" lib test docs .codex` shows one live provider declaration in this file and many UI/test references. No duplicate declaration in controller now. | SAFE | KEEP |
| `lib/features/meal_plan/providers/meal_plan_provider.dart` | provider | Older `.codex` notes mention duplicate meal plan datasource/repository providers. | `rg "mealPlanLocalDatasourceProvider\|mealPlanRepositoryProvider\|getMealPlanProvider\|mealPlanControllerProvider" lib test docs .codex` shows datasource/repository providers centralized here and controller provider in controller. | SAFE | KEEP |
| `lib/features/daily_health_tracking/providers/daily_health_tracking_provider.dart` | provider | New feature provider surface is preservation-critical. | `rg "dailyHealthTrackingLocalDatasourceProvider\|dailyHealthTrackingRepositoryProvider\|dailyHealthTrackingControllerProvider" lib test docs .codex` shows use in `main.dart`, page, and controller. | HIGH | KEEP |
| `lib/services/ai/providers/ai_provider.dart` | service/provider | Unused Dio provider and duplicate provider name `dioProvider`. | `rg "services/ai/providers/ai_provider\|final dioProvider\|GEMINI_BASE_URL" lib test docs .codex .env.example` finds only provider file plus docs for optional env. No active code import. | MEDIUM | REVIEW |
| `lib/core/network/dio_provider.dart` | service/provider | Unused Dio provider and duplicate provider name `dioProvider`. | `rg "core/network/dio_provider\|final dioProvider\|OPENAI_BASE_URL" lib test docs .codex .env.example` finds only provider file plus docs for optional env. No active code import. | MEDIUM | REVIEW |
| `lib/features/auth/data/models/user_model.dart` | model | Duplicate class name with core local DB `UserModel`; not used by auth flow. | `rg "features/auth/data/models/user_model\|auth/data/models/user_model\|UserModel" lib test docs .codex` finds this file, core local DB user model/DAO, and DD checklist mention. No auth import. | MEDIUM | REVIEW |
| `lib/core/storage/localdb/models/user_model.dart` | model | Minimal placeholder-like model. | Used by `lib/core/storage/localdb/daos/users_dao.dart`; tied to SQLite mapper surface. | HIGH | KEEP |
| `lib/core/storage/localdb/models/ai_insight_model.dart` and sibling local DB placeholder models | model | Many are one-field placeholder mappers. | `rg` shows use from corresponding DAOs; they mirror SQLite table surfaces even if DAOs are TODO. | HIGH | KEEP |
| `lib/features/onboarding/data/models/onboarding_model.dart` | model | Entity/model overlap. | `rg "OnboardingModel\|onboarding_model" lib test` shows use by `OnboardingLocalDatasource` row builders. | HIGH | KEEP |
| `lib/features/meal_plan/data/models/meal_plan_model.dart` | model | Data model overlaps with `MealPlanEntity`. | Preservation-critical: used by AI parsing, DAO mapping, tests, dashboard save flow, and cooking instructions serialization. | HIGH | KEEP |
| `lib/features/meal_plan/domain/entities/meal_plan_entity.dart` | entity | Data/entity duplication. | Used by meal plan repository/controller/page; model converts to/from entity. | HIGH | KEEP |
| `lib/features/daily_health_tracking/data/models/daily_health_task_model.dart` | model | Data/entity overlap. | Preservation-critical: used by DAO, datasource, tests, and AI normalizer. | HIGH | KEEP |
| `lib/features/daily_health_tracking/data/models/daily_health_ai_task_normalizer.dart` | model/service | AI parsing helper looks isolated but is preservation-critical. | Used by `AIService.generateDailyHealthTasks` and dedicated tests; must preserve 28 task normalization. | HIGH | KEEP |
| `lib/features/ai_chat/data/models/chat_message_model.dart` | model | Model/entity overlap. | Used by `AIChatRepositoryImpl` to create user/assistant messages. | HIGH | KEEP |
| `lib/features/settings/data/models/user_profile_model.dart` | model | Settings feature incomplete; model/entity overlap. | Used by settings data/domain contracts and tests around local datasource behavior; settings must not be deleted for incompleteness. | MEDIUM | KEEP |
| `lib/features/profile/presentation/profile_screen.dart` | widget | Unreferenced placeholder-like profile screen. | `rg "ProfileScreen" lib test docs .codex` finds only class declaration. Product placeholders/profile scope are documented, so not safe to remove by reference count alone. | MEDIUM | REVIEW |
| `lib/features/profile/presentation/pages/profile_page.dart` | widget | Unreferenced placeholder page. | `rg "ProfilePage" lib test docs .codex` finds only class declaration; `RoutePaths.profile` currently builds `Placeholder`, but profile route/product scope exists. | MEDIUM | REVIEW |
| `lib/features/nutrition/presentation/pages/nutrition_page.dart` | widget | Unreferenced placeholder page. | `rg "NutritionPage" lib test docs .codex` finds only class declaration; nutrition route/product scope exists. | MEDIUM | REVIEW |
| `lib/features/sleep_tracking/presentation/pages/sleep_tracking_page.dart` | widget | Unreferenced placeholder page. | `rg "SleepTrackingPage" lib test docs .codex` finds only class declaration; sleep tracking route/product scope exists. | MEDIUM | REVIEW |
| `lib/features/stress_tracking/presentation/pages/stress_tracking_page.dart` | widget | Unreferenced placeholder page. | `rg "StressTrackingPage" lib test docs .codex` finds only class declaration; stress tracking route/product scope exists. | MEDIUM | REVIEW |
| `lib/features/community/presentation/pages/community_page.dart` | widget | Unreferenced placeholder page. | `rg "CommunityPage" lib test docs .codex` finds only class declaration; community route/product scope exists. | MEDIUM | REVIEW |
| `lib/features/other/presentation/pages/other_page.dart` | widget | Large mock/insights page. | Imported by `MainNavigationPage` and used as active tab `HealthInsightsView`; keep. | HIGH | KEEP |
| `lib/features/splash/presentation/pages/splash_page.dart` | widget | Splash contains direct local prefs routing logic. | Active route `/`; preserves Splash -> onboarding/menu flow. | HIGH | KEEP |
| `lib/core/constants/app/app_assets.dart` | asset constant | Points to missing `assets/images/logo.png` and `assets/images/ai_bot.png`. | `rg "AppAssets\|assets/images" lib test docs .codex pubspec.yaml` finds only constants; assets folder has `assets/icons/logo.png` and translations. | LOW | REVIEW |
| `assets/translations/en.json`, `assets/translations/vi.json` | asset | No direct code references found. | `pubspec.yaml` includes entire `assets/`; app may use later localization. No delete in safe pass. | MEDIUM | REVIEW |
| `connectivity_plus` in `pubspec.yaml` | dependency | No Dart code references found. | `rg "connectivity_plus\|Connectivity\|connectivity" lib test pubspec.yaml` finds only `pubspec.yaml`. | MEDIUM | REVIEW |
| `cupertino_icons` in `pubspec.yaml` | dependency | No `CupertinoIcons` references found. | `rg "cupertino_icons\|CupertinoIcons" lib test pubspec.yaml` finds only `pubspec.yaml`. | MEDIUM | REVIEW |
| `rename`, `mockito`, `build_runner` in `pubspec.yaml` | dependency | No active code references found. | `rg "rename\|mockito\|build_runner" lib test pubspec.yaml` finds only dependency entries, except tooling may be intentional. | MEDIUM | REVIEW |
| `sqflite_common_ffi` in `pubspec.yaml` | dependency | Test-only dependency. | Used by local DB tests including migration and daily health DAO tests. | HIGH | KEEP |

## Feature audit notes

- `auth`: keep Supabase auth datasource/repository/providers; auth `UserModel` is REVIEW because unused but product docs mention it.
- `onboarding`: keep controller, provider, local datasource, entity/model, widgets, and completion callback. Current provider duplication appears resolved.
- `dashboard`: keep dashboard datasource/repository/controller/UI; repository implementation location is architecture debt only.
- `meal_plan`: keep active model/entity/DAO/datasource/providers/page/controller. Do not alter cooking instructions serialization.
- `daily_health_tracking`: keep all models, normalizer, DAO, datasource, providers, controller, page, and tests.
- `ai_chat`: keep `AIChatScreen`, providers, repository, model/entity, service, FAB, and guarded route. Delete only unused placeholder `AiChatPage`.
- `settings`: keep incomplete feature files; no repository implementation cleanup in this pass.
- `profile`, `nutrition`, `sleep_tracking`, `stress_tracking`, `community`: placeholders are REVIEW_REQUIRED because product routes/modules exist.
- `other`: keep active tab `HealthInsightsView`.
- `splash`: keep active Splash -> onboarding/menu flow.

## Architecture debt to report only

- Repository implementations live under `domain/repositories`.
- `AIService` returns feature-specific `MealPlanModel` and imports daily health feature models.
- `main.dart` contains onboarding completion orchestration for meal plan plus daily task generation.
- Some domain/repository files import data-layer classes.
- `DashboardController` and app-level onboarding completion create cross-feature orchestration.
- `AIService`, `AIChatService`, and onboarding datasource debug-print AI/user health payloads.
- Several UI files are very large, especially meal plan, onboarding widgets, AI chat, splash, and daily health tracking.
