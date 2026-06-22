Commit de xuat: feat(sync): them time gate, sync outbox va giao dien Sale

# Time Gate, Auto Sync Va Sale Interface

## Muc tieu

- Chan app khi thiet bi sai gio, sai timezone hoac khong kiem tra duoc gio chuan Supabase.
- Mo rong cloud sync hien co bang SQLite outbox de local writes cua user duoc retry len Supabase.
- Them giao dien Sale rieng, doc truc tiep Supabase va chi mo khi `sale_status = active`.
- Them flow dang ky tham gia Sale trong settings voi dieu le versioned va trang thai `pending` cho den khi admin/backend duyet.

## Pham vi

- Bao gom: Supabase RPC `server_time_check`, time integrity gate, SQLite migration v9 `sync_outbox`, outbox service/refresher, write hooks cho profile/task/schedule/meal/notification, Sale RPC contracts, Sale shell 4 tab, settings Sale CTA.
- Khong bao gom: chat history sync, production payout/KYC/accounting, admin approval UI, payment provider integration, service-role/backend job implementation.
- Sale data khong luu SQLite; app doc Sale dashboard/tree/leaderboard truc tiep tu Supabase RPC.

## Luong time gate

1. `BioAIV2App` wrap router bang `TimeIntegrityGatePage`.
2. Gate goi RPC `server_time_check` de lay `server_utc`.
3. Gate lay timezone identifier tu `flutter_timezone`.
4. `TimeIntegrityPolicy` cho phep neu drift <= 5 phut va timezone co dang IANA hop le.
5. Neu RPC fail, drift qua nguong hoac timezone khong hop le, app fail-closed bang man hinh support tieng Viet.

## Luong cloud sync

1. Login/auth refresh van dung `AuthenticatedUserDataSyncRepository`.
2. Neu pending guest va cloud chua completed, local snapshot push len Supabase, roi cloud snapshot pull ve SQLite.
3. Neu cloud da completed, cloud thang va pull de len SQLite.
4. Local writes cua user enqueue vao `sync_outbox` theo table/id/operation/payload.
5. Outbox drain ngay sau enqueue, sau auth sync, khi app resume va khi connectivity restore.
6. Failed mutation giu trong outbox voi attempt count, next retry va last error.

## Luong Sale

1. Settings doc `get_my_sale_state`.
2. `none`: hien "Tham gia kiem tien cung Nami", mo dialog dieu le va goi `request_sale_participation`.
3. RPC ghi acceptance va tao/cap nhat `sale_profiles.status = pending`.
4. `pending`: settings chi hien trang thai cho duyet.
5. `active`: settings hien "Chuyen sang giao dien Sale" va route `/sale`.
6. `/sale` hien shell rieng gom Tong quan, Mang luoi, Xep hang, Cong cu.
7. `suspended/closed`: settings va route Sale hien support state, khong co nut switch.

## Du lieu va luu tru

- SQLite: them `sync_outbox`.
- Supabase core: them RPC `server_time_check`.
- Supabase Sale: them `sale_terms_versions`, `sale_terms_acceptances`, `request_sale_participation`, `get_my_sale_state`, `get_my_sale_dashboard`, `get_my_sale_referral_tree`, `get_sale_leaderboard`, `get_my_commission_summary`.
- Outbox scope: cac bang trong `UserDataSyncTables` va `users`; catalog/payment/sale/family khong sync qua local outbox.

## UI/UX

- Time gate: blocking screen, khong co bypass.
- Settings Sale CTA:
  - `none`: tham gia kiem tien cung Nami.
  - `pending`: ho so dang cho duyet.
  - `active`: chuyen sang giao dien Sale.
  - `suspended/closed`: lien he ho tro.
- Sale shell: giao dien rieng, mau teal/blue, bottom navigation 4 tab.

## Files

- `lib/app_versions/v2/features/time_integrity/` - policy, datasource, repository, provider, blocking gate.
- `lib/services/supabase/cloud_sync/` - outbox service/refresher.
- `lib/services/supabase/sale/` - Sale terms, Supabase service, providers.
- `lib/sale_referral/presentation/pages/sale_shell_page.dart` - Sale shell UI.
- `lib/core/storage/localdb/tables/sync_outbox_table.dart` - SQLite outbox table.
- `docs/supabase/01-core-auth-profile.sql` - `server_time_check`.
- `docs/supabase/05-sale-referral-commission.sql` - Sale terms/RPC contracts.

## Kiem chung

- Command: `flutter test test\core\storage\localdb\migration_manager_test.dart test\app_versions\v2\features\time_integrity\time_integrity_policy_test.dart test\app_versions\v2\features\cloud_sync\user_data_sync_outbox_test.dart test\architecture_version_boundary_test.dart`
- Ket qua: PASS.
- Command: `flutter analyze`
- Ket qua: PASS.

## Rui ro

- Can chay Supabase sandbox SQL va test RLS/RPC thuc te truoc release.
- Outbox client-side khong thay the backend transaction; neu mutation phuc tap lien quan nhieu table van can RPC/backend job rieng.
- Sale payout, tax, KYC, anti-fraud va legal review chua production-ready.
- AI chat history van ngoai sync vi chua co schema chat history.
