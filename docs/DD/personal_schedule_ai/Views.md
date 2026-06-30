# Views — PERSONAL_SCHEDULE_AI / AI Lịch trình cá nhân

## 0. View Inventory

| ID | View Name | Route / Entry Point | Actor | Feature | Type | Data Source | Status | Mockup |
|---|---|---|---|---|---|---|---|---|
| PERSONAL_SCHEDULE_AI-V01 | Initial schedule generation | planned route/action for personal_schedule_ai | Guest | PERSONAL_SCHEDULE_AI-F01 | Page / Flow / Admin view | PERSONAL_SCHEDULE_AI-API01 | Draft | assets/README.md |
| PERSONAL_SCHEDULE_AI-V02 | Regenerate schedule | planned route/action for personal_schedule_ai | Free, Plus, FamilyPlus | PERSONAL_SCHEDULE_AI-F02 | Page / Flow / Admin view | PERSONAL_SCHEDULE_AI-API02 | Draft | assets/README.md |

## 1. Navigation Map

| Source | Action | Destination | Condition |
|---|---|---|---|
| Module entry | Actor selects feature action | Feature view | Actor has permission and dependency data can load |
| Feature view | Submit/confirm | Result state or next feature | PERSONAL_SCHEDULE_AI-FNxx succeeds |
| Any view | Permission/data error | Safe error state | UI, route, use-case, or API blocks access |

---

<a id="personal_schedule_ai-v01"></a>
# PERSONAL_SCHEDULE_AI-V01 — Initial schedule generation

## A. Thông tin cơ bản

| Trường | Nội dung |
|---|---|
| Feature liên quan | PERSONAL_SCHEDULE_AI-F01 |
| Route / entry point | Planned route/action for personal_schedule_ai; final route must follow app router DD/code. |
| Loại view | Page / Screen / Widget / Admin view depending on platform surface |
| Actor được phép | Guest |
| Điều kiện truy cập | Theo quyền hiệu lực trong BD sections 3 và 5. |
| Hành vi khi không đủ quyền | Chặn ở route/use-case/API; UI chỉ hiển thị hướng dẫn an toàn. |
| Responsive | Mobile first for app surfaces; desktop/tablet for Admin surfaces. |
| Mockup / prototype | PLANNED CONFIRMATION: mockup chưa có trong BD, lưu sau vào assets/. |

## B. Layout và thành phần giao diện

| Component ID | Khu vực | Loại | Nội dung / label | Hiển thị khi | Dữ liệu nguồn | Validation / rule |
|---|---|---|---|---|---|---|
| PERSONAL_SCHEDULE_AI-V01-C01 | Header | Title / navigation | Initial schedule generation | Always | Static + module state | None |
| PERSONAL_SCHEDULE_AI-V01-C02 | Body | Form/list/detail | Dữ liệu nghiệp vụ của AI Lịch trình cá nhân | Actor có quyền | PERSONAL_SCHEDULE_AI-API01 | PERSONAL_SCHEDULE_AI-BR01 |
| PERSONAL_SCHEDULE_AI-V01-C03 | Action | Primary button/action | Onboarding completed | Khi trạng thái hợp lệ | UI state | PERSONAL_SCHEDULE_AI-FN01 |
| PERSONAL_SCHEDULE_AI-V01-C04 | Feedback | Alert/toast/empty | Hướng dẫn, lỗi hoặc kết quả | Khi có trạng thái tương ứng | Result/Error | Không lộ stack trace/DB/API/secret |

## C. Trạng thái giao diện bắt buộc

| State | Điều kiện kích hoạt | UI phải hiển thị | Hành động cho người dùng |
|---|---|---|---|
| Initial | Lần đầu mở view | Skeleton hoặc trạng thái mặc định | Chờ dữ liệu |
| Loading | Đang gọi PERSONAL_SCHEDULE_AI-FN01 hoặc API | Loading không gây layout shift, khóa duplicate action nếu cần | Chờ |
| Success | Kết quả hợp lệ | Dữ liệu/trạng thái mới và CTA tiếp theo | Tiếp tục flow |
| Empty | Không có dữ liệu | Lý do và CTA phù hợp | Tạo mới/quay lại |
| Validation error | Input sai | Field-level message bằng tiếng Việt/Nabitone | Sửa dữ liệu |
| Business error | Vi phạm rule | Message an toàn, không thuật ngữ nội bộ | Làm theo hướng dẫn |
| System error | Network/5xx/dependency lỗi | Retry + correlation id khi cần hỗ trợ | Thử lại/liên hệ hỗ trợ |
| Unauthorized/Forbidden | Thiếu đăng nhập/quyền | Login/no permission view | Đăng nhập/quay lại |

## D. Tương tác và mapping đến function

| Interaction ID | Người dùng thao tác | Điều kiện | Hệ thống gọi | Thành công | Thất bại | Navigation |
|---|---|---|---|---|---|---|
| PERSONAL_SCHEDULE_AI-V01-I01 | Onboarding completed | Input và quyền hợp lệ | PERSONAL_SCHEDULE_AI-FN01 | Refresh trạng thái AI Lịch trình cá nhân | Hiển thị lỗi an toàn | Giữ view hoặc tới bước kế tiếp |
| PERSONAL_SCHEDULE_AI-V01-I02 | Tải lại dữ liệu | User có quyền xem | PERSONAL_SCHEDULE_AI-FN02 hoặc API đọc | Cập nhật view | Empty/error state | Không đổi route |

