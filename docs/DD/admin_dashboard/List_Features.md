# List Features — ADMIN_DASHBOARD / Admin View / Dashboard

## 0. Document Information

| Field | Value |
|---|---|
| Module | ADMIN_DASHBOARD |
| Overall | [Overall.md](Overall.md) |
| Version | v1.0 |
| Last Updated | 2026-06-28 |
| Source | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 11.1/11.2, 12.2, 16.3 AC-19, Appendix A UC-20 |

## 1. Feature Inventory

| ID | Feature | Goal | Actor | Trigger | Priority | Source | Functions | Views | Status |
|---|---|---|---|---|---|---|---|---|---|
| ADMIN_DASHBOARD-F01 | Xem dashboard Admin | Admin xem chỉ số vận hành theo permission. | Admin | Admin opens dashboard | P0 | BD section 11.2, AC-19, UC-20 | ADMIN_DASHBOARD-FN01 | ADMIN_DASHBOARD-V01 | Draft |
| ADMIN_DASHBOARD-F02 | Drill-down theo quyền | Admin đi từ chỉ số sang module chi tiết đúng quyền. | Admin | Click metric/filter | P1 | BD section 11.2 workflow | ADMIN_DASHBOARD-FN02 | ADMIN_DASHBOARD-V02 | Draft |

## 2. Dependencies Between Features

| Source Feature | Relationship | Target Feature | Data / State Passed | Condition |
|---|---|---|---|---|
| ADMIN_DASHBOARD-F01 | prerequisite / trigger | Next feature in this module | Module state and actor context | Previous feature succeeds and business rules pass |
| Cross-module | dependency | Related module DD | Entitlement, ownership, audit, or event state | Dependency module is available and accepted decision/evidence gates are satisfied |

---

<a id="admin_dashboard-f01"></a>
# ADMIN_DASHBOARD-F01 — Xem dashboard Admin

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Admin xem chỉ số vận hành theo permission. |
| Actor chính | Admin |
| Actor phụ / hệ thống | Reporting, audit |
| Trigger | Admin opens dashboard |
| Phạm vi | Load scoped metrics and alerts. |
| Không thuộc feature | Direct mutation from dashboard. |
| Requirement nguồn | BD section 11.2, AC-19, UC-20 |
| Rule áp dụng | ADMIN_DASHBOARD-BR01 |
| View liên quan | ADMIN_DASHBOARD-V01 |
| Function liên quan | ADMIN_DASHBOARD-FN01 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 11.1/11.2, 12.2, 16.3 AC-19, Appendix A UC-20. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Admin View / Dashboard được cập nhật và có thể truy vết tới BD section 11.2, AC-19, UC-20. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Admin mở ADMIN_DASHBOARD-V01 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=dashboard_metric; Name=Dashboard Metric; Purpose=Chỉ số tổng hợp; Attributes=metric key, period, value, scope; Relationships=Derived from reporting}, @{Id=admin_scope; Name=Admin Scope; Purpose=Phạm vi quyền xem; Attributes=role, permission, scope; Relationships=Limits metrics}.
4. Actor thực hiện hành động: Admin opens dashboard.
5. ADMIN_DASHBOARD-FN01 kiểm tra ADMIN_DASHBOARD-BR01 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| ADMIN_DASHBOARD-F01-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | ADMIN_DASHBOARD-TC01 |
| ADMIN_DASHBOARD-F01-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | ADMIN_DASHBOARD-TC01 |
| ADMIN_DASHBOARD-F01-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | ADMIN_DASHBOARD-TC01 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| ADMIN_DASHBOARD-BR01 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | ADMIN_DASHBOARD-E-main | Dữ liệu nghiệp vụ chính của Admin View / Dashboard | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | ADMIN_DASHBOARD-API01 | Contract dự kiến cho ADMIN_DASHBOARD-FN01 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD section 11.2, AC-19, UC-20, feature tạo đúng outcome: Admin xem chỉ số vận hành theo permission..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] ADMIN_DASHBOARD-V01 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
---

<a id="admin_dashboard-f02"></a>
# ADMIN_DASHBOARD-F02 — Drill-down theo quyền

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Admin đi từ chỉ số sang module chi tiết đúng quyền. |
| Actor chính | Admin |
| Actor phụ / hệ thống | Admin operations |
| Trigger | Click metric/filter |
| Phạm vi | Navigate with permission check. |
| Không thuộc feature | Bypass detail permission. |
| Requirement nguồn | BD section 11.2 workflow |
| Rule áp dụng | ADMIN_DASHBOARD-BR02 |
| View liên quan | ADMIN_DASHBOARD-V02 |
| Function liên quan | ADMIN_DASHBOARD-FN02 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 11.1/11.2, 12.2, 16.3 AC-19, Appendix A UC-20. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Admin View / Dashboard được cập nhật và có thể truy vết tới BD section 11.2 workflow. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Admin mở ADMIN_DASHBOARD-V02 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=dashboard_metric; Name=Dashboard Metric; Purpose=Chỉ số tổng hợp; Attributes=metric key, period, value, scope; Relationships=Derived from reporting}, @{Id=admin_scope; Name=Admin Scope; Purpose=Phạm vi quyền xem; Attributes=role, permission, scope; Relationships=Limits metrics}.
4. Actor thực hiện hành động: Click metric/filter.
5. ADMIN_DASHBOARD-FN02 kiểm tra ADMIN_DASHBOARD-BR02 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| ADMIN_DASHBOARD-F02-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | ADMIN_DASHBOARD-TC02 |
| ADMIN_DASHBOARD-F02-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | ADMIN_DASHBOARD-TC02 |
| ADMIN_DASHBOARD-F02-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | ADMIN_DASHBOARD-TC02 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| ADMIN_DASHBOARD-BR02 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | ADMIN_DASHBOARD-E-main | Dữ liệu nghiệp vụ chính của Admin View / Dashboard | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | ADMIN_DASHBOARD-API02 | Contract dự kiến cho ADMIN_DASHBOARD-FN02 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD section 11.2 workflow, feature tạo đúng outcome: Admin đi từ chỉ số sang module chi tiết đúng quyền..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] ADMIN_DASHBOARD-V02 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
