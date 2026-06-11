# API Reference

## Kiến trúc API

Ứng dụng này **không có REST API backend tự xây**. Tất cả external calls đi qua:
1. **Supabase** — authentication
2. **Google Gemini API** — AI meal plan generation

---

## Supabase Auth API (via `supabase_flutter`)

### Login
- **Method**: `supabase.auth.signInWithPassword(email, password)`
- **Dùng tại**: `AuthRemoteDatasource.login()`
- **Response**: `AuthResponse` (Supabase SDK)

### Register
- **Method**: `SupabaseService.client.auth.signUp(email, password)`
- **Dùng tại**: `AuthService.signUp()` — hiện chưa có UI register
- **Endpoint thực tế**: `https://rnwohifdnylqfofkydfl.supabase.co`

### Sign Out
- **Method**: `SupabaseService.client.auth.signOut()`
- **Dùng tại**: `AuthService.signOut()`

### Check current user
- **Method**: `Supabase.instance.client.auth.currentUser`
- **Dùng tại**: `RouteGuards.authGuard`, `RouteGuards.guestGuard`

---

## Gemini AI API

### Generate Meal Plan
- **Endpoint**: `https://generativelanguage.googleapis.com/v1beta`
- **Model**: `gemini-2.5-flash` (từ `.env`)
- **SDK**: `google_generative_ai` (không dùng raw HTTP)
- **Dùng tại**: `AIService.generateMealPlan(healthData: DashboardEntity)`
- **Input**: `DashboardEntity` → build thành prompt text (NutritionPrompt.generateMealPlan)
- **Output**: `List<MealPlanModel>` (parse từ raw JSON response)
- **Timeout**: connect 30s, receive 60s
- **Retry**: tối đa 3 lần, delay tăng dần (2s, 4s)

### Prompt structure (NutritionPrompt)
Prompt được viết bằng tiếng Việt, yêu cầu AI trả về pure JSON array theo schema `meal_plans`. Dữ liệu đầu vào: `fullName`, `bmi`, `goals`, `conditions`, `habits`, `sleepQuality`, `activityLevel`, `waterPerDay`, `concernText`.

---

## Routes / Navigation (GoRouter — internal)

| Route | Path | Guard | Page |
|---|---|---|---|
| splash | `/` | — | `SplashPage` |
| login | `/login` | guestGuard | `LoginPage` |
| register | `/register` | — | `Placeholder` |
| dashboard | `/dashboard` | — (guard tắt) | `DashboardPage` |
| onboarding | `/onboarding` | — | `OnboardingPage` |
| menu | `/menu` | — | `MainNavigationPage` |
| meal-plan | `/meal-plan` | — | `MealPlanPage` |
| ai-chat | `/ai-chat` | authGuard | `Placeholder` |
| nutrition | `/nutrition` | authGuard | `Placeholder` |
| profile | `/profile` | authGuard | `Placeholder` |

**authGuard**: redirect về `/login` nếu `Supabase.currentUser == null`  
**guestGuard**: redirect về `/dashboard` nếu đã login  
**Note**: Dashboard route hiện có `authGuard` bị comment out → không cần login để xem dashboard
