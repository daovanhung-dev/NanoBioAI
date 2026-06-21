Commit de xuat: docs(worklog): ghi nhan phien onboarding auth sync

# Worklog - Onboarding Auth Sync

## Thoi gian

- Ngay: 2026-06-21
- Bat dau: khong ghi nhan tu dong
- Ket thuc: khong ghi nhan tu dong
- Timezone: Asia/Saigon

## Pham vi

- Loai task: coding/test/docs
- Module chinh: v1 onboarding/splash/dashboard, v2 auth/membership/cloud sync, Supabase docs.
- Yeu cau goc: implement plan onboarding entry, dashboard membership, SQL dev seed account membership va cloud sync sau auth.

## Da lam

- Them route/page `/start` de user chon dang nhap/tao tai khoan hoac onboarding ngay.
- Dashboard hien thi membership pill qua provider mapper, uu tien auth state khi co session va fallback local.
- Them `AppPrefs.pendingGuestUserId` va doi local onboarding save tra ve local user id.
- Them module `v2/features/cloud_sync` voi contract/result, local SQLite datasource, Supabase datasource, repository va provider.
- Wire sync vao sign in, sign up session-ready, auth callback va AuthGate refresh.
- Them SQL seed dev/sandbox cho `dev.free`, `dev.plus`, `dev.family` voi subscription active.
- Them unit/widget/static tests va cap nhat preservation/auth contract tests.

## File code/docs da sua

- `lib/app_versions/v1/features/splash/domain/services/splash_route_decision.dart` - sua - route first-run unauthenticated ve onboarding entry.
- `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart` - tao - UI 2 CTA.
- `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart` - sua - membership pill.
- `lib/app_versions/v2/features/membership_entitlement/membership_entitlement.dart` - tao/sua - display mapper/provider.
- `lib/core/storage/localdb/app_prefs.dart` - sua - pending guest id va last sync timestamp.
- `lib/app_versions/v1/features/onboarding/data/datasource/onboarding_local_datasource.dart` - sua - tra local user id.
- `lib/app_versions/v1/features/onboarding/domain/repositories/onboarding_repository_impl.dart` - sua - set/clear pending guest id.
- `lib/app_versions/v2/features/cloud_sync/` - tao - cloud sync module.
- `lib/app_versions/v2/features/auth/presentation/controllers/auth_controller.dart` - sua - goi sync sau auth va invalidate providers.
- `docs/supabase/09-dev-seed-membership-test-accounts.sql` - tao - seed account membership dev.
- `test/app_versions/v2/features/cloud_sync/` - tao - sync tests.

## Tai lieu lien quan

- [Feature onboarding auth sync](../../features/onboarding-auth-sync/001-feature-onboarding-auth-sync.md)
- [Test onboarding auth sync](../../test/onboarding-auth-sync/001-test-onboarding-auth-sync.md)

## Commands

- `dart format <touched dart files>`: PASS - format 31 files, 13 changed.
- `flutter test test\app_versions\v1\features\splash\splash_route_decision_test.dart test\app_versions\v1\features\onboarding\onboarding_entry_page_test.dart test\app_versions\v2\features\membership_entitlement\membership_display_info_test.dart test\app_versions\v2\features\cloud_sync\authenticated_user_data_sync_repository_test.dart test\app_versions\v2\features\cloud_sync\cloud_sync_contract_test.dart test\app_versions\v2\features\auth\auth_flow_contract_test.dart test\docs\supabase_dev_seed_membership_test.dart test\architecture_preservation_property_test.dart`: PASS - 32 tests.
- `flutter test test\app_versions\v2\features\auth test\features\dashboard test\core\storage\localdb`: PASS - 49 tests.
- `flutter test test\app_versions\v2\features\cloud_sync\authenticated_user_data_sync_repository_test.dart test\app_versions\v2\features\cloud_sync\cloud_sync_contract_test.dart`: PASS - 5 tests.
- `dart analyze <scoped touched files>`: PASS - no issues found.
- `flutter analyze`: FAIL - 288 warning/info legacy ngoai scope, khong thay loi compile trong file moi/sua.

## Loi/Rui ro

- Da fix: Riverpod `AsyncValue.valueOrNull` khong co trong version hien tai, da doi sang `.value`; test preservation da can chinh dung layer signature.
- Chua fix: full analyze repo co warning/info legacy ngoai scope.
- Can kiem tra tiep: live Supabase local voi file seed va luong sync that tren device/emulator.

## Ty le hoan thanh

- Hoan thanh: 100% pham vi implementation/test/doc theo plan trong repo.
- Dang do: chua test live Supabase production-like va chua xu ly warning legacy toan repo.
