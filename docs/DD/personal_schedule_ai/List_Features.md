# List Features — PERSONAL_SCHEDULE_AI / AI Lịch trình cá nhân

## 0. Document Information

| Field | Value |
|---|---|
| Module | PERSONAL_SCHEDULE_AI |
| Overall | [Overall.md](Overall.md) |
| Version | v1.0 |
| Last Updated | 2026-06-28 |
| Source | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M02, 13, 16.1 AC-01/AC-02/AC-05/AC-06, Appendix A UC-02/UC-08 |

## 1. Feature Inventory

| ID | Feature | Goal | Actor | Trigger | Priority | Source | Functions | Views | Status |
|---|---|---|---|---|---|---|---|---|---|
| PERSONAL_SCHEDULE_AI-F01 | Sinh lịch trình đầu tiên cho Guest | Guest hoàn tất onboarding nhận lịch trình đầu tiên. | Guest | Onboarding completed | P0 | BD M02 Guest flow, AC-01, AC-02, UC-02 | PERSONAL_SCHEDULE_AI-FN01 | PERSONAL_SCHEDULE_AI-V01 | Draft |
| PERSONAL_SCHEDULE_AI-F02 | Tạo lịch trình mới cho Member | Member tạo lịch trình mới theo quota hoặc quyền Plus/FamilyPlus. | Free, Plus, FamilyPlus | Member yêu cầu tạo lịch trình mới | P0 | BD M02 Member flow, AC-05, AC-06, UC-08 | PERSONAL_SCHEDULE_AI-FN02 | PERSONAL_SCHEDULE_AI-V02 | Draft |

## 2. Dependencies Between Features

| Source Feature | Relationship | Target Feature | Data / State Passed | Condition |
|---|---|---|---|---|
| PERSONAL_SCHEDULE_AI-F01 | prerequisite / trigger | Next feature in this module | Module state and actor context | Previous feature succeeds and business rules pass |
| Cross-module | dependency | Related module DD | Entitlement, ownership, audit, or event state | Dependency module is available and not blocked by open questions |

---

<a id="personal_schedule_ai-f01"></a>
# PERSONAL_SCHEDULE_AI-F01 — Sinh lịch trình đầu tiên cho Guest

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Guest hoàn tất onboarding nhận lịch trình đầu tiên. |
| Actor chính | Guest |
| Actor phụ / hệ thống | AI service, local storage |
| Trigger | Onboarding completed |
| Phạm vi | Generate first plan and save active plan. |
| Không thuộc feature | AI Chat và tạo lại không giới hạn. |
| Requirement nguồn | BD M02 Guest flow, AC-01, AC-02, UC-02 |
| Rule áp dụng | PERSONAL_SCHEDULE_AI-BR01 |
| View liên quan | PERSONAL_SCHEDULE_AI-V01 |
| Function liên quan | PERSONAL_SCHEDULE_AI-FN01 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 6/M02, 13, 16.1 AC-01/AC-02/AC-05/AC-06, Appendix A UC-02/UC-08. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của AI Lịch trình cá nhân được cập nhật và có thể truy vết tới BD M02 Guest flow, AC-01, AC-02, UC-02. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Guest mở PERSONAL_SCHEDULE_AI-V01 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=personal_plan; Name=Personal Plan; Purpose=Lịch trình AI; Attributes=owner, subject, version, status, AI source; Relationships=Has Plan Items}, @{Id=plan_item; Name=Plan Item; Purpose=Bữa ăn/bài tập/mốc lịch; Attributes=plan id, time, type, status; Relationships=Used by dashboard and notification}, @{Id=ai_request; Name=AI Request; Purpose=Theo dõi request/quota; Attributes=request_id, type, status, quota impact; Relationships=Linked to quota ledger}.
4. Actor thực hiện hành động: Onboarding completed.
5. PERSONAL_SCHEDULE_AI-FN01 kiểm tra PERSONAL_SCHEDULE_AI-BR01 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| PERSONAL_SCHEDULE_AI-F01-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | PERSONAL_SCHEDULE_AI-TC01 |
| PERSONAL_SCHEDULE_AI-F01-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | PERSONAL_SCHEDULE_AI-TC01 |
| PERSONAL_SCHEDULE_AI-F01-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | PERSONAL_SCHEDULE_AI-TC01 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| PERSONAL_SCHEDULE_AI-BR01 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | PERSONAL_SCHEDULE_AI-E-main | Dữ liệu nghiệp vụ chính của AI Lịch trình cá nhân | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | PERSONAL_SCHEDULE_AI-API01 | Contract dự kiến cho PERSONAL_SCHEDULE_AI-FN01 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD M02 Guest flow, AC-01, AC-02, UC-02, feature tạo đúng outcome: Guest hoàn tất onboarding nhận lịch trình đầu tiên..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] PERSONAL_SCHEDULE_AI-V01 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
---