## E. Acceptance checklist cho QA/UI

- [ ] View chỉ hiển thị đúng role và trạng thái.
- [ ] Các state bắt buộc đều có thiết kế và test.
- [ ] Action chính gọi đúng PERSONAL_SCHEDULE_AI-FN01.
- [ ] Error message không lộ thông tin kỹ thuật hoặc dữ liệu nhạy cảm.
---

<a id="personal_schedule_ai-v02"></a>
# PERSONAL_SCHEDULE_AI-V02 — Regenerate schedule

## A. Thông tin cơ bản

| Trường | Nội dung |
|---|---|
| Feature liên quan | PERSONAL_SCHEDULE_AI-F02 |
| Route / entry point | Planned route/action for personal_schedule_ai; final route must follow app router DD/code. |
| Loại view | Page / Screen / Widget / Admin view depending on platform surface |
| Actor được phép | Free, Plus, FamilyPlus |
| Điều kiện truy cập | Theo quyền hiệu lực trong BD sections 3 và 5. |
| Hành vi khi không đủ quyền | Chặn ở route/use-case/API; UI chỉ hiển thị hướng dẫn an toàn. |
| Responsive | Mobile first for app surfaces; desktop/tablet for Admin surfaces. |
| Mockup / prototype | PLANNED CONFIRMATION: mockup chưa có trong BD, lưu sau vào assets/. |

## B. Layout và thành phần giao diện

| Component ID | Khu vực | Loại | Nội dung / label | Hiển thị khi | Dữ liệu nguồn | Validation / rule |
|---|---|---|---|---|---|---|
| PERSONAL_SCHEDULE_AI-V02-C01 | Header | Title / navigation | Regenerate schedule | Always | Static + module state | None |
| PERSONAL_SCHEDULE_AI-V02-C02 | Body | Form/list/detail | Dữ liệu nghiệp vụ của AI Lịch trình cá nhân | Actor có quyền | PERSONAL_SCHEDULE_AI-API02 | PERSONAL_SCHEDULE_AI-BR01 |
| PERSONAL_SCHEDULE_AI-V02-C03 | Action | Primary button/action | Member yêu cầu tạo lịch trình mới | Khi trạng thái hợp lệ | UI state | PERSONAL_SCHEDULE_AI-FN02 |
| PERSONAL_SCHEDULE_AI-V02-C04 | Feedback | Alert/toast/empty | Hướng dẫn, lỗi hoặc kết quả | Khi có trạng thái tương ứng | Result/Error | Không lộ stack trace/DB/API/secret |

## C. Trạng thái giao diện bắt buộc

| State | Điều kiện kích hoạt | UI phải hiển thị | Hành động cho người dùng |
|---|---|---|---|
| Initial | Lần đầu mở view | Skeleton hoặc trạng thái mặc định | Chờ dữ liệu |
| Loading | Đang gọi PERSONAL_SCHEDULE_AI-FN02 hoặc API | Loading không gây layout shift, khóa duplicate action nếu cần | Chờ |
| Success | Kết quả hợp lệ | Dữ liệu/trạng thái mới và CTA tiếp theo | Tiếp tục flow |
| Empty | Không có dữ liệu | Lý do và CTA phù hợp | Tạo mới/quay lại |
| Validation error | Input sai | Field-level message bằng tiếng Việt/Nabitone | Sửa dữ liệu |
| Business error | Vi phạm rule | Message an toàn, không thuật ngữ nội bộ | Làm theo hướng dẫn |
| System error | Network/5xx/dependency lỗi | Retry + correlation id khi cần hỗ trợ | Thử lại/liên hệ hỗ trợ |
| Unauthorized/Forbidden | Thiếu đăng nhập/quyền | Login/no permission view | Đăng nhập/quay lại |

## D. Tương tác và mapping đến function

| Interaction ID | Người dùng thao tác | Điều kiện | Hệ thống gọi | Thành công | Thất bại | Navigation |
|---|---|---|---|---|---|---|
| PERSONAL_SCHEDULE_AI-V02-I01 | Member yêu cầu tạo lịch trình mới | Input và quyền hợp lệ | PERSONAL_SCHEDULE_AI-FN02 | Refresh trạng thái AI Lịch trình cá nhân | Hiển thị lỗi an toàn | Giữ view hoặc tới bước kế tiếp |
| PERSONAL_SCHEDULE_AI-V02-I02 | Tải lại dữ liệu | User có quyền xem | PERSONAL_SCHEDULE_AI-FN02 hoặc API đọc | Cập nhật view | Empty/error state | Không đổi route |

## E. Acceptance checklist cho QA/UI

- [ ] View chỉ hiển thị đúng role và trạng thái.
- [ ] Các state bắt buộc đều có thiết kế và test.
- [ ] Action chính gọi đúng PERSONAL_SCHEDULE_AI-FN02.
- [ ] Error message không lộ thông tin kỹ thuật hoặc dữ liệu nhạy cảm.
