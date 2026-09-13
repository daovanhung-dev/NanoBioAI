Commit đề xuất: feat(admin-web): hiển thị và điều chỉnh thời hạn gói

# Điều chỉnh và hiển thị thời hạn gói trong Admin Web

## Mục tiêu

- Hiển thị thời điểm bắt đầu/kết thúc của subscription hiện hành trong danh
  sách Người dùng và drawer chi tiết, theo `Asia/Ho_Chi_Minh`.
- Cho Super Admin điều chỉnh subscription `manual` đang hiệu lực bằng số ngày
  cộng/trừ hoặc ngày kết thúc tuyệt đối.
- Giữ toàn bộ thay đổi membership ở trusted backend; không mở ghi trực tiếp từ
  Admin Web, không thay đổi Flutter Admin cũ, bulk provisioning hoặc payment
  provider/Google Play.

## Phạm vi đã triển khai

- `admin_search_users` trả plan hiện hành, `subscription_id`, status, source,
  `starts_at` và `ends_at`; subscription paid không có `ends_at` hiển thị là
  `Không thời hạn`, tài khoản không có gói paid hiển thị `—`.
- Drawer trả và hiển thị đầy đủ plan/source/start/end, đồng thời có nút
  `Chỉnh thời hạn` khi actor là Super Admin và membership là manual hiện hành.
- Form cấp gói giữ reason bắt buộc và bước xác nhận, thêm lựa chọn `Tùy chỉnh`
  với `datetime-local`; giá trị được chuyển từ giờ Việt Nam sang UTC trước khi
  gửi endpoint cấp gói hiện có.
- Form chỉnh hạn có `Thêm số ngày`, `Giảm số ngày`, `Chọn ngày kết thúc`,
  preview trước/sau, cảnh báo hết hạn ngay và không báo thành công trước khi
  backend xác nhận.

## Backend contract

- Rebuild SQL drop/recreate đúng signature của `admin_search_users` và bổ sung
  RPC `admin_adjust_membership_period`.
- RPC khóa `membership_subscriptions` bằng `FOR UPDATE`, kiểm tra actor là
  Super Admin active, user/subscription khớp, source `manual`, trạng thái hiện
  hành và `expected_ends_at` không stale.
- `add_days`/`subtract_days` chỉ nhận `p_days` và không nhận end date; gói vô
  thời hạn chỉ được `set_end_at`. End date có thể ở quá khứ nhưng phải lớn hơn
  `starts_at`, khi đó status chuyển thành `expired`.
- `ends_at` và `current_period_end` cập nhật cùng transaction; trigger hiện
  hành đồng bộ quyền ở `users`; audit lưu before/after summary, reason và
  idempotency key. Retry cùng key trả lại kết quả đã ghi; dùng key cho target
  khác bị từ chối.
- Edge Function `admin-adjust-membership-period` yêu cầu JWT, tự kiểm tra
  Super Admin, chỉ gọi RPC bằng service role và trả lỗi an toàn không lộ chi
  tiết backend. `verify_jwt = true`.

## Kiểm thử và rollout

- Admin Web có test mapper, permission, format/parse thời gian Việt Nam, form
  validation và payload API.
- Deno handler tests bao phủ CORS, JWT/Super Admin, validation, payload chuẩn
  hóa và che lỗi backend; Dart contract tests bao phủ SQL signature, manual-only
  guard, row lock, expiry, audit/idempotency, Edge Function config và
  service-role boundary.
- Chưa áp dụng SQL vào Supabase sandbox, deploy Edge Function hoặc browser-smoke
  trong workspace này. Trước rollout cần test hữu hạn, vô thời hạn,
  provider-managed, giảm hết hạn và retry cùng idempotency key trên sandbox.

## Ràng buộc dữ liệu

- `ends_at IS NULL` vẫn là gói không thời hạn; không suy diễn từ
  `current_period_end` và không sửa seed hiện có.
- Thời gian nhập là local date-time `Asia/Ho_Chi_Minh`, lưu dưới dạng UTC.
