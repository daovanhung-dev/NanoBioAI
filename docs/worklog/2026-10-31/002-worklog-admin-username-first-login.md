# Worklog - Đăng nhập Admin bằng username và đổi mật khẩu lần đầu

## Phạm vi

- Loại task: feature
- Module chính: backend auth, Admin Web
- Yêu cầu gốc: Gắn username `admin` vào user `super_admin` hiện tại, cấp mật khẩu tạm và buộc đổi trước khi mở dashboard.

## Đã làm

- Thêm cột username tùy chọn và unique index không phân biệt hoa thường bằng Alembic revision `0007_admin_username`.
- Backend nhận đúng một trong username, email hoặc số điện thoại; username được chuẩn hóa chữ thường và xuất trong session.
- Admin Web gửi identifier theo đúng loại, nhận cờ `must_change_password`, hiển thị form đặt mật khẩu mới và chưa gọi API Admin khi cờ còn bật.
- Sau khi đổi mật khẩu, Admin Web nhận phiên mới, xác minh quyền quản trị rồi điều hướng tới dashboard.
- Provision tài khoản `super_admin` hiện có, giữ UUID/role/dữ liệu, lưu Argon2 hash, bật bắt buộc đổi mật khẩu và thu hồi phiên refresh đang hoạt động. Mật khẩu tạm không được ghi vào source, cấu hình hoặc worklog.

## Triển khai và kiểm chứng

- Sao lưu DB `nanobio` trước migration tại `/var/backups/nanobio/nanobio-before-admin-username-20261031.dump` (337,366 bytes, mode 600, owner `postgres:postgres`); giữ nguyên `nanobio_legacy`.
- Production Alembic chạy từ `0006_referral_comm` lên `0007_admin_username`; `nanobio-backend` khởi động lại và active.
- Push commit `5cd959f3` lên `codex/self-hosted-cutover`; workflow `Deploy NanoBio Admin Web` run `41175096383` hoàn tất success.
- Trang GitHub Pages và `/health/ready` trả HTTP 200. Bundle live dùng `https://42.118.174.147`, có label đăng nhập username/email/phone và luồng đổi mật khẩu; không chứa Supabase SDK/domain.
- Smoke test qua HTTPS: đăng nhập `admin` trả role `super_admin` và `must_change_password=true`; `/admin/session` bị chặn với `403 PASSWORD_CHANGE_REQUIRED`; logout thành công.
- Backend: Ruff check/format, mypy và toàn bộ pytest đều qua; có 2 test được skip.
- Admin Web: typecheck, 67 test và production build đều qua.
- Alembic rehearsal SQLite cô lập nâng cấp thành công tới `0007_admin_username`.

## Còn cần người dùng hoàn tất

- Đăng nhập trang Admin Web bằng username `admin` và mật khẩu tạm đã cấp, rồi tự đặt mật khẩu cá nhân mới. Backend sẽ chỉ mở dashboard sau bước này.
- Chưa xác nhận dashboard trực tiếp sau lần đổi mật khẩu do người dùng cần tự chọn mật khẩu mới; quyền truy cập trước thời điểm đổi đã được kiểm tra bị khóa.

## Giới hạn

- Không thay đổi Supabase, user UUID, role, hoặc dữ liệu khác.
- Không ghi mật khẩu tạm hay hash vào worklog.
