Commit de xuat: test(auth): kiem chung authentication v2

# Test Authentication V2

## Pham vi

- Loai test: unit/widget/targeted regression.
- Module: authentication v2, onboarding lifecycle, dashboard user selection, daily health tracking user selection.
- Case bao gom: route-state mapping, auth validators, auth page smoke render, v1/v2 architecture boundary, architecture preservation guard cap nhat UUID, onboarding widget regression, dashboard/daily tracking targeted tests.
- Cap nhat 2026-06-21: production entrypoint v2, Splash route decision, shared auth route constants, AuthController presentation flow, `subscription_tier` resolver.
- Case chua bao gom: manual Supabase email verification, RLS two-account smoke, Edge Function delete account.

## Moi truong

- OS: Windows / PowerShell.
- Flutter/Dart: theo `pubspec.yaml`, SDK `^3.9.2`.
- Device/emulator: test runner local.

## Commands/Kich ban

- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test test\app_versions\v2\features\auth test\app_versions\v1\features\splash test\architecture_version_boundary_test.dart`
- `flutter test test\architecture_preservation_property_test.dart test\app_versions\v2\features\auth test\architecture_version_boundary_test.dart test\widget_test.dart test\features\dashboard test\features\daily_health_tracking`
- `flutter test test\app_versions\v2\features\auth test\features\settings test\architecture_version_boundary_test.dart`
- `flutter test test\features\features_hub\features_hub_page_test.dart`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .codex\tool\codex_quick_check.ps1`
- `powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1`

## Ket qua hien tai

- PASS - 2026-06-21 format check: 386 files, 0 changed sau lan format cuoi.
- PASS - 2026-06-21 auth flow targeted tests: 29 tests pass, gom auth v2, splash route decision va architecture version boundary.
- PASS - 2026-06-21 quick check: script exit 0, in `QUICK CHECK PASSED`; full suite pass 290 tests.
- FAIL - 2026-06-21 `flutter analyze`: repo dang co 287 warning/info lint nen hien co.

## Ket qua lich su truoc 2026-06-21

- PASS - targeted tests: 63 tests pass.
- PASS - code gaps targeted tests: 79 tests pass, gom auth v2, settings datasource/validators, profile update contract, account security contract, user-scoped cache contract va version boundary.
- PASS - broader authentication regression: 126 tests pass, gom architecture preservation, auth v2, settings, boundary, widget onboarding, dashboard va daily health tracking.
- PASS - analyzer filter cho file vua sua: khong co issue trong auth v2, Supabase auth service, onboarding cloud-first, dashboard/daily tracking UUID readers, router v2.
- FAIL - `flutter analyze`: repo dang co 289 warning/info lint o cac file cu.
- FAIL - `test/features/features_hub/features_hub_page_test.dart`: test doc lap khong tim thay widget text `AI Coach`.
- PARTIAL - quick check: script exit 0 va in `QUICK CHECK PASSED` nhung log full test co `Some tests failed` vi `features_hub_page_test`, nen xem la chua clean full-suite.

## Lien ket

- Feature: `../../features/authentication/001-feature-authentication-v2.md`
- Worklog: `../../worklog/2026-06-20/002-worklog-authentication-v2.md`
- Worklog auth flow: `../../worklog/2026-06-21/003-worklog-auth-system-flow.md`

## Rui ro

- Can kiem tra manual tren Supabase that: integrity query 0 row, RLS hai tai khoan, email redirect allow-list, recovery callback va Edge Function xoa tai khoan.
