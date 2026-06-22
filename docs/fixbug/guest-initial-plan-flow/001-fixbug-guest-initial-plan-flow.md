Commit de xuat: fix(onboarding): cho guest tao lich dau tien sau onboarding

# Fixbug - Guest initial plan flow

## Van de

Guest hoan tat onboarding nhung flow tao lich ca nhan dau tien bi bo qua khi
chua co Supabase user. `AppPrefs.setOnboardingCompleted(true)` van co the chay,
lam guest vao app ma chua co lich ca nhan dau tien.

## Root cause

- `main.dart` va `main_v2.dart` return som trong onboarding callback khi
  `currentSupabaseUserIdOrNull() == null`.
- `GeneratedPlanService.generateNextPlan()` bat buoc authenticated user, chua
  co API rieng cho initial guest generation.
- `onboarding_controller.dart` catch auth-required exception va tiep tuc mark
  onboarding completed.
- Guest route allowlist chua tap trung, route nhu `community` co the mo bang
  deep-link.

## Fix

- Them `GeneratedPlanService.generateInitialGuestPlan()` cho guest initial
  schedule, khong dung Supabase auth gate.
- Giu `generateNextPlan()` authenticated-only cho additional generation.
- Doi onboarding callback sang `OnboardingCompletionResult`; controller chi set
  completed khi `generatedInitialPlan == true`.
- Them centralized guest allowlist guard cho `v1Router` va `v2Router`.
- Mo rong regression tests cho generated plan, onboarding completion, route
  allowlist, va auth cloud sync route-ready.

## Validation

- `flutter test test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart test/app_versions/v1/router/v1_route_guards_test.dart test/app_versions/v2/features/cloud_sync/authenticated_user_data_sync_repository_test.dart test/app_versions/v2/features/auth/auth_route_state_resolver_test.dart`: PASS.

## Con lai

- Free quota, membership entitlement, FamilyPlus, Sale/referral van
  Blocked/Planned cho toi khi DD Q-01..Q-10 va Supabase sandbox/staging
  verification duoc dong.
