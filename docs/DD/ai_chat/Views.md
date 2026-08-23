# Views — AI_CHAT / AI Chat

## 0. View Inventory

| ID | View Name | Route / Entry Point | Actor | Feature | Type | Data Source | Status | Mockup |
|---|---|---|---|---|---|---|---|---|
| AI_CHAT-V01 | AI Chat screen | planned route/action for ai_chat | Free, Plus, FamilyPlus | AI_CHAT-F01 | Page / Flow / Admin view | AI_CHAT-API01 | Approved - DD docs complete | assets/README.md |
| AI_CHAT-V02 | AI Chat composer | planned route/action for ai_chat | Free, Plus, FamilyPlus | AI_CHAT-F02 | Page / Flow / Admin view | AI_CHAT-API02 | Approved - DD docs complete | assets/README.md |
| AI_CHAT-V03 | Trò chuyện giọng nói với Nabi | `/ai-voice` | Plus, FamilyPlus | AI_CHAT-F03 | Mobile page | AI_CHAT-API03 trực tiếp qua controller/repository/datasource | Reaction-speed Android PASS; 3-minute source/test/build/install PASS, >60-second continuity pending; iOS pending | No custom asset required |

## 1. Navigation Map

| Source | Action | Destination | Condition |
|---|---|---|---|
| Module entry | Actor selects feature action | Feature view | Actor has permission and dependency data can load |
| Feature view | Submit/confirm | Result state or next feature | AI_CHAT-FNxx succeeds |
| Any view | Permission/data error | Safe error state | UI, route, use-case, or API blocks access |
| AI Chat chữ | Chọn nhập bằng giọng nói | AI_CHAT-V03 | Authenticated Plus/FamilyPlus; fail-closed gate passes |
| AI_CHAT-V03 | Chọn Nhập chữ | AI Chat composer | Voice session is stopped and history RAM cleared |

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
| Mockup / prototype | Optional future asset: BD v2.0 has no required mockup; view state/action contract is complete in this DD |

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

## E. Documented View Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| AI_CHAT-VIEW-EV01-01 | View chỉ hiển thị đúng role và trạng thái. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-VIEW-EV01-02 | Các state bắt buộc đều có thiết kế và test. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-VIEW-EV01-03 | Action chính gọi đúng AI_CHAT-FN01. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-VIEW-EV01-04 | Error message không lộ thông tin kỹ thuật hoặc dữ liệu nhạy cảm. | Documented | Required in implementation/test phase; not executed in this DD docs pass |

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
| Mockup / prototype | Optional future asset: BD v2.0 has no required mockup; view state/action contract is complete in this DD |

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

## E. Documented View Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| AI_CHAT-VIEW-EV02-01 | View chỉ hiển thị đúng role và trạng thái. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-VIEW-EV02-02 | Các state bắt buộc đều có thiết kế và test. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-VIEW-EV02-03 | Action chính gọi đúng AI_CHAT-FN02. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-VIEW-EV02-04 | Error message không lộ thông tin kỹ thuật hoặc dữ liệu nhạy cảm. | Documented | Required in implementation/test phase; not executed in this DD docs pass |

---

<a id="ai_chat-v03"></a>
# AI_CHAT-V03 — Trò chuyện giọng nói với Nabi

## A. Thông tin cơ bản

| Trường | Nội dung |
|---|---|
| Feature | AI_CHAT-F03 |
| Route | `/ai-voice`, có auth guard; không thuộc guest allowlist. |
| Actor được phép | Plus, FamilyPlus. |
| Gate | Chỉ mount trang/controller khi access thuộc exact current user, không anonymous và `hasPaidAccess == true`. Loading/error/null/user mismatch/Free fail-closed. |
| Hành vi Guest | Chuyển tới đăng nhập. |
| Hành vi Free | Không mount controller/micro; hiển thị CTA nâng cấp Plus. |
| Khởi động micro | Không tự động; chỉ sau khi người dùng nhấn **Bắt đầu**. |

## B. Layout tối giản

| Component ID | Thành phần | Nội dung/hành vi |
|---|---|---|
| AI_CHAT-V03-C01 | Trạng thái | `Sẵn sàng`, `Đang nghe`, `Nabi đang suy nghĩ`, `Nabi đang nói` hoặc lỗi an toàn. |
| AI_CHAT-V03-C02 | Transcript cuối | Câu người dùng vừa nói; không phải lịch sử persistent. |
| AI_CHAT-V03-C03 | Câu trả lời cuối | Text Nabi vừa trả lời; TTS đọc đúng text này. |
| AI_CHAT-V03-C04 | Nút chính | **Bắt đầu** khi idle/error; **Dừng** khi session active. |
| AI_CHAT-V03-C05 | Liên kết phụ | **Nhập chữ** để quay về AI Chat chữ. |
| AI_CHAT-V03-C06 | Dropdown tốc độ phản ứng | Nhãn **Tốc độ phản ứng**; Siêu nhanh 0,2 giây, Nhanh 0,5 giây, Bình thường 1 giây (mặc định), Chậm 2 giây. Helper: “Nabi sẽ gửi câu hỏi khi bạn im lặng đủ thời gian đã chọn.” |

