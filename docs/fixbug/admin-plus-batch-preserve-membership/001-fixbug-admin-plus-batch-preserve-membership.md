Commit đề xuất: fix(admin): bảo toàn gói trả phí khi chạy batch cấp Plus

# Fixbug - Batch tạo tài khoản và cấp Plus 30 ngày an toàn

## Nguyên nhân/rủi ro

- Batch cần tạo tài khoản thiếu và cấp Plus theo từng tài khoản qua các Edge
  Function được bảo vệ.
- Nếu xử lý chung như thao tác cấp gói thủ công thông thường, một tài khoản
  đang có Plus hoặc FamilyPlus còn hạn có thể bị thay thế subscription hiện
  tại.
- Retry sau trạng thái dở dang cần nhận diện đúng idempotency key, không tạo
  thêm entitlement.

## Thay đổi

- Thêm cờ 'preserve_existing_paid_plan' cho luồng batch; hành vi Admin Web cũ
  không truyền cờ này nên không đổi.
- Khi cờ bật, server chọn entitlement Plus/FamilyPlus đang có hiệu lực và ghi
  audit 'skipped', không insert hoặc hủy subscription.
- Ưu tiên FamilyPlus, sau đó entitlement cùng loại có 'starts_at' mới hơn.
- Xử lý subscription đã tạo với cùng idempotency key trước guard bảo toàn để
  retry có thể hoàn tất cleanup/audit của trạng thái dở dang.
- Batch local xử lý tuần tự, dừng ở lỗi đầu tiên, dùng key ổn định theo từng
  địa chỉ, nhận session JWT và mật khẩu tạm qua stdin; output không in
  credential hoặc email.
- Không thay đổi schema, RLS, payment, service-role key hoặc SQL production.

## Kiểm chứng

- 'deno check --no-lock' cho handler, server function, guard và batch: PASS.
- Handler + guard tests: PASS - 15 tests.
- 'git diff --check': PASS.
- Deploy riêng 'admin-grant-membership' lên project NanoBio: PASS.
- Production preflight 'OPTIONS' tới endpoint: 'HTTP 200', đầy đủ CORS headers.
- Function production: 'ACTIVE', 'verify_jwt: true'.
- Batch production: CHƯA THỰC THI trong phiên này vì không có session JWT
  Super Admin an toàn trong stdin; không sử dụng token từng xuất hiện trong
  ảnh hoặc nhận credential qua chat.

## Rollout còn lại

1. Người vận hành mở phiên Admin Web mới và cấp session JWT trực tiếp vào stdin
   của 'tools/admin-grant-plus/grant.ts'.
2. Nhập mật khẩu tạm qua stdin và danh sách tám địa chỉ đã được phê duyệt.
3. Kiểm tra output tổng hợp, Admin Web và truy vấn chỉ đọc; nếu lỗi, dừng và
   chỉ chạy lại với cùng input/idempotency key.
4. Xác nhận các tài khoản Plus/FamilyPlus cũ vẫn giữ nguyên thời hạn.
