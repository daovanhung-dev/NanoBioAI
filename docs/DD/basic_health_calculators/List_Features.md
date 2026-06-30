# List Features — BASIC_HEALTH_CALC / Tính toán sức khỏe cơ bản

## 0. Document Information

| Field | Value |
|---|---|
| Module | BASIC_HEALTH_CALC |
| Overall | [Overall.md](Overall.md) |
| Version | v1.0 |
| Last Updated | 2026-06-30 |
| Source | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M04, 18.2 Q-14, Appendix A UC-03 |

## 1. Feature Inventory

| ID | Feature | Goal | Actor | Trigger | Priority | Source | Functions | Views | Status |
|---|---|---|---|---|---|---|---|---|---|
| BASIC_HEALTH_CALC-F01 | Chạy công cụ tính toán cơ bản | Trả kết quả từ dữ liệu hợp lệ. | Guest, Member | Người dùng nhập dữ liệu và bấm tính | P1 | BD M04 luồng, UC-03 | BASIC_HEALTH_CALC-FN01 | BASIC_HEALTH_CALC-V01 | Approved - DD docs complete |
| BASIC_HEALTH_CALC-F02 | Quản lý version công thức | Đảm bảo thay đổi công thức có version và audit. | Admin | Admin/PO phê duyệt công thức mới | P1 | BD M04 lưu ý, Q-14 | BASIC_HEALTH_CALC-FN02 | BASIC_HEALTH_CALC-V02 | Approved - DD docs complete |

## 2. Dependencies Between Features

| Source Feature | Relationship | Target Feature | Data / State Passed | Condition |
|---|---|---|---|---|
| BASIC_HEALTH_CALC-F01 | prerequisite / trigger | Next feature in this module | Module state and actor context | Previous feature succeeds and business rules pass |
| Cross-module | dependency | Related module DD | Entitlement, ownership, audit, or event state | Dependency module is available and accepted decision/evidence gates are satisfied |

---

<a id="basic_health_calc-f01"></a>
# BASIC_HEALTH_CALC-F01 — Chạy công cụ tính toán cơ bản

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Trả kết quả từ dữ liệu hợp lệ. |
| Actor chính | Guest, Member |
| Actor phụ / hệ thống | Formula policy |
| Trigger | Người dùng nhập dữ liệu và bấm tính |
| Phạm vi | Validate input and calculate approved metrics. |
| Không thuộc feature | Medical diagnosis. |
| Requirement nguồn | BD M04 luồng, UC-03 |
| Rule áp dụng | BASIC_HEALTH_CALC-BR01 |
| View liên quan | BASIC_HEALTH_CALC-V01 |
| Function liên quan | BASIC_HEALTH_CALC-FN01 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 6/M04, 18.2 Q-14, Appendix A UC-03. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Tính toán sức khỏe cơ bản được cập nhật và có thể truy vết tới BD M04 luồng, UC-03. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Guest, Member mở BASIC_HEALTH_CALC-V01 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=calculator_input; Name=Calculator Input; Purpose=Dữ liệu tính toán; Attributes=height, weight, age group, goal fields; Relationships=May derive from onboarding}, @{Id=formula_version; Name=Formula Version; Purpose=Version công thức; Attributes=code, version, status, effective_from; Relationships=Managed by admin if approved}.
4. Actor thực hiện hành động: Người dùng nhập dữ liệu và bấm tính.
5. BASIC_HEALTH_CALC-FN01 kiểm tra BASIC_HEALTH_CALC-BR01 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| BASIC_HEALTH_CALC-F01-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | BASIC_HEALTH_CALC-TC01 |
| BASIC_HEALTH_CALC-F01-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | BASIC_HEALTH_CALC-TC01 |
| BASIC_HEALTH_CALC-F01-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | BASIC_HEALTH_CALC-TC01 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| BASIC_HEALTH_CALC-BR01 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | BASIC_HEALTH_CALC-E-main | Dữ liệu nghiệp vụ chính của Tính toán sức khỏe cơ bản | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | BASIC_HEALTH_CALC-API01 | Contract dự kiến cho BASIC_HEALTH_CALC-FN01 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Documented Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| BASIC_HEALTH_CALC-AC01-01 | Với source BD M04 luồng, UC-03, feature tạo đúng outcome: Trả kết quả từ dữ liệu hợp lệ.. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| BASIC_HEALTH_CALC-AC01-02 | Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| BASIC_HEALTH_CALC-AC01-03 | Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| BASIC_HEALTH_CALC-AC01-04 | BASIC_HEALTH_CALC-V01 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied. | Documented | Required in implementation/test phase; not executed in this DD docs pass |

---

<a id="basic_health_calc-f02"></a>
# BASIC_HEALTH_CALC-F02 — Quản lý version công thức

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Đảm bảo thay đổi công thức có version và audit. |
| Actor chính | Admin |
| Actor phụ / hệ thống | Audit |
| Trigger | Admin/PO phê duyệt công thức mới |
| Phạm vi | Record formula version metadata. |
| Không thuộc feature | Final medical validation. |
| Requirement nguồn | BD M04 lưu ý, Q-14 |
| Rule áp dụng | BASIC_HEALTH_CALC-BR02 |
| View liên quan | BASIC_HEALTH_CALC-V02 |
| Function liên quan | BASIC_HEALTH_CALC-FN02 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 6/M04, 18.2 Q-14, Appendix A UC-03. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Tính toán sức khỏe cơ bản được cập nhật và có thể truy vết tới BD M04 lưu ý, Q-14. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Admin mở BASIC_HEALTH_CALC-V02 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=calculator_input; Name=Calculator Input; Purpose=Dữ liệu tính toán; Attributes=height, weight, age group, goal fields; Relationships=May derive from onboarding}, @{Id=formula_version; Name=Formula Version; Purpose=Version công thức; Attributes=code, version, status, effective_from; Relationships=Managed by admin if approved}.
4. Actor thực hiện hành động: Admin/PO phê duyệt công thức mới.
5. BASIC_HEALTH_CALC-FN02 kiểm tra BASIC_HEALTH_CALC-BR02 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| BASIC_HEALTH_CALC-F02-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | BASIC_HEALTH_CALC-TC02 |
| BASIC_HEALTH_CALC-F02-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | BASIC_HEALTH_CALC-TC02 |
| BASIC_HEALTH_CALC-F02-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | BASIC_HEALTH_CALC-TC02 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| BASIC_HEALTH_CALC-BR02 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | BASIC_HEALTH_CALC-E-main | Dữ liệu nghiệp vụ chính của Tính toán sức khỏe cơ bản | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | BASIC_HEALTH_CALC-API02 | Contract dự kiến cho BASIC_HEALTH_CALC-FN02 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Documented Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| BASIC_HEALTH_CALC-AC02-01 | Với source BD M04 lưu ý, Q-14, feature tạo đúng outcome: Đảm bảo thay đổi công thức có version và audit.. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| BASIC_HEALTH_CALC-AC02-02 | Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| BASIC_HEALTH_CALC-AC02-03 | Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| BASIC_HEALTH_CALC-AC02-04 | BASIC_HEALTH_CALC-V02 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
