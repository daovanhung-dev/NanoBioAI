# Views — AI_CHAT / AI Chat

## 0. View Inventory

| ID | View Name | Route / Entry Point | Actor | Feature | Type | Data Source | Status | Mockup |
|---|---|---|---|---|---|---|---|---|
| AI_CHAT-V01 | AI Chat screen | planned route/action for ai_chat | Free, Plus, FamilyPlus | AI_CHAT-F01 | Page / Flow / Admin view | AI_CHAT-API01 | Draft | assets/README.md |
| AI_CHAT-V02 | AI Chat composer | planned route/action for ai_chat | Free, Plus, FamilyPlus | AI_CHAT-F02 | Page / Flow / Admin view | AI_CHAT-API02 | Draft | assets/README.md |

## 1. Navigation Map

| Source | Action | Destination | Condition |
|---|---|---|---|
| Module entry | Actor selects feature action | Feature view | Actor has permission and dependency data can load |
| Feature view | Submit/confirm | Result state or next feature | AI_CHAT-FNxx succeeds |
| Any view | Permission/data error | Safe error state | UI, route, use-case, or API blocks access |

---

<a id="ai_chat-v01"></a>
# AI_CHAT-V01 — AI Chat screen

## A. Thông tin cơ bản

| Trường | Nội dung |
|---|---|
| Feature liên quan | AI_CHAT-F01 |
| Route / entry point | Planned route/action for ai_chat; final route must follow app router DD/code. |
| Loại view | Page / Screen / Widget / Admin view depending on platform surface |
| Actor được phép | Free, Plus, FamilyPlus |
| Điều kiện truy cập | Theo quyền hiệu lực trong BD sections 3 và 5. |
| Hành vi khi không đủ quyền | Chặn ở route/use-case/API; UI chỉ hiển thị hướng dẫn an toàn. |
| Responsive | Mobile first for app surfaces; desktop/tablet for Admin surfaces. |
| Mockup / prototype | PLANNED CONFIRMATION: mockup chưa có trong BD, lưu sau vào assets/. |

## B. Layout và thành phần giao diện

| Component ID | Khu vực | Loại | Nội dung / label | Hiển thị khi | Dữ liệu nguồn | Validation / rule |
|---|---|---|---|---|---|---|
| AI_CHAT-V01-C01 | Header | Title / navigation | AI Chat screen | Always | Static + module state | None |
| AI_CHAT-V01-C02 | Body | Form/list/detail | Dữ liệu nghiệp vụ của AI Chat | Actor có quyền | AI_CHAT-API01 | AI_CHAT-BR01 |
| AI_CHAT-V01-C03 | Action | Primary button/action | Mở AI Chat | Khi trạng thái hợp lệ | UI state | AI_CHAT-FN01 |
| AI_CHAT-V01-C04 | Feedback | Alert/toast/empty | Hướng dẫn, lỗi hoặc kết quả | Khi có trạng thái tương ứng | Result/Error | Không lộ stack trace/DB/API/secret |

## C. Trạng thái giao diện bắt buộc

| State | Điều kiện kích hoạt | UI phải hiển thị | Hành động cho người dùng |
|---|---|---|---|
| Initial | Lần đầu mở view | Skeleton hoặc trạng thái mặc định | Chờ dữ liệu |
| Loading | Đang gọi AI_CHAT-FN01 hoặc API | Loading không gây layout shift, khóa duplicate action nếu cần | Chờ |
| Success | Kết quả hợp lệ | Dữ liệu/trạng thái mới và CTA tiếp theo | Tiếp tục flow |
| Empty | Không có dữ liệu | Lý do và CTA phù hợp | Tạo mới/quay lại |
| Validation error | Input sai | Field-level message bằng tiếng Việt/Nabitone | Sửa dữ liệu |
| Business error | Vi phạm rule | Message an toàn, không thuật ngữ nội bộ | Làm theo hướng dẫn |
| System error | Network/5xx/dependency lỗi | Retry + correlation id khi cần hỗ trợ | Thử lại/liên hệ hỗ trợ |
| Unauthorized/Forbidden | Thiếu đăng nhập/quyền | Login/no permission view | Đăng nhập/quay lại |

## D. Tương tác và mapping đến function

| Interaction ID | Người dùng thao tác | Điều kiện | Hệ thống gọi | Thành công | Thất bại | Navigation |
|---|---|---|---|---|---|---|
| AI_CHAT-V01-I01 | Mở AI Chat | Input và quyền hợp lệ | AI_CHAT-FN01 | Refresh trạng thái AI Chat | Hiển thị lỗi an toàn | Giữ view hoặc tới bước kế tiếp |
| AI_CHAT-V01-I02 | Tải lại dữ liệu | User có quyền xem | AI_CHAT-FN02 hoặc API đọc | Cập nhật view | Empty/error state | Không đổi route |

