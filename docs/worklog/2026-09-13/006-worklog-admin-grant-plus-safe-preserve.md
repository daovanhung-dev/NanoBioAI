Commit đề xuất: fix(admin): bảo toàn entitlement khi batch cấp Plus

# Worklog - Batch tạo tài khoản và cấp Plus 30 ngày an toàn

## Thời gian

- Ngày: 2026-09-13
- Múi giờ: Asia/Ho_Chi_Minh (UTC+07:00)

## Phạm vi

- Xử lý danh sách tám địa chỉ do người vận hành cung cấp, không ghi danh sách
  vào repository, output hoặc tài liệu.
- Tài khoản thiếu được tạo qua 'admin-create-account'; tài khoản đã tồn tại
  không bị đổi mật khẩu.
- Cấp Plus 30 ngày qua 'admin-grant-membership'.
- Nếu đã có Plus/FamilyPlus còn hạn, giữ nguyên và ghi audit trạng thái bỏ qua.
- Không ghi trực tiếp vào 'auth.users' hoặc 'membership_subscriptions' bằng SQL.

## Đã làm

- Cập nhật handler để nhận và trả trạng thái preservation/skipped.
- Cập nhật server function để:
  - nhận diện Plus/FamilyPlus đang hiệu lực;
  - ưu tiên FamilyPlus;
  - ghi audit tổng hợp mà không thay đổi entitlement;
  - xử lý idempotency retry sau trạng thái dở dang.
- Tách guard thuần để kiểm thử độc lập.
- Cập nhật batch tool xử lý tuần tự, dừng lỗi đầu tiên, giữ key ổn định và
  chỉ in số thứ tự/trạng thái/tổng kết.
- Giữ 'verify_jwt = true'; deploy riêng một Function.

## File code/docs

- 'supabase/functions/admin-grant-membership/handler.ts'
- 'supabase/functions/admin-grant-membership/index.ts'
- 'supabase/functions/admin-grant-membership/membership-guard.ts'
- 'supabase/functions/admin-grant-membership/handler_test.ts'
- 'supabase/functions/admin-grant-membership/membership-guard_test.ts'
- 'tools/admin-grant-plus/grant.ts'
- 'docs/fixbug/admin-plus-batch-preserve-membership/001-fixbug-admin-plus-batch-preserve-membership.md'

## Bằng chứng

- 'deno check --no-lock' cho các file Edge Function và batch: PASS.
- 'deno test --no-lock' handler và guard: PASS - 15/15.
- 'deno fmt --check' cho guard và batch: PASS.
- 'git diff --check': PASS.
- 'supabase functions deploy admin-grant-membership --project-ref rnwohifdnylqfofkydfl --use-api': PASS.
- 'supabase functions list --project-ref rnwohifdnylqfofkydfl': Function
  'ACTIVE', 'verify_jwt: true'.
- 'curl -X OPTIONS' endpoint production với origin Admin Web: 'HTTP 200', CORS
  headers hợp lệ.

## Trạng thái production

- Function đã được deploy đúng project.
- Batch tạo tài khoản/cấp Plus chưa chạy trong phiên này vì agent không có
  session JWT Super Admin an toàn; không dùng credential đã lộ trong ảnh và
  không nhận credential qua chat.
- Cần hậu kiểm sau khi người vận hành chạy batch: số tài khoản, trạng thái Plus,
  preservation của Plus/FamilyPlus, audit và retry cùng key.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - đường ghi đặc quyền giữ JWT, idempotency và guard
  bảo toàn gói ở server; không đưa credential vào mã hoặc log.
- Mức độ hoàn thành task: hoàn tất code, test và deploy; batch production và
  hậu kiểm dữ liệu còn chờ session local an toàn của người vận hành.
- Bằng chứng kiểm chứng: 15/15 test Deno pass, typecheck pass, deploy production
  pass và preflight HTTP 200.
- Điểm tốn token/chưa tối ưu: rà soát thêm source lịch sử và không thể xác minh
  dữ liệu production khi thiếu session JWT.
- Cách tối ưu cho phiên sau: chuẩn bị session ngắn hạn trực tiếp trên máy vận
  hành, chạy batch một lần rồi hậu kiểm read-only theo cùng idempotency key.
- Task-skill cần đọc lần sau: '.codex/task-skills/coding.md'