Không có mute, pause/resume, nói chen, reconnect Live, greeting tự động hoặc copy
khẳng định có thể chen lời.

## C. Trạng thái và hành động

| State | Micro | TTS | UI / action |
|---|---|---|---|
| Access loading/error/null/mismatch | Off | Off | Fail-closed, retry access; không mount Voice controller. |
| Free | Off | Off | Thông tin cần Plus + CTA nâng cấp. |
| Idle | Off | Off | Nút **Bắt đầu**; dropdown enabled. |
| Listening | On | Off | Nút **Dừng**; hiển thị đang nghe; dropdown disabled. |
| Thinking | Off | Off | Nút **Dừng**; hiển thị Nabi đang suy nghĩ; dropdown disabled. |
| Speaking | Off | On | Nút **Dừng**; hiển thị Nabi đang nói; dropdown disabled. |
| Error/permission denied | Off | Off | Copy an toàn + **Thử lại/Bắt đầu** do người dùng chủ động; dropdown enabled khi session đã dừng. |

## D. Interaction mapping

| ID | Thao tác/sự kiện | Gọi | Kết quả |
|---|---|---|---|
| AI_CHAT-V03-I01 | Nhấn Bắt đầu | AI_CHAT-FN03 `start()` | Reset history, xin/kiểm tra audio capability và bắt đầu nghe. |
| AI_CHAT-V03-I02 | STT final, endpointing 0,2/0,5/1/2 giây sau speech result hoặc hard cap 3 phút | AI_CHAT-FN03 turn loop | Dừng STT trước khi gọi API; transcript rỗng không gọi Gemini. Final/endpointing có thể kết thúc trước hard cap; recognizer OS cũng có thể stop sớm. Threshold không phải Gemini latency. |
| AI_CHAT-V03-I03 | TTS completion | AI_CHAT-FN03 loop | Chờ 300 ms rồi listen nếu generation còn active. |
| AI_CHAT-V03-I04 | Nhấn Dừng | AI_CHAT-FN03 `stop()` | Cancel STT/TTS, clear history, idle, không restart. |
| AI_CHAT-V03-I05 | App background/rời trang | lifecycle stop/dispose | Giống Stop và bỏ late response. |
| AI_CHAT-V03-I06 | Nhấn Nhập chữ | stop + router | Dừng Voice trước khi chuyển route. |
| AI_CHAT-V03-I07 | Chọn Tốc độ phản ứng khi session đã dừng | Controller `setReactionSpeed()` | Cập nhật selection RAM cho lần Start kế; giữ qua Stop/Start cùng page, reset 1 giây khi page/controller được tạo lại. |

## E. Copy lỗi an toàn

- Permission: hướng dẫn người dùng cấp quyền micro/nhận dạng giọng nói rồi chủ
  động thử lại.
- Auth/access: hướng dẫn đăng nhập lại hoặc nâng cấp Plus, không dùng từ nội bộ
  như entitlement/gate.
- Rate/provider/TTS: “Nabi chưa thể trò chuyện lúc này. Bạn thử lại sau nhé.”
- Không hiển thị status thô, stack trace, tên bảng, key, raw Gemini response hoặc
  transcript/history ngoài hai trường cuối trên màn hình.
- Gate Plus/FamilyPlus nằm ở client; UI không được diễn đạt đây là cơ chế chống
  bypass hoặc bảo vệ key khỏi APK bị sửa.

## F. Acceptance

- `AI_CHAT-TC03`: route/gate matrix Guest, Free, Plus, FamilyPlus và access state.
- `AI_CHAT-TC04..TC07`: state/action/error/lifecycle bằng fake, không STT/TTS overlap.
- `AI_CHAT-TC13`: Android baseline multi-turn Vietnamese smoke PASS trên Xiaomi
  `220333QPG`.
- `AI_CHAT-TC14`: iOS build/device acceptance còn pending và chỉ được claim trên macOS/iPhone.
- `AI_CHAT-TC15..TC16`: dropdown/default/selection RAM và delayed-arm
  endpointing plugin contract PASS trong expanded 86/86 tests.
- `AI_CHAT-TC17`: Android reaction-speed re-smoke PASS trên Xiaomi
  `220333QPG`, gồm default/dropdown, Siêu nhanh delayed arm, two-turn/safe
  retry, selector lock/persistence và Stop trong TTS.
- `AI_CHAT-TC18`: hard cap mỗi lượt 180.000 ms cùng user/history input 6.000 ký
  tự và response 2.000 ký tự; source/90 tests/analyze/build/install PASS,
  >60-second device continuity pending; không cam kết recognizer OS chạy đủ 3 phút.
