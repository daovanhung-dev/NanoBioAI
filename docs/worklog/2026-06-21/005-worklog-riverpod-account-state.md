Commit de xuat: docs(worklog): ghi nhan phien riverpod account state

# Worklog - Riverpod Account State

## Thoi gian

- Ngay: 2026-06-21
- Bat dau: khoang 17:00
- Ket thuc: 17:40
- Timezone: Asia/Saigon (+07:00)

## Pham vi

- Loai task: coding
- Module chinh: Authentication v2, Settings account security
- Yeu cau goc: "Toi muon riverpod quan ly trang thai tai khoan cua nguoi dung"

## Da lam

- Doc `.codex` core context, workRule develop, playbook access/membership/referral, BD/DD authentication lien quan AuthGate/session/layer contracts.
- Tach dependency provider cua auth v2 sang `auth_dependencies.dart`.
- Doi `AuthController` thanh `AsyncNotifier<AuthRouteState>` de Riverpod nam state tai khoan/auth route.
- Doi `v2AuthControllerProvider` thanh `AsyncNotifierProvider`.
- Cho AuthGate watch controller va retry bang `AuthController.refresh()`.
- Doi auth pages goi `v2AuthControllerProvider.notifier`.
- Bo sung email vao `AuthRouteState` cho cac state da co session.
- Them `accountSecurityControllerProvider` dung chung cho update password, sign out, request delete account.
- Doi Settings dung shared Riverpod controller thay vi khoi tao `AccountSecurityService()` truc tiep.
- Cap nhat contract tests va `.codex/MAP_TREE.md`.

## File code/docs da sua

- `lib/app_versions/v2/features/auth/providers/auth_dependencies.dart` - tao - tach provider dependency.
- `lib/app_versions/v2/features/auth/providers/auth_providers.dart` - sua - khai bao account state controller provider.
- `lib/app_versions/v2/features/auth/presentation/controllers/auth_controller.dart` - sua - chuyen thanh AsyncNotifier.
- `lib/app_versions/v2/features/auth/presentation/pages/auth_gate_page.dart` - sua - watch controller state.
- `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` - sua - goi controller notifier.
- `lib/app_versions/v2/features/auth/domain/entities/auth_route_state.dart` - sua - them email/subscription state.
- `lib/app_versions/v2/features/auth/domain/services/auth_route_state_resolver.dart` - sua - map email tu session.
- `lib/services/supabase/auth/account_security_provider.dart` - tao - Riverpod controller cho account security actions.
- `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart` - sua - dung account security controller.
- `test/app_versions/v2/features/auth/auth_flow_contract_test.dart` - sua - them contract Riverpod account state.
- `test/app_versions/v2/features/auth/auth_route_state_resolver_test.dart` - sua - them assertion email/subscription tier.
- `test/app_versions/v2/features/auth/account_security_contract_test.dart` - sua - them contract Settings dung Riverpod controller.
- `.codex/MAP_TREE.md` - sua - cap nhat file moi.
- `docs/features/authentication/003-feature-riverpod-account-state.md` - tao - mo ta feature.
- `docs/test/authentication/002-test-riverpod-account-state.md` - tao - ghi ket qua test.
- `docs/worklog/2026-06-21/005-worklog-riverpod-account-state.md` - tao - ghi nhan phien.

## Tai lieu lien quan

- [Feature - Riverpod Account State](../../features/authentication/003-feature-riverpod-account-state.md)
- [Test - Riverpod Account State](../../test/authentication/002-test-riverpod-account-state.md)

## Commands

- `dart format ...auth/settings/test touched files`: PASS.
- `flutter test test\app_versions\v2\features\auth test\architecture_version_boundary_test.dart`: PASS - 27 tests pass.
- `flutter analyze`: FAIL - 287 warning/info nen co san ngoai pham vi; khong thay issue moi trong file vua sua.

## Loi/Rui ro

- Da fix: AuthGate/auth pages va Settings account security khong con quan ly account flow bang direct wrapper/FutureProvider roi rac.
- Chua fix: warning/info analyze nen o v1/core/test.
- Can kiem tra tiep: manual Supabase smoke cho login/logout/delete request va auth event stream.
