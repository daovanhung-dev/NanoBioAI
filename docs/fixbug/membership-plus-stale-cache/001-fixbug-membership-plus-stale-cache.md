Commit de xuat: fix(membership): refresh effective plan in app and expose admin phone

# Đồng bộ gói Plus trong app và số điện thoại trong Admin

## Hiện tượng

- Tài khoản đã được cấp gói Plus và Admin hiển thị Plus, nhưng một số màn hình app vẫn hiển thị gói Miễn phí.
- Admin Web có cột số điện thoại nhưng hiển thị dấu gạch ngang cho tài khoản có số điện thoại.

## Nguyên nhân

- Dashboard, Hồ sơ và Cài đặt trong app lấy nhãn gói từ `subscription_tier` trong SQLite cục bộ. Dữ liệu này có thể vẫn là `free` sau khi gói được cấp ở backend.
- Provider đọc quyền thành viên từ `GET /api/v1/membership/me` nhưng giữ kết quả trong cache và không được làm mới khi quay lại app hoặc kéo làm mới ở các màn hình liên quan.
- Admin Web đã đọc trường `phone`; response production của `/api/v1/admin/users/search` thiếu trường đó nên giao diện hiện dấu gạch ngang.

## Thay đổi

- Dashboard, Hồ sơ và Cài đặt dùng `effectiveAccessProvider` làm nguồn gói thành viên hiện hành; trạng thái loading/lỗi không còn hiển thị nhầm Free.
- Làm mới quyền thành viên khi app trở lại foreground và khi người dùng kéo làm mới Dashboard, Hồ sơ hoặc Cài đặt.
- Trên backend production, bổ sung `phone` vào response Admin user search. Đã sao lưu file trước khi vá và giữ nguyên các chỉnh sửa chưa commit khác trong checkout server.
- Không sửa DB, tài khoản, luồng đăng nhập, token hoặc quyền gói.

## Kiểm chứng

- `dart format` cho bốn file Flutter: đạt.
- `flutter analyze` bốn file: không có error/warning; có một diagnostic mức info `use_build_context_synchronously` tại đoạn code dashboard không thuộc diff hiện tại.
- Release APK build: đạt, tạo `build/app/outputs/flutter-apk/app-release.apk`.
- Cài APK lên điện thoại qua `adb install -r`: bị Android từ chối với `INSTALL_FAILED_UPDATE_INCOMPATIBLE` vì chữ ký khác bản đang cài. Không gỡ ứng dụng cũ; dữ liệu trên máy được giữ nguyên.
- `git diff --check`: đạt.
- HTTPS readiness `https://nanobio.s2w.click/health/ready`: HTTP 200, TLS verification hợp lệ (`tls_verify=0`).
- Admin Web trên Chrome sau khi reload: API sẵn sàng, 7 dòng tài khoản; dòng đầu có số điện thoại, gói Plus và trạng thái đang hoạt động. Giá trị số điện thoại không được ghi lại.
- DTD không có app Flutter đang chạy nên không thể hot reload/restart. Vì chữ ký khác nhau, APK mới chưa cài được để xác minh UI trên thiết bị.
- Tests không chạy; phần app cần kiểm tra giao diện thủ công sau khi cài được bản mới.

## Giới hạn triển khai

- Bản Flutter đang cài trên điện thoại chưa nhận các sửa đổi source trong worktree. Cần build qua luồng phát hành dùng đúng signing key của app đã cài, hoặc chọn quy trình cài khác có chủ đích; không thể cập nhật bằng APK ký bằng key hiện tại.
- Admin phone được xác minh trong Chrome production sau khi backend restart; số điện thoại không được đưa vào tài liệu.
