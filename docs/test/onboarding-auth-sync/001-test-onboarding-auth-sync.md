Commit de xuat: test(auth): kiem chung onboarding entry va cloud sync

# Test - Onboarding Auth Sync

## Pham vi

- Loai test: unit, widget, static contract, targeted regression.
- Module: splash/onboarding entry, membership entitlement, auth controller contract, cloud sync repository, Supabase seed SQL, dashboard/localdb regression.
- Case bao gom: first-run route, 2 CTA entry, Guest/Free/Plus/FamilyPlus mapper, pending guest push/pull, cloud completed wins, sync fail giu pending id, remap `source_id` static, seed SQL static.
- Case chua bao gom: integration test Supabase live va mobile notification scheduling tren thiet bi that.

## Moi truong

- OS: Windows workspace.
- Flutter/Dart: theo pubspec hien tai (`sdk: ^3.9.2`).
- Device/emulator: Flutter widget/unit test host.

## Commands/Kich ban

- `dart format <touched dart files>`
- `flutter test test\app_versions\v1\features\splash\splash_route_decision_test.dart test\app_versions\v1\features\onboarding\onboarding_entry_page_test.dart test\app_versions\v2\features\membership_entitlement\membership_display_info_test.dart test\app_versions\v2\features\cloud_sync\authenticated_user_data_sync_repository_test.dart test\app_versions\v2\features\cloud_sync\cloud_sync_contract_test.dart test\app_versions\v2\features\auth\auth_flow_contract_test.dart test\docs\supabase_dev_seed_membership_test.dart test\architecture_preservation_property_test.dart`
- `flutter test test\app_versions\v2\features\auth test\features\dashboard test\core\storage\localdb`
- `flutter test test\app_versions\v2\features\cloud_sync\authenticated_user_data_sync_repository_test.dart test\app_versions\v2\features\cloud_sync\cloud_sync_contract_test.dart`
- `dart analyze lib\app_versions\v2\features\cloud_sync lib\app_versions\v2\features\membership_entitlement lib\app_versions\v2\features\auth\presentation\controllers\auth_controller.dart lib\app_versions\v1\features\onboarding\presentation\pages\onboarding_entry_page.dart test\app_versions\v2\features\cloud_sync test\app_versions\v2\features\membership_entitlement test\app_versions\v1\features\onboarding\onboarding_entry_page_test.dart test\docs\supabase_dev_seed_membership_test.dart`
- `flutter analyze`

## Ket qua

- PASS: dart format.
- PASS: targeted splash/onboarding/membership/cloud/auth/sql/preservation tests, 32 tests.
- PASS: targeted auth/dashboard/localdb tests, 49 tests.
- PASS: cloud sync focused retest, 5 tests.
- PASS: scoped analyzer for files moi/sua.
- FAIL: full `flutter analyze` do 288 warning/info legacy ngoai scope, vi du deprecated `withOpacity`, unused private helpers trong localdb models, va warning test cu.

## Lien ket

- Worklog: [006-worklog-onboarding-auth-sync](../../worklog/2026-06-21/006-worklog-onboarding-auth-sync.md)
- Feature: [001-feature-onboarding-auth-sync](../../features/onboarding-auth-sync/001-feature-onboarding-auth-sync.md)

## Rui ro

- Chua co test live Supabase de xac nhan auth.identities schema tren tung phien ban Supabase local.
- Sync push khong transactional tren server; can can nhac RPC/Edge Function neu yeu cau atomic cao hon.
