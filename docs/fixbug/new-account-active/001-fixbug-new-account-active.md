Commit de xuat: fix(auth): enforce active status for new accounts

# Đảm bảo tài khoản mới luôn hoạt động

## Hiện tượng

Tài khoản mới được báo ở trạng thái không hoạt động. Bản sửa source đã gán tường minh `is_active=True` và `admin_status="active"` trong từng luồng tạo; production vẫn cần xác nhận đang chạy đúng revision.

## Thay đổi

- Gán tường minh `is_active=True` và `admin_status="active"` khi đăng ký điện thoại, Admin tạo một tài khoản và Admin tạo tài khoản hàng loạt.
- Không đổi schema, trạng thái onboarding, hoặc chính sách đổi mật khẩu lần đầu.
- Không cập nhật tài khoản đã có; trạng thái Admin Web vẫn lấy từ backend.

## Kiểm chứng

- Kiểm thử đăng ký điện thoại xác nhận hai trạng thái, đăng nhập được và truy cập `/api/v1/profile/me` thành công dù onboarding vẫn `pending`.
- Regression test liên thông xác nhận tài khoản signup có `status=active` và `is_active=true` khi được Admin tìm kiếm.
- Kiểm thử tạo đơn lẻ và hàng loạt xác nhận bản ghi mới có `is_active=True`, `admin_status="active"`.
- Ruff, Ruff format check, mypy và toàn bộ backend pytest đều đạt.

## Điều tra production ngày 2026-11-02

- Điện thoại Android đang cài `1.0.2+7`; API host trong cấu hình app hiện tại là `https://42.118.174.147`.
- Bundle Admin Web đang chạy cũng cấu hình cùng API host. Danh sách lấy trạng thái từ `is_active` trong phản hồi tìm kiếm; backend source trả trực tiếp `user.is_active` và `user.admin_status`.
- Admin Web hiện hiển thị 5 tài khoản không hoạt động. Hồ sơ của cả 5 được mở qua luồng có audit; trường `admin_roles` rỗng ở cả 5, không tài khoản nào có quyền quản trị đang gán.
- Sau khi xem hồ sơ, Admin Web báo API chưa sẵn sàng và khóa thao tác ghi; probe HTTPS `/health/ready` cũng timeout sau 12 giây.
- Chưa tạo tài khoản production test vì chưa có tên và số điện thoại test do người dùng cung cấp. Chưa đổi trạng thái 5 bản ghi; thao tác bật tài khoản cần xác nhận tại thời điểm thực hiện và API phải sẵn sàng.
- SSH key đến máy chủ tiếp tục bị từ chối. Vì vậy chưa thể nối một request signup mới với trace/status, xác nhận revision backend đang chạy hoặc triển khai lại backend.

## Giới hạn triển khai

- Probe trước đó trả HTTP 200 nhưng không xác nhận revision đang chạy; probe `/health/ready` ngày 2026-11-02 timeout và Admin Web khóa thao tác ghi.
- SSH bằng khóa hiện có bị từ chối (`Permission denied (publickey,password)`). Backend chưa được triển khai lại và chưa đăng ký tài khoản production khác.
- Vì vậy kết quả xác nhận source và test cục bộ; hành vi production sau triển khai vẫn cần được xác nhận.
