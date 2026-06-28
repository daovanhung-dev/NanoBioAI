# List Features — ONBOARDING_PROFILE / Onboarding & Hồ sơ sức khỏe

## 0. Document Information

| Field | Value |
|---|---|
| Module | ONBOARDING_PROFILE |
| Overall | [Overall.md](Overall.md) |
| Version | v1.0 |
| Last Updated | 2026-06-28 |
| Source | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M01, 13, 16.1 AC-01, Appendix A UC-01 |

## 1. Feature Inventory

| ID | Feature | Goal | Actor | Trigger | Priority | Source | Functions | Views | Status |
|---|---|---|---|---|---|---|---|---|---|
| ONBOARDING_PROFILE-F01 | Thu thập dữ liệu onboarding | Người dùng hoàn tất dữ liệu đầu vào tối thiểu. | Guest, Member | Mở app lần đầu hoặc hồ sơ chưa hoàn tất | P0 | BD M01, AC-01, UC-01 | ONBOARDING_PROFILE-FN01 | ONBOARDING_PROFILE-V01 | Draft |
| ONBOARDING_PROFILE-F02 | Xác nhận hoàn tất onboarding | Đánh dấu hồ sơ đủ điều kiện để sinh lịch trình. | Guest, Member | Người dùng xác nhận màn tổng rà soát | P0 | BD M01 luồng chính, AC-01 | ONBOARDING_PROFILE-FN02 | ONBOARDING_PROFILE-V02 | Draft |

## 2. Dependencies Between Features

| Source Feature | Relationship | Target Feature | Data / State Passed | Condition |
|---|---|---|---|---|
| ONBOARDING_PROFILE-F01 | prerequisite / trigger | Next feature in this module | Module state and actor context | Previous feature succeeds and business rules pass |
| Cross-module | dependency | Related module DD | Entitlement, ownership, audit, or event state | Dependency module is available and not blocked by open questions |

---

<a id="onboarding_profile-f01"></a>
# ONBOARDING_PROFILE-F01 — Thu thập dữ liệu onboarding

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Người dùng hoàn tất dữ liệu đầu vào tối thiểu. |
| Actor chính | Guest, Member |
| Actor phụ / hệ thống | System |
| Trigger | Mở app lần đầu hoặc hồ sơ chưa hoàn tất |
| Phạm vi | Thông tin cơ bản, mục tiêu, lối sống, chỉ số cơ thể. |
| Không thuộc feature | Công thức y tế và tư vấn điều trị. |
| Requirement nguồn | BD M01, AC-01, UC-01 |
| Rule áp dụng | ONBOARDING_PROFILE-BR01 |
| View liên quan | ONBOARDING_PROFILE-V01 |
| Function liên quan | ONBOARDING_PROFILE-FN01 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 6/M01, 13, 16.1 AC-01, Appendix A UC-01. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Onboarding & Hồ sơ sức khỏe được cập nhật và có thể truy vết tới BD M01, AC-01, UC-01. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Guest, Member mở ONBOARDING_PROFILE-V01 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=guest_profile; Name=Guest Profile; Purpose=Hồ sơ local trước đăng nhập; Attributes=local key, first schedule flag, onboarding status; Relationships=May sync to App User}, @{Id=onboarding_profile; Name=Onboarding Profile; Purpose=Dữ liệu cá nhân hóa; Attributes=owner, subject, profile version, completion status; Relationships=Used by Personal Plan and Health Calculator}.
4. Actor thực hiện hành động: Mở app lần đầu hoặc hồ sơ chưa hoàn tất.
5. ONBOARDING_PROFILE-FN01 kiểm tra ONBOARDING_PROFILE-BR01 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| ONBOARDING_PROFILE-F01-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | ONBOARDING_PROFILE-TC01 |
| ONBOARDING_PROFILE-F01-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | ONBOARDING_PROFILE-TC01 |
| ONBOARDING_PROFILE-F01-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | ONBOARDING_PROFILE-TC01 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| ONBOARDING_PROFILE-BR01 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | ONBOARDING_PROFILE-E-main | Dữ liệu nghiệp vụ chính của Onboarding & Hồ sơ sức khỏe | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | ONBOARDING_PROFILE-API01 | Contract dự kiến cho ONBOARDING_PROFILE-FN01 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD M01, AC-01, UC-01, feature tạo đúng outcome: Người dùng hoàn tất dữ liệu đầu vào tối thiểu..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] ONBOARDING_PROFILE-V01 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
---

<a id="onboarding_profile-f02"></a>
# ONBOARDING_PROFILE-F02 — Xác nhận hoàn tất onboarding

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Đánh dấu hồ sơ đủ điều kiện để sinh lịch trình. |
| Actor chính | Guest, Member |
| Actor phụ / hệ thống | Personal schedule service |
| Trigger | Người dùng xác nhận màn tổng rà soát |
| Phạm vi | Validate, save, mark completed, handoff. |
| Không thuộc feature | Sinh lịch trình AI chi tiết. |
| Requirement nguồn | BD M01 luồng chính, AC-01 |
| Rule áp dụng | ONBOARDING_PROFILE-BR02 |
| View liên quan | ONBOARDING_PROFILE-V02 |
| Function liên quan | ONBOARDING_PROFILE-FN02 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 6/M01, 13, 16.1 AC-01, Appendix A UC-01. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Onboarding & Hồ sơ sức khỏe được cập nhật và có thể truy vết tới BD M01 luồng chính, AC-01. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Guest, Member mở ONBOARDING_PROFILE-V02 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=guest_profile; Name=Guest Profile; Purpose=Hồ sơ local trước đăng nhập; Attributes=local key, first schedule flag, onboarding status; Relationships=May sync to App User}, @{Id=onboarding_profile; Name=Onboarding Profile; Purpose=Dữ liệu cá nhân hóa; Attributes=owner, subject, profile version, completion status; Relationships=Used by Personal Plan and Health Calculator}.
4. Actor thực hiện hành động: Người dùng xác nhận màn tổng rà soát.
5. ONBOARDING_PROFILE-FN02 kiểm tra ONBOARDING_PROFILE-BR02 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| ONBOARDING_PROFILE-F02-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | ONBOARDING_PROFILE-TC02 |
| ONBOARDING_PROFILE-F02-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | ONBOARDING_PROFILE-TC02 |
| ONBOARDING_PROFILE-F02-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | ONBOARDING_PROFILE-TC02 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| ONBOARDING_PROFILE-BR02 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | ONBOARDING_PROFILE-E-main | Dữ liệu nghiệp vụ chính của Onboarding & Hồ sơ sức khỏe | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | ONBOARDING_PROFILE-API02 | Contract dự kiến cho ONBOARDING_PROFILE-FN02 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD M01 luồng chính, AC-01, feature tạo đúng outcome: Đánh dấu hồ sơ đủ điều kiện để sinh lịch trình..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] ONBOARDING_PROFILE-V02 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
