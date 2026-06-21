Commit de xuat: feat(auth): quan ly trang thai tai khoan bang Riverpod

# Riverpod Account State

## Muc tieu

- Dua trang thai tai khoan/auth route cua nguoi dung vao Riverpod controller thay vi FutureProvider mot lan.
- AuthGate, login/register/reset/callback doc va lam moi state qua cung mot controller.
- Settings thuc hien cac thao tac bao mat tai khoan qua Riverpod controller dung chung, khong khoi tao service truc tiep trong UI.

## Pham vi

- Bao gom:
  - `v2AuthControllerProvider` quan ly `AuthRouteState` bang `AsyncNotifier`.
  - Auth controller watch Supabase auth changes va resolve lai session/profile/onboarding status.
  - Auth pages goi controller notifier cho sign in, sign up, resend email, password recovery, reset password va callback recovery.
  - Settings goi `accountSecurityControllerProvider` cho update password, sign out va request delete account.
- Khong bao gom:
  - Khong doi schema Supabase/SQLite.
  - Khong doi business rule onboarding, email verification, membership tier.
  - Khong sua cac warning analyze nen ngoai pham vi.

## Luong hoat dong

1. App/AuthGate watch `v2AuthControllerProvider`.
2. Controller build state tu `AuthRepository.resolveAuthRouteState()`.
3. Controller watch `v2AuthChangesProvider` de auth event tu Supabase lam moi account state.
4. Sau thao tac tai khoan thanh cong, controller resolve lai route state.
5. Settings goi shared `accountSecurityControllerProvider`; controller set loading/error/data cho thao tac bao mat.

## Du lieu va luu tru

- Nguon doc: Supabase Auth session va `public.users` qua repository/datasource hien co.
- Noi ghi: khong them noi ghi moi; sign out/delete/update password dung service/repository hien co.
- Table/model/entity: `AuthRouteState`, `AuthProfile`, `AuthSessionSnapshot`.
- Migration/version: khong co.

## UI/UX

- Loading: `AuthGatePage` hien loading khi controller dang resolve/mutate account state.
- Empty: unauthenticated route ve login theo AuthGate.
- Error: AuthGate hien support state than thien va retry qua `AuthController.refresh()`.
- Success: route theo state da resolve: verify email, onboarding hoac menu.

## Files

- `lib/app_versions/v2/features/auth/presentation/controllers/auth_controller.dart` - doi thanh Riverpod `AsyncNotifier<AuthRouteState>`.
- `lib/app_versions/v2/features/auth/providers/auth_dependencies.dart` - tach dependency provider de controller doc repository.
- `lib/app_versions/v2/features/auth/providers/auth_providers.dart` - khai bao `AsyncNotifierProvider`.
- `lib/app_versions/v2/features/auth/presentation/pages/auth_gate_page.dart` - watch account controller.
- `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` - goi controller notifier.
- `lib/app_versions/v2/features/auth/domain/entities/auth_route_state.dart` - bo sung email cho state da xac thuc/pending.
- `lib/app_versions/v2/features/auth/domain/services/auth_route_state_resolver.dart` - truyen email tu session vao state.
- `lib/services/supabase/auth/account_security_provider.dart` - controller Riverpod dung chung cho security actions.
- `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart` - dung security controller thay vi khoi tao service truc tiep.

## Kiem chung

- Command: `dart format ...`
- Ket qua: PASS.
- Command: `flutter test test\app_versions\v2\features\auth test\architecture_version_boundary_test.dart`
- Ket qua: PASS, 27 tests pass.
- Command: `flutter analyze`
- Ket qua: FAIL do 287 warning/info nen co san o cac module v1/core/test; khong thay issue moi trong cac file auth/settings/provider vua sua.

## Lien ket

- Worklog: [005-worklog-riverpod-account-state](../../worklog/2026-06-21/005-worklog-riverpod-account-state.md)
- Test: [002-test-riverpod-account-state](../../test/authentication/002-test-riverpod-account-state.md)

## Rui ro

- Can manual smoke voi Supabase that cho login/logout/delete request vi unit test hien tai khong goi backend that.
- Analyze toan repo van dang do do warning/info ngoai pham vi.
