# List Features — AUDIT_SECURITY / Audit, bảo mật & hỗ trợ

## 0. Document Information

| Field | Value |
|---|---|
| Module | AUDIT_SECURITY |
| Overall | [Overall.md](Overall.md) |
| Version | v1.0 |
| Last Updated | 2026-06-28 |
| Source | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 11.8, 14, 15, 16.3 AC-20/AC-21/AC-24, Appendix A UC-23 |

## 1. Feature Inventory

| ID | Feature | Goal | Actor | Trigger | Priority | Source | Functions | Views | Status |
|---|---|---|---|---|---|---|---|---|---|
| AUDIT_SECURITY-F01 | Ghi audit bắt buộc | Mọi thao tác nhạy cảm có audit đủ actor/action/entity/reason/time. | System | Sensitive write/read/export/action | P0 | BD sections 14.3, 11.8, UC-23 | AUDIT_SECURITY-FN01 | AUDIT_SECURITY-V01 | Draft |
| AUDIT_SECURITY-F02 | Kiểm soát quyền và hỗ trợ rủi ro | Chặn truy cập sai scope và hỗ trợ xử lý bất thường. | Admin, Super Admin, System | Permission check, suspicious event, support action | P0 | BD sections 14.1/14.2/15, AC-20/AC-24 | AUDIT_SECURITY-FN02 | AUDIT_SECURITY-V02 | Draft |

## 2. Dependencies Between Features

| Source Feature | Relationship | Target Feature | Data / State Passed | Condition |
|---|---|---|---|---|
| AUDIT_SECURITY-F01 | prerequisite / trigger | Next feature in this module | Module state and actor context | Previous feature succeeds and business rules pass |
| Cross-module | dependency | Related module DD | Entitlement, ownership, audit, or event state | Dependency module is available and accepted decision/evidence gates are satisfied |

---

<a id="audit_security-f01"></a>
# AUDIT_SECURITY-F01 — Ghi audit bắt buộc

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Mọi thao tác nhạy cảm có audit đủ actor/action/entity/reason/time. |
| Actor chính | System |
| Actor phụ / hệ thống | All modules |
| Trigger | Sensitive write/read/export/action |
| Phạm vi | Record audit safely after/with transaction. |
| Không thuộc feature | Logging secrets/raw payloads. |
| Requirement nguồn | BD sections 14.3, 11.8, UC-23 |
| Rule áp dụng | AUDIT_SECURITY-BR01 |
| View liên quan | AUDIT_SECURITY-V01 |
| Function liên quan | AUDIT_SECURITY-FN01 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 11.8, 14, 15, 16.3 AC-20/AC-21/AC-24, Appendix A UC-23. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Audit, bảo mật & hỗ trợ được cập nhật và có thể truy vết tới BD sections 14.3, 11.8, UC-23. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. System mở AUDIT_SECURITY-V01 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=audit_log; Name=Audit Log; Purpose=Truy vết; Attributes=actor, action, entity, before/after, reason, timestamp, correlation id; Relationships=Written by all sensitive modules}, @{Id=security_event; Name=Security Event; Purpose=Sự kiện bảo mật/rủi ro; Attributes=event type, actor, target, severity, status; Relationships=May open support case}, @{Id=support_case; Name=Support Case; Purpose=Hỗ trợ/vi phạm; Attributes=subject, reason, status, evidence summary; Relationships=Linked to audit/security}.
4. Actor thực hiện hành động: Sensitive write/read/export/action.
5. AUDIT_SECURITY-FN01 kiểm tra AUDIT_SECURITY-BR01 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| AUDIT_SECURITY-F01-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | AUDIT_SECURITY-TC01 |
| AUDIT_SECURITY-F01-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | AUDIT_SECURITY-TC01 |
| AUDIT_SECURITY-F01-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | AUDIT_SECURITY-TC01 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| AUDIT_SECURITY-BR01 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | AUDIT_SECURITY-E-main | Dữ liệu nghiệp vụ chính của Audit, bảo mật & hỗ trợ | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | AUDIT_SECURITY-API01 | Contract dự kiến cho AUDIT_SECURITY-FN01 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD sections 14.3, 11.8, UC-23, feature tạo đúng outcome: Mọi thao tác nhạy cảm có audit đủ actor/action/entity/reason/time..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] AUDIT_SECURITY-V01 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
---

<a id="audit_security-f02"></a>
# AUDIT_SECURITY-F02 — Kiểm soát quyền và hỗ trợ rủi ro

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Chặn truy cập sai scope và hỗ trợ xử lý bất thường. |
| Actor chính | Admin, Super Admin, System |
| Actor phụ / hệ thống | Security policies |
| Trigger | Permission check, suspicious event, support action |
| Phạm vi | Authorize, flag, review, support. |
| Không thuộc feature | Bypass RLS/backend check. |
| Requirement nguồn | BD sections 14.1/14.2/15, AC-20/AC-24 |
| Rule áp dụng | AUDIT_SECURITY-BR02 |
| View liên quan | AUDIT_SECURITY-V02 |
| Function liên quan | AUDIT_SECURITY-FN02 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 11.8, 14, 15, 16.3 AC-20/AC-21/AC-24, Appendix A UC-23. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Audit, bảo mật & hỗ trợ được cập nhật và có thể truy vết tới BD sections 14.1/14.2/15, AC-20/AC-24. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Admin, Super Admin, System mở AUDIT_SECURITY-V02 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=audit_log; Name=Audit Log; Purpose=Truy vết; Attributes=actor, action, entity, before/after, reason, timestamp, correlation id; Relationships=Written by all sensitive modules}, @{Id=security_event; Name=Security Event; Purpose=Sự kiện bảo mật/rủi ro; Attributes=event type, actor, target, severity, status; Relationships=May open support case}, @{Id=support_case; Name=Support Case; Purpose=Hỗ trợ/vi phạm; Attributes=subject, reason, status, evidence summary; Relationships=Linked to audit/security}.
4. Actor thực hiện hành động: Permission check, suspicious event, support action.
5. AUDIT_SECURITY-FN02 kiểm tra AUDIT_SECURITY-BR02 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| AUDIT_SECURITY-F02-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | AUDIT_SECURITY-TC02 |
| AUDIT_SECURITY-F02-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | AUDIT_SECURITY-TC02 |
| AUDIT_SECURITY-F02-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | AUDIT_SECURITY-TC02 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| AUDIT_SECURITY-BR02 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | AUDIT_SECURITY-E-main | Dữ liệu nghiệp vụ chính của Audit, bảo mật & hỗ trợ | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | AUDIT_SECURITY-API02 | Contract dự kiến cho AUDIT_SECURITY-FN02 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD sections 14.1/14.2/15, AC-20/AC-24, feature tạo đúng outcome: Chặn truy cập sai scope và hỗ trợ xử lý bất thường..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] AUDIT_SECURITY-V02 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
