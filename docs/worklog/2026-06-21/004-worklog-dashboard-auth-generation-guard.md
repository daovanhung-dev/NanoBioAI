Commit de xuat: fix(dashboard): chan tao lich trinh AI khi chua dang nhap

# Worklog Dashboard Auth Generation Guard

## Thoi gian

- Ngay: 2026-06-21
- Pham vi: Dashboard tao du lieu lich trinh AI 7 ngay, onboarding completion callback, test/docs.

## Muc tieu

- Khong cho tao du lieu moi cho lich trinh AI 7 ngay tren Dashboard neu chua co Supabase session.
- Khong chi chan UI; phai chan truoc khi goi AI va truoc khi ghi meal plan/schedule/reminder.
- Guest onboarding van duoc hoan tat, nhung skip buoc tao plan neu chua dang nhap.

## Da lam

- Them `DashboardGenerationAuthRequiredException` va helper `requireAuthenticatedGeneratedPlanUser`.
- `GeneratedPlanService.generateNextPlan()` kiem Supabase user truoc khi fetch dashboard/profile, goi AI, save meal plan, seed schedule hoac schedule reminder.
- `DashboardController.generateAdditionalPlan()` va `genMealByWeeksToDB()` kiem auth truoc khi tao du lieu.
- Dashboard page bat rieng exception thieu dang nhap va hien copy dang nhap cho Nabi.
- `main.dart` va `main_v2.dart` skip onboarding completion generated-plan callback neu chua co session.
- `OnboardingController` coi auth-required khi tao plan la skip hop le, khong lam fail guest onboarding.
- Them unit test dam bao unauthenticated generate khong goi AI/repository/datasource/reminder.

## Files chinh

- `lib/app_versions/v1/services/ai/generated_plan_service.dart`
- `lib/app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart`
- `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart`
- `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart`
- `lib/main.dart`
- `lib/main_v2.dart`
- `test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart`

## Kiem chung

- PASS - `flutter test test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart`: 2 tests pass.
- PASS - `flutter test test/features/dashboard test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart`: 13 tests pass.
- PASS - `flutter test test/architecture_version_boundary_test.dart test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart`: 9 tests pass.
- PASS - `dart format --set-exit-if-changed` tren cac file chinh vua sua: 0 changed.
- PARTIAL - `dart analyze` tren cac file chinh vua sua: chi con 16 info `withOpacity` nen trong `dashboard_page.dart`, khong co loi moi tu auth guard.

## Ghi chu

- Guard nay chi chan luong tao du lieu lich trinh AI 7 ngay. Cac action dashboard khac nhu mood/water/weight chua duoc mo rong trong task nay.
- Full repo analyzer van co lint nen da biet tu cac phien truoc.
