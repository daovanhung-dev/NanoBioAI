# Views — DASHBOARD_SCHEDULE / Dashboard & Thực hiện lịch trình

## 0. View Inventory

| ID | View Name | Route / Entry Point | Actor | Feature | Type | Data Source | Status | Mockup |
|---|---|---|---|---|---|---|---|---|
| DASHBOARD_SCHEDULE-V01 | Schedule dashboard | planned route/action for dashboard_schedule | Guest, Member, Family | DASHBOARD_SCHEDULE-F01 | Page / Flow / Admin view | DASHBOARD_SCHEDULE-API01 | Approved - DD docs complete | assets/README.md |
| DASHBOARD_SCHEDULE-V02 | Plan item action | planned route/action for dashboard_schedule | Guest, Member, Family | DASHBOARD_SCHEDULE-F02 | Page / Flow / Admin view | DASHBOARD_SCHEDULE-API02 | Approved - DD docs complete | assets/README.md |

## 1. Navigation Map

| Source | Action | Destination | Condition |
|---|---|---|---|
| Module entry | Actor selects feature action | Feature view | Actor has permission and dependency data can load |
| Feature view | Submit/confirm | Result state or next feature | DASHBOARD_SCHEDULE-FNxx succeeds |
| Any view | Permission/data error | Safe error state | UI, route, use-case, or API blocks access |

---

<a id="dashboard_schedule-v01"></a>
# DASHBOARD_SCHEDULE-V01 — Schedule dashboard

## A. Thông tin cơ bản

| Trường | Nội dung |
|---|---|
| Feature liên quan | DASHBOARD_SCHEDULE-F01 |
| Route / entry point | Planned route/action for dashboard_schedule; final route must follow app router DD/code. |
| Loại view | Page / Screen / Widget / Admin view depending on platform surface |
| Actor được phép | Guest, Member, Family |
| Điều kiện truy cập | Theo quyền hiệu lực trong BD sections 3 và 5. |
| Hành vi khi không đủ quyền | Chặn ở route/use-case/API; UI chỉ hiển thị hướng dẫn an toàn. |
| Responsive | Mobile first for app surfaces; desktop/tablet for Admin surfaces. |
| Mockup / prototype | Optional future asset: BD v2.0 has no required mockup; view state/action contract is complete in this DD |

## B. Layout và thành phần giao diện

| Component ID | Khu vực | Loại | Nội dung / label | Hiển thị khi | Dữ liệu nguồn | Validation / rule |
|---|---|---|---|---|---|---|
| DASHBOARD_SCHEDULE-V01-C01 | Header | Title / navigation | Schedule dashboard | Always | Static + module state | None |
| DASHBOARD_SCHEDULE-V01-C02 | Body | Form/list/detail | Dữ liệu nghiệp vụ của Dashboard & Thực hiện lịch trình | Actor có quyền | DASHBOARD_SCHEDULE-API01 | DASHBOARD_SCHEDULE-BR01 |
| DASHBOARD_SCHEDULE-V01-C03 | Action | Primary button/action | Mở dashboard | Khi trạng thái hợp lệ | UI state | DASHBOARD_SCHEDULE-FN01 |
| DASHBOARD_SCHEDULE-V01-C04 | Feedback | Alert/toast/empty | Hướng dẫn, lỗi hoặc kết quả | Khi có trạng thái tương ứng | Result/Error | Không lộ stack trace/DB/API/secret |

## C. Trạng thái giao diện bắt buộc

| State | Điều kiện kích hoạt | UI phải hiển thị | Hành động cho người dùng |
|---|---|---|---|
| Initial | Lần đầu mở view | Skeleton hoặc trạng thái mặc định | Chờ dữ liệu |
| Loading | Đang gọi DASHBOARD_SCHEDULE-FN01 hoặc API | Loading không gây layout shift, khóa duplicate action nếu cần | Chờ |
| Success | Kết quả hợp lệ | Dữ liệu/trạng thái mới và CTA tiếp theo | Tiếp tục flow |
| Empty | Không có dữ liệu | Lý do và CTA phù hợp | Tạo mới/quay lại |
| Validation error | Input sai | Field-level message bằng tiếng Việt/Nabitone | Sửa dữ liệu |
| Business error | Vi phạm rule | Message an toàn, không thuật ngữ nội bộ | Làm theo hướng dẫn |
| System error | Network/5xx/dependency lỗi | Retry + correlation id khi cần hỗ trợ | Thử lại/liên hệ hỗ trợ |
| Unauthorized/Forbidden | Thiếu đăng nhập/quyền | Login/no permission view | Đăng nhập/quay lại |

## D. Tương tác và mapping đến function

| Interaction ID | Người dùng thao tác | Điều kiện | Hệ thống gọi | Thành công | Thất bại | Navigation |
|---|---|---|---|---|---|---|
| DASHBOARD_SCHEDULE-V01-I01 | Mở dashboard | Input và quyền hợp lệ | DASHBOARD_SCHEDULE-FN01 | Refresh trạng thái Dashboard & Thực hiện lịch trình | Hiển thị lỗi an toàn | Giữ view hoặc tới bước kế tiếp |
| DASHBOARD_SCHEDULE-V01-I02 | Tải lại dữ liệu | User có quyền xem | DASHBOARD_SCHEDULE-FN02 hoặc API đọc | Cập nhật view | Empty/error state | Không đổi route |

