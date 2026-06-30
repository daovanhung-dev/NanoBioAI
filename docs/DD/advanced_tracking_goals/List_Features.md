# List Features — ADVANCED_TRACKING_GOALS / Theo dõi nâng cao & mục tiêu

## 0. Document Information

| Field | Value |
|---|---|
| Module | ADVANCED_TRACKING_GOALS |
| Overall | [Overall.md](Overall.md) |
| Version | v1.0 |
| Last Updated | 2026-06-28 |
| Source | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M10, 16.1 AC-06, Appendix A UC-10 |

## 1. Feature Inventory

| ID | Feature | Goal | Actor | Trigger | Priority | Source | Functions | Views | Status |
|---|---|---|---|---|---|---|---|---|---|
| ADVANCED_TRACKING_GOALS-F01 | Chọn mục tiêu nâng cao | Plus/FamilyPlus tạo mục tiêu hợp lệ. | Plus, FamilyPlus | Select advanced goal | P2 | BD M10 chức năng, UC-10 | ADVANCED_TRACKING_GOALS-FN01 | ADVANCED_TRACKING_GOALS-V01 | Draft |
| ADVANCED_TRACKING_GOALS-F02 | Theo dõi lộ trình mục tiêu | Hiển thị tiến độ theo goal roadmap. | Plus, FamilyPlus | Open goal tracking | P2 | BD M10 luồng | ADVANCED_TRACKING_GOALS-FN02 | ADVANCED_TRACKING_GOALS-V02 | Draft |

## 2. Dependencies Between Features

| Source Feature | Relationship | Target Feature | Data / State Passed | Condition |
|---|---|---|---|---|
| ADVANCED_TRACKING_GOALS-F01 | prerequisite / trigger | Next feature in this module | Module state and actor context | Previous feature succeeds and business rules pass |
| Cross-module | dependency | Related module DD | Entitlement, ownership, audit, or event state | Dependency module is available and accepted decision/evidence gates are satisfied |

---

<a id="advanced_tracking_goals-f01"></a>
# ADVANCED_TRACKING_GOALS-F01 — Chọn mục tiêu nâng cao

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Plus/FamilyPlus tạo mục tiêu hợp lệ. |
| Actor chính | Plus, FamilyPlus |
| Actor phụ / hệ thống | Entitlement service |
| Trigger | Select advanced goal |
| Phạm vi | Gate and create goal. |
| Không thuộc feature | Final catalog without PO. |
| Requirement nguồn | BD M10 chức năng, UC-10 |
| Rule áp dụng | ADVANCED_TRACKING_GOALS-BR01 |
| View liên quan | ADVANCED_TRACKING_GOALS-V01 |
| Function liên quan | ADVANCED_TRACKING_GOALS-FN01 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 6/M10, 16.1 AC-06, Appendix A UC-10. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Theo dõi nâng cao & mục tiêu được cập nhật và có thể truy vết tới BD M10 chức năng, UC-10. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Plus, FamilyPlus mở ADVANCED_TRACKING_GOALS-V01 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=goal; Name=Advanced Goal; Purpose=Mục tiêu nâng cao; Attributes=subject, type, status, start/end; Relationships=Links plan and progress}, @{Id=roadmap_step; Name=Roadmap Step; Purpose=Mốc lộ trình; Attributes=goal, order, status, target; Relationships=Tracked over time}.
4. Actor thực hiện hành động: Select advanced goal.
5. ADVANCED_TRACKING_GOALS-FN01 kiểm tra ADVANCED_TRACKING_GOALS-BR01 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| ADVANCED_TRACKING_GOALS-F01-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | ADVANCED_TRACKING_GOALS-TC01 |
| ADVANCED_TRACKING_GOALS-F01-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | ADVANCED_TRACKING_GOALS-TC01 |
| ADVANCED_TRACKING_GOALS-F01-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | ADVANCED_TRACKING_GOALS-TC01 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| ADVANCED_TRACKING_GOALS-BR01 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | ADVANCED_TRACKING_GOALS-E-main | Dữ liệu nghiệp vụ chính của Theo dõi nâng cao & mục tiêu | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | ADVANCED_TRACKING_GOALS-API01 | Contract dự kiến cho ADVANCED_TRACKING_GOALS-FN01 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD M10 chức năng, UC-10, feature tạo đúng outcome: Plus/FamilyPlus tạo mục tiêu hợp lệ..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] ADVANCED_TRACKING_GOALS-V01 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
---

<a id="advanced_tracking_goals-f02"></a>
# ADVANCED_TRACKING_GOALS-F02 — Theo dõi lộ trình mục tiêu

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Hiển thị tiến độ theo goal roadmap. |
| Actor chính | Plus, FamilyPlus |
| Actor phụ / hệ thống | Health score and schedule |
| Trigger | Open goal tracking |
| Phạm vi | Load progress and next steps. |
| Không thuộc feature | Medical treatment plan. |
| Requirement nguồn | BD M10 luồng |
| Rule áp dụng | ADVANCED_TRACKING_GOALS-BR02 |
| View liên quan | ADVANCED_TRACKING_GOALS-V02 |
| Function liên quan | ADVANCED_TRACKING_GOALS-FN02 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 6/M10, 16.1 AC-06, Appendix A UC-10. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Theo dõi nâng cao & mục tiêu được cập nhật và có thể truy vết tới BD M10 luồng. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Plus, FamilyPlus mở ADVANCED_TRACKING_GOALS-V02 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=goal; Name=Advanced Goal; Purpose=Mục tiêu nâng cao; Attributes=subject, type, status, start/end; Relationships=Links plan and progress}, @{Id=roadmap_step; Name=Roadmap Step; Purpose=Mốc lộ trình; Attributes=goal, order, status, target; Relationships=Tracked over time}.
4. Actor thực hiện hành động: Open goal tracking.
5. ADVANCED_TRACKING_GOALS-FN02 kiểm tra ADVANCED_TRACKING_GOALS-BR02 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| ADVANCED_TRACKING_GOALS-F02-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | ADVANCED_TRACKING_GOALS-TC02 |
| ADVANCED_TRACKING_GOALS-F02-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | ADVANCED_TRACKING_GOALS-TC02 |
| ADVANCED_TRACKING_GOALS-F02-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | ADVANCED_TRACKING_GOALS-TC02 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| ADVANCED_TRACKING_GOALS-BR02 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | ADVANCED_TRACKING_GOALS-E-main | Dữ liệu nghiệp vụ chính của Theo dõi nâng cao & mục tiêu | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | ADVANCED_TRACKING_GOALS-API02 | Contract dự kiến cho ADVANCED_TRACKING_GOALS-FN02 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD M10 luồng, feature tạo đúng outcome: Hiển thị tiến độ theo goal roadmap..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] ADVANCED_TRACKING_GOALS-V02 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
