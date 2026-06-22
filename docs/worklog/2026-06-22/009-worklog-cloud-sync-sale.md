Commit de xuat: feat(sync-sale): dong bo user snapshot va khong gian Sale cloud-direct

# Worklog - Cloud Sync Va Sale Interface

## Thoi gian

- Ngay: 2026-06-22
- Timezone: Asia/Bangkok (+07:00)

## Pham vi

- Loai task: coding + Supabase schema draft + UI Sale + test/docs.
- Yeu cau: tu dong dong bo tat ca du lieu user SQLite/Supabase va them giao dien Sale tach rieng, chi hien switch trong Settings khi role Sale active.
- Tai lieu da tham khao: `docs/supabase/*`, `docs/BD/project_flow/*`, `docs/DD/product_flow/10_FEATURE_SALE_REFERRAL_REGISTRATION.md`, `docs/DD/product_flow/11_FEATURE_PAYMENT_COMMISSION_TWO_LEVEL.md`.

## Da lam

- Tang SQLite database len v9 va them outbox durable bang trigger cho toan bo user-owned tables.
- Them runtime guard de cloud pull khong tao pull->push loop.
- Them full snapshot push qua RPC va full cloud replace SQLite theo auth UUID.
- Chot cloud-wins khi account da co onboarding/row du lieu; chi local-wins cho Guest onboarding -> fresh authenticated account.
- Sua onboarding local-first: local chi duoc mark `completed` sau AI initial plan thanh cong; authenticated completion thu drain outbox ngay.
- Them migration SQL draft cho `sync_my_mobile_snapshot`, Sale participation/state/dashboard/tree/leaderboard RPC.
- Them Settings entry, page dieu le Sale, route Sale, shell Sale co tong quan/mang luoi/xep hang/cong cu uoc tinh.
- Bo sung terms version va guard de client khong tu ghi role/quyen/payment/commission.
- Them/cap nhat regression test cho migration, outbox race, cloud conflict va calculator.

## File code/docs da sua

- `lib/core/storage/localdb/database_version.dart`
- `lib/core/storage/localdb/database_service.dart`
- `lib/core/storage/localdb/migrations/migration_manager.dart`
- `lib/core/storage/localdb/tables/users_table.dart`
- `lib/core/storage/localdb/sync/*`
- `lib/services/supabase/cloud_sync/*`
- `lib/app_versions/v2/features/cloud_sync/*`
- `lib/app_versions/v1/features/onboarding/*`
- `lib/app_versions/v1/features/profile/presentation/pages/profile_page.dart`
- `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart`
- `lib/app_versions/v2/router/*`
- `lib/sale_referral/*`
- `lib/services/supabase/sale/*`
- `docs/supabase/10-mobile-sync-and-sale-rpc.sql`
- `docs/supabase/README.md`
- `docs/supabase/08-acceptance-checks.md`
- `test/...cloud_sync...`, `test/...migration...`, `test/...sale...`, `test/features/settings/profile_update_contract_test.dart`

## Kiem chung

- Static review: da doi chieu schema local, mapping snapshot, contract cloud, route guard va Sale RPC scope.
- `dart format`, `flutter analyze`, `flutter test`: **khong chay duoc** trong container hien tai vi Flutter/Dart SDK khong duoc cai dat.
- Supabase SQL: **chua chay** tren sandbox/staging; `10-mobile-sync-and-sale-rpc.sql` la DRAFT, can review/deploy rieng.

## Rui ro / viec tiep theo

- Multi-device conflict resolver chua duoc chot; snapshot replacement co policy cloud-wins luc login.
- History refresh PowerShell cua `.codex` khong chay duoc trong container vi khong co PowerShell; worklog index/risk register da duoc cap nhat thu cong.
- Cac bang Sale/payment/commission phai duoc review business/legal truoc production payout.
- Can co staging project de chay acceptance checklist, verify RLS/RPC va thu offline retry tren Android/iOS that.