## E. Documented View Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| DASHBOARD_SCHEDULE-VIEW-EV01-01 | View chỉ hiển thị đúng role và trạng thái. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| DASHBOARD_SCHEDULE-VIEW-EV01-02 | Các state bắt buộc đều có thiết kế và test. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| DASHBOARD_SCHEDULE-VIEW-EV01-03 | Action chính gọi đúng DASHBOARD_SCHEDULE-FN01. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| DASHBOARD_SCHEDULE-VIEW-EV01-04 | Error message không lộ thông tin kỹ thuật hoặc dữ liệu nhạy cảm. | Documented | Required in implementation/test phase; not executed in this DD docs pass |

---

<a id="dashboard_schedule-v02"></a>
# DASHBOARD_SCHEDULE-V02 — Plan item action

## A. Thông tin cơ bản

| Trường | Nội dung |
|---|---|
| Feature liên quan | DASHBOARD_SCHEDULE-F02 |
| Route / entry point | Planned route/action for dashboard_schedule; final route must follow app router DD/code. |
| Loại view | Page / Screen / Widget / Admin view depending on platform surface |
| Actor được phép | Guest, Member, Family |
| Điều kiện truy cập | Theo quyền hiệu lực trong BD sections 3 và 5. |
| Hành vi khi không đủ quyền | Chặn ở route/use-case/API; UI chỉ hiển thị hướng dẫn an toàn. |
| Responsive | Mobile first for app surfaces; desktop/tablet for Admin surfaces. |
| Mockup / prototype | Optional future asset: BD v2.0 has no required mockup; view state/action contract is complete in this DD |

## B. Layout và thành phần giao diện

| Component ID | Khu vực | Loại | Nội dung / label | Hiển thị khi | Dữ liệu nguồn | Validation / rule |
|---|---|---|---|---|---|---|
| DASHBOARD_SCHEDULE-V02-C01 | Header | Title / navigation | Plan item action | Always | Static + module state | None |
| DASHBOARD_SCHEDULE-V02-C02 | Body | Form/list/detail | Dữ liệu nghiệp vụ của Dashboard & Thực hiện lịch trình | Actor có quyền | DASHBOARD_SCHEDULE-API02 | DASHBOARD_SCHEDULE-BR01 |
| DASHBOARD_SCHEDULE-V02-C03 | Action | Primary button/action | Bấm hoàn thành hoặc bỏ qua | Khi trạng thái hợp lệ | UI state | DASHBOARD_SCHEDULE-FN02 |
| DASHBOARD_SCHEDULE-V02-C04 | Feedback | Alert/toast/empty | Hướng dẫn, lỗi hoặc kết quả | Khi có trạng thái tương ứng | Result/Error | Không lộ stack trace/DB/API/secret |

## C. Trạng thái giao diện bắt buộc

| State | Điều kiện kích hoạt | UI phải hiển thị | Hành động cho người dùng |
|---|---|---|---|
| Initial | Lần đầu mở view | Skeleton hoặc trạng thái mặc định | Chờ dữ liệu |
| Loading | Đang gọi DASHBOARD_SCHEDULE-FN02 hoặc API | Loading không gây layout shift, khóa duplicate action nếu cần | Chờ |
| Success | Kết quả hợp lệ | Dữ liệu/trạng thái mới và CTA tiếp theo | Tiếp tục flow |
| Empty | Không có dữ liệu | Lý do và CTA phù hợp | Tạo mới/quay lại |
| Validation error | Input sai | Field-level message bằng tiếng Việt/Nabitone | Sửa dữ liệu |
| Business error | Vi phạm rule | Message an toàn, không thuật ngữ nội bộ | Làm theo hướng dẫn |
| System error | Network/5xx/dependency lỗi | Retry + correlation id khi cần hỗ trợ | Thử lại/liên hệ hỗ trợ |
| Unauthorized/Forbidden | Thiếu đăng nhập/quyền | Login/no permission view | Đăng nhập/quay lại |

## D. Tương tác và mapping đến function

| Interaction ID | Người dùng thao tác | Điều kiện | Hệ thống gọi | Thành công | Thất bại | Navigation |
|---|---|---|---|---|---|---|
| DASHBOARD_SCHEDULE-V02-I01 | Bấm hoàn thành hoặc bỏ qua | Input và quyền hợp lệ | DASHBOARD_SCHEDULE-FN02 | Refresh trạng thái Dashboard & Thực hiện lịch trình | Hiển thị lỗi an toàn | Giữ view hoặc tới bước kế tiếp |
| DASHBOARD_SCHEDULE-V02-I02 | Tải lại dữ liệu | User có quyền xem | DASHBOARD_SCHEDULE-FN02 hoặc API đọc | Cập nhật view | Empty/error state | Không đổi route |

## E. Documented View Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| DASHBOARD_SCHEDULE-VIEW-EV02-01 | View chỉ hiển thị đúng role và trạng thái. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| DASHBOARD_SCHEDULE-VIEW-EV02-02 | Các state bắt buộc đều có thiết kế và test. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| DASHBOARD_SCHEDULE-VIEW-EV02-03 | Action chính gọi đúng DASHBOARD_SCHEDULE-FN02. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| DASHBOARD_SCHEDULE-VIEW-EV02-04 | Error message không lộ thông tin kỹ thuật hoặc dữ liệu nhạy cảm. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
