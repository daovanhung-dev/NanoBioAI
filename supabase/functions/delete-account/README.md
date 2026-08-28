# `delete-account` Edge Function

Lifecycle: `Current`. Implementation: `Static-verified` at baseline `25018e8`;
deployment and Supabase runtime remain `Sandbox-unverified` unless rerun.

Hàm này phục vụ thao tác xóa tài khoản từ Flutter. Nó bắt buộc JWT hợp lệ,
yêu cầu body `{ "confirm": true }`, lấy người dùng từ JWT và chỉ gọi Admin API
để xóa chính người dùng đó. Khóa service role chỉ tồn tại trong Edge runtime.

Schema `public.users.id` đã có khóa ngoại `on delete cascade` tới `auth.users`,
nên Supabase Auth xử lý dữ liệu phụ thuộc theo ràng buộc server. Trước khi row
profile bị xóa, trigger `anonymize_deleted_user_records` giữ purchase ledger
không gắn user để reconciliation và thay snapshot/note/installation của
`ai_content_reports` bằng dữ liệu ẩn danh; không giữ nội dung người dùng.

Deploy vào môi trường đã link project:

```bash
supabase functions deploy delete-account --project-ref "$SUPABASE_PROJECT_REF"
deno test --allow-net supabase/functions/delete-account/handler_test.ts
```

Giữ `verify_jwt = true` trong `supabase/config.toml`. Không log JWT, định danh
người dùng, service-role key hoặc chi tiết lỗi Admin API.
