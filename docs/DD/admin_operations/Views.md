# Views — ADMIN_OPS / Admin quản lý hệ thống

## 0. View Inventory

| ID | View Name | Route / Entry Point | Actor | Feature | Type | Data Source | Status | Mockup |
|---|---|---|---|---|---|---|---|---|
| ADMIN_OPS-V01 | Admin management views | planned route/action for admin_operations | Admin, Super Admin | ADMIN_OPS-F01 | Page / Flow / Admin view | ADMIN_OPS-API01 | Draft | assets/README.md |
| ADMIN_OPS-V02 | Finance admin queue | planned route/action for admin_operations | Finance Admin, Super Admin | ADMIN_OPS-F02 | Page / Flow / Admin view | ADMIN_OPS-API02 | Draft | assets/README.md |

## 1. Navigation Map

| Source | Action | Destination | Condition |
|---|---|---|---|
| Module entry | Actor selects feature action | Feature view | Actor has permission and dependency data can load |
| Feature view | Submit/confirm | Result state or next feature | ADMIN_OPS-FNxx succeeds |
| Any view | Permission/data error | Safe error state | UI, route, use-case, or API blocks access |

---

<a id="admin_ops-v01"></a>
# ADMIN_OPS-V01 — Admin management views

## A. Thông tin cơ bản

| Trường | Nội dung |
|---|---|
| Feature liên quan | ADMIN_OPS-F01 |
| Route / entry point | Planned route/action for admin_operations; final route must follow app router DD/code. |
| Loại view | Page / Screen / Widget / Admin view depending on platform surface |
| Actor được phép | Admin, Super Admin |
| Điều kiện truy cập | Theo quyền hiệu lực trong BD sections 3 và 5. |
| Hành vi khi không đủ quyền | Chặn ở route/use-case/API; UI chỉ hiển thị hướng dẫn an toàn. |
| Responsive | Mobile first for app surfaces; desktop/tablet for Admin surfaces. |
| Mockup / prototype | PLANNED CONFIRMATION: mockup chưa có trong BD, lưu sau vào assets/. |

## B. Layout và thành phần giao diện

| Component ID | Khu vực | Loại | Nội dung / label | Hiển thị khi | Dữ liệu nguồn | Validation / rule |
|---|---|---|---|---|---|---|
| ADMIN_OPS-V01-C01 | Header | Title / navigation | Admin management views | Always | Static + module state | None |
| ADMIN_OPS-V01-C02 | Body | Form/list/detail | Dữ liệu nghiệp vụ của Admin quản lý hệ thống | Actor có quyền | ADMIN_OPS-API01 | ADMIN_OPS-BR01 |
| ADMIN_OPS-V01-C03 | Action | Primary button/action | Admin opens management module | Khi trạng thái hợp lệ | UI state | ADMIN_OPS-FN01 |
| ADMIN_OPS-V01-C04 | Feedback | Alert/toast/empty | Hướng dẫn, lỗi hoặc kết quả | Khi có trạng thái tương ứng | Result/Error | Không lộ stack trace/DB/API/secret |

## C. Trạng thái giao diện bắt buộc

| State | Điều kiện kích hoạt | UI phải hiển thị | Hành động cho người dùng |
|---|---|---|---|
| Initial | Lần đầu mở view | Skeleton hoặc trạng thái mặc định | Chờ dữ liệu |
| Loading | Đang gọi ADMIN_OPS-FN01 hoặc API | Loading không gây layout shift, khóa duplicate action nếu cần | Chờ |
| Success | Kết quả hợp lệ | Dữ liệu/trạng thái mới và CTA tiếp theo | Tiếp tục flow |
| Empty | Không có dữ liệu | Lý do và CTA phù hợp | Tạo mới/quay lại |
| Validation error | Input sai | Field-level message bằng tiếng Việt/Nabitone | Sửa dữ liệu |
| Business error | Vi phạm rule | Message an toàn, không thuật ngữ nội bộ | Làm theo hướng dẫn |
| System error | Network/5xx/dependency lỗi | Retry + correlation id khi cần hỗ trợ | Thử lại/liên hệ hỗ trợ |
| Unauthorized/Forbidden | Thiếu đăng nhập/quyền | Login/no permission view | Đăng nhập/quay lại |

## D. Tương tác và mapping đến function

| Interaction ID | Người dùng thao tác | Điều kiện | Hệ thống gọi | Thành công | Thất bại | Navigation |
|---|---|---|---|---|---|---|
| ADMIN_OPS-V01-I01 | Admin opens management module | Input và quyền hợp lệ | ADMIN_OPS-FN01 | Refresh trạng thái Admin quản lý hệ thống | Hiển thị lỗi an toàn | Giữ view hoặc tới bước kế tiếp |
| ADMIN_OPS-V01-I02 | Tải lại dữ liệu | User có quyền xem | ADMIN_OPS-FN02 hoặc API đọc | Cập nhật view | Empty/error state | Không đổi route |

