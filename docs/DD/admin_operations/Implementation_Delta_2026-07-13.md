# Implementation Delta — M16 quản trị ưu đãi, kho mã và giao dịch

| Thuộc tính | Giá trị |
|---|---|
| Module | M16 `ADMIN_OPS` |
| Trạng thái DD gốc | Approved — giữ nguyên |
| Nguồn bổ sung | `BD-BIOAI-WELLNESS-REWARDS-001` |
| Ngày | 2026-07-13 |

## 1. Phạm vi mutation mới

Actor có `wellness_rewards.write` được:

- tạo/sửa/tắt ưu đãi với tiêu đề/mô tả tiếng Việt có dấu, nhà cung cấp, giá
  điểm, gói được phép, cửa sổ mở và hạn voucher;
- nhập/dán hàng loạt mã; nhận thống kê mã hợp lệ, trùng hoặc sai định dạng;
- xem tồn kho và giao dịch mà không đọc mã chưa cấp;
- hủy giao dịch với lý do và xác nhận đã xử lý mã bên ngoài.

Hủy giao dịch là mutation idempotent: mã bị loại vĩnh viễn, không trở lại kho;
điểm được hoàn đúng một lần thành allocation mới theo policy đang hiệu lực và
mọi bước có audit. Không có trạng thái tự động `Đã sử dụng` trong đợt này.

## 2. RPC và transaction contract

| RPC | Contract chính |
|---|---|
| `admin_upsert_reward_offer` | Validate nội dung/cửa sổ/gói/giá; reason + idempotency; audit before/after summary. |
| `admin_import_reward_codes` | Tối đa batch theo server policy; normalize/validate, chặn trùng, không trả plaintext inventory trong list API. |
| `admin_cancel_reward_redemption` | Row lock redemption/wallet; yêu cầu external revocation confirmed; discard code, refund một lần và audit nguyên tử. |
| `admin_list_wellness_rewards` | Read-only privacy-limited rows cho catalog, tồn kho và redemption. |

Tất cả dùng `auth.uid()`, fixed `search_path`, stable error code và kiểm tra
permission ở backend. Client bị revoke DML trực tiếp vào ledger và inventory.

## 3. Implementation map

- `lib/app_versions/admin/features/wellness_rewards/`: entity/command, remote
  datasource, repository, Riverpod controller và responsive Admin panel.
- `lib/app_versions/admin/features/admin_panel/`: section/permission/route và
  safe mapping cho permission, action, audit target/reason.
- `docs/supabase/16-wellness-rewards.sql`: schema, RLS, RPC, append-only ledger,
  inventory/redemption/refund/audit contract.
- `docs/supabase/config.sql`: rebuild source đồng bộ migration 16.

## 4. Bằng chứng và phần còn thiếu

- Reward user/Admin/cache/secure-store/gateway tests: 38/38 PASS.
- Targeted analyze reward client/Admin: PASS.
- Supabase static contract bundle kiểm tra RPC/permission/RLS/Storage: 40 test
  PASS; full `config.sql` rebuild trên PostgreSQL 18 tạm với Auth/Storage stub:
  PASS.
- Local end-to-end smoke register → begin → upload → finalize → undo → refinalize
  → redeem → cancel, RLS chéo người dùng và direct-ledger rejection: PASS.

Migration 16, quyền, audit, row-lock concurrency, import inventory và cancel/
refund chưa được thực thi trong một dự án Supabase sandbox thật. Feature flag
phải giữ `false` cho tới khi các acceptance này pass, bucket runtime được kiểm tra
và catalog/kho mã thử nghiệm đã được nhập an toàn.
