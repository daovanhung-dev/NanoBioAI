# Repository Structure

## Cây thư mục cấp cao

```
nano_app/
├── lib/
│   ├── main.dart                    ← Entry point
│   ├── app/app.dart                 ← BioAIApp widget
│   ├── core/                        ← Nền tảng hệ thống
│   │   ├── constants/               ← RoutePaths, enums, keys
│   │   ├── network/dio_provider.dart
│   │   ├── router/                  ← GoRouter, RouteGuards, AppNavigator
│   │   ├── storage/localdb/         ← SQLite: tables, daos, models, migrations
│   │   ├── theme/                   ← AppColors, AppTheme, AppTextStyles, design tokens
│   │   └── utils/                   ← [trống]
│   ├── features/
│   │   ├── splash/                  ← SplashPage, SplashNotifier, AppPrefs routing
│   │   ├── auth/                    ← Login (Supabase email/password)
│   │   ├── onboarding/              ← 7-step wizard → save SQLite → trigger AI meal gen
│   │   ├── dashboard/               ← Tổng quan sức khỏe, fetch local data
│   │   ├── meal_plan/dashboard/     ← Hiển thị meal plan từ SQLite
│   │   ├── ai_chat/                 ← [placeholder]
│   │   ├── nutrition/               ← [placeholder page]
│   │   ├── profile/                 ← [placeholder page]
│   │   ├── settings/                ← [placeholder page]
│   │   ├── community/               ← [placeholder page]
│   │   ├── sleep_tracking/          ← [placeholder page]
│   │   ├── stress_tracking/         ← [placeholder page]
│   │   └── other/                   ← [placeholder page]
│   ├── services/
│   │   ├── ai/                      ← AIService (Gemini), NutritionPrompt
│   │   ├── supabase/                ← SupabaseService, AuthService
│   │   └── notification/            ← [trống]
│   └── shared/widgets/              ← HealthCard, LoadingGenAI
├── assets/                          ← fonts, icons, audio, animations (phần lớn .gitkeep)
├── docs/                            ← changelog, issues, todo
├── android/, ios/, web/, linux/...  ← platform configs
├── pubspec.yaml
└── .env                             ← SUPABASE_URL, SUPABASE_ANON_KEY, GEMINI_API_KEY
```

## Thư mục quan trọng

### `lib/core/storage/localdb/`
Toàn bộ SQLite layer:
- `database_service.dart` — singleton `DatabaseService`, khởi tạo DB
- `tables/*.dart` — CREATE TABLE SQL
- `daos/*.dart` — CRUD operations
- `models/*.dart` — Dart model map ↔ SQLite row
- `migrations/migration_v1.dart` — hiện trống (version 1)
- `app_prefs.dart` — `SharedPreferences` lưu flag `onboarding_completed`

### `lib/core/router/`
- `app_router.dart` — định nghĩa toàn bộ GoRouter routes
- `route_guards.dart` — `authGuard` (chặn nếu chưa login), `guestGuard` (redirect nếu đã login)
- `navigation_service.dart` — `AppNavigator` static helpers

### `lib/features/onboarding/`
Feature hoàn chỉnh nhất hiện tại — có đủ data/domain/presentation/providers.

### `lib/services/ai/`
- `ai_service.dart` — gọi Gemini API, parse JSON response thành `List<MealPlanModel>`
- `prompts/nutrition_prompt.dart` — xây dựng prompt tiếng Việt cho meal plan 7 ngày

## Files không quan trọng (bỏ qua khi đọc)
- `assets/*/. gitkeep` — placeholder
- `lib/core/utils/.gitkeep` — trống
- `lib/features/*/. gitkeep` — placeholder feature chưa triển khai
- `.dart_tool/`, `build/` — generated
