Commit đề xuất: fix(admin-web): xử lý CORS preflight cấp gói

# Fixbug - Không cấp được gói Plus từ Admin Web

## Nguyên nhân

- Browser gửi request `OPTIONS` preflight trước khi gọi `POST` tới
  `admin-grant-membership` vì request có `Authorization` và JSON body.
- Handler chỉ cho phép `POST`, nên preflight nhận `405 Method Not Allowed`.
- Các response JSON của handler cũng chưa có CORS headers, nên browser không
  thể đọc kết quả thành công hoặc lỗi.
- Admin Web vì vậy chỉ hiển thị thông báo chung `Thao tác chưa hoàn tất`.

## Thay đổi

- `admin-grant-membership` trả `200` cho `OPTIONS`.
- Cho phép `POST, OPTIONS` và các request headers cần thiết:
  `authorization`, `x-client-info`, `apikey`, `content-type`.
- Gắn CORS headers cho toàn bộ response JSON của Function.
- Không thay đổi schema, RLS, quyền Super Admin, payload cấp gói,
  idempotency hoặc logic membership.

## Kiểm chứng

- `deno test --allow-net supabase/functions/admin-grant-membership/handler_test.ts`:
  PASS - 8 tests.
- Test mới xác nhận status `200` và đầy đủ CORS headers cho preflight.
- Frontend `npm run typecheck`, `npm test`, `npm run build`: UNVERIFIED trong
  phiên này vì môi trường không có `npm`/`node`.
- Supabase production Function chưa được deploy từ phiên này.

## Rollout

1. Deploy lại `admin-grant-membership` lên đúng Supabase project.
2. Mở Admin Web, xóa request cũ trong Network và thử cấp Plus lại.
3. Xác nhận `OPTIONS` trả `200`, tiếp theo `POST` không còn bị browser chặn.
4. Nếu `POST` vẫn lỗi, đọc status/response mới để xử lý riêng quyền hoặc
   runtime secret; không lặp lại thao tác bằng idempotency key mới khi chưa
   xác định kết quả lần gửi trước.

