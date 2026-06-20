Commit de xuat: docs(worklog): cap nhat code gaps authentication v2

# Worklog - Authentication V2 Code Gaps

## Thoi gian

- Ngay: 2026-06-20
- Bat dau: Khoang 10:00
- Ket thuc: Khoang 10:56
- Timezone: Asia/Saigon

## Pham vi

- Loai task: coding/test/docs
- Module chinh: authentication v2
- Yeu cau goc: Hoan thanh code gaps authentication v2, cap nhat checklist DD va bao cao % hoan thanh theo module, tach code-level voi manual Supabase ops.

## Da lam

- Bo sung profile update sau onboarding: UI edit profile, validation, cloud-first update `users`/`health_profiles`, mirror SQLite bang current auth UUID, safe failure khi thieu session.
- Bo sung settings security actions: doi mat khau, logout, request account deletion, confirm dialogs, route ve `/v2/auth`.
- Them shared `AccountSecurityService` de update password, sign out va invoke Edge Function xoa tai khoan ma khong dung Admin API/service-role trong Flutter.
- Them central user-scoped cache invalidation cho dashboard, daily tracking, lifestyle, meal plan, nutrition va settings providers.
- Bo sung auth error code/mapping duplicate email than thien hon.
- Bo sung tests cho profile validator, profile update contract, account security contract va user-scoped cache contract.
- Cap nhat checklist DD authentication v2 va test docs theo ket qua moi.

## % hoan thanh theo module

| Module/Phase | Code % | Overall % | Ghi chu |
|---|---:|---:|---|
| A. Database foundation | 100% | 20% | Code khong vi pham Supabase ops; SQL deploy, integrity query, RLS smoke va backfill van manual. |
| B. Auth data/domain | 100% | 95% | Commands/results/errors/repository/datasource/error mapping/security contract done; con manual trigger/email behavior that. |
| C. Presentation/routing | 100% | 85% | Auth pages/AuthGate/deep link code done; email verification/recovery manual pending. |
| D. Onboarding/profile | 95% | 80% | Cloud-first onboarding/profile update/local mirror done; RLS real va fake Supabase coverage chi tiet con pending. |
| E. Settings/account safety | 95% | 75% | Change password/logout/delete UI + cache invalidation done; Edge Function JWT/cascade verify manual pending. |
| Test/traceability | 85% | 65% | Targeted tests pass va checklist updated; analyzer nen/full quick check/manual Supabase chua clean. |

Ghi chu: Phan tram la snapshot sau phien code nay, khong phai cam ket production-ready khi cac buoc manual Supabase chua chay.

## File code/docs da sua

- `lib/services/supabase/auth/account_security_service.dart` - tao moi - gom change password, logout, request account deletion qua Edge Function.
- `lib/services/supabase/auth/auth_profile_service.dart` - sua - them `CloudProfileUpdatePayload` va `updateProfile`.
- `lib/app_versions/v1/features/profile/presentation/pages/profile_page.dart` - sua - them edit profile sheet, cloud-first save va local mirror.
- `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart` - sua - them change password/logout/delete UI va confirm dialogs.
- `lib/app_versions/v1/features/settings/providers/settings_provider.dart` - sua - them user-scoped cache invalidation helper.
- `lib/app_versions/v2/features/auth/domain/entities/auth_failure.dart` - sua - them auth failure code cho session/duplicate email.
- `lib/app_versions/v2/features/auth/data/repositories/supabase_auth_repository.dart` - sua - map duplicate email neutral.
- `test/features/settings/domain/validators/profile_validator_test.dart` - tao moi - test profile validation.
- `test/app_versions/v2/features/auth/account_security_contract_test.dart` - tao moi - verify security contract/settings wiring.
- `test/features/settings/profile_update_contract_test.dart` - tao moi - verify profile update cloud/local contract.
- `test/features/settings/user_scoped_cache_contract_test.dart` - tao moi - verify cache invalidation scope.
- `docs/features/authentication/002-dd-checklist-authentication-v2.md` - sua - cap nhat trang thai DD/TC sau code gaps.
- `docs/test/authentication/001-test-authentication-v2.md` - sua - them ket qua targeted tests code gaps.

## Tai lieu lien quan

- [Checklist DD Authentication V2](../../features/authentication/002-dd-checklist-authentication-v2.md)
- [Feature Authentication V2](../../features/authentication/001-feature-authentication-v2.md)
- [Test Authentication V2](../../test/authentication/001-test-authentication-v2.md)
- [Worklog Authentication V2](002-worklog-authentication-v2.md)

## Commands

- `flutter analyze`: FAIL - repo con 289 warning/info nen cu; khong thay issue compile moi trong file vua sua.
- `dart format --set-exit-if-changed .`: PASS - 370 files, 0 changed sau lan format cuoi.
- `flutter test test\app_versions\v2\features\auth test\features\settings test\architecture_version_boundary_test.dart`: PASS - 79 tests pass.
- `flutter test test\architecture_preservation_property_test.dart test\app_versions\v2\features\auth test\features\settings test\architecture_version_boundary_test.dart test\widget_test.dart test\features\dashboard test\features\daily_health_tracking`: PASS - 126 tests pass.
- `powershell -NoProfile -ExecutionPolicy Bypass -File .codex\tool\codex_quick_check.ps1`: PARTIAL - script exit 0 va in `QUICK CHECK PASSED`, nhung log full test co `Some tests failed` do `test/features/features_hub/features_hub_page_test.dart` khong tim thay text `AI Coach`.

## Loi/Rui ro

- Da fix: Profile update sau onboarding, settings security UI, logout/delete cache invalidation, duplicate email mapping, code-level contract tests.
- Chua fix: Analyzer full repo van fail boi lint/warning nen cu; quick check full-suite truoc do fail ngoai scope o `features_hub_page_test.dart`.
- Can kiem tra tiep: Supabase SQL deploy, integrity query 0 row, RLS smoke 2 account, email/recovery link, Edge Function delete-account JWT/cascade delete, backfill old users.
