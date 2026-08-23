# `delete-account` Edge Function

Hàm này phục vụ thao tác xóa tài khoản từ Flutter. Nó bắt buộc JWT hợp lệ,
yêu cầu body `{ "confirm": true }`, lấy người dùng từ JWT và chỉ gọi Admin API
để xóa chính người dùng đó. Khóa service role chỉ tồn tại trong Edge runtime.

Schema `public.users.id` đã có khóa ngoại `on delete cascade` tới `auth.users`,
nên Supabase Auth xử lý việc xóa các dữ liệu phụ thuộc theo ràng buộc server.

Deploy vào môi trường đã link project:

```bash
supabase functions deploy delete-account --project-ref "$SUPABASE_PROJECT_REF"
deno test --allow-net supabase/functions/delete-account/handler_test.ts
```

Giữ `verify_jwt = true` trong `supabase/config.toml`. Không log JWT, định danh
người dùng, service-role key hoặc chi tiết lỗi Admin API.
