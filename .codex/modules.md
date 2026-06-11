# Modules

## Module map

| Module | Vai trò | Trạng thái |
|---|---|---|
| `splash` | Khởi động app, routing theo onboarding flag | ✅ Hoàn chỉnh |
| `auth` | Đăng nhập Supabase email/password | ✅ Cơ bản xong |
| `onboarding` | Wizard 7 bước thu thập health info → lưu SQLite | ✅ Hoàn chỉnh |
| `dashboard` | Tổng quan, fetch health data local, trigger AI meal gen | ✅ Cơ bản xong |
| `meal_plan` | Hiển thị meal plan 7 ngày từ SQLite | ✅ Cơ bản xong |
| `ai_chat` | AI health chat assistant | 🚧 Placeholder |
| `nutrition` | Theo dõi calories/meals | 🚧 Placeholder |
| `profile` | Hồ sơ người dùng | 🚧 Placeholder |
| `settings` | Cài đặt app | 🚧 Placeholder |
| `sleep_tracking` | Theo dõi giấc ngủ | 🚧 Placeholder |
| `stress_tracking` | Theo dõi stress | 🚧 Placeholder |
| `community` | Cộng đồng | 🚧 Placeholder |

## Core modules (lõi, không thể thiếu)
- `core/storage/localdb` — database layer cho toàn hệ thống
- `core/router` — navigation cho toàn hệ thống
- `core/theme` — design system
- `services/ai` — AI service dùng bởi `dashboard` module

## Module dependencies

```
splash
  └── depends on: core/storage/localdb (AppPrefs), core/router

auth
  └── depends on: services/supabase, core/router

onboarding
  ├── depends on: core/storage/localdb (DatabaseService, tables)
  └── after save → calls: dashboard (dashboardControllerProvider.genMealByWeeksToDB)

dashboard
  ├── depends on: core/storage/localdb (fetch all health data)
  └── depends on: services/ai (AIService.generateMealPlan)

meal_plan
  └── depends on: core/storage/localdb (MealPlansDao)

services/ai
  └── depends on: features/dashboard (DashboardEntity dùng làm input)

services/supabase
  └── độc lập, wrap Supabase.instance.client
```

## Luồng phụ thuộc quan trọng

`onboarding` → save SQLite → gọi `dashboard` controller → gọi `services/ai` → lưu meal plan → `meal_plan` đọc ra

Đây là luồng duy nhất cross-feature trực tiếp. Nếu sửa `OnboardingController.saveOnboarding()`, phải chú ý dependency này.
