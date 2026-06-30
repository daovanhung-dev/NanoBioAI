# List Features — AI_CHAT / AI Chat

## 0. Document Information

| Field | Value |
|---|---|
| Module | AI_CHAT |
| Overall | [Overall.md](Overall.md) |
| Version | v1.0 |
| Last Updated | 2026-06-30 |
| Source | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M07, 16.1 AC-03/AC-04/AC-06, Appendix A UC-07 |

## 1. Feature Inventory

| ID | Feature | Goal | Actor | Trigger | Priority | Source | Functions | Views | Status |
|---|---|---|---|---|---|---|---|---|---|
| AI_CHAT-F01 | Mở AI Chat theo quyền | Chỉ actor có entitlement hợp lệ được vào chat. | Free, Plus, FamilyPlus | Mở AI Chat | P0 | BD M07 luồng, AC-03/AC-06 | AI_CHAT-FN01 | AI_CHAT-V01 | Approved - DD docs complete |
| AI_CHAT-F02 | Gửi câu hỏi AI theo quota | Gửi câu hỏi khi quota/rate policy cho phép. | Free, Plus, FamilyPlus | Submit chat question | P0 | BD M07 rules, AC-04 | AI_CHAT-FN02 | AI_CHAT-V02 | Approved - DD docs complete |

## 2. Dependencies Between Features

| Source Feature | Relationship | Target Feature | Data / State Passed | Condition |
|---|---|---|---|---|
| AI_CHAT-F01 | prerequisite / trigger | Next feature in this module | Module state and actor context | Previous feature succeeds and business rules pass |
| Cross-module | dependency | Related module DD | Entitlement, ownership, audit, or event state | Dependency module is available and accepted decision/evidence gates are satisfied |

---

<a id="ai_chat-f01"></a>
# AI_CHAT-F01 — Mở AI Chat theo quyền

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Chỉ actor có entitlement hợp lệ được vào chat. |
| Actor chính | Free, Plus, FamilyPlus |
| Actor phụ / hệ thống | Membership quota |
| Trigger | Mở AI Chat |
| Phạm vi | Access check and load chat shell. |
| Không thuộc feature | Prompt design. |
| Requirement nguồn | BD M07 luồng, AC-03/AC-06 |
| Rule áp dụng | AI_CHAT-BR01 |
| View liên quan | AI_CHAT-V01 |
| Function liên quan | AI_CHAT-FN01 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 6/M07, 16.1 AC-03/AC-04/AC-06, Appendix A UC-07. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của AI Chat được cập nhật và có thể truy vết tới BD M07 luồng, AC-03/AC-06. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Free, Plus, FamilyPlus mở AI_CHAT-V01 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=ai_request; Name=AI Request; Purpose=Theo dõi request chat; Attributes=request_id, user, status, quota impact; Relationships=Uses quota ledger}, @{Id=chat_message; Name=Chat Message; Purpose=Tin nhắn chat nếu lưu; Attributes=owner, role, content summary, created_at; Relationships=Subject to privacy policy}.
4. Actor thực hiện hành động: Mở AI Chat.
5. AI_CHAT-FN01 kiểm tra AI_CHAT-BR01 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| AI_CHAT-F01-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | AI_CHAT-TC01 |
| AI_CHAT-F01-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | AI_CHAT-TC01 |
| AI_CHAT-F01-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | AI_CHAT-TC01 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| AI_CHAT-BR01 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | AI_CHAT-E-main | Dữ liệu nghiệp vụ chính của AI Chat | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | AI_CHAT-API01 | Contract dự kiến cho AI_CHAT-FN01 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Documented Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| AI_CHAT-AC01-01 | Với source BD M07 luồng, AC-03/AC-06, feature tạo đúng outcome: Chỉ actor có entitlement hợp lệ được vào chat.. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-AC01-02 | Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-AC01-03 | Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-AC01-04 | AI_CHAT-V01 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied. | Documented | Required in implementation/test phase; not executed in this DD docs pass |

---

<a id="ai_chat-f02"></a>
# AI_CHAT-F02 — Gửi câu hỏi AI theo quota

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Gửi câu hỏi khi quota/rate policy cho phép. |
| Actor chính | Free, Plus, FamilyPlus |
| Actor phụ / hệ thống | AI service |
| Trigger | Submit chat question |
| Phạm vi | Check quota, call AI, record success. |
| Không thuộc feature | Raw AI logs. |
| Requirement nguồn | BD M07 rules, AC-04 |
| Rule áp dụng | AI_CHAT-BR02 |
| View liên quan | AI_CHAT-V02 |
| Function liên quan | AI_CHAT-FN02 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 6/M07, 16.1 AC-03/AC-04/AC-06, Appendix A UC-07. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của AI Chat được cập nhật và có thể truy vết tới BD M07 rules, AC-04. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Free, Plus, FamilyPlus mở AI_CHAT-V02 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=ai_request; Name=AI Request; Purpose=Theo dõi request chat; Attributes=request_id, user, status, quota impact; Relationships=Uses quota ledger}, @{Id=chat_message; Name=Chat Message; Purpose=Tin nhắn chat nếu lưu; Attributes=owner, role, content summary, created_at; Relationships=Subject to privacy policy}.
4. Actor thực hiện hành động: Submit chat question.
5. AI_CHAT-FN02 kiểm tra AI_CHAT-BR02 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| AI_CHAT-F02-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | AI_CHAT-TC02 |
| AI_CHAT-F02-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | AI_CHAT-TC02 |
| AI_CHAT-F02-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | AI_CHAT-TC02 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| AI_CHAT-BR02 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | AI_CHAT-E-main | Dữ liệu nghiệp vụ chính của AI Chat | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | AI_CHAT-API02 | Contract dự kiến cho AI_CHAT-FN02 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Documented Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| AI_CHAT-AC02-01 | Với source BD M07 rules, AC-04, feature tạo đúng outcome: Gửi câu hỏi khi quota/rate policy cho phép.. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-AC02-02 | Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-AC02-03 | Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-AC02-04 | AI_CHAT-V02 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