## E. Acceptance checklist cho QA/UI

- [ ] View chỉ hiển thị đúng role và trạng thái.
- [ ] Các state bắt buộc đều có thiết kế và test.
- [ ] Action chính gọi đúng ADMIN_OPS-FN01.
- [ ] Error message không lộ thông tin kỹ thuật hoặc dữ liệu nhạy cảm.
---

<a id="admin_ops-v02"></a>
# ADMIN_OPS-V02 — Finance admin queue

## A. Thông tin cơ bản

| Trường | Nội dung |
|---|---|
| Feature liên quan | ADMIN_OPS-F02 |
| Route / entry point | Planned route/action for admin_operations; final route must follow app router DD/code. |
| Loại view | Page / Screen / Widget / Admin view depending on platform surface |
| Actor được phép | Finance Admin, Super Admin |
| Điều kiện truy cập | Theo quyền hiệu lực trong BD sections 3 và 5. |
| Hành vi khi không đủ quyền | Chặn ở route/use-case/API; UI chỉ hiển thị hướng dẫn an toàn. |
| Responsive | Mobile first for app surfaces; desktop/tablet for Admin surfaces. |
| Mockup / prototype | PLANNED CONFIRMATION: mockup chưa có trong BD, lưu sau vào assets/. |

## B. Layout và thành phần giao diện

| Component ID | Khu vực | Loại | Nội dung / label | Hiển thị khi | Dữ liệu nguồn | Validation / rule |
|---|---|---|---|---|---|---|
| ADMIN_OPS-V02-C01 | Header | Title / navigation | Finance admin queue | Always | Static + module state | None |
| ADMIN_OPS-V02-C02 | Body | Form/list/detail | Dữ liệu nghiệp vụ của Admin quản lý hệ thống | Actor có quyền | ADMIN_OPS-API02 | ADMIN_OPS-BR01 |
| ADMIN_OPS-V02-C03 | Action | Primary button/action | Review payment/conversion/adjustment | Khi trạng thái hợp lệ | UI state | ADMIN_OPS-FN02 |
| ADMIN_OPS-V02-C04 | Feedback | Alert/toast/empty | Hướng dẫn, lỗi hoặc kết quả | Khi có trạng thái tương ứng | Result/Error | Không lộ stack trace/DB/API/secret |

## C. Trạng thái giao diện bắt buộc

| State | Điều kiện kích hoạt | UI phải hiển thị | Hành động cho người dùng |
|---|---|---|---|
| Initial | Lần đầu mở view | Skeleton hoặc trạng thái mặc định | Chờ dữ liệu |
| Loading | Đang gọi ADMIN_OPS-FN02 hoặc API | Loading không gây layout shift, khóa duplicate action nếu cần | Chờ |
| Success | Kết quả hợp lệ | Dữ liệu/trạng thái mới và CTA tiếp theo | Tiếp tục flow |
| Empty | Không có dữ liệu | Lý do và CTA phù hợp | Tạo mới/quay lại |
| Validation error | Input sai | Field-level message bằng tiếng Việt/Nabitone | Sửa dữ liệu |
| Business error | Vi phạm rule | Message an toàn, không thuật ngữ nội bộ | Làm theo hướng dẫn |
| System error | Network/5xx/dependency lỗi | Retry + correlation id khi cần hỗ trợ | Thử lại/liên hệ hỗ trợ |
| Unauthorized/Forbidden | Thiếu đăng nhập/quyền | Login/no permission view | Đăng nhập/quay lại |

## D. Tương tác và mapping đến function

| Interaction ID | Người dùng thao tác | Điều kiện | Hệ thống gọi | Thành công | Thất bại | Navigation |
|---|---|---|---|---|---|---|
| ADMIN_OPS-V02-I01 | Review payment/conversion/adjustment | Input và quyền hợp lệ | ADMIN_OPS-FN02 | Refresh trạng thái Admin quản lý hệ thống | Hiển thị lỗi an toàn | Giữ view hoặc tới bước kế tiếp |
| ADMIN_OPS-V02-I02 | Tải lại dữ liệu | User có quyền xem | ADMIN_OPS-FN02 hoặc API đọc | Cập nhật view | Empty/error state | Không đổi route |

## E. Acceptance checklist cho QA/UI

- [ ] View chỉ hiển thị đúng role và trạng thái.
- [ ] Các state bắt buộc đều có thiết kế và test.
- [ ] Action chính gọi đúng ADMIN_OPS-FN02.
- [ ] Error message không lộ thông tin kỹ thuật hoặc dữ liệu nhạy cảm.
