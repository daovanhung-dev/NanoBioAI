Commit de xuat: feat(auth): them onboarding entry va dong bo cloud sau auth

# Onboarding Entry Va Dong Bo Cloud Sau Auth

## Muc tieu

- Cho user lan dau chua dang nhap chon dang nhap/tao tai khoan hoac onboarding ngay.
- Hien thi trang thai goi thanh vien tren dashboard ma khong query Supabase truc tiep tu UI.
- Dong bo du lieu guest local len Supabase sau khi co session va pull cloud ve SQLite cho account da dang nhap.
- Tao SQL dev seed de test Free/Plus/FamilyPlus.

## Pham vi

- Bao gom: route `/start`, page entry onboarding, membership display provider, AppPrefs pending guest id, cloud sync repository/datasource/provider, auth controller wiring, SQL seed dev account, tests.
- Khong bao gom: sync catalog, payment, sale/referral, family tables; production user provisioning bang SQL truc tiep.

## Luong hoat dong

1. Splash thay no session + chua onboarding thanh `V1RoutePaths.onboardingEntry`.
2. Entry page co CTA dang nhap/tao tai khoan sang v2 login va CTA onboarding ngay sang v1 onboarding.
3. Khi onboarding local truoc auth, repository luu `pendingGuestUserId`.
4. Sau sign in, sign up co session, auth callback hoac AuthGate refresh, `AuthenticatedUserDataSyncRepository` chay sync.
5. Neu pending guest va cloud chua completed: push local snapshot len cloud, remap local text id sang UUID, remap `source_id`, roi pull cloud ve SQLite.
6. Neu cloud da completed: cloud thang, pull ve SQLite va clear pending guest.
7. Sau pull, invalidate dashboard/meal/schedule/tracking/nutrition providers va refresh local notifications.

## Du lieu va luu tru

- Nguon doc: Supabase auth session, `public.users`, cac bang user-owned trong `02-health-and-schedule.sql`, SQLite local.
- Noi ghi: SQLite cache local va Supabase public user-owned tables.
- Table/model/entity: `users`, onboarding/profile tables, `meal_plans`, `daily_health_tasks`, `lifestyle_schedule_items`, `notifications`, tracking/nutrition/AI tables.
- Migration/version: khong tang SQLite version; chi them sync/cache logic va SQL dev seed.

## UI/UX

- Loading: Splash/AuthGate giu loading trong luc resolve route va sync.
- Empty: Guest/no session hien thi `Khach trai nghiem`; blank tier fallback `free`.
- Error: sync fail khong clear pending guest id; AuthGate co error/retry san co.
- Success: dashboard co membership pill cung vung hero/BMI.

## Files

- `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart` - page lua chon login/onboarding.
- `lib/app_versions/v1/features/splash/domain/services/splash_route_decision.dart` - them target onboarding entry.
- `lib/app_versions/v2/features/membership_entitlement/membership_entitlement.dart` - mapper/provider hien thi goi.
- `lib/app_versions/v2/features/cloud_sync/` - contract, datasource, repository, provider sync.
- `lib/app_versions/v2/features/auth/presentation/controllers/auth_controller.dart` - goi sync sau auth.
- `docs/supabase/09-dev-seed-membership-test-accounts.sql` - dev seed account membership.

## Kiem chung

- Command: `flutter test test\app_versions\v1\features\splash\splash_route_decision_test.dart test\app_versions\v1\features\onboarding\onboarding_entry_page_test.dart test\app_versions\v2\features\membership_entitlement\membership_display_info_test.dart test\app_versions\v2\features\cloud_sync\authenticated_user_data_sync_repository_test.dart test\app_versions\v2\features\cloud_sync\cloud_sync_contract_test.dart test\app_versions\v2\features\auth\auth_flow_contract_test.dart test\docs\supabase_dev_seed_membership_test.dart test\architecture_preservation_property_test.dart`
- Ket qua: PASS.
- Command: `flutter test test\app_versions\v2\features\auth test\features\dashboard test\core\storage\localdb`
- Ket qua: PASS.
- Command: `dart analyze ...scoped touched files...`
- Ket qua: PASS.
- Command: `flutter analyze`
- Ket qua: FAIL do canh bao/info legacy ngoai scope da ton tai.

## Lien ket

- Worklog: [006-worklog-onboarding-auth-sync](../../worklog/2026-06-21/006-worklog-onboarding-auth-sync.md)
- Test: [001-test-onboarding-auth-sync](../../test/onboarding-auth-sync/001-test-onboarding-auth-sync.md)

## Rui ro

- Push cloud hien tai dung nhieu request client-side, chua phai transaction/RPC Supabase; neu fail giua chung, pending local van duoc giu de retry.
- Full analyze repo van do do warning legacy; scope file moi/sua analyze sach.
