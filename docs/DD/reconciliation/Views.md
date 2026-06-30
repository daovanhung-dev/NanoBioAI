# Views — RECONCILIATION / Tính toán & đối soát

## 0. View Inventory

| ID | View Name | Route / Entry Point | Actor | Feature | Type | Data Source | Status | Mockup |
|---|---|---|---|---|---|---|---|---|
| RECONCILIATION-V01 | Reconciliation run view | planned route/action for reconciliation | Admin, System | RECONCILIATION-F01 | Page / Flow / Admin view | RECONCILIATION-API01 | Approved - DD docs complete | assets/README.md |
| RECONCILIATION-V02 | Discrepancy detail | planned route/action for reconciliation | Admin | RECONCILIATION-F02 | Page / Flow / Admin view | RECONCILIATION-API02 | Approved - DD docs complete | assets/README.md |

## 1. Navigation Map

| Source | Action | Destination | Condition |
|---|---|---|---|
| Module entry | Actor selects feature action | Feature view | Actor has permission and dependency data can load |
| Feature view | Submit/confirm | Result state or next feature | RECONCILIATION-FNxx succeeds |
| Any view | Permission/data error | Safe error state | UI, route, use-case, or API blocks access |

---

<a id="reconciliation-v01"></a>
# RECONCILIATION-V01 — Reconciliation run view

## A. Thông tin cơ bản

| Trường | Nội dung |
|---|---|
| Feature liên quan | RECONCILIATION-F01 |
| Route / entry point | Planned route/action for reconciliation; final route must follow app router DD/code. |
| Loại view | Page / Screen / Widget / Admin view depending on platform surface |
| Actor được phép | Admin, System |
| Điều kiện truy cập | Theo quyền hiệu lực trong BD sections 3 và 5. |
| Hành vi khi không đủ quyền | Chặn ở route/use-case/API; UI chỉ hiển thị hướng dẫn an toàn. |
| Responsive | Mobile first for app surfaces; desktop/tablet for Admin surfaces. |
| Mockup / prototype | Optional future asset: BD v2.0 has no required mockup; view state/action contract is complete in this DD |

## B. Layout và thành phần giao diện

| Component ID | Khu vực | Loại | Nội dung / label | Hiển thị khi | Dữ liệu nguồn | Validation / rule |
|---|---|---|---|---|---|---|
| RECONCILIATION-V01-C01 | Header | Title / navigation | Reconciliation run view | Always | Static + module state | None |
| RECONCILIATION-V01-C02 | Body | Form/list/detail | Dữ liệu nghiệp vụ của Tính toán & đối soát | Actor có quyền | RECONCILIATION-API01 | RECONCILIATION-BR01 |
| RECONCILIATION-V01-C03 | Action | Primary button/action | Admin chọn kỳ hoặc scheduled job | Khi trạng thái hợp lệ | UI state | RECONCILIATION-FN01 |
| RECONCILIATION-V01-C04 | Feedback | Alert/toast/empty | Hướng dẫn, lỗi hoặc kết quả | Khi có trạng thái tương ứng | Result/Error | Không lộ stack trace/DB/API/secret |

## C. Trạng thái giao diện bắt buộc

| State | Điều kiện kích hoạt | UI phải hiển thị | Hành động cho người dùng |
|---|---|---|---|
| Initial | Lần đầu mở view | Skeleton hoặc trạng thái mặc định | Chờ dữ liệu |
| Loading | Đang gọi RECONCILIATION-FN01 hoặc API | Loading không gây layout shift, khóa duplicate action nếu cần | Chờ |
| Success | Kết quả hợp lệ | Dữ liệu/trạng thái mới và CTA tiếp theo | Tiếp tục flow |
| Empty | Không có dữ liệu | Lý do và CTA phù hợp | Tạo mới/quay lại |
| Validation error | Input sai | Field-level message bằng tiếng Việt/Nabitone | Sửa dữ liệu |
| Business error | Vi phạm rule | Message an toàn, không thuật ngữ nội bộ | Làm theo hướng dẫn |
| System error | Network/5xx/dependency lỗi | Retry + correlation id khi cần hỗ trợ | Thử lại/liên hệ hỗ trợ |
| Unauthorized/Forbidden | Thiếu đăng nhập/quyền | Login/no permission view | Đăng nhập/quay lại |

## D. Tương tác và mapping đến function

| Interaction ID | Người dùng thao tác | Điều kiện | Hệ thống gọi | Thành công | Thất bại | Navigation |
|---|---|---|---|---|---|---|
| RECONCILIATION-V01-I01 | Admin chọn kỳ hoặc scheduled job | Input và quyền hợp lệ | RECONCILIATION-FN01 | Refresh trạng thái Tính toán & đối soát | Hiển thị lỗi an toàn | Giữ view hoặc tới bước kế tiếp |
| RECONCILIATION-V01-I02 | Tải lại dữ liệu | User có quyền xem | RECONCILIATION-FN02 hoặc API đọc | Cập nhật view | Empty/error state | Không đổi route |

