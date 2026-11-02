Commit de xuat: fix(auth): enforce active status for new accounts

# Đảm bảo tài khoản mới luôn hoạt động

## Hiện tượng

Tài khoản mới được báo ở trạng thái không hoạt động. Backend source hiện tại đã khai báo mặc định `is_active=True` và `admin_status="active"`, nhưng các luồng tạo tài khoản dựa vào mặc định ngầm đó.

## Thay đổi

- Gán tường minh `is_active=True` và `admin_status="active"` khi đăng ký điện thoại, Admin tạo một tài khoản và Admin tạo tài khoản hàng loạt.
- Không đổi schema, trạng thái onboarding, hoặc chính sách đổi mật khẩu lần đầu.
- Không cập nhật tài khoản đã có; trạng thái Admin Web vẫn lấy từ backend.

## Kiểm chứng

- Kiểm thử đăng ký điện thoại xác nhận hai trạng thái, đăng nhập được và truy cập `/api/v1/profile/me` thành công dù onboarding vẫn `pending`.
- Kiểm thử tạo đơn lẻ và hàng loạt xác nhận bản ghi mới có `is_active=True`, `admin_status="active"`.
- Ruff, Ruff format check, mypy và toàn bộ backend pytest đều đạt.

## Giới hạn triển khai

- Health endpoint production trả HTTP 200 nhưng không xác nhận revision đang chạy.
- SSH bằng khóa hiện có bị từ chối (`Permission denied (publickey,password)`). Backend chưa được triển khai lại và chưa đăng ký tài khoản production khác.
- Vì vậy kết quả xác nhận source và test cục bộ; hành vi production sau triển khai vẫn cần được xác nhận.
