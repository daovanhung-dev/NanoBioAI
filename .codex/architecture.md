# Architecture

## Mau kien truc thuc te

Du an theo huong Feature-first + Clean Architecture, nhung chua dong nhat hoan toan. Mau ly tuong:

```txt
UI Page/Widget
  -> Riverpod Provider/Controller
  -> Repository interface/implementation
  -> Datasource
  -> SQLite / Supabase / AI service
```

Trong code hien tai, repository implementation thuong dat ngay trong `domain/repositories/` thay vi `data/repositories/`. Day la quy uoc dang duoc dung o nhieu feature, du co lech voi Clean Architecture truyen thong.

## App boot

`lib/main.dart`

- Load `.env`.
- Init Supabase.
- Wrap app bang `ProviderScope`.
- Override `onboardingCompletionCallbackProvider` de orchestration sau onboarding: generate 21 meal records va 28 daily health tasks truoc khi onboarding completed.

`lib/app/app.dart`

- `MaterialApp.router`.
- `AppTheme.lightTheme`.
- `appRouter`.

## Navigation

File chinh:

- `lib/core/constants/routes/route_names.dart`
- `lib/core/router/app_router.dart`
- `lib/core/router/route_guards.dart`
- `lib/core/router/navigation_service.dart`
- `lib/core/router/transitions.dart`

Route hien co:

| Path | Widget | Guard |
| --- | --- | --- |
| `/` | `SplashPage` | none |
| `/login` | `LoginPage` | `guestGuard` |
| `/register` | `Placeholder` | none |
| `/dashboard` | `DashboardPage` | auth guard dang comment |
| `/onboarding` | `OnboardingPage` | none |
| `/menu` | `MainNavigationPage` | none |
| `/meal-plan` | `MealPlanPage` | none |
| `/health-tracking` | `DailyHealthTrackingPage` | none |
| `/ai-chat` | `AIChatScreen` | `authGuard` |
| `/nutrition` | `Placeholder` | `authGuard` |
| `/profile` | `Placeholder` | `authGuard` |

`RouteGuards` doc Supabase session:

- `authGuard`: neu `Supabase.instance.client.auth.currentUser == null` thi redirect `/login`.
- `guestGuard`: neu da login thi redirect `/dashboard`.

Luu y: `SplashPage` khong kiem tra Supabase auth, chi xem `AppPrefs.isOnboardingCompleted()` roi di `/menu` hoac `/onboarding`.

## Splash flow

`SplashPage`:

1. Khoi tao animation.
2. Goi `splashProvider.notifier.initialize()`.
3. Doc `AppPrefs.isOnboardingCompleted()`.
4. Delay theo `AppDuration.loading`.
5. Neu completed -> `AppNavigator.goMenu(context)`.
6. Neu chua -> `AppNavigator.goOnboarding(context)`.

`SplashNotifier` hien chi set `SplashStatus.loading`; enum co `initial`, `loading`, `onboarded`, `onboardingRequired`.

## Riverpod patterns

Co nhieu the he song song:

- Moi hon: `NotifierProvider`, `AsyncNotifierProvider`, `FutureProvider`, `Provider`.
- Cu hon: `StateNotifierProvider` tu `flutter_riverpod/legacy` trong auth.

Provider quan trong:

| Provider | File | Type / Purpose |
| --- | --- | --- |
| `splashProvider` | `features/splash/providers/splash_provider.dart` | `NotifierProvider<SplashNotifier, SplashStatus>` |
| `loginControllerProvider` | `features/auth/providers/auth_provider.dart` | legacy `StateNotifierProvider<LoginController, AsyncValue<void>>` |
| `onboardingProvider` | `features/onboarding/providers/onboarding_provider.dart` | `NotifierProvider<OnboardingController, OnboardingState>` |
| `dashboardProvider` | `features/dashboard/providers/dashboard_provider.dart` | `FutureProvider<DashboardEntity>` |
| `dashboardControllerProvider` | `features/dashboard/presentation/controllers/dashboard_controller.dart` | `AsyncNotifierProvider<DashboardController, void>` |
| `mealPlanControllerProvider` | `features/meal_plan/presentation/controllers/meal_plan_controller.dart` | `AsyncNotifierProvider<MealPlanController, List<MealPlanEntity>>` |
| `dailyHealthTrackingControllerProvider` | `features/daily_health_tracking/providers/daily_health_tracking_provider.dart` | `AsyncNotifierProvider<DailyHealthTrackingController, DailyHealthTrackingState>` |
| `aiChatControllerProvider` | `features/ai_chat/presentation/controllers/ai_chat_controller.dart` | `NotifierProvider<AIChatController, AIChatState>` |
| `aiServiceProvider` | `services/ai/ai_service.dart` | `Provider<AIService>` |
| `aiChatServiceProvider` | `services/ai/ai_chat_service.dart` | `Provider<AIChatService>` |

Provider status after 2026-06-16 cleanup:

- `onboardingProvider` duplication appears resolved in current code; controller imports no provider declaration.
- `meal_plan` providers hien o `features/meal_plan/providers/meal_plan_provider.dart`; controller doc repository abstraction qua provider nay.

## Layer boundaries hien tai

Dang dung tot:

- `AIService.generateMealPlan` nhan `HealthDataInterface`, khong phu thuoc truc tiep `DashboardEntity`.
- `DashboardEntity implements HealthDataInterface`.
- `OnboardingLocalDatasource` da duoc doi ten dung local, doc/ghi SQLite.

Dang lech/tech debt:

- `OnboardingController` goi `onboardingCompletionCallbackProvider`; `main.dart` override callback nay de orchestration sau onboarding.
- `meal_plan` da flat o `features/meal_plan/{data,domain,presentation,providers}`.
- `MealPlanModel` nam trong `features/meal_plan/data/models/meal_plan_model.dart`.
- `AIService` van tra feature data models (`MealPlanModel`, `DailyHealthTaskModel`), nen service layer con biet chi tiet data model cua feature.
- `DashboardRepositoryImpl` nam trong `domain/repositories/`, nhung comment lai noi `data/repositories`.
- `DashboardController.genMealByWeeksToDB({bool requireComplete = false})` co mode bat buoc du 21 meal records cho onboarding completion.

## Main navigation

`MainNavigationPage` trong `features/dashboard/presentation/pages/menu_page.dart` la shell 4 tab:

1. `DashboardPage` - label `Hôm nay`.
2. `MealPlanPage` - label `Ăn gì`.
3. `HealthInsightsView` tu `features/other/presentation/pages/other_page.dart` - label `Góc của bạn`.
4. `SettingsView` - label `Tùy chỉnh`.

Shell co `AIChatFAB` o goc duoi phai, day sang `/ai-chat`.

## Barrel exports

- `features/auth/auth.dart` export login page.
- `features/dashboard/dashboard.dart` export dashboard page.
- `features/onboarding/onboarding.dart` export onboarding page.
- `features/splash/splash.dart` export splash page.
- `features/ai_chat/ai_chat.dart` export screen/controller/providers/entity.
- `core/core.dart` chi export app_router va route_names.

Dung barrel co san neu feature da co, nhung can coi lai vi nhieu barrel chua export du public API.
