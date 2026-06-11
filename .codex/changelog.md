# Changelog

## Trạng thái khởi tạo .codex
Tài liệu này được tạo từ trạng thái code hiện tại (June 2026).

---

## v0.1.0 (từ `docs/changelog/changelog.md`)
- Setup project structure (Feature-first + Clean Architecture)
- Setup dashboard UI
- Setup theme system (`AppColors`, `AppTheme`, design tokens)
- Setup feature-first architecture
- Fix: `login_ui_refactor_issue`

---

## Thay đổi kiến trúc đáng chú ý (suy ra từ code)

### SQLite schema v1
- 14 bảng: users, health_profiles, health_goals, health_conditions, lifestyle_habits, food_allergies, medical_treatments, health_tracking_logs, nutrition_logs, ai_insights, ai_recommendations, notifications, survey_answers, meal_plans
- Migration v1 tồn tại nhưng trống — schema tạo toàn bộ trong `onCreate`

### AI Meal Plan integration
- `AIService` dùng `google_generative_ai` SDK với model `gemini-2.5-flash`
- Prompt tiếng Việt, output JSON 7 ngày × 3 bữa
- Retry logic 3 lần

### Onboarding flow
- 7 bước wizard với `AnimatedSwitcher`
- `OnboardingState` immutable với `copyWith`
- Post-save trigger meal plan generation

### Pending issues (từ `docs/issues/`)
- `ui_issues_dashboard.md`: Dashboard cần tách thành nhiều widget components (status: Pending)
- `login_ui_refactor_issue`: Đã fix (v0.1.0)

### Features chưa hoàn thiện
- `ai_chat`, `nutrition`, `profile`, `settings`, `sleep_tracking`, `stress_tracking`, `community` — tất cả là placeholder pages
- `SplashNotifier.initialize()` chưa implement auth check thực sự (hardcode `onboardingRequired`)
- `AppPrefs.setOnboardingCompleted(true)` chưa được gọi sau khi onboarding hoàn thành [cần kiểm tra]
