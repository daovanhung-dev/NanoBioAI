Commit de xuat: feat(app): hop nhat entrypoint va tu dong chon giao dien theo quyen

# Worklog - Hợp nhất phiên bản và phân giao diện theo quyền

## Thời gian

- Ngày: 2026-07-13
- Timezone: Asia/Bangkok (UTC+07:00)
- Loại task: coding/test/docs

## Công việc hiện tại

- Gộp V1/V2/V3/Admin về một entrypoint `lib/main.dart`.
- Dùng chung một phiên Supabase và tự động chọn giao diện sau đăng nhập.
- Hỗ trợ tài khoản chỉ Admin, chỉ người dùng và tài khoản có cả hai quyền.

## Thay đổi đã thực hiện

- Tạo `BioAIApp` và `AppSurfaceController` để phân giải bề mặt ứng dụng từ phiên đăng nhập, quyền Admin và `app_access_mode`.
- `main.dart` khởi tạo một Supabase client/session, override cả auth availability người dùng và Admin, sau đó chạy `BioAIApp`.
- Xóa `main_v2.dart`, `main_admin.dart`; cập nhật VS Code launch, integration preflight và regression scripts về `main.dart`.
- Nhập `v3Routes` vào `v2RouterProvider`; V1/V2/V3 chạy trong router người dùng thống nhất.
- Admin access không còn tự sign-out tài khoản không có/quá hạn role Admin; role bị thu hồi chỉ trả về giao diện người dùng.
- Tài khoản `both` có nút chuyển sang Admin trong Cài đặt và nút quay lại giao diện người dùng trong Admin top bar.
- Bổ sung `public.users.app_access_mode`, trường `can_use_user_app` trong RPC, thu hồi client update cột quyền và nâng existing active Admin thành `both`.
- Cập nhật unit/static contract cho resolver, Admin session, auth router, single entrypoint và Supabase SQL.

## Tệp chính đã sửa/tạo

- `lib/main.dart` - sửa - entrypoint duy nhất và shared Supabase bootstrap.
- `lib/app/bio_ai_app.dart` - tạo - root chọn user/Admin surface.
- `lib/app/app_surface_controller.dart` - tạo - trạng thái chuyển surface và resolver thuần.
- `lib/main_v2.dart`, `lib/main_admin.dart` - xóa.
- `lib/app_versions/v2/router/v2_router.dart`, `lib/app_versions/v3/router/v3_router.dart` - sửa - hợp nhất route V1/V2/V3.
- `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart` - sửa - nút chuyển Admin cho dual-role.
- `lib/app_versions/admin/features/admin_panel/` - sửa - session mode, không sign-out nhầm, chuyển hai chiều.
- `docs/supabase/17-unified-app-role-surface.sql` - tạo - migration không phá hủy cho database hiện tại.
- `docs/supabase/11-admin-access-dashboard.sql`, `docs/supabase/config.sql` - sửa - role surface contract.
- `.vscode/launch.json`, `tools/regression/`, `integration_test/`, `test/` - sửa - entrypoint và contract mới.
- `.codex/Design.md`, `.codex/MAP_TREE.md`, `.codex/PROJECT_MAP.md`, `.codex/AGENTS.md` - sửa - context kiến trúc hiện tại.

## Lệnh và kiểm chứng

- Tìm `flutter`, `dart`, `pwsh`, `powershell`: không có trong môi trường.
- Static grep entrypoint/role/route/SQL và import/bracket scan 22 changed Dart files: PASS.
- JSON parse `.vscode/launch.json`: PASS.
- Dart formatter/analyzer/tests/build: SKIPPED do môi trường không có Flutter/Dart.
- `.codex` PowerShell integrity/history refresh: SKIPPED do không có PowerShell.

## Chú ý và rủi ro

- Phải apply migration Admin cập nhật trên Supabase sandbox trước khi kiểm tra thực tế `app_access_mode`.
- `app_access_mode='admin'` dùng cho tài khoản chỉ quản trị; `both` dùng cho tài khoản có hai giao diện.
- Không chạy `docs/supabase/config.sql` trên production vì đây là destructive rebuild script; dùng migration workflow phù hợp.
- Cần chạy `flutter analyze`, full `flutter test`, login smoke ba loại tài khoản và build thiết bị trong môi trường Flutter thật.

## Phân task / việc tiếp theo

- Apply SQL vào sandbox và tạo ba account smoke: user-only, admin-only, both.
- Kiểm tra login/restore/sign-out/role revoke và chuyển hai chiều trên Android.
- Chạy format, analyze, targeted/full tests và build `lib/main.dart`.
