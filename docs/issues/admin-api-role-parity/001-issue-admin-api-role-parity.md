Commit de xuat: docs(issue): ghi nhan lech quyen Admin Web va backend

# Admin Web và backend không thống nhất quyền trên một số API

## Tóm tắt

- Các route mà Admin Web gọi đều có trong backend, nhưng quyền do Admin Web hiển thị không thống nhất với allowlist của server.
- Theo guard trong source, một số vai trò được cấp quyền trong `/admin/session` nhưng sẽ nhận `403` khi gọi API tương ứng. Ngược lại, một số API người dùng dùng allowlist mặc định, cho phép `operations_admin` dù session không cấp `users.write` cho vai trò này.

## Kỳ vọng và thực tế

- Kỳ vọng: quyền hiển thị trong Admin Web và quyền server kiểm tra trên cùng API cùng phản ánh một chính sách vai trò.
- Thực tế:
  - `finance_admin` và `content_admin` nhận `dashboard.read`, nhưng `GET /admin/dashboard` dùng `require_admin()` mặc định chỉ nhận `super_admin`, `support_admin`, `operations_admin`.
  - Các vai trò `finance_admin` và `content_admin` nhận `audit.read`, nhưng `GET /admin/audit-events` cũng dùng allowlist mặc định trên.
  - Backend cho phép `finance_admin`/`content_admin` đọc section tương ứng qua `GET /admin/business/{section}`, còn `POST /admin/business/{section}` lại dùng allowlist mặc định, nên mutation đối soát của finance và mutation wellness rewards của content bị từ chối.
  - Backend cho `finance_admin` đọc `sale-conversions`, nhưng cấu hình menu frontend yêu cầu `sales.write`; quyền finance hiện không có permission này nên section bị ẩn.
  - Dashboard luôn gọi API payment alert; endpoint chỉ cho super/finance, còn frontend nuốt lỗi thành số 0 nên support/operations có thể thấy số giao dịch chờ duyệt bằng 0 dù API không trả dữ liệu.
  - Admin Web hiện nút tạo tài khoản cho `support_admin`, còn `POST /admin/accounts` chỉ cho `super_admin`.
  - API tìm kiếm, xem chi tiết, sửa hồ sơ và trạng thái người dùng dùng allowlist mặc định; `operations_admin` không nhận `users.write` từ `/admin/session` nhưng server vẫn chấp nhận vai trò này trên các route đó.

## Mức độ ảnh hưởng

- Severity: medium.
- Người dùng: một số thao tác hiện trong giao diện thất bại với `403`; người có quyền finance/content có thể không xem dashboard/lịch sử hoặc không ghi được dữ liệu thuộc phạm vi của họ.
- Phân quyền: các route người dùng cho phép vai trò rộng hơn quyền được công bố trong session; cần xác nhận đây có phải chủ đích chính sách hay không.

## Cách tái hiện hoặc xác minh

1. Đăng nhập bằng một tài khoản chỉ có `finance_admin` hoặc `content_admin`.
2. Đối chiếu quyền từ `GET /api/v1/admin/session` với route được UI mở.
3. Gọi `GET /api/v1/admin/dashboard` hoặc `GET /api/v1/admin/audit-events`: theo guard source, request bị từ chối với `403 ACCESS_DENIED`.
4. Với finance, thử mutation `POST /api/v1/admin/business/reconciliation`; với content, thử mutation `POST /api/v1/admin/business/wellness-rewards`: source cho thấy route cũng áp dụng allowlist mặc định.
5. Với finance, so sánh backend `GET /api/v1/admin/business/sale-conversions` cho phép role này với `SECTION_CONFIG` frontend yêu cầu `sales.write`.
6. Mở dashboard bằng support/operations: frontend vẫn gọi `GET /api/v1/admin/payments/review-alert`, nhưng endpoint chỉ nhận super/finance và lỗi bị chuyển thành `0`.
7. Đăng nhập `support_admin`, mở Người dùng và thấy nút Tạo tài khoản; gửi form sẽ gọi `POST /api/v1/admin/accounts`, endpoint chỉ nhận `super_admin`, nên theo guard source request bị từ chối.
8. So sánh `operations_admin` không có `users.write` trong session nhưng các route người dùng gọi `require_admin()` không chỉ định role.

## Bằng chứng

- `backend/src/nanobio_backend/modules/admin/router.py:37-84` - quyền được trả trong Admin Session; finance/content có dashboard/audit và quyền section riêng.
- `backend/src/nanobio_backend/modules/business/router.py:222-257` - dashboard dùng guard mặc định; GET business list dùng role scope riêng.
- `backend/src/nanobio_backend/modules/business/router.py:264-275` - mọi mutation business dùng `require_admin(actor)` mặc định.
- `backend/src/nanobio_backend/modules/admin/router.py:295-305` - payment alert chỉ nhận super/finance.
- `backend/src/nanobio_backend/core/security.py:110-113` - role mặc định gồm super, support, operations.
- `backend/src/nanobio_backend/modules/admin/router.py:100-112,115-124,222-265,282-292` - các route người dùng/audit và tạo tài khoản dùng các allowlist khác nhau.
- `admin-web/src/types.ts:305-377,430-434` - quyền section và quy tắc hiển thị nút tạo tài khoản.
- `admin-web/src/pages/DashboardPage.tsx:25-30` - payment alert luôn được gọi và lỗi bị đổi thành 0.
- `admin-web/src/lib/admin-api.ts:178-182` - đọc số lượng pending từ API alert.
- `admin-web/src/pages/AccountsPage.tsx:184-224` - support_admin thấy nút tạo tài khoản.

## Hướng xử lý đề xuất

- Chốt một ma trận vai trò/API làm nguồn chuẩn.
- Đồng bộ allowlist backend với quyền session/UI cho từng route; quyết định rõ các API người dùng mà operations được phép gọi.
- Thêm kiểm tra hợp đồng phân quyền cho dashboard, audit, business mutations, account creation và user-management routes.

## Files/log liên quan

- `admin-web/src/types.ts`
- `admin-web/src/pages/AccountsPage.tsx`
- `backend/src/nanobio_backend/core/security.py`
- `backend/src/nanobio_backend/modules/admin/router.py`
- `backend/src/nanobio_backend/modules/business/router.py`

## Liên kết

- Worklog: ../../worklog/2026-10-31/004-worklog-admin-web-api-contract-audit.md
