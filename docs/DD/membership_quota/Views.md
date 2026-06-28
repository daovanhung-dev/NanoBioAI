# Views — MEMBERSHIP_QUOTA / Gói thành viên & quota

## 0. View Inventory

| ID | View Name | Route / Entry Point | Actor | Feature | Type | Data Source | Status | Mockup |
|---|---|---|---|---|---|---|---|---|
| MEMBERSHIP_QUOTA-V01 | Access state provider | planned route/action for membership_quota | System, Member | MEMBERSHIP_QUOTA-F01 | Page / Flow / Admin view | MEMBERSHIP_QUOTA-API01 | Draft | assets/README.md |
| MEMBERSHIP_QUOTA-V02 | Quota gate messaging | planned route/action for membership_quota | Free | MEMBERSHIP_QUOTA-F02 | Page / Flow / Admin view | MEMBERSHIP_QUOTA-API02 | Draft | assets/README.md |

## 1. Navigation Map

| Source | Action | Destination | Condition |
|---|---|---|---|
| Module entry | Actor selects feature action | Feature view | Actor has permission and dependency data can load |
| Feature view | Submit/confirm | Result state or next feature | MEMBERSHIP_QUOTA-FNxx succeeds |
| Any view | Permission/data error | Safe error state | UI, route, use-case, or API blocks access |

---

<a id="membership_quota-v01"></a>
# MEMBERSHIP_QUOTA-V01 — Access state provider

## A. Thông tin cơ bản

| Trường | Nội dung |
|---|---|
| Feature liên quan | MEMBERSHIP_QUOTA-F01 |
| Route / entry point | Planned route/action for membership_quota; final route must follow app router DD/code. |
| Loại view | Page / Screen / Widget / Admin view depending on platform surface |
| Actor được phép | System, Member |
| Điều kiện truy cập | Theo quyền hiệu lực trong BD sections 3 và 5. |
| Hành vi khi không đủ quyền | Chặn ở route/use-case/API; UI chỉ hiển thị hướng dẫn an toàn. |
| Responsive | Mobile first for app surfaces; desktop/tablet for Admin surfaces. |
| Mockup / prototype | OPEN QUESTION: mockup chưa có trong BD, lưu sau vào assets/. |

## B. Layout và thành phần giao diện

| Component ID | Khu vực | Loại | Nội dung / label | Hiển thị khi | Dữ liệu nguồn | Validation / rule |
|---|---|---|---|---|---|---|
| MEMBERSHIP_QUOTA-V01-C01 | Header | Title / navigation | Access state provider | Always | Static + module state | None |
| MEMBERSHIP_QUOTA-V01-C02 | Body | Form/list/detail | Dữ liệu nghiệp vụ của Gói thành viên & quota | Actor có quyền | MEMBERSHIP_QUOTA-API01 | MEMBERSHIP_QUOTA-BR01 |
| MEMBERSHIP_QUOTA-V01-C03 | Action | Primary button/action | Login, app resume, package change | Khi trạng thái hợp lệ | UI state | MEMBERSHIP_QUOTA-FN01 |
| MEMBERSHIP_QUOTA-V01-C04 | Feedback | Alert/toast/empty | Hướng dẫn, lỗi hoặc kết quả | Khi có trạng thái tương ứng | Result/Error | Không lộ stack trace/DB/API/secret |

## C. Trạng thái giao diện bắt buộc

| State | Điều kiện kích hoạt | UI phải hiển thị | Hành động cho người dùng |
|---|---|---|---|
| Initial | Lần đầu mở view | Skeleton hoặc trạng thái mặc định | Chờ dữ liệu |
| Loading | Đang gọi MEMBERSHIP_QUOTA-FN01 hoặc API | Loading không gây layout shift, khóa duplicate action nếu cần | Chờ |
| Success | Kết quả hợp lệ | Dữ liệu/trạng thái mới và CTA tiếp theo | Tiếp tục flow |
| Empty | Không có dữ liệu | Lý do và CTA phù hợp | Tạo mới/quay lại |
| Validation error | Input sai | Field-level message bằng tiếng Việt/Nabitone | Sửa dữ liệu |
| Business error | Vi phạm rule | Message an toàn, không thuật ngữ nội bộ | Làm theo hướng dẫn |
| System error | Network/5xx/dependency lỗi | Retry + correlation id khi cần hỗ trợ | Thử lại/liên hệ hỗ trợ |
| Unauthorized/Forbidden | Thiếu đăng nhập/quyền | Login/no permission view | Đăng nhập/quay lại |

## D. Tương tác và mapping đến function

| Interaction ID | Người dùng thao tác | Điều kiện | Hệ thống gọi | Thành công | Thất bại | Navigation |
|---|---|---|---|---|---|---|
| MEMBERSHIP_QUOTA-V01-I01 | Login, app resume, package change | Input và quyền hợp lệ | MEMBERSHIP_QUOTA-FN01 | Refresh trạng thái Gói thành viên & quota | Hiển thị lỗi an toàn | Giữ view hoặc tới bước kế tiếp |
| MEMBERSHIP_QUOTA-V01-I02 | Tải lại dữ liệu | User có quyền xem | MEMBERSHIP_QUOTA-FN02 hoặc API đọc | Cập nhật view | Empty/error state | Không đổi route |

