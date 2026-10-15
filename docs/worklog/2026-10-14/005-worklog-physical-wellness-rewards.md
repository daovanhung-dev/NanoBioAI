# Worklog - Đổi quà vật lý và ledger thưởng

## Thời gian

- Ngày: 2026-10-14
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Module: M08 `HEALTH_SCORE_HABITS`, M15 `ADMIN_DASHBOARD`, M16 `ADMIN_OPS`.
- Thực hiện kế hoạch Đổi quà: catalog voucher/quà vật lý, redeem online,
  nguyên tử hóa điểm/tồn/lịch sử, Admin xác nhận đã trao, và cache SQLite.
- Production migration được người dùng cho phép. Không commit/push/release app.

## Thay đổi

- App user có lối vào Đổi quà, hiển thị số dư khả dụng/đang chờ, loại quà,
  giá điểm, tồn kho và lịch sử. Redeem bị chặn khi offline; sau khi server xác
  nhận, controller tải lại số dư, ledger, catalog và lịch sử giao dịch.
- Admin dùng quyền thưởng hiện tại để tạo/sửa ưu đãi và tồn quà; giao dịch quà
  vật lý có thể được xác nhận đã trao, lưu actor/time và audit; retry có khóa
  idempotency.
- Supabase migration `20261014130000_wellness_physical_rewards.sql` thêm loại
  ưu đãi, tồn kho, snapshot loại quà và metadata đã nhận; thêm RPC v2 với khóa,
  idempotency và ledger; giữ RPC voucher cũ tương thích.
- SQLite schema/cache v32 lưu loại quà và trạng thái nhận. Ledger local là bản
  mirror có ID server; Supabase vẫn là nguồn quyết định số dư.
- Cập nhật canonical SQL, BD v1.1, Admin implementation delta, checklist và
  hướng dẫn migration.

## Kiểm chứng source và môi trường cục bộ

- `dart format` trên 26 file Dart thay đổi: PASS.
- `flutter analyze --no-pub` trên 26 file Dart thay đổi: PASS, không issue.
- 39 focused Flutter tests PASS: user repository/local cache/controller, Admin
  rewards/idempotency và SQLite v31/v32 migrations.
- Isolated PostgreSQL 17 scratch harness chạy migration transaction và kiểm
  tra voucher route, physical redemption/ledger/stock, insufficient points,
  out-of-stock, idempotency, hai redemption đồng thời với stock 1, Admin denied,
  received actor/time/audit và upsert. Fixture tổng hợp; auth/Admin helper là
  stubs. Đây không phải hosted Supabase sandbox hay RLS acceptance.
- `docs/supabase/01_build_system.sql` kết thúc bằng chính xác nội dung migration
  versioned; `git diff --check` PASS trước production.
- Flutter DTD hot reload không thấy active app connection. Không cài/chạy app
  vật lý để tránh ghi đè app hoặc dữ liệu hiện có; device acceptance pending.

## Production — project `rnwohifdnylqfofkydfl`

- Xác nhận project `NanoBio`, main `PRODUCTION`; `.temp/project-ref` khớp.
- Trước write: remote history đến `20261014110000_member_phone_login_alias`;
  `supabase db push --linked --dry-run` chỉ liệt kê migration
  `20261014130000_wellness_physical_rewards.sql`.
- Dashboard gói Free không có scheduled backups; PITR là add-on Pro. Không tạo
  dump vì `supabase db dump --linked` cần Docker chưa có trong môi trường.
  Recovery basis đã rà: migration có transaction, additive, không xóa/rewrite
  dữ liệu; lỗi DDL rollback, app cũ tiếp tục dùng RPC voucher và sửa ứng dụng
  bằng forward migration. Không chạy rebuild hoặc seed.
- Đã chạy `supabase db push --linked --yes`; CLI báo áp dụng đúng migration
  `20261014130000_wellness_physical_rewards.sql` thành công.
- Sau write, `supabase migration list --linked` xác nhận local/remote khớp tại
  `20261014130000` (record time 2026-10-14 13:00 UTC) và các migration trước đó.
- Truy vấn linked DB chỉ đọc xác nhận cột `reward_type`, `stock_count`,
  `reward_type_snapshot`, `received_at`, `received_by`; sáu RPC v2 hiện diện.
  Metadata xác nhận RPC `SECURITY DEFINER`, execute cho `authenticated` và
  không cho `anon`.
- Các RPC voucher/user và Admin cũ (`list_my_reward_offers`,
  `list_my_reward_redemptions`, `redeem_my_reward_offer`, Admin list/upsert)
  vẫn hiện diện và giữ execute cho `authenticated`.
- Không chạy mutation hoặc live voucher/physical redemption/Admin action trên
  production. Role/RLS behavior, giao dịch end-to-end, app/device và catalog
  thật chưa được xác nhận; không thêm offer hoặc thay đổi dữ liệu người dùng.

## Trạng thái

- Source, migration SQL, local focused tests/analyzer: PASS.
- Production migration + schema/RPC/grant/history verification: PASS.
- Hosted sandbox và Supabase live role/RLS acceptance: chưa chạy.
- App build/release, device UI smoke, production user/Admin transactions: chưa
  chạy.
- Không commit/push.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - voucher cũ được giữ tương thích; đổi quà mới có ledger,
  inventory, history và Admin audit trong transaction/RPC có kiểm soát.
- Mức độ hoàn thành task: source, SQLite v32 và production migration hoàn tất;
  hosted sandbox, live role/RLS, UI device acceptance và app release còn pending.
- Bằng chứng kiểm chứng: 39 tests, analyze 26 Dart files, PostgreSQL 17 scratch
  concurrency harness, production migration list/schema/RPC/grant read-only.
- Điểm tốn token/chưa tối ưu: Supabase Dashboard AX tree không hiển thị bảng
  chi tiết; CLI Management API query/read-only cho metadata hiệu quả hơn.
- Cách tối ưu cho phiên sau: tạo disposable Supabase sandbox/branch trước live
  behavior test và bố trí app runtime connection trước khi chạy device acceptance.
- Task-skill cần đọc lần sau: `.codex/task-skills/supabase-schema.md` cho live
  role/RLS acceptance và `.codex/task-skills/test.md` cho app/device acceptance.
