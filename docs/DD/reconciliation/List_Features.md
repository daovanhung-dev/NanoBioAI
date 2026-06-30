# List Features — RECONCILIATION / Tính toán & đối soát

## 0. Document Information

| Field | Value |
|---|---|
| Module | RECONCILIATION |
| Overall | [Overall.md](Overall.md) |
| Version | v1.0 |
| Last Updated | 2026-06-30 |
| Source | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD section 12.1, 14.4, 15, Appendix A UC-22 |

## 1. Feature Inventory

| ID | Feature | Goal | Actor | Trigger | Priority | Source | Functions | Views | Status |
|---|---|---|---|---|---|---|---|---|---|
| RECONCILIATION-F01 | Chạy đối soát định kỳ | Tạo danh sách sai lệch theo kỳ/scope. | Admin, System | Admin chọn kỳ hoặc scheduled job | P1 | BD section 12.1, UC-22 | RECONCILIATION-FN01 | RECONCILIATION-V01 | Approved - DD docs complete |
| RECONCILIATION-F02 | Xử lý sai lệch | Admin phân loại và tạo adjustment có audit. | Admin | Admin reviews discrepancy | P1 | BD section 12.1 luồng đối soát | RECONCILIATION-FN02 | RECONCILIATION-V02 | Approved - DD docs complete |

## 2. Dependencies Between Features

| Source Feature | Relationship | Target Feature | Data / State Passed | Condition |
|---|---|---|---|---|
| RECONCILIATION-F01 | prerequisite / trigger | Next feature in this module | Module state and actor context | Previous feature succeeds and business rules pass |
| Cross-module | dependency | Related module DD | Entitlement, ownership, audit, or event state | Dependency module is available and accepted decision/evidence gates are satisfied |

---

<a id="reconciliation-f01"></a>
# RECONCILIATION-F01 — Chạy đối soát định kỳ

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Tạo danh sách sai lệch theo kỳ/scope. |
| Actor chính | Admin, System |
| Actor phụ / hệ thống | Payment, entitlement, points, quota |
| Trigger | Admin chọn kỳ hoặc scheduled job |
| Phạm vi | Compare source records and summary state. |
| Không thuộc feature | Tax/accounting final close. |
| Requirement nguồn | BD section 12.1, UC-22 |
| Rule áp dụng | RECONCILIATION-BR01 |
| View liên quan | RECONCILIATION-V01 |
| Function liên quan | RECONCILIATION-FN01 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD section 12.1, 14.4, 15, Appendix A UC-22. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Tính toán & đối soát được cập nhật và có thể truy vết tới BD section 12.1, UC-22. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Admin, System mở RECONCILIATION-V01 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=reconciliation_run; Name=Reconciliation Run; Purpose=Kỳ đối soát; Attributes=period, scope, status, actor; Relationships=Has discrepancies}, @{Id=discrepancy; Name=Discrepancy; Purpose=Sai lệch cần xử lý; Attributes=source entity, expected, actual, status; Relationships=May create adjustment}.
4. Actor thực hiện hành động: Admin chọn kỳ hoặc scheduled job.
5. RECONCILIATION-FN01 kiểm tra RECONCILIATION-BR01 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| RECONCILIATION-F01-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | RECONCILIATION-TC01 |
| RECONCILIATION-F01-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | RECONCILIATION-TC01 |
| RECONCILIATION-F01-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | RECONCILIATION-TC01 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| RECONCILIATION-BR01 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | RECONCILIATION-E-main | Dữ liệu nghiệp vụ chính của Tính toán & đối soát | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | RECONCILIATION-API01 | Contract dự kiến cho RECONCILIATION-FN01 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Documented Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| RECONCILIATION-AC01-01 | Với source BD section 12.1, UC-22, feature tạo đúng outcome: Tạo danh sách sai lệch theo kỳ/scope.. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| RECONCILIATION-AC01-02 | Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| RECONCILIATION-AC01-03 | Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| RECONCILIATION-AC01-04 | RECONCILIATION-V01 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied. | Documented | Required in implementation/test phase; not executed in this DD docs pass |

---

<a id="reconciliation-f02"></a>
# RECONCILIATION-F02 — Xử lý sai lệch

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Admin phân loại và tạo adjustment có audit. |
| Actor chính | Admin |
| Actor phụ / hệ thống | Audit, related module owner |
| Trigger | Admin reviews discrepancy |
| Phạm vi | Classify, resolve, adjust. |
| Không thuộc feature | Direct overwrite of closed ledger. |
| Requirement nguồn | BD section 12.1 luồng đối soát |
| Rule áp dụng | RECONCILIATION-BR02 |
| View liên quan | RECONCILIATION-V02 |
| Function liên quan | RECONCILIATION-FN02 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD section 12.1, 14.4, 15, Appendix A UC-22. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Tính toán & đối soát được cập nhật và có thể truy vết tới BD section 12.1 luồng đối soát. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Admin mở RECONCILIATION-V02 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=reconciliation_run; Name=Reconciliation Run; Purpose=Kỳ đối soát; Attributes=period, scope, status, actor; Relationships=Has discrepancies}, @{Id=discrepancy; Name=Discrepancy; Purpose=Sai lệch cần xử lý; Attributes=source entity, expected, actual, status; Relationships=May create adjustment}.
4. Actor thực hiện hành động: Admin reviews discrepancy.
5. RECONCILIATION-FN02 kiểm tra RECONCILIATION-BR02 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| RECONCILIATION-F02-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | RECONCILIATION-TC02 |
| RECONCILIATION-F02-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | RECONCILIATION-TC02 |
| RECONCILIATION-F02-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | RECONCILIATION-TC02 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| RECONCILIATION-BR02 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | RECONCILIATION-E-main | Dữ liệu nghiệp vụ chính của Tính toán & đối soát | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | RECONCILIATION-API02 | Contract dự kiến cho RECONCILIATION-FN02 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Documented Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| RECONCILIATION-AC02-01 | Với source BD section 12.1 luồng đối soát, feature tạo đúng outcome: Admin phân loại và tạo adjustment có audit.. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| RECONCILIATION-AC02-02 | Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| RECONCILIATION-AC02-03 | Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| RECONCILIATION-AC02-04 | RECONCILIATION-V02 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
