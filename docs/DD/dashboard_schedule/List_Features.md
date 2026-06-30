# List Features — DASHBOARD_SCHEDULE / Dashboard & Thực hiện lịch trình

## 0. Document Information

| Field | Value |
|---|---|
| Module | DASHBOARD_SCHEDULE |
| Overall | [Overall.md](Overall.md) |
| Version | v1.0 |
| Last Updated | 2026-06-30 |
| Source | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M03, 13, Appendix A UC-09 |

## 1. Feature Inventory

| ID | Feature | Goal | Actor | Trigger | Priority | Source | Functions | Views | Status |
|---|---|---|---|---|---|---|---|---|---|
| DASHBOARD_SCHEDULE-F01 | Xem lịch trình hôm nay | Actor thấy việc cần làm và tiến độ hiện tại. | Guest, Member, Family | Mở dashboard | P0 | BD M03 chức năng | DASHBOARD_SCHEDULE-FN01 | DASHBOARD_SCHEDULE-V01 | Approved - DD docs complete |
| DASHBOARD_SCHEDULE-F02 | Đánh dấu thực hiện lịch trình | Lưu completion event đúng subject. | Guest, Member, Family | Bấm hoàn thành hoặc bỏ qua | P0 | BD M03 luồng đánh dấu | DASHBOARD_SCHEDULE-FN02 | DASHBOARD_SCHEDULE-V02 | Approved - DD docs complete |

## 2. Dependencies Between Features

| Source Feature | Relationship | Target Feature | Data / State Passed | Condition |
|---|---|---|---|---|
| DASHBOARD_SCHEDULE-F01 | prerequisite / trigger | Next feature in this module | Module state and actor context | Previous feature succeeds and business rules pass |
| Cross-module | dependency | Related module DD | Entitlement, ownership, audit, or event state | Dependency module is available and accepted decision/evidence gates are satisfied |

---

<a id="dashboard_schedule-f01"></a>
# DASHBOARD_SCHEDULE-F01 — Xem lịch trình hôm nay

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Actor thấy việc cần làm và tiến độ hiện tại. |
| Actor chính | Guest, Member, Family |
| Actor phụ / hệ thống | Plan repository |
| Trigger | Mở dashboard |
| Phạm vi | Read plan items by owner/subject. |
| Không thuộc feature | AI generation. |
| Requirement nguồn | BD M03 chức năng |
| Rule áp dụng | DASHBOARD_SCHEDULE-BR01 |
| View liên quan | DASHBOARD_SCHEDULE-V01 |
| Function liên quan | DASHBOARD_SCHEDULE-FN01 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 6/M03, 13, Appendix A UC-09. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Dashboard & Thực hiện lịch trình được cập nhật và có thể truy vết tới BD M03 chức năng. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Guest, Member, Family mở DASHBOARD_SCHEDULE-V01 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=plan_item; Name=Plan Item; Purpose=Task lịch trình; Attributes=status, due time, type; Relationships=Belongs to Personal Plan}, @{Id=completion_event; Name=Plan Completion Event; Purpose=Lịch sử thực hiện; Attributes=item, status, actor, time; Relationships=Feeds Health Score}.
4. Actor thực hiện hành động: Mở dashboard.
5. DASHBOARD_SCHEDULE-FN01 kiểm tra DASHBOARD_SCHEDULE-BR01 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| DASHBOARD_SCHEDULE-F01-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | DASHBOARD_SCHEDULE-TC01 |
| DASHBOARD_SCHEDULE-F01-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | DASHBOARD_SCHEDULE-TC01 |
| DASHBOARD_SCHEDULE-F01-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | DASHBOARD_SCHEDULE-TC01 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| DASHBOARD_SCHEDULE-BR01 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | DASHBOARD_SCHEDULE-E-main | Dữ liệu nghiệp vụ chính của Dashboard & Thực hiện lịch trình | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | DASHBOARD_SCHEDULE-API01 | Contract dự kiến cho DASHBOARD_SCHEDULE-FN01 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Documented Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| DASHBOARD_SCHEDULE-AC01-01 | Với source BD M03 chức năng, feature tạo đúng outcome: Actor thấy việc cần làm và tiến độ hiện tại.. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| DASHBOARD_SCHEDULE-AC01-02 | Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| DASHBOARD_SCHEDULE-AC01-03 | Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| DASHBOARD_SCHEDULE-AC01-04 | DASHBOARD_SCHEDULE-V01 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied. | Documented | Required in implementation/test phase; not executed in this DD docs pass |

---

<a id="dashboard_schedule-f02"></a>
# DASHBOARD_SCHEDULE-F02 — Đánh dấu thực hiện lịch trình

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Lưu completion event đúng subject. |
| Actor chính | Guest, Member, Family |
| Actor phụ / hệ thống | Health score module |
| Trigger | Bấm hoàn thành hoặc bỏ qua |
| Phạm vi | Update item status and write event. |
| Không thuộc feature | Tính điểm cuối cùng. |
| Requirement nguồn | BD M03 luồng đánh dấu |
| Rule áp dụng | DASHBOARD_SCHEDULE-BR02 |
| View liên quan | DASHBOARD_SCHEDULE-V02 |
| Function liên quan | DASHBOARD_SCHEDULE-FN02 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 6/M03, 13, Appendix A UC-09. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Dashboard & Thực hiện lịch trình được cập nhật và có thể truy vết tới BD M03 luồng đánh dấu. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Guest, Member, Family mở DASHBOARD_SCHEDULE-V02 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=plan_item; Name=Plan Item; Purpose=Task lịch trình; Attributes=status, due time, type; Relationships=Belongs to Personal Plan}, @{Id=completion_event; Name=Plan Completion Event; Purpose=Lịch sử thực hiện; Attributes=item, status, actor, time; Relationships=Feeds Health Score}.
4. Actor thực hiện hành động: Bấm hoàn thành hoặc bỏ qua.
5. DASHBOARD_SCHEDULE-FN02 kiểm tra DASHBOARD_SCHEDULE-BR02 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| DASHBOARD_SCHEDULE-F02-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | DASHBOARD_SCHEDULE-TC02 |
| DASHBOARD_SCHEDULE-F02-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | DASHBOARD_SCHEDULE-TC02 |
| DASHBOARD_SCHEDULE-F02-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | DASHBOARD_SCHEDULE-TC02 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| DASHBOARD_SCHEDULE-BR02 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | DASHBOARD_SCHEDULE-E-main | Dữ liệu nghiệp vụ chính của Dashboard & Thực hiện lịch trình | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | DASHBOARD_SCHEDULE-API02 | Contract dự kiến cho DASHBOARD_SCHEDULE-FN02 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Documented Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| DASHBOARD_SCHEDULE-AC02-01 | Với source BD M03 luồng đánh dấu, feature tạo đúng outcome: Lưu completion event đúng subject.. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| DASHBOARD_SCHEDULE-AC02-02 | Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| DASHBOARD_SCHEDULE-AC02-03 | Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| DASHBOARD_SCHEDULE-AC02-04 | DASHBOARD_SCHEDULE-V02 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
