# Features

## Splash
**Mục đích**: Khởi động app, animate logo, kiểm tra onboarding flag rồi điều hướng.

- **Input**: `SharedPreferences` key `onboarding_completed`
- **Output**: Navigate → `/onboarding` (chưa done) hoặc `/dashboard` (đã done)
- **Logic**: `SplashPage.initState` → gọi `splashProvider.initialize()` → `AppPrefs.isOnboardingCompleted()` → `AppNavigator.go*`
- **Note**: `SplashNotifier.initialize()` hiện hardcode `state = SplashStatus.onboardingRequired`, chưa check auth thực

---

## Auth — Login
**Mục đích**: Đăng nhập bằng email/password qua Supabase.

- **Input**: email (String), password (String)
- **Output**: Supabase session hoặc error
- **Flow**: `LoginPage` → `loginControllerProvider` → `LoginController.login()` → `AuthRepositoryImpl.login()` → `AuthRemoteDatasource.login()` → `supabase.auth.signInWithPassword()`
- **State**: `AsyncValue<void>` — `AsyncLoading` → `AsyncData(null)` | `AsyncError`
- **Guard**: `RouteGuards.guestGuard` redirect về `/dashboard` nếu đã login

---

## Onboarding (feature chính, đầy đủ nhất)
**Mục đích**: Thu thập thông tin sức khỏe người dùng qua 7 bước → lưu SQLite → sinh meal plan AI.

**7 bước (step index 0–6)**:
| Step | Widget | Nội dung |
|---|---|---|
| 0 | `WelcomeStep` | Màn hình chào |
| 1 | `BasicInfoStep` | Họ tên, email, SĐT, giới tính, năm sinh, nghề nghiệp, chiều cao, cân nặng |
| 2 | `GoalsStep` | Chọn mục tiêu sức khỏe (toggle multi-select, 15 loại) |
| 3 | `ConditionsStep` | Chọn tình trạng sức khỏe (14 loại) |
| 4 | `LifestyleStep` | Thói quen ăn uống (9 habit flags), chất lượng ngủ, mức vận động, lượng nước |
| 5 | `ExtrasStep` | Dị ứng thực phẩm, điều trị y tế |
| 6 | `ReviewStep` | Xem lại + đồng ý điều khoản → Save |

- **Input**: Form fields trong `OnboardingState`
- **Output**: Ghi vào 7 bảng SQLite + trigger `genMealByWeeksToDB`
- **Validation `canSave`**: `fullName` + `gender` + `birthYear > 1900` + `occupation` + `agreed == true`
- **BMI**: tính inline từ `heightCm` và `weightKg`

---

## Dashboard
**Mục đích**: Hiển thị tổng quan sức khỏe người dùng từ dữ liệu SQLite.

- **Input**: Đọc từ SQLite (users, health_profiles, health_goals, conditions, lifestyle, allergies, treatments, surveys)
- **Output**: `DashboardEntity` hiển thị lên UI
- **Controller**: `DashboardController.genMealByWeeksToDB()` — orchestrate AI meal generation
- **Note**: Dashboard UI đang chứa nhiều widget trong 1 file (xem `docs/issues/ui_issues_dashboard.md`), có plan refactor nhưng chưa thực hiện

---

## Meal Plan
**Mục đích**: Hiển thị kế hoạch ăn 7 ngày do AI sinh ra từ health profile.

- **Input**: `MealPlanModel` records từ SQLite (`meal_plans` table)
- **Output**: List meal plans theo ngày/bữa
- **Trigger generate**: sau `onboarding.saveOnboarding()` → `DashboardController.genMealByWeeksToDB()`
- **AI flow**: `AIService.generateMealPlan(healthData)` → Gemini API → parse JSON → `List<MealPlanModel>` → `MealPlansDao.insertMany()`
- **Retry**: AI service tự retry tối đa 3 lần nếu lỗi, return `[]` nếu fail

---

## Features chưa triển khai (placeholder)
- `ai_chat` — page trống, route có `authGuard`
- `nutrition` — page trống, route có `authGuard`
- `profile` — page trống, route có `authGuard`
- `settings`, `sleep_tracking`, `stress_tracking`, `community` — page trống
