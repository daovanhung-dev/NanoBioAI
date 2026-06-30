# List Features — HEALTH_SCORE_HABITS / Điểm sức khỏe & thói quen

## 0. Document Information

| Field | Value |
|---|---|
| Module | HEALTH_SCORE_HABITS |
| Overall | [Overall.md](Overall.md) |
| Version | v1.0 |
| Last Updated | 2026-06-30 |
| Source | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M08, 9, 13, Appendix A UC-09 |

## 1. Feature Inventory

| ID | Feature | Goal | Actor | Trigger | Priority | Source | Functions | Views | Status |
|---|---|---|---|---|---|---|---|---|---|
| HEALTH_SCORE_HABITS-F01 | Tính điểm sức khỏe | Tạo điểm từ lịch sử thực hiện theo công thức version hóa. | System, Member | Completion event or scheduled recalculation | P1 | BD M08, section 9 | HEALTH_SCORE_HABITS-FN01 | HEALTH_SCORE_HABITS-V01 | Approved - DD docs complete |
| HEALTH_SCORE_HABITS-F02 | Theo dõi thói quen | Hiển thị tiến độ theo lịch sử thực hiện. | Member, Family member | Open progress view | P1 | BD M08 luồng | HEALTH_SCORE_HABITS-FN02 | HEALTH_SCORE_HABITS-V02 | Approved - DD docs complete |

## 2. Dependencies Between Features

| Source Feature | Relationship | Target Feature | Data / State Passed | Condition |
|---|---|---|---|---|
| HEALTH_SCORE_HABITS-F01 | prerequisite / trigger | Next feature in this module | Module state and actor context | Previous feature succeeds and business rules pass |
| Cross-module | dependency | Related module DD | Entitlement, ownership, audit, or event state | Dependency module is available and accepted decision/evidence gates are satisfied |

---

<a id="health_score_habits-f01"></a>
# HEALTH_SCORE_HABITS-F01 — Tính điểm sức khỏe

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Tạo điểm từ lịch sử thực hiện theo công thức version hóa. |
| Actor chính | System, Member |
| Actor phụ / hệ thống | Completion events |
| Trigger | Completion event or scheduled recalculation |
| Phạm vi | Calculate health score ledger. |
| Không thuộc feature | Sale point or payout. |
| Requirement nguồn | BD M08, section 9 |
| Rule áp dụng | HEALTH_SCORE_HABITS-BR01 |
| View liên quan | HEALTH_SCORE_HABITS-V01 |
| Function liên quan | HEALTH_SCORE_HABITS-FN01 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 6/M08, 9, 13, Appendix A UC-09. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Điểm sức khỏe & thói quen được cập nhật và có thể truy vết tới BD M08, section 9. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. System, Member mở HEALTH_SCORE_HABITS-V01 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=health_score_ledger; Name=Health Score Ledger; Purpose=Điểm sức khỏe; Attributes=subject, source event, formula version, score; Relationships=Uses completion events}, @{Id=habit_progress; Name=Habit Progress; Purpose=Tiến độ thói quen; Attributes=subject, period, score, status; Relationships=Displayed on dashboard}.
4. Actor thực hiện hành động: Completion event or scheduled recalculation.
5. HEALTH_SCORE_HABITS-FN01 kiểm tra HEALTH_SCORE_HABITS-BR01 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| HEALTH_SCORE_HABITS-F01-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | HEALTH_SCORE_HABITS-TC01 |
| HEALTH_SCORE_HABITS-F01-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | HEALTH_SCORE_HABITS-TC01 |
| HEALTH_SCORE_HABITS-F01-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | HEALTH_SCORE_HABITS-TC01 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| HEALTH_SCORE_HABITS-BR01 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | HEALTH_SCORE_HABITS-E-main | Dữ liệu nghiệp vụ chính của Điểm sức khỏe & thói quen | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | HEALTH_SCORE_HABITS-API01 | Contract dự kiến cho HEALTH_SCORE_HABITS-FN01 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Documented Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| HEALTH_SCORE_HABITS-AC01-01 | Với source BD M08, section 9, feature tạo đúng outcome: Tạo điểm từ lịch sử thực hiện theo công thức version hóa.. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| HEALTH_SCORE_HABITS-AC01-02 | Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| HEALTH_SCORE_HABITS-AC01-03 | Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| HEALTH_SCORE_HABITS-AC01-04 | HEALTH_SCORE_HABITS-V01 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied. | Documented | Required in implementation/test phase; not executed in this DD docs pass |

---

<a id="health_score_habits-f02"></a>
# HEALTH_SCORE_HABITS-F02 — Theo dõi thói quen

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Hiển thị tiến độ theo lịch sử thực hiện. |
| Actor chính | Member, Family member |
| Actor phụ / hệ thống | Dashboard |
| Trigger | Open progress view |
| Phạm vi | Read progress by subject. |
| Không thuộc feature | Medical diagnosis. |
| Requirement nguồn | BD M08 luồng |
| Rule áp dụng | HEALTH_SCORE_HABITS-BR02 |
| View liên quan | HEALTH_SCORE_HABITS-V02 |
| Function liên quan | HEALTH_SCORE_HABITS-FN02 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 6/M08, 9, 13, Appendix A UC-09. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Điểm sức khỏe & thói quen được cập nhật và có thể truy vết tới BD M08 luồng. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Member, Family member mở HEALTH_SCORE_HABITS-V02 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=health_score_ledger; Name=Health Score Ledger; Purpose=Điểm sức khỏe; Attributes=subject, source event, formula version, score; Relationships=Uses completion events}, @{Id=habit_progress; Name=Habit Progress; Purpose=Tiến độ thói quen; Attributes=subject, period, score, status; Relationships=Displayed on dashboard}.
4. Actor thực hiện hành động: Open progress view.
5. HEALTH_SCORE_HABITS-FN02 kiểm tra HEALTH_SCORE_HABITS-BR02 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| HEALTH_SCORE_HABITS-F02-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | HEALTH_SCORE_HABITS-TC02 |
| HEALTH_SCORE_HABITS-F02-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | HEALTH_SCORE_HABITS-TC02 |
| HEALTH_SCORE_HABITS-F02-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | HEALTH_SCORE_HABITS-TC02 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| HEALTH_SCORE_HABITS-BR02 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | HEALTH_SCORE_HABITS-E-main | Dữ liệu nghiệp vụ chính của Điểm sức khỏe & thói quen | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | HEALTH_SCORE_HABITS-API02 | Contract dự kiến cho HEALTH_SCORE_HABITS-FN02 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Documented Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| HEALTH_SCORE_HABITS-AC02-01 | Với source BD M08 luồng, feature tạo đúng outcome: Hiển thị tiến độ theo lịch sử thực hiện.. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| HEALTH_SCORE_HABITS-AC02-02 | Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| HEALTH_SCORE_HABITS-AC02-03 | Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| HEALTH_SCORE_HABITS-AC02-04 | HEALTH_SCORE_HABITS-V02 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
