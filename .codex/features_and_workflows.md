# Features And Workflows

## Product modules tu docs/DD

`docs/DD/DD_Module` mo ta 9 module product:

1. Profile Assessment: thu thap tinh trang suc khoe, tao ho so ca nhan.
2. Personalized MealPlan 30 Days: tao va hien thi thuc don 30 ngay.
3. MealPlan Storage: luu va tra cuu thuc don da sinh.
4. Cycle Refresh After 30 Days: ket thuc chu ky cu, nhap lai tinh trang, tao chu ky moi.
5. Daily Health Tracking: ghi nhan nhiem vu suc khoe hang ngay.
6. Weekly Summary Scoring: tong hop 7 ngay, chot diem thu 6 luc 21:00.
7. Health Assistant QA: hoi dap voi tro ly suc khoe.
8. Zalo Special Care Group: kenh cham soc ngoai app.
9. Health Knowledge Base: bai viet/video suc khoe.

Code hien tai moi thuc hien ro nhat module 1, mot phan module 2/3, mot phan module 7, dashboard UI cho module 5/6 o muc mock/hien thi.

## Authentication

Files:

- `features/auth/presentation/pages/login_pages.dart`
- `features/auth/presentation/controllers/login_controller.dart`
- `features/auth/providers/auth_provider.dart`
- `features/auth/data/datasource/auth_remote_datasource.dart`
- `features/auth/domain/repositories/auth_repository.dart`
- `features/auth/domain/repositories/auth_repository_impl.dart`

Flow login:

1. `LoginPage` co form email/password inline validation.
2. Submit -> `loginControllerProvider.notifier.login(...)`.
3. `LoginController` set `AsyncLoading`, goi `AuthRepository.login`.
4. `AuthRepositoryImpl` delegate `AuthRemoteDatasource.login`.
5. `AuthRemoteDatasource` goi `Supabase.instance.client.auth.signInWithPassword`.
6. `LoginPage` `ref.listen` neu success -> `context.go('/menu')`; neu error -> `SnackBar`.

Chua thay register/forgot password that, route `/register` dang `Placeholder`.

## Onboarding

Files chinh:

- `features/onboarding/presentation/pages/onboarding_page.dart`
- `features/onboarding/presentation/controllers/onboarding_controller.dart`
- `features/onboarding/domain/entities/onboarding_entity.dart`
- `features/onboarding/domain/repositories/onboarding_repository.dart`
- `features/onboarding/domain/repositories/onboarding_repository_impl.dart`
- `features/onboarding/data/datasource/onboarding_local_datasource.dart`
- `features/onboarding/data/models/onboarding_model.dart`
- `features/onboarding/presentation/widgets/*`

State:

- `OnboardingState.currentStep`: 0-6, tong 7 step.
- Basic user fields: email, phone, fullName, gender, birthYear, occupation, heightCm, weightKg.
- Health lists: goals, conditions, habits.
- Lifestyle: sleepQuality, activityLevel, waterPerDay.
- Extras: allergyName/note, treatmentName/medicationName/treatmentNote.
- `concernText`, `agreed`, `isSaving`, `savedLog`.

Step UI:

0. `WelcomeStep`
1. `BasicInfoStep`
2. `GoalsStep`
3. `ConditionsStep`
4. `LifestyleStep`
5. `ExtrasStep`
6. `ReviewStep`

Save flow in `OnboardingController.saveOnboarding()`:

1. Validate `agreed`.
2. Validate required fields qua `state.canSave`: fullName, gender, birthYear > 1900, occupation, agreed.
3. Set `isSaving`.
4. Convert `OnboardingState` -> `OnboardingEntity`.
5. `OnboardingRepository.save(entity)`.
6. `OnboardingLocalDatasource.saveOnboarding(entity)` luu SQLite transaction.
7. Goi truc tiep `dashboardControllerProvider.notifier.genMealByWeeksToDB()`.
8. `AppPrefs.setOnboardingCompleted(true)`.
9. Set `savedLog` success/error.

Can giu khi refactor: onboarding completion van phai trigger meal generation va set onboarding completed flag.

## Dashboard

Files chinh:

- `features/dashboard/presentation/pages/dashboard_page.dart`
- `features/dashboard/presentation/pages/menu_page.dart`
- `features/dashboard/providers/dashboard_provider.dart`
- `features/dashboard/presentation/controllers/dashboard_controller.dart`
- `features/dashboard/data/datasources/dashboard_local_datasource.dart`
- `features/dashboard/domain/entities/dashboard_entity.dart`

Data:

- `dashboardProvider` fetch `DashboardEntity` tu SQLite.
- Dashboard UI ket hop real data (name, bmi, height, weight, goals, conditions, sleepQuality, activityLevel, waterPerDay, concernText) va mock stats (`DashboardMockStats`) cho timeline/goals/insights.

UI sections:

- `HeroHeader`
- `HealthScoreCard`
- `QuickStatsGrid`
- `AiInsightSection`
- `DailyTimeline`
- `GoalProgressSection`
- `SmartLifestyleSection`
- `GoalChipsGrid`

Meal generation orchestration:

`DashboardController.genMealByWeeksToDB()`:

1. Read `dashboardRepositoryProvider`.
2. `repository.fetchDashboard()`.
3. Read `AIService` tu `aiServiceProvider`.
4. `aiService.generateMealPlan(healthData: dashboardData)`.
5. `repository.saveMealPlan(mealPlan)`.

