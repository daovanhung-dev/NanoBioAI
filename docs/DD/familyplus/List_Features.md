# List Features — FAMILYPLUS / FamilyPlus

## 0. Document Information

| Field | Value |
|---|---|
| Module | FAMILYPLUS |
| Overall | [Overall.md](Overall.md) |
| Version | v1.0 |
| Last Updated | 2026-06-28 |
| Source | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 10/M11, 13, 14.2, 16.1 AC-06, Appendix A UC-11 |

## 1. Feature Inventory

| ID | Feature | Goal | Actor | Trigger | Priority | Source | Functions | Views | Status |
|---|---|---|---|---|---|---|---|---|---|
| FAMILYPLUS-F01 | Quản lý nhóm gia đình | Chủ FamilyPlus tạo/quản lý nhóm và thành viên. | FamilyPlus owner | Open family management | P1 | BD M11 chức năng, UC-11 | FAMILYPLUS-FN01 | FAMILYPLUS-V01 | Draft |
| FAMILYPLUS-F02 | Theo dõi dữ liệu từng thành viên | Tạo/xem lịch trình và dashboard đúng subject. | FamilyPlus owner, Family member | Select family member context | P1 | BD M11 luồng thêm thành viên | FAMILYPLUS-FN02 | FAMILYPLUS-V02 | Draft |

## 2. Dependencies Between Features

| Source Feature | Relationship | Target Feature | Data / State Passed | Condition |
|---|---|---|---|---|
| FAMILYPLUS-F01 | prerequisite / trigger | Next feature in this module | Module state and actor context | Previous feature succeeds and business rules pass |
| Cross-module | dependency | Related module DD | Entitlement, ownership, audit, or event state | Dependency module is available and accepted decision/evidence gates are satisfied |

---

<a id="familyplus-f01"></a>
# FAMILYPLUS-F01 — Quản lý nhóm gia đình

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Chủ FamilyPlus tạo/quản lý nhóm và thành viên. |
| Actor chính | FamilyPlus owner |
| Actor phụ / hệ thống | Entitlement service |
| Trigger | Open family management |
| Phạm vi | Add/remove/update member roles. |
| Không thuộc feature | Final consent policy. |
| Requirement nguồn | BD M11 chức năng, UC-11 |
| Rule áp dụng | FAMILYPLUS-BR01 |
| View liên quan | FAMILYPLUS-V01 |
| Function liên quan | FAMILYPLUS-FN01 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 10/M11, 13, 14.2, 16.1 AC-06, Appendix A UC-11. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của FamilyPlus được cập nhật và có thể truy vết tới BD M11 chức năng, UC-11. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. FamilyPlus owner mở FAMILYPLUS-V01 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=family_group; Name=Family Group; Purpose=Nhóm FamilyPlus; Attributes=owner, status, member quota; Relationships=Has family members}, @{Id=family_member; Name=Family Member; Purpose=Một người trong Family; Attributes=subject_member_id, role, consent, status; Relationships=Owns health/schedule data}.
4. Actor thực hiện hành động: Open family management.
5. FAMILYPLUS-FN01 kiểm tra FAMILYPLUS-BR01 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| FAMILYPLUS-F01-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | FAMILYPLUS-TC01 |
| FAMILYPLUS-F01-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | FAMILYPLUS-TC01 |
| FAMILYPLUS-F01-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | FAMILYPLUS-TC01 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| FAMILYPLUS-BR01 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | FAMILYPLUS-E-main | Dữ liệu nghiệp vụ chính của FamilyPlus | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | FAMILYPLUS-API01 | Contract dự kiến cho FAMILYPLUS-FN01 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD M11 chức năng, UC-11, feature tạo đúng outcome: Chủ FamilyPlus tạo/quản lý nhóm và thành viên..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] FAMILYPLUS-V01 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
---

<a id="familyplus-f02"></a>
# FAMILYPLUS-F02 — Theo dõi dữ liệu từng thành viên

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Tạo/xem lịch trình và dashboard đúng subject. |
| Actor chính | FamilyPlus owner, Family member |
| Actor phụ / hệ thống | Onboarding, schedule, dashboard |
| Trigger | Select family member context |
| Phạm vi | Switch subject context and validate permission. |
| Không thuộc feature | Unauthorized cross-member access. |
| Requirement nguồn | BD M11 luồng thêm thành viên |
| Rule áp dụng | FAMILYPLUS-BR02 |
| View liên quan | FAMILYPLUS-V02 |
| Function liên quan | FAMILYPLUS-FN02 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 10/M11, 13, 14.2, 16.1 AC-06, Appendix A UC-11. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của FamilyPlus được cập nhật và có thể truy vết tới BD M11 luồng thêm thành viên. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. FamilyPlus owner, Family member mở FAMILYPLUS-V02 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=family_group; Name=Family Group; Purpose=Nhóm FamilyPlus; Attributes=owner, status, member quota; Relationships=Has family members}, @{Id=family_member; Name=Family Member; Purpose=Một người trong Family; Attributes=subject_member_id, role, consent, status; Relationships=Owns health/schedule data}.
4. Actor thực hiện hành động: Select family member context.
5. FAMILYPLUS-FN02 kiểm tra FAMILYPLUS-BR02 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| FAMILYPLUS-F02-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | FAMILYPLUS-TC02 |
| FAMILYPLUS-F02-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | FAMILYPLUS-TC02 |
| FAMILYPLUS-F02-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | FAMILYPLUS-TC02 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| FAMILYPLUS-BR02 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | FAMILYPLUS-E-main | Dữ liệu nghiệp vụ chính của FamilyPlus | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | FAMILYPLUS-API02 | Contract dự kiến cho FAMILYPLUS-FN02 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD M11 luồng thêm thành viên, feature tạo đúng outcome: Tạo/xem lịch trình và dashboard đúng subject..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] FAMILYPLUS-V02 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
