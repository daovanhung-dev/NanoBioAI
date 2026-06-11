# Workflows

## 1. App Startup Flow

1. `main()`: load `.env` → `Supabase.initialize()` → `runApp(ProviderScope(BioAIApp))`
2. `BioAIApp`: `MaterialApp.router` với `appRouter` (GoRouter)
3. `appRouter.initialLocation = '/'` → `SplashPage`
4. `SplashPage.initState`: gọi `splashProvider.initialize()` (hardcode `onboardingRequired`)
5. Sau đó gọi `AppPrefs.isOnboardingCompleted()`:
   - `true` → `AppNavigator.goDashboard()`
   - `false` → `AppNavigator.goOnboarding()`

---

## 2. Onboarding Flow

1. User mở app lần đầu → `OnboardingPage` load
2. `onboardingProvider` khởi tạo `OnboardingState` (step = 0)
3. User đi qua 7 bước (WelcomeStep → BasicInfoStep → GoalsStep → ConditionsStep → LifestyleStep → ExtrasStep → ReviewStep)
4. Mỗi field update gọi `controller.updateXxx(value)` → `state.copyWith(...)`
5. `ReviewStep`: user tick "Đồng ý" → `controller.setAgreed(true)` → `canSave == true`
6. User nhấn Save → `controller.saveOnboarding()`:
   - `_repository.save(state.toEntity())` → `OnboardingRemoteDatasource.saveOnboarding()`
   - Mở `db.transaction()`: upsert user + insert 7 bảng con
   - Sau thành công: gọi `ref.read(dashboardControllerProvider.notifier).genMealByWeeksToDB()`
7. `genMealByWeeksToDB()`:
   - Fetch `DashboardEntity` từ SQLite
   - Build AI prompt (`NutritionPrompt.generateMealPlan`)
   - Gọi Gemini API → nhận JSON → parse `List<MealPlanModel>`
   - Lưu vào `meal_plans` table
8. `AppPrefs.setOnboardingCompleted(true)` [INFERRED - chưa thấy trong code hiện tại]
9. Navigate → Dashboard

---

## 3. Login Flow

1. User tại `/login` → nhập email + password
2. `LoginController.login()` → `state = AsyncLoading`
3. Gọi `AuthRepositoryImpl.login()` → `AuthRemoteDatasource.login()` → Supabase
4. Thành công: `state = AsyncData(null)` → UI navigate (logic trong Page)
5. Thất bại: `state = AsyncError(e, st)` → UI hiển thị error

---

## 4. Meal Plan Generation Flow (AI)

```
OnboardingController.saveOnboarding()
  → DashboardController.genMealByWeeksToDB()
    → DashboardRepository.fetchDashboard()
      → DashboardLocalDatasource.fetchDashboard()
        → SQLite: query users + 6 bảng liên quan
        → return DashboardEntity
    → NutritionPrompt.generateMealPlan(healthData)
      → return String prompt (tiếng Việt)
    → AIService.generateMealPlan(healthData)
      → gọi Gemini API với prompt
      → parse JSON response → List<MealPlanModel>
      → retry tối đa 3 lần nếu lỗi
    → DashboardRepository.saveMealPlan(mealPlan)
      → DashboardLocalDatasource.saveMealPlan()
        → MealPlansDao.insertMany()
```

---

## 5. View Meal Plan Flow

1. User navigate đến `/meal-plan`
2. `getMealPlanProvider` (FutureProvider) auto-trigger
3. `MealPlanRepositoryImpl.getMealByWeeks()` → `MealPlanDatasource.getMealByWeeks()` → `MealPlansDao.getAll()`
4. Trả về `List<MealPlanModel>` sorted by `plan_date ASC`
5. `MealPlanPage` render danh sách

---

## 6. Route Guard Flow

```
User navigate → GoRouter check redirect
  authGuard: user == null → go '/login'
  guestGuard: user != null → go '/dashboard'
  no guard: navigate trực tiếp
```