Luu y: method co `print()` debug va read `nutritionPromptProvider` nhung bien `prompt` khong dung.

## Meal Plan

Files chinh:

- `features/meal_plan/dashboard/presentation/pages/meal_plan_page.dart`
- `features/meal_plan/dashboard/presentation/controllers/meal_plan_controller.dart`
- `features/meal_plan/dashboard/data/datasources/meal_datasource.dart`
- `features/meal_plan/dashboard/domain/repositories/meal_plan_repository.dart`
- `features/meal_plan/dashboard/domain/repositories/meal_plan_repository_impl.dart`
- `features/meal_plan/dashboard/providers/meal_plan_provider.dart`

Current behavior:

- `MealPlanController.build()` doc `MealPlanRepositoryImpl` va fetch all meal plans.
- `MealPlanDatasource.getMealByWeeks()` doc `MealPlansDao.getAll()`.
- `MealPlanPage` hien danh sach meal plan theo ngay.
- UI trich ngay kha dung bang `_extractAvailableDates`.
- Date parser ho tro ISO `DateTime.tryParse`, `YYYY-MM-DD`, va `DD/MM/YYYY`.
- Neu khong co meal: empty state.
- Co refresh indicator va nut refresh.

Meal card hien:

- meal type/name/description.
- calories, water, protein, carbs, fat, fiber.
- status badges.
- responsive helper `_MealPlanResponsiveUi`.

Tech debt:

- Folder nested `meal_plan/dashboard`.
- Providers duplicate.
- Presentation import datasource.
- `MealPlanModel` nam o core storage.

## AI Chat

Files:

- `features/ai_chat/domain/entities/chat_message_entity.dart`
- `features/ai_chat/data/models/chat_message_model.dart`
- `features/ai_chat/domain/repositories/ai_chat_repository.dart`
- `features/ai_chat/domain/repositories/ai_chat_repository_impl.dart`
- `features/ai_chat/providers/ai_chat_providers.dart`
- `features/ai_chat/presentation/controllers/ai_chat_controller.dart`
- `features/ai_chat/presentation/ai_chat_screen.dart`
- `shared/widgets/ai_chat_fab.dart`
- `services/ai/ai_chat_service.dart`

Flow:

1. User bam `AIChatFAB` trong `MainNavigationPage`.
2. `context.push(RoutePaths.aiChat)`.
3. Route `/ai-chat` co `authGuard`.
4. `AIChatScreen` watch `aiChatControllerProvider`.
5. Send message -> controller add user message vao state ngay.
6. Repository goi `AIChatService.sendMessage`.
7. `AIChatService` dung Gemini chat session voi system instruction tieng Viet.
8. Controller append AI message, stop loading.

Storage:

- Chat history chi in-memory trong `AIChatRepositoryImpl._history`.
- `clearHistory()` clear list va reset Gemini chat session.
- Khong persist chat vao SQLite.

AI assistant safety:

- System instruction yeu cau khong chan doan y te, khong thay the bac si, khuyen gap bac si neu nghiem trong.

## Settings

Files:

- `features/settings/domain/repositories/settings_repository.dart`
- `features/settings/data/datasources/settings_local_datasource.dart`
- `features/settings/data/datasources/settings_remote_datasource.dart`
- `features/settings/domain/entities/*`
- `features/settings/data/models/*`
- `features/settings/domain/validators/settings_validator.dart`
- `features/settings/utils/profile_validator.dart`
- `features/settings/presentation/pages/settings_page.dart`

Trang thai:

- Domain interface rat rong: profile, preferences, password, cache, meal plan delete, logout.
- Local datasource co thao tac that voi SQLite/SharedPreferences/cache.
- Remote datasource co password update va sign out Supabase.
- Chua co `SettingsRepositoryImpl`, provider hay controller noi UI voi datasource.
- `SettingsView` hien UI hardcoded; profile name hardcoded `Đào Văn Hùng`; switch/action dang no-op.

## Services phu

### Biometric

`services/biometric/biometric_service.dart`

- `BiometricService.isAvailable()`.
- `authenticate(reason)`.
- `getAvailableBiometrics()`.
- Throws `BiometricException`.
- Dung `local_auth`, `AuthenticationOptions(stickyAuth: true, biometricOnly: true)`.

### Image picker

`services/image_picker/image_picker_service.dart`

- `pickFromCamera()`: request `Permission.camera`, pick image.
- `pickFromGallery()`: request `Permission.photos`, pick image.
- `validateImage(XFile)`: allow png/jpg/jpeg va max 5MB.
- `saveImageLocally(XFile)`: copy vao app documents `avatars/avatar_<timestamp>.<ext>`.
- `getValidationError(XFile)`.

## Placeholder / unfinished pages

- `features/nutrition/presentation/pages/nutrition_page.dart`
- `features/sleep_tracking/presentation/pages/sleep_tracking_page.dart`
- `features/stress_tracking/presentation/pages/stress_tracking_page.dart`
- `features/profile/presentation/*`
- `features/community/presentation/pages/community_page.dart`
- `features/other/presentation/pages/other_page.dart` co view insight/mock.

Can doc file cu the truoc khi sua vi muc hoan thien khac nhau.
