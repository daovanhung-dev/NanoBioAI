Commit de xuat: test(sync-sale): them regression cho outbox, cloud-wins va Sale calculator

# Kiem Chung Dong Bo User Va Sale

## Unit/regression test them hoac cap nhat

- `test/core/storage/localdb/migration_manager_test.dart`
  - v9 tao cot onboarding/access/Sale va outbox/runtime table.
  - Trigger marker cho user-owned write.
  - Cloud apply guard khong enqueue marker.
- `test/services/supabase/cloud_sync/user_data_sync_outbox_test.dart`
  - Local write tao mot snapshot push va marker duoc xoa sau thanh cong.
  - Write trong luc snapshot dang push khong bi xoa nham; con lai cho lan drain sau.
- `test/app_versions/v2/features/cloud_sync/authenticated_user_data_sync_repository_test.dart`
  - Guest snapshot chi upload vao fresh cloud account.
  - Cloud data completed/in-progress co row thuc su thang Guest cache.
  - Loi sau Guest upload khong clear pending Guest id.
- `test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart`
  - Mark completed chi xay ra sau khi AI initial plan thanh cong.
- `test/features/settings/profile_update_contract_test.dart`
  - Ho so ghi SQLite truoc, tao outbox va chi drain cloud sau khi local write thanh cong.
- `test/sale_referral/domain/services/sale_commission_calculator_test.dart`
  - Uoc tinh 10% tang 1 va 5% tang 2.
  - Input am khong tao gia tri chi tra.

## Kiem chung thu cong Supabase staging bat buoc

1. Chay `01`, `02`, `03`, `05`, sau do `10-mobile-sync-and-sale-rpc.sql` trong sandbox.
2. Login account da co meal/task/log cloud; kiem tra SQLite sau pull chi con snapshot cloud cua auth UUID.
3. Hoan tat onboarding Guest, dang ky account moi, kiem tra cloud co profile + lich AI + task; local duoc doi sang UUID cloud.
4. Offline -> sua task/diem -> mo mang; kiem tra outbox drain va cloud nhan snapshot moi.
5. Tao write trong luc RPC dang chay, kiem tra marker moi con lai va duoc push lan thu hai.
6. Account chua Sale chay Sale RPC dashboard/tree/leaderboard phai bi tu choi.
7. Account chon dong y dieu le, kiem tra `sale_profiles` co version/thoi diem, `users.sale_status = active`, referral code active duoc tao.
8. Kiem tra snapshot xoa ca notification legacy chi co `user_id` (khong co `subject_id`) de cloud khong con du lieu cu.
9. Kiem tra Sale UI doc truc tiep cloud va khong co bang/table Sale trong SQLite snapshot list.

## Trang thai kiem chung trong moi truong hien tai

- Da review source va test regression da duoc them/cap nhat.
- Khong the chay `dart format`, `flutter analyze` hay `flutter test` trong container nay vi khong co Flutter/Dart SDK.
- Chua deploy/chay SQL tren Supabase; bo SQL giu trang thai DRAFT.
