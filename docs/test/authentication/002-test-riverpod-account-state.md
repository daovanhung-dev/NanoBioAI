Commit de xuat: test(auth): kiem chung riverpod account state

# Test - Riverpod Account State

## Pham vi

- Loai test: format, auth v2 test, architecture boundary, analyze.
- Module: Authentication v2, Settings account security.
- Case bao gom:
  - Auth pages delegate action qua `v2AuthControllerProvider.notifier`.
  - Account route state duoc quan ly bang `AsyncNotifierProvider<AuthController, AuthRouteState>`.
  - Settings account security action di qua `accountSecurityControllerProvider`.
  - Resolver giu email/subscription tier trong state.
  - Boundary v1/v2/sale/core khong bi pha.
- Case chua bao gom:
  - Manual login/logout voi Supabase that.
  - Edge Function delete-account that.

## Moi truong

- OS: Windows
- Flutter/Dart: theo workspace hien tai
- Device/emulator: khong dung emulator trong test nay

## Commands/Kich ban

- `dart format lib\app_versions\v2\features\auth\providers\auth_dependencies.dart lib\app_versions\v2\features\auth\providers\auth_providers.dart lib\app_versions\v2\features\auth\presentation\controllers\auth_controller.dart lib\app_versions\v2\features\auth\presentation\pages\auth_gate_page.dart lib\app_versions\v2\features\auth\presentation\pages\auth_pages.dart lib\app_versions\v2\features\auth\domain\entities\auth_route_state.dart lib\app_versions\v2\features\auth\domain\services\auth_route_state_resolver.dart test\app_versions\v2\features\auth\auth_flow_contract_test.dart test\app_versions\v2\features\auth\auth_route_state_resolver_test.dart`
- `dart format lib\services\supabase\auth\account_security_provider.dart lib\app_versions\v1\features\settings\presentation\pages\settings_page.dart test\app_versions\v2\features\auth\account_security_contract_test.dart`
- `flutter test test\app_versions\v2\features\auth test\architecture_version_boundary_test.dart`
- `flutter analyze`

## Ket qua

- PASS - format touched Dart files.
- PASS - targeted auth + architecture tests: 27 tests passed.
- FAIL - `flutter analyze`: 287 warning/info nen co san, vi du deprecated `withOpacity`, `curly_braces_in_flow_control_structures`, unused helpers trong core models; khong phat hien issue moi trong file vua sua.

## Lien ket

- Worklog: [005-worklog-riverpod-account-state](../../worklog/2026-06-21/005-worklog-riverpod-account-state.md)
- Feature: [003-feature-riverpod-account-state](../../features/authentication/003-feature-riverpod-account-state.md)

## Rui ro

- Can chay smoke tren app that sau khi Supabase env san sang de xac nhan auth event stream, logout va delete request end-to-end.
