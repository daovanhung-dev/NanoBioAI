Commit de xuat: feat(auth): toi uu luong auth he thong

# Worklog Auth System Flow

## Thoi gian

- Ngay: 2026-06-21
- Pham vi: auth routing, AuthGate data flow, auth presentation controller, docs/test traceability.

## Muc tieu

- Dua production entrypoint sang `BioAIV2App/v2Router` de auth v2 la luong he thong chinh.
- Giu guest/basic v1: user chua dang nhap van di Splash -> Onboarding/Menu theo local flow.
- Dua user da co Supabase session vao AuthGate de route theo session/email/profile/onboarding.
- Doc them `subscription_tier` tu `public.users` nhu hook tin cay toi thieu, default `free`.
- Khong mo quota/entitlement Free/Plus/FamilyPlus trong task nay.

## Da lam

- Doi `lib/main.dart` sang `BioAIV2App`.
- Them route constants dung chung tai `lib/core/constants/routes/auth_route_paths.dart`.
- Tach logic Splash route thanh service thuan `SplashRouteDecision`.
- Cap nhat Splash: co Supabase session -> AuthGate; khong co session -> local guest onboarding/menu.
- Cap nhat v1 auth entry, settings va route guards dung auth route constants, khong hard-code `/v2/auth...` rai rac.
- Cap nhat `V1RouteGuards`: guard chi kiem session presence va tra ve AuthGate/login, khong tu quyet dashboard.
- Mo rong `AuthProfile` va `AuthRouteState` voi `subscriptionTier`.
- Cap nhat Supabase datasource select `id,onboarding_status,subscription_tier`.
- Them `AuthController` presentation layer va provider; auth pages goi controller thay vi repository truc tiep.
- Cap nhat boundary/contract/unit tests cho entrypoint v2, route constants, no baseline profile insert, `subscriptionTier`, Splash decision.

## Files chinh

- `lib/main.dart`
- `lib/core/constants/routes/auth_route_paths.dart`
- `lib/app_versions/v1/features/splash/domain/services/splash_route_decision.dart`
- `lib/app_versions/v1/features/splash/presentation/pages/splash_page.dart`
- `lib/app_versions/v1/router/v1_navigation_service.dart`
- `lib/app_versions/v1/router/v1_route_guards.dart`
- `lib/app_versions/v2/features/auth/domain/entities/auth_profile.dart`
- `lib/app_versions/v2/features/auth/domain/entities/auth_route_state.dart`
- `lib/app_versions/v2/features/auth/domain/services/auth_route_state_resolver.dart`
- `lib/app_versions/v2/features/auth/data/datasources/supabase_auth_remote_datasource.dart`
- `lib/app_versions/v2/features/auth/presentation/controllers/auth_controller.dart`
- `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart`
- `lib/app_versions/v2/features/auth/providers/auth_providers.dart`
- `test/app_versions/v1/features/splash/splash_route_decision_test.dart`
- `test/app_versions/v2/features/auth/auth_flow_contract_test.dart`
- `test/app_versions/v2/features/auth/auth_route_state_resolver_test.dart`
- `test/architecture_version_boundary_test.dart`

## Kiem chung

- PASS - `dart format --set-exit-if-changed .` sau lan format cuoi: 386 files, 0 changed.
- PASS - `flutter test test\app_versions\v2\features\auth test\app_versions\v1\features\splash test\architecture_version_boundary_test.dart`: 29 tests pass.
- PASS - `powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1`: script exit 0, `QUICK CHECK PASSED`, full suite pass 290 tests.
- FAIL - `flutter analyze`: 287 warning/info lint nen hien co cua repo.

## Khong lam trong scope

- Khong deploy/chay SQL Supabase.
- Khong chay RLS smoke, email redirect, recovery link, Edge Function delete-account.
- Khong trien khai quota/entitlement Free/Plus/FamilyPlus day du.

## Ghi chu

- Repo da co dirty worktree truoc task; chi cac thay doi lien quan auth/docs/test duoc cap nhat trong worklog nay.
- `subscription_tier` hien chi la snapshot doc tu Supabase de san sang noi voi module membership sau nay.
