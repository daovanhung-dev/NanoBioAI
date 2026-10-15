# Implementation Delta — M16 quà vật lý và xác nhận đã trao

| Thuộc tính | Giá trị |
|---|---|
| Module | M16 `ADMIN_OPS`, M15 `ADMIN_DASHBOARD`, M08 `HEALTH_SCORE_HABITS` |
| Trạng thái DD gốc | Approved — giữ nguyên |
| Nguồn bổ sung | `BD-BIOAI-WELLNESS-REWARDS-001`, v1.1; user plan approved 2026-10-14 |
| Ngày | 2026-10-14 |

## 1. Phạm vi đã thêm

- Catalog hỗ trợ voucher và quà vật lý. Quà vật lý theo dõi số lượng còn lại;
  voucher tiếp tục dùng kho mã một lần hiện tại.
- Người dùng chỉ đổi khi online. RPC v2 khóa ưu đãi/ví, kiểm tra điều kiện,
  trừ điểm theo allocation FEFO, giảm tồn kho và ghi redemption cùng ledger
  trong một transaction có idempotency.
- Quà vật lý tạo trạng thái `redeemed` (Đã đổi). Admin có
  `wellness_rewards.write` xác nhận trao trực tiếp để chuyển sang `received`
  (Đã nhận), ghi actor/time và audit.
- SQLite v32 cache loại quà, tồn kho và `received_at`; point ledger vẫn do
  Supabase quyết định. Sau RPC thành công, controller tải lại summary, catalog,
  point history và redemption history từ Supabase để thay cache.
- RPC voucher cũ được giữ lại; legacy customer catalog/history chỉ trả voucher
  để bản app trước không thấy quà vật lý như voucher.

## 2. RPC và dữ liệu

| RPC/schema | Contract |
|---|---|
| `list_my_reward_catalog_v2` | Trả loại quà và tồn kho cùng catalog hiện có. |
| `redeem_my_reward_v2` | Route voucher qua RPC voucher cũ; quà vật lý dùng transaction có khóa, FEFO, ledger âm và idempotency. |
| `list_my_reward_redemptions_v2` | Trả loại quà, trạng thái và thời gian nhận cho lịch sử tài khoản. |
| `admin_upsert_reward_offer_v2` | Tạo/sửa voucher hoặc quà vật lý bằng quyền hiện có; loại quà bất biến sau khi tạo. |
| `admin_list_wellness_rewards_v2` | Danh sách catalog/giao dịch; chỉ trả mã voucher đã che. |
| `admin_mark_reward_redemption_received` | Kiểm quyền `wellness_rewards.write`, khóa redemption, ghi `received_by`/`received_at`/audit, replay an toàn. |
| Migration SQLite v32 | Bổ sung `reward_type`, `stock_count`, `received_at`; giữ nguyên các hàng voucher cũ. |

Forward migration: `supabase/migrations/20261014130000_wellness_physical_rewards.sql`.
Canonical rebuild source: cuối `docs/supabase/01_build_system.sql`.

## 3. Recovery và ranh giới production

Project Supabase được kiểm tra là `rnwohifdnylqfofkydfl` (`NanoBio`, main
PRODUCTION). Ngay trước write, remote history kết thúc tại
`20261014110000_member_phone_login_alias` và dry-run chỉ liệt kê migration
`20261014130000_wellness_physical_rewards.sql`. Migration đã được áp dụng lúc
2026-10-14 13:00 UTC; lần đọc lại sau write xác nhận local/remote cùng có
`20261014130000` và toàn bộ history khớp.

Dashboard gói Free báo không có scheduled backups; PITR là add-on gói Pro. Không
có dump production vì `supabase db dump --linked` cần Docker trong môi trường
này. Migration được bọc trong một transaction và chỉ thêm cột/index/trigger/RPC,
nới null/status cho lịch sử cũ; không xóa hoặc rewrite giao dịch. Nếu DDL lỗi,
transaction rollback. Nếu app có lỗi sau khi áp dụng, bản app cũ tiếp tục dùng
RPC voucher; giữ schema additive và sửa bằng forward migration.

`supabase db dump --linked` không tạo được bản dump trong môi trường này vì CLI
cần Docker. Kiểm tra production sau migration dựa vào lịch sử migration, schema
và function/grant metadata; không chạy canonical rebuild hoặc seed trên
production.

## 4. Bằng chứng hiện có

- `flutter analyze --no-pub` trên 26 file Dart thay đổi: PASS, không issue.
- 39 targeted Flutter tests nhóm user/Admin/SQLite: PASS.
- Migration và smoke chạy trên PostgreSQL 17 cô lập trong `/tmp`, với fixture
  tổng hợp, helper auth/permission giả lập và function voucher cũ lấy từ
  canonical source. Đã kiểm tra voucher route, giao dịch vật lý, balance/stock,
  insufficient points, out-of-stock, replay, lượt đổi đồng thời, quyền Admin,
  actor/time và audit. Đây không phải Supabase branch hoặc RLS acceptance.
- Production migration `20261014130000` đã apply; linked read-only query xác nhận
  cột `reward_type`, `stock_count`, `reward_type_snapshot`, `received_at`,
  `received_by`, sáu RPC v2 và quyền execute cho `authenticated` nhưng không
  cho `anon`. Các RPC voucher/user và Admin cũ vẫn tồn tại, execute cho
  `authenticated`. `supabase migration list --linked` xác nhận history khớp.
- Không chạy live redemption/Admin mutation trên production; RLS/role behavior,
  test người dùng/Admin đăng nhập thật và device acceptance còn pending. DTD
  Flutter hot reload không tìm được app connection active; không cài/ghi dữ liệu
  lên app vật lý.
