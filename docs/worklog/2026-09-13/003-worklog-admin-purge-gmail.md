Yê

Commit đề xuất: feat(admin): thêm preview purge Gmail có kiểm soát

# Worklog - Preview và purge tài khoản Gmail thật

## Thời gian

- Ngày: 2026-09-13
- Múi giờ: Asia/Ho_Chi_Minh (UTC+07:00)

## Phạm vi

- Project Supabase: NanoBio, ref `rnwohifdnylqfofkydfl`.
- Chỉ email domain `@gmail.com`, không phân biệt hoa thường.
- Giữ mọi user có Admin assignment active; không xử lý domain khác hoặc fixture.
- Cơ chế xóa: Edge Function tạm thời, Auth Admin API, preview trước.

## Đã làm

- Thêm `admin-purge-gmail-accounts` với `verify_jwt = true` trong config.
- Thêm guard Super Admin active và loại trừ user có Admin role active.
- Thêm Auth user pagination, lọc Gmail exact suffix và fingerprint ổn định.
- Thêm confirmation bắt buộc, count/fingerprint re-check và idempotency audit.
- Xóa tuần tự, dừng tại lỗi đầu tiên, trả summary và giữ lỗi backend ở mức an toàn.
- Thêm công cụ local đọc session JWT từ stdin, lưu preview quyền `0600`, không
  in danh sách email ra terminal.
- Không thay đổi schema, RLS, membership, payment hoặc dữ liệu production.

## Kiểm chứng code

- `deno check --no-lock supabase/functions/admin-purge-gmail-accounts/handler.ts`:
  PASS.
- `deno check --no-lock supabase/functions/admin-purge-gmail-accounts/index.ts`:
  PASS.
- `deno check --no-lock tools/admin-purge-gmail/purge.ts`: PASS.
- `deno test --no-lock --allow-net supabase/functions/admin-purge-gmail-accounts/handler_test.ts`:
  PASS - 11 tests.
- `git diff --check`: PASS sau khi hoàn tất code và tài liệu.

## Rollout production

- Chưa chạy preview production vì agent không có session JWT Admin khả dụng và
  không yêu cầu người dùng gửi JWT vào chat.
- Đã deploy riêng Function `admin-purge-gmail-accounts` vào project NanoBio;
  runtime list xác nhận `ACTIVE`, version 2 và `verify_jwt = true`.
- Đã kiểm tra production preflight: `OPTIONS` trả HTTP 200 với CORS headers.
- Đã kiểm tra POST bằng anon JWT: HTTP 401, xác nhận gateway/guard không cho
  tài khoản không có session Admin thực hiện preview.
- Đã sửa lỗi rollout phát hiện sau deploy: `index.ts` tạo handler nhưng thiếu
  `Deno.serve`, khiến request timeout dù Function báo `ACTIVE`.
- Chưa thực hiện delete production.
- Chưa xóa Function tạm thời; chỉ làm sau khi hậu kiểm sau delete thành công.

Lệnh người vận hành chạy local sau khi deploy Function:

```bash
set -a
source <(grep -E '^(SUPABASE_URL|SUPABASE_ANON_KEY)=' .env)
set +a
read -rsp 'Admin session JWT: ' NANOBIO_PURGE_JWT; printf '\n'
printf '%s' "$NANOBIO_PURGE_JWT" | \
  deno run --no-check --allow-env --allow-net --allow-read --allow-write \
  tools/admin-purge-gmail/purge.ts preview \
  --output /tmp/nanobio-gmail-preview.json
unset NANOBIO_PURGE_JWT SUPABASE_URL SUPABASE_ANON_KEY
```

Terminal chỉ trả count/fingerprint/path. Sau khi kiểm tra file local, delete
chỉ được gọi bằng cùng preview count/fingerprint và confirmation chính xác.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - destructive path có preview, re-check và audit.
- Mức độ hoàn thành task: code và test hoàn tất; deploy/preview/delete production
  còn chờ runtime session và xác nhận cuối.
- Bằng chứng kiểm chứng: Deno check 3 entry points và 11 handler tests PASS.
- Điểm tốn token/chưa tối ưu: không có browser session để chạy preview production;
  không đọc lại toàn bộ schema ngoài các contract cần thiết.
- Cách tối ưu cho phiên sau: sau preview, chỉ chạy delete một lần với cùng
  idempotency key, rồi hậu kiểm trước khi gỡ Function.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