## E. Documented View Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| RECONCILIATION-VIEW-EV01-01 | View chỉ hiển thị đúng role và trạng thái. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| RECONCILIATION-VIEW-EV01-02 | Các state bắt buộc đều có thiết kế và test. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| RECONCILIATION-VIEW-EV01-03 | Action chính gọi đúng RECONCILIATION-FN01. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| RECONCILIATION-VIEW-EV01-04 | Error message không lộ thông tin kỹ thuật hoặc dữ liệu nhạy cảm. | Documented | Required in implementation/test phase; not executed in this DD docs pass |

---

<a id="reconciliation-v02"></a>
# RECONCILIATION-V02 — Discrepancy detail

## A. Thông tin cơ bản

| Trường | Nội dung |
|---|---|
| Feature liên quan | RECONCILIATION-F02 |
| Route / entry point | Planned route/action for reconciliation; final route must follow app router DD/code. |
| Loại view | Page / Screen / Widget / Admin view depending on platform surface |
| Actor được phép | Admin |
| Điều kiện truy cập | Theo quyền hiệu lực trong BD sections 3 và 5. |
| Hành vi khi không đủ quyền | Chặn ở route/use-case/API; UI chỉ hiển thị hướng dẫn an toàn. |
| Responsive | Mobile first for app surfaces; desktop/tablet for Admin surfaces. |
| Mockup / prototype | Optional future asset: BD v2.0 has no required mockup; view state/action contract is complete in this DD |

## B. Layout và thành phần giao diện

| Component ID | Khu vực | Loại | Nội dung / label | Hiển thị khi | Dữ liệu nguồn | Validation / rule |
|---|---|---|---|---|---|---|
| RECONCILIATION-V02-C01 | Header | Title / navigation | Discrepancy detail | Always | Static + module state | None |
| RECONCILIATION-V02-C02 | Body | Form/list/detail | Dữ liệu nghiệp vụ của Tính toán & đối soát | Actor có quyền | RECONCILIATION-API02 | RECONCILIATION-BR01 |
| RECONCILIATION-V02-C03 | Action | Primary button/action | Admin reviews discrepancy | Khi trạng thái hợp lệ | UI state | RECONCILIATION-FN02 |
| RECONCILIATION-V02-C04 | Feedback | Alert/toast/empty | Hướng dẫn, lỗi hoặc kết quả | Khi có trạng thái tương ứng | Result/Error | Không lộ stack trace/DB/API/secret |

## C. Trạng thái giao diện bắt buộc

| State | Điều kiện kích hoạt | UI phải hiển thị | Hành động cho người dùng |
|---|---|---|---|
| Initial | Lần đầu mở view | Skeleton hoặc trạng thái mặc định | Chờ dữ liệu |
| Loading | Đang gọi RECONCILIATION-FN02 hoặc API | Loading không gây layout shift, khóa duplicate action nếu cần | Chờ |
| Success | Kết quả hợp lệ | Dữ liệu/trạng thái mới và CTA tiếp theo | Tiếp tục flow |
| Empty | Không có dữ liệu | Lý do và CTA phù hợp | Tạo mới/quay lại |
| Validation error | Input sai | Field-level message bằng tiếng Việt/Nabitone | Sửa dữ liệu |
| Business error | Vi phạm rule | Message an toàn, không thuật ngữ nội bộ | Làm theo hướng dẫn |
| System error | Network/5xx/dependency lỗi | Retry + correlation id khi cần hỗ trợ | Thử lại/liên hệ hỗ trợ |
| Unauthorized/Forbidden | Thiếu đăng nhập/quyền | Login/no permission view | Đăng nhập/quay lại |

## D. Tương tác và mapping đến function

| Interaction ID | Người dùng thao tác | Điều kiện | Hệ thống gọi | Thành công | Thất bại | Navigation |
|---|---|---|---|---|---|---|
| RECONCILIATION-V02-I01 | Admin reviews discrepancy | Input và quyền hợp lệ | RECONCILIATION-FN02 | Refresh trạng thái Tính toán & đối soát | Hiển thị lỗi an toàn | Giữ view hoặc tới bước kế tiếp |
| RECONCILIATION-V02-I02 | Tải lại dữ liệu | User có quyền xem | RECONCILIATION-FN02 hoặc API đọc | Cập nhật view | Empty/error state | Không đổi route |

## E. Documented View Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| RECONCILIATION-VIEW-EV02-01 | View chỉ hiển thị đúng role và trạng thái. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| RECONCILIATION-VIEW-EV02-02 | Các state bắt buộc đều có thiết kế và test. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| RECONCILIATION-VIEW-EV02-03 | Action chính gọi đúng RECONCILIATION-FN02. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| RECONCILIATION-VIEW-EV02-04 | Error message không lộ thông tin kỹ thuật hoặc dữ liệu nhạy cảm. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
