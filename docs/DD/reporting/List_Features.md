# List Features — REPORTING / Thống kê & báo cáo

## 0. Document Information

| Field | Value |
|---|---|
| Module | REPORTING |
| Overall | [Overall.md](Overall.md) |
| Version | v1.0 |
| Last Updated | 2026-06-28 |
| Source | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD section 12.2, 14.2, 16.3 AC-23, Appendix A UC-24 |

## 1. Feature Inventory

| ID | Feature | Goal | Actor | Trigger | Priority | Source | Functions | Views | Status |
|---|---|---|---|---|---|---|---|---|---|
| REPORTING-F01 | Tạo báo cáo theo scope | Admin xem báo cáo theo thời gian/bộ lọc/quyền. | Admin | Select report and filters | P1 | BD section 12.2 | REPORTING-FN01 | REPORTING-V01 | Draft |
| REPORTING-F02 | Xuất báo cáo | Xuất file khi có quyền và log export. | Admin with export permission | Click export | P1 | BD section 12.2 rules, AC-23, UC-24 | REPORTING-FN02 | REPORTING-V02 | Draft |

## 2. Dependencies Between Features

| Source Feature | Relationship | Target Feature | Data / State Passed | Condition |
|---|---|---|---|---|
| REPORTING-F01 | prerequisite / trigger | Next feature in this module | Module state and actor context | Previous feature succeeds and business rules pass |
| Cross-module | dependency | Related module DD | Entitlement, ownership, audit, or event state | Dependency module is available and accepted decision/evidence gates are satisfied |

---

<a id="reporting-f01"></a>
# REPORTING-F01 — Tạo báo cáo theo scope

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Admin xem báo cáo theo thời gian/bộ lọc/quyền. |
| Actor chính | Admin |
| Actor phụ / hệ thống | Data sources, reconciliation |
| Trigger | Select report and filters |
| Phạm vi | Generate scoped report. |
| Không thuộc feature | Raw health data by default. |
| Requirement nguồn | BD section 12.2 |
| Rule áp dụng | REPORTING-BR01 |
| View liên quan | REPORTING-V01 |
| Function liên quan | REPORTING-FN01 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD section 12.2, 14.2, 16.3 AC-23, Appendix A UC-24. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Thống kê & báo cáo được cập nhật và có thể truy vết tới BD section 12.2. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Admin mở REPORTING-V01 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=report_definition; Name=Report Definition; Purpose=Định nghĩa báo cáo; Attributes=type, filters, scope, permissions; Relationships=Used by dashboard/export}, @{Id=report_export; Name=Report Export; Purpose=Lịch sử xuất báo cáo; Attributes=actor, format, filters, reason, timestamp; Relationships=Writes audit}.
4. Actor thực hiện hành động: Select report and filters.
5. REPORTING-FN01 kiểm tra REPORTING-BR01 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| REPORTING-F01-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | REPORTING-TC01 |
| REPORTING-F01-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | REPORTING-TC01 |
| REPORTING-F01-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | REPORTING-TC01 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| REPORTING-BR01 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | REPORTING-E-main | Dữ liệu nghiệp vụ chính của Thống kê & báo cáo | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | REPORTING-API01 | Contract dự kiến cho REPORTING-FN01 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD section 12.2, feature tạo đúng outcome: Admin xem báo cáo theo thời gian/bộ lọc/quyền..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] REPORTING-V01 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
---

<a id="reporting-f02"></a>
# REPORTING-F02 — Xuất báo cáo

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Xuất file khi có quyền và log export. |
| Actor chính | Admin with export permission |
| Actor phụ / hệ thống | Audit/security |
| Trigger | Click export |
| Phạm vi | Create export record and artifact. |
| Không thuộc feature | Export without audit. |
| Requirement nguồn | BD section 12.2 rules, AC-23, UC-24 |
| Rule áp dụng | REPORTING-BR02 |
| View liên quan | REPORTING-V02 |
| Function liên quan | REPORTING-FN02 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD section 12.2, 14.2, 16.3 AC-23, Appendix A UC-24. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Thống kê & báo cáo được cập nhật và có thể truy vết tới BD section 12.2 rules, AC-23, UC-24. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Admin with export permission mở REPORTING-V02 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=report_definition; Name=Report Definition; Purpose=Định nghĩa báo cáo; Attributes=type, filters, scope, permissions; Relationships=Used by dashboard/export}, @{Id=report_export; Name=Report Export; Purpose=Lịch sử xuất báo cáo; Attributes=actor, format, filters, reason, timestamp; Relationships=Writes audit}.
4. Actor thực hiện hành động: Click export.
5. REPORTING-FN02 kiểm tra REPORTING-BR02 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| REPORTING-F02-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | REPORTING-TC02 |
| REPORTING-F02-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | REPORTING-TC02 |
| REPORTING-F02-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | REPORTING-TC02 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| REPORTING-BR02 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | REPORTING-E-main | Dữ liệu nghiệp vụ chính của Thống kê & báo cáo | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | REPORTING-API02 | Contract dự kiến cho REPORTING-FN02 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD section 12.2 rules, AC-23, UC-24, feature tạo đúng outcome: Xuất file khi có quyền và log export..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] REPORTING-V02 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