## E. Acceptance checklist cho QA/UI

- [ ] View chỉ hiển thị đúng role và trạng thái.
- [ ] Các state bắt buộc đều có thiết kế và test.
- [ ] Action chính gọi đúng AI_CHAT-FN01.
- [ ] Error message không lộ thông tin kỹ thuật hoặc dữ liệu nhạy cảm.
---

<a id="ai_chat-v02"></a>
# AI_CHAT-V02 — AI Chat composer

## A. Thông tin cơ bản

| Trường | Nội dung |
|---|---|
| Feature liên quan | AI_CHAT-F02 |
| Route / entry point | Planned route/action for ai_chat; final route must follow app router DD/code. |
| Loại view | Page / Screen / Widget / Admin view depending on platform surface |
| Actor được phép | Free, Plus, FamilyPlus |
| Điều kiện truy cập | Theo quyền hiệu lực trong BD sections 3 và 5. |
| Hành vi khi không đủ quyền | Chặn ở route/use-case/API; UI chỉ hiển thị hướng dẫn an toàn. |
| Responsive | Mobile first for app surfaces; desktop/tablet for Admin surfaces. |
| Mockup / prototype | PLANNED CONFIRMATION: mockup chưa có trong BD, lưu sau vào assets/. |

## B. Layout và thành phần giao diện

| Component ID | Khu vực | Loại | Nội dung / label | Hiển thị khi | Dữ liệu nguồn | Validation / rule |
|---|---|---|---|---|---|---|
| AI_CHAT-V02-C01 | Header | Title / navigation | AI Chat composer | Always | Static + module state | None |
| AI_CHAT-V02-C02 | Body | Form/list/detail | Dữ liệu nghiệp vụ của AI Chat | Actor có quyền | AI_CHAT-API02 | AI_CHAT-BR01 |
| AI_CHAT-V02-C03 | Action | Primary button/action | Submit chat question | Khi trạng thái hợp lệ | UI state | AI_CHAT-FN02 |
| AI_CHAT-V02-C04 | Feedback | Alert/toast/empty | Hướng dẫn, lỗi hoặc kết quả | Khi có trạng thái tương ứng | Result/Error | Không lộ stack trace/DB/API/secret |

## C. Trạng thái giao diện bắt buộc

| State | Điều kiện kích hoạt | UI phải hiển thị | Hành động cho người dùng |
|---|---|---|---|
| Initial | Lần đầu mở view | Skeleton hoặc trạng thái mặc định | Chờ dữ liệu |
| Loading | Đang gọi AI_CHAT-FN02 hoặc API | Loading không gây layout shift, khóa duplicate action nếu cần | Chờ |
| Success | Kết quả hợp lệ | Dữ liệu/trạng thái mới và CTA tiếp theo | Tiếp tục flow |
| Empty | Không có dữ liệu | Lý do và CTA phù hợp | Tạo mới/quay lại |
| Validation error | Input sai | Field-level message bằng tiếng Việt/Nabitone | Sửa dữ liệu |
| Business error | Vi phạm rule | Message an toàn, không thuật ngữ nội bộ | Làm theo hướng dẫn |
| System error | Network/5xx/dependency lỗi | Retry + correlation id khi cần hỗ trợ | Thử lại/liên hệ hỗ trợ |
| Unauthorized/Forbidden | Thiếu đăng nhập/quyền | Login/no permission view | Đăng nhập/quay lại |

## D. Tương tác và mapping đến function

| Interaction ID | Người dùng thao tác | Điều kiện | Hệ thống gọi | Thành công | Thất bại | Navigation |
|---|---|---|---|---|---|---|
| AI_CHAT-V02-I01 | Submit chat question | Input và quyền hợp lệ | AI_CHAT-FN02 | Refresh trạng thái AI Chat | Hiển thị lỗi an toàn | Giữ view hoặc tới bước kế tiếp |
| AI_CHAT-V02-I02 | Tải lại dữ liệu | User có quyền xem | AI_CHAT-FN02 hoặc API đọc | Cập nhật view | Empty/error state | Không đổi route |

## E. Acceptance checklist cho QA/UI

- [ ] View chỉ hiển thị đúng role và trạng thái.
- [ ] Các state bắt buộc đều có thiết kế và test.
- [ ] Action chính gọi đúng AI_CHAT-FN02.
- [ ] Error message không lộ thông tin kỹ thuật hoặc dữ liệu nhạy cảm.