<a id="personal_schedule_ai-f02"></a>
# PERSONAL_SCHEDULE_AI-F02 — Tạo lịch trình mới cho Member

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Member tạo lịch trình mới theo quota hoặc quyền Plus/FamilyPlus. |
| Actor chính | Free, Plus, FamilyPlus |
| Actor phụ / hệ thống | Quota service, AI service |
| Trigger | Member yêu cầu tạo lịch trình mới |
| Phạm vi | Check entitlement/quota, call AI, save result. |
| Không thuộc feature | Quota configuration final policy. |
| Requirement nguồn | BD M02 Member flow, AC-05, AC-06, UC-08 |
| Rule áp dụng | PERSONAL_SCHEDULE_AI-BR02 |
| View liên quan | PERSONAL_SCHEDULE_AI-V02 |
| Function liên quan | PERSONAL_SCHEDULE_AI-FN02 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 6/M02, 13, 16.1 AC-01/AC-02/AC-05/AC-06, Appendix A UC-02/UC-08. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của AI Lịch trình cá nhân được cập nhật và có thể truy vết tới BD M02 Member flow, AC-05, AC-06, UC-08. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Free, Plus, FamilyPlus mở PERSONAL_SCHEDULE_AI-V02 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=personal_plan; Name=Personal Plan; Purpose=Lịch trình AI; Attributes=owner, subject, version, status, AI source; Relationships=Has Plan Items}, @{Id=plan_item; Name=Plan Item; Purpose=Bữa ăn/bài tập/mốc lịch; Attributes=plan id, time, type, status; Relationships=Used by dashboard and notification}, @{Id=ai_request; Name=AI Request; Purpose=Theo dõi request/quota; Attributes=request_id, type, status, quota impact; Relationships=Linked to quota ledger}.
4. Actor thực hiện hành động: Member yêu cầu tạo lịch trình mới.
5. PERSONAL_SCHEDULE_AI-FN02 kiểm tra PERSONAL_SCHEDULE_AI-BR02 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| PERSONAL_SCHEDULE_AI-F02-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | PERSONAL_SCHEDULE_AI-TC02 |
| PERSONAL_SCHEDULE_AI-F02-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | PERSONAL_SCHEDULE_AI-TC02 |
| PERSONAL_SCHEDULE_AI-F02-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | PERSONAL_SCHEDULE_AI-TC02 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| PERSONAL_SCHEDULE_AI-BR02 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | PERSONAL_SCHEDULE_AI-E-main | Dữ liệu nghiệp vụ chính của AI Lịch trình cá nhân | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | PERSONAL_SCHEDULE_AI-API02 | Contract dự kiến cho PERSONAL_SCHEDULE_AI-FN02 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD M02 Member flow, AC-05, AC-06, UC-08, feature tạo đúng outcome: Member tạo lịch trình mới theo quota hoặc quyền Plus/FamilyPlus..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] PERSONAL_SCHEDULE_AI-V02 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
