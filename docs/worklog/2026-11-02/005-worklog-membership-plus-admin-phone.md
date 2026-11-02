Commit de xuat: docs(worklog): ghi nhan fix dong bo goi thanh vien va admin phone

# Worklog - Đồng bộ gói Plus và hiển thị số điện thoại Admin

## Thời gian

- Ngày: 2026-11-02
- Bắt đầu: 12:35
- Kết thúc: 12:52
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: bugfix
- Module chính: Flutter membership display; Admin user search
- Mục tiêu: app hiển thị gói thành viên backend đang áp dụng; Admin Web hiển thị số điện thoại đã lưu.

## Nguyên nhân

- Dashboard, Hồ sơ và Cài đặt lấy nhãn gói từ `subscription_tier` trong SQLite cục bộ. Khi Admin cấp Plus, bản ghi local vẫn có thể giữ `free`.
- `effectiveAccessProvider` đọc `GET /api/v1/membership/me` nhưng không được làm mới khi app resume hoặc người dùng refresh các màn hình này.
- Response production của `/api/v1/admin/users/search` không có trường `phone`, dù Admin Web đã hỗ trợ render trường đó.

## Đã làm

- Cập nhật Dashboard, Hồ sơ và Cài đặt để hiển thị `membership_plan` lấy từ endpoint quyền thành viên; trong lúc đang tải hoặc khi API lỗi, app hiển thị trạng thái chưa xác định thay vì khẳng định Free.
- Invalidate quyền thành viên khi app vào foreground và khi kéo làm mới Dashboard, Hồ sơ, Cài đặt.
- Vá response Admin search trên backend production để trả `phone`; file server đã được sao lưu trước khi sửa, không ghi đè các thay đổi chưa commit khác.
- Backend đã được restart trong bước triển khai trước của phiên. Không thay DB, tài khoản, secrets hoặc logic quyền gói.

## Kiểm tra

- `dart format` bốn file Flutter: PASS.
- `flutter analyze` các file đã sửa: không có error/warning; một diagnostic info tại `dashboard_page.dart:155` cho `use_build_context_synchronously`, ở đoạn code ngoài diff.
- Release APK build: PASS - `build/app/outputs/flutter-apk/app-release.apk`.
- Cài APK lên thiết bị: BLOCKED - `INSTALL_FAILED_UPDATE_INCOMPATIBLE` vì signing certificate không khớp bản app hiện có. Không gỡ app cũ hoặc xóa dữ liệu.
- `git diff --check`: PASS.
- HTTPS readiness: PASS - HTTP 200, TLS verify result 0.
- Chrome Admin sau reload: PASS - API ready; danh sách có 7 dòng; dòng đầu hiển thị số điện thoại, Plus và đang hoạt động. Không ghi giá trị số điện thoại.
- Flutter DTD: không có app đang chạy; hot reload/restart không thực hiện được.
- Tests: không chạy. UI app trên thiết bị chưa được xác minh do signing mismatch.

## File thay đổi

- `lib/app/bio_ai_app.dart` - làm mới quyền thành viên khi app resume.
- `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart` - đọc gói từ backend và refresh quyền thành viên.
- `lib/app_versions/v1/features/profile/presentation/pages/profile_page.dart` - đọc gói từ backend và refresh quyền thành viên.
- `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart` - đọc gói từ backend và refresh quyền thành viên.
- Backend production Admin user search - thêm trường `phone` vào response.
- `docs/fixbug/membership-plus-stale-cache/001-fixbug-membership-plus-stale-cache.md` - ghi nhận nguyên nhân, sửa đổi và giới hạn xác minh.

## Giới hạn và bước tiếp

- Source Flutter đã sửa nhưng APK hiện tại chưa chứa thay đổi. Build APK/AAB mới, cài lên thiết bị, mở app khi đã đăng nhập và kiểm tra Dashboard, Hồ sơ, Cài đặt đều hiện Plus; kéo làm mới hoặc đưa app về nền rồi mở lại để xác minh refresh.
- APK đã build nhưng không thể cập nhật đè do signing certificate khác với bản đã cài. Cần dùng đúng signing key của luồng phát hành hiện hành; không gỡ bản cũ vì việc đó có thể xóa dữ liệu cục bộ.
- Admin Web phone field đã được xác minh production trong Chrome; không thực hiện thay đổi dữ liệu.
