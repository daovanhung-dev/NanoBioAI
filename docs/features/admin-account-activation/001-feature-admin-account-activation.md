Commit đề xuất: feat(admin-web): thêm thao tác kích hoạt tài khoản

# Kích hoạt tài khoản trong Admin Web

## Mục tiêu

Cho Super Admin kích hoạt lại tài khoản không hoạt động từ hồ sơ người dùng,
để chủ tài khoản có thể đăng nhập sau khi trạng thái được backend cập nhật.

## Luồng

- Drawer hồ sơ hiển thị `Kích hoạt tài khoản` khi `is_active` là `false` và
  `admin_status` chưa phải `closed`.
- Admin nhập lý do và xác nhận. Giao diện gửi `PATCH
  /api/v1/admin/users/{user_id}/status` với `status: active`, `reason` và
  `idempotency_key`.
- Backend hiện có yêu cầu Super Admin, cập nhật `admin_status`/`is_active`
  trong transaction và ghi audit. Admin Web tải lại hồ sơ và danh sách sau khi
  backend xác nhận thành công.
- Tài khoản đã đóng không có thao tác kích hoạt trong drawer. Các thao tác khác
  đang bị khóa với tài khoản không hoạt động giữ nguyên hành vi hiện có.

## Ràng buộc và bằng chứng

- Thay đổi chỉ thêm giao diện Admin Web và kiểu payload của client; không đổi
  API, schema, trạng thái onboarding, membership hoặc dữ liệu tài khoản.
- Kiểm tra TypeScript tập trung cho các file nguồn ứng dụng: PASS. Typecheck cả
  project chưa chạy được do môi trường không phân giải module `vitest`; chưa
  chạy test suite hoặc triển khai website.
