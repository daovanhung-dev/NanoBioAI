# List Features — ADMIN_OPS / Admin quản lý hệ thống

## 0. Document Information

| Field | Value |
|---|---|
| Module | ADMIN_OPS |
| Overall | [Overall.md](Overall.md) |
| Version | v1.0 |
| Last Updated | 2026-06-28 |
| Source | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 11.3..11.7, 16.3 AC-20..AC-24, Appendix A UC-21 |

## 1. Feature Inventory

| ID | Feature | Goal | Actor | Trigger | Priority | Source | Functions | Views | Status |
|---|---|---|---|---|---|---|---|---|---|
| ADMIN_OPS-F01 | Quản lý người dùng/gói/Sale/config | Admin thao tác dữ liệu vận hành trong phạm vi quyền. | Admin, Super Admin | Admin opens management module | P0 | BD sections 11.3..11.5, UC-21 | ADMIN_OPS-FN01 | ADMIN_OPS-V01 | Draft |
| ADMIN_OPS-F02 | Quản lý tài chính hỗ trợ | Admin xử lý payment/conversion/adjustment đúng quyền. | Finance Admin, Super Admin | Review payment/conversion/adjustment | P0 | BD section 11.6, AC-20..AC-23 | ADMIN_OPS-FN02 | ADMIN_OPS-V02 | Draft |

## 2. Dependencies Between Features

| Source Feature | Relationship | Target Feature | Data / State Passed | Condition |
|---|---|---|---|---|
| ADMIN_OPS-F01 | prerequisite / trigger | Next feature in this module | Module state and actor context | Previous feature succeeds and business rules pass |
| Cross-module | dependency | Related module DD | Entitlement, ownership, audit, or event state | Dependency module is available and not blocked by open questions |

---

<a id="admin_ops-f01"></a>
# ADMIN_OPS-F01 — Quản lý người dùng/gói/Sale/config

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Admin thao tác dữ liệu vận hành trong phạm vi quyền. |
| Actor chính | Admin, Super Admin |
| Actor phụ / hệ thống | Audit/security |
| Trigger | Admin opens management module |
| Phạm vi | CRUD/admin actions with permissions. |
| Không thuộc feature | Bypass backend permission. |
| Requirement nguồn | BD sections 11.3..11.5, UC-21 |
| Rule áp dụng | ADMIN_OPS-BR01 |
| View liên quan | ADMIN_OPS-V01 |
| Function liên quan | ADMIN_OPS-FN01 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 11.3..11.7, 16.3 AC-20..AC-24, Appendix A UC-21. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Admin quản lý hệ thống được cập nhật và có thể truy vết tới BD sections 11.3..11.5, UC-21. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Admin, Super Admin mở ADMIN_OPS-V01 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=admin_role_permission; Name=Admin Role/Permission; Purpose=Phân quyền quản trị; Attributes=role, permission, scope; Relationships=Controls admin actions}, @{Id=system_configuration; Name=System Configuration; Purpose=Cấu hình version hóa; Attributes=key, value, effective time, approval/audit; Relationships=Used by packages, Sale, points}, @{Id=admin_action; Name=Admin Action; Purpose=Thao tác quản trị; Attributes=actor, action, target, reason, status; Relationships=Writes audit}.
4. Actor thực hiện hành động: Admin opens management module.
5. ADMIN_OPS-FN01 kiểm tra ADMIN_OPS-BR01 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| ADMIN_OPS-F01-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | ADMIN_OPS-TC01 |
| ADMIN_OPS-F01-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | ADMIN_OPS-TC01 |
| ADMIN_OPS-F01-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | ADMIN_OPS-TC01 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| ADMIN_OPS-BR01 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | ADMIN_OPS-E-main | Dữ liệu nghiệp vụ chính của Admin quản lý hệ thống | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | ADMIN_OPS-API01 | Contract dự kiến cho ADMIN_OPS-FN01 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD sections 11.3..11.5, UC-21, feature tạo đúng outcome: Admin thao tác dữ liệu vận hành trong phạm vi quyền..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] ADMIN_OPS-V01 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
---

<a id="admin_ops-f02"></a>
# ADMIN_OPS-F02 — Quản lý tài chính hỗ trợ

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Admin xử lý payment/conversion/adjustment đúng quyền. |
| Actor chính | Finance Admin, Super Admin |
| Actor phụ / hệ thống | Payment, Sale points |
| Trigger | Review payment/conversion/adjustment |
| Phạm vi | Approve/reject/confirm with audit. |
| Không thuộc feature | Self-approve if separation policy applies. |
| Requirement nguồn | BD section 11.6, AC-20..AC-23 |
| Rule áp dụng | ADMIN_OPS-BR02 |
| View liên quan | ADMIN_OPS-V02 |
| Function liên quan | ADMIN_OPS-FN02 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 11.3..11.7, 16.3 AC-20..AC-24, Appendix A UC-21. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Admin quản lý hệ thống được cập nhật và có thể truy vết tới BD section 11.6, AC-20..AC-23. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Finance Admin, Super Admin mở ADMIN_OPS-V02 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=admin_role_permission; Name=Admin Role/Permission; Purpose=Phân quyền quản trị; Attributes=role, permission, scope; Relationships=Controls admin actions}, @{Id=system_configuration; Name=System Configuration; Purpose=Cấu hình version hóa; Attributes=key, value, effective time, approval/audit; Relationships=Used by packages, Sale, points}, @{Id=admin_action; Name=Admin Action; Purpose=Thao tác quản trị; Attributes=actor, action, target, reason, status; Relationships=Writes audit}.
4. Actor thực hiện hành động: Review payment/conversion/adjustment.
5. ADMIN_OPS-FN02 kiểm tra ADMIN_OPS-BR02 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| ADMIN_OPS-F02-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | ADMIN_OPS-TC02 |
| ADMIN_OPS-F02-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | ADMIN_OPS-TC02 |
| ADMIN_OPS-F02-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | ADMIN_OPS-TC02 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| ADMIN_OPS-BR02 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | ADMIN_OPS-E-main | Dữ liệu nghiệp vụ chính của Admin quản lý hệ thống | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | ADMIN_OPS-API02 | Contract dự kiến cho ADMIN_OPS-FN02 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD section 11.6, AC-20..AC-23, feature tạo đúng outcome: Admin xử lý payment/conversion/adjustment đúng quyền..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] ADMIN_OPS-V02 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
