Commit de xuat: feat(app): hop nhat entrypoint va tu dong chon giao dien theo quyen

# Ứng dụng hợp nhất theo quyền tài khoản

## Phạm vi

- Chỉ chạy `lib/main.dart`; loại bỏ `lib/main_v2.dart` và `lib/main_admin.dart`.
- Dùng một phiên Supabase cho giao diện người dùng và giao diện quản trị.
- Nhập route V1, V2 và V3 vào router người dùng hiện tại.
- Quyền quản trị tiếp tục lấy từ RPC `get_my_admin_session`; Flutter không tự gán role.

## Quy tắc chọn giao diện

| Trạng thái tài khoản | `app_access_mode` | Giao diện sau đăng nhập |
|---|---|---|
| Không có role Admin | `user` | Người dùng |
| Có role Admin, chỉ quản trị | `admin` | Quản trị |
| Có role Admin và dùng cả hai bề mặt | `both` | Người dùng; có nút chuyển sang quản trị trong Cài đặt |

- Tài khoản `both` có nút **Chuyển sang giao diện quản trị** trong Cài đặt.
- Trong giao diện quản trị, tài khoản `both` có nút **Giao diện người dùng** để quay lại.
- Chuyển giao diện không đăng nhập lại và không tạo phiên Supabase thứ hai.
- Nếu role Admin bị thu hồi, ứng dụng quay về giao diện người dùng nhưng không đăng xuất phiên người dùng.

## Backend contract

- `public.users.app_access_mode` nhận một trong `user`, `admin`, `both`.
- `get_my_admin_session()` trả thêm `app_access_mode` và `can_use_user_app`.
- `app_access_mode` là server-owned; quyền update trực tiếp từ `anon`/`authenticated` bị thu hồi.
- Khi nâng cấp schema, Admin đang hoạt động có mode cũ `user` được chuyển thành `both` để không mất giao diện người dùng.
- `bootstrap_admin_by_email` đặt tài khoản Admin mới thành `both`, trừ tài khoản đã được cấu hình rõ là `admin`.

## Tệp chính

- `lib/main.dart`
- `lib/app/bio_ai_app.dart`
- `lib/app/app_surface_controller.dart`
- `lib/app_versions/v2/router/v2_router.dart`
- `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart`
- `lib/app_versions/admin/features/admin_panel/`
- `docs/supabase/17-unified-app-role-surface.sql`
- `docs/supabase/11-admin-access-dashboard.sql`
- `docs/supabase/config.sql`

## Kiểm chứng

- Có unit contract cho resolver: Guest/người thường, Admin-only và dual-role.
- Có contract kiểm tra entrypoint duy nhất, route V3 được nhập và SQL trả mode truy cập.
- Môi trường đóng gói hiện tại không có Flutter/Dart nên chưa chạy `dart format`, `flutter analyze`, `flutter test` hoặc build thiết bị.
