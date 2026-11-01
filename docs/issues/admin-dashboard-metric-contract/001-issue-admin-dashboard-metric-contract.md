Commit de xuat: docs(issue): ghi nhan lech contract metric dashboard

# Dashboard Admin dùng metric key backend không cung cấp

## Tóm tắt

- Route `GET /admin/dashboard` và cấu trúc metric cơ bản có ở cả frontend lẫn backend.
- Các thẻ tổng quan cố định tra `users_total` và `revenue_succeeded`, trong khi backend trả `users` và không trả metric doanh thu.

## Kỳ vọng và thực tế

- Kỳ vọng: các metric mà DashboardPage tra cứu có mặt trong danh sách metric backend trả về.
- Thực tế: API trả metric key `users`, `active_memberships`, `sale_profiles_pending`, `payment_reviews`, `reward_redemptions`. DashboardPage đọc `users_total` để hiện số người dùng trong ưu tiên và `revenue_succeeded` để hiện doanh thu đã duyệt. Hai lookup này không khớp response; số người dùng trong phần ưu tiên rơi về `0`, còn doanh thu không có dữ liệu.

## Mức độ ảnh hưởng

- Severity: medium.
- Người vận hành có thể đọc nhầm số người dùng là 0 và không thấy doanh thu đã duyệt ở snapshot, dù backend trả metric tổng người dùng dưới key khác.

## Cách tái hiện hoặc xác minh

1. Đọc `GET /api/v1/admin/dashboard` trong frontend hoặc kiểm tra response từ backend.
2. Xác nhận danh sách trả về có `metric_key: "users"`, không có `users_total` hoặc `revenue_succeeded`.
3. Mở DashboardPage: phần ưu tiên tìm `users_total`; snapshot tìm `revenue_succeeded`.

## Bằng chứng

- `admin-web/src/pages/DashboardPage.tsx:46-66` - map response theo `metric.key`; lookup `users_total` và `revenue_succeeded`.
- `admin-web/src/lib/admin-api.ts:165-175` - chuyển `metric_key` của response thành `key` trực tiếp, không đổi tên alias.
- `backend/src/nanobio_backend/modules/business/view.py:724-793` - backend chỉ tạo metric `users`, `active_memberships`, `sale_profiles_pending`, `payment_reviews`, `reward_redemptions`.
- `backend/src/nanobio_backend/modules/business/router.py:222-235` - route dashboard trả danh sách metric từ view.

## Hướng xử lý đề xuất

- Thống nhất tên metric và metric được hỗ trợ giữa hợp đồng API và DashboardPage.
- Thêm kiểm tra hợp đồng response cho các metric mà giao diện phụ thuộc.

## Files/log liên quan

- `admin-web/src/pages/DashboardPage.tsx`
- `admin-web/src/lib/admin-api.ts`
- `backend/src/nanobio_backend/modules/business/view.py`
- `backend/src/nanobio_backend/modules/business/router.py`

## Liên kết

- Worklog: ../../worklog/2026-10-31/004-worklog-admin-web-api-contract-audit.md