## E. Acceptance checklist cho QA/UI

- [ ] View chỉ hiển thị đúng role và trạng thái.
- [ ] Các state bắt buộc đều có thiết kế và test.
- [ ] Action chính gọi đúng MEMBERSHIP_QUOTA-FN01.
- [ ] Error message không lộ thông tin kỹ thuật hoặc dữ liệu nhạy cảm.
---

<a id="membership_quota-v02"></a>
# MEMBERSHIP_QUOTA-V02 — Quota gate messaging

## A. Thông tin cơ bản

| Trường | Nội dung |
|---|---|
| Feature liên quan | MEMBERSHIP_QUOTA-F02 |
| Route / entry point | Planned route/action for membership_quota; final route must follow app router DD/code. |
| Loại view | Page / Screen / Widget / Admin view depending on platform surface |
| Actor được phép | Free |
| Điều kiện truy cập | Theo quyền hiệu lực trong BD sections 3 và 5. |
| Hành vi khi không đủ quyền | Chặn ở route/use-case/API; UI chỉ hiển thị hướng dẫn an toàn. |
| Responsive | Mobile first for app surfaces; desktop/tablet for Admin surfaces. |
| Mockup / prototype | OPEN QUESTION: mockup chưa có trong BD, lưu sau vào assets/. |

## B. Layout và thành phần giao diện

| Component ID | Khu vực | Loại | Nội dung / label | Hiển thị khi | Dữ liệu nguồn | Validation / rule |
|---|---|---|---|---|---|---|
| MEMBERSHIP_QUOTA-V02-C01 | Header | Title / navigation | Quota gate messaging | Always | Static + module state | None |
| MEMBERSHIP_QUOTA-V02-C02 | Body | Form/list/detail | Dữ liệu nghiệp vụ của Gói thành viên & quota | Actor có quyền | MEMBERSHIP_QUOTA-API02 | MEMBERSHIP_QUOTA-BR01 |
| MEMBERSHIP_QUOTA-V02-C03 | Action | Primary button/action | AI Chat hoặc tạo lịch trình | Khi trạng thái hợp lệ | UI state | MEMBERSHIP_QUOTA-FN02 |
| MEMBERSHIP_QUOTA-V02-C04 | Feedback | Alert/toast/empty | Hướng dẫn, lỗi hoặc kết quả | Khi có trạng thái tương ứng | Result/Error | Không lộ stack trace/DB/API/secret |

## C. Trạng thái giao diện bắt buộc

| State | Điều kiện kích hoạt | UI phải hiển thị | Hành động cho người dùng |
|---|---|---|---|
| Initial | Lần đầu mở view | Skeleton hoặc trạng thái mặc định | Chờ dữ liệu |
| Loading | Đang gọi MEMBERSHIP_QUOTA-FN02 hoặc API | Loading không gây layout shift, khóa duplicate action nếu cần | Chờ |
| Success | Kết quả hợp lệ | Dữ liệu/trạng thái mới và CTA tiếp theo | Tiếp tục flow |
| Empty | Không có dữ liệu | Lý do và CTA phù hợp | Tạo mới/quay lại |
| Validation error | Input sai | Field-level message bằng tiếng Việt/Nabitone | Sửa dữ liệu |
| Business error | Vi phạm rule | Message an toàn, không thuật ngữ nội bộ | Làm theo hướng dẫn |
| System error | Network/5xx/dependency lỗi | Retry + correlation id khi cần hỗ trợ | Thử lại/liên hệ hỗ trợ |
| Unauthorized/Forbidden | Thiếu đăng nhập/quyền | Login/no permission view | Đăng nhập/quay lại |

## D. Tương tác và mapping đến function

| Interaction ID | Người dùng thao tác | Điều kiện | Hệ thống gọi | Thành công | Thất bại | Navigation |
|---|---|---|---|---|---|---|
| MEMBERSHIP_QUOTA-V02-I01 | AI Chat hoặc tạo lịch trình | Input và quyền hợp lệ | MEMBERSHIP_QUOTA-FN02 | Refresh trạng thái Gói thành viên & quota | Hiển thị lỗi an toàn | Giữ view hoặc tới bước kế tiếp |
| MEMBERSHIP_QUOTA-V02-I02 | Tải lại dữ liệu | User có quyền xem | MEMBERSHIP_QUOTA-FN02 hoặc API đọc | Cập nhật view | Empty/error state | Không đổi route |

## E. Acceptance checklist cho QA/UI

- [ ] View chỉ hiển thị đúng role và trạng thái.
- [ ] Các state bắt buộc đều có thiết kế và test.
- [ ] Action chính gọi đúng MEMBERSHIP_QUOTA-FN02.
- [ ] Error message không lộ thông tin kỹ thuật hoặc dữ liệu nhạy cảm.
