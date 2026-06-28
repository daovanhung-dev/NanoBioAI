# List Features — MEMBERSHIP_QUOTA / Gói thành viên & quota

## 0. Document Information

| Field | Value |
|---|---|
| Module | MEMBERSHIP_QUOTA |
| Overall | [Overall.md](Overall.md) |
| Version | v1.0 |
| Last Updated | 2026-06-28 |
| Source | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M06, 13, 16.1 AC-04..AC-08, Appendix A UC-06 |

## 1. Feature Inventory

| ID | Feature | Goal | Actor | Trigger | Priority | Source | Functions | Views | Status |
|---|---|---|---|---|---|---|---|---|---|
| MEMBERSHIP_QUOTA-F01 | Dựng quyền hiệu lực | Tạo access state dùng chung cho UI/route/use-case/API. | System, Member | Login, app resume, package change | P0 | BD M06 luồng dựng quyền, AC-07/AC-08, UC-06 | MEMBERSHIP_QUOTA-FN01 | MEMBERSHIP_QUOTA-V01 | Draft |
| MEMBERSHIP_QUOTA-F02 | Kiểm soát quota Free | Chặn vượt quota và không trừ sai khi dependency lỗi. | Free | AI Chat hoặc tạo lịch trình | P0 | BD M06 quota, AC-04/AC-05 | MEMBERSHIP_QUOTA-FN02 | MEMBERSHIP_QUOTA-V02 | Draft |

## 2. Dependencies Between Features

| Source Feature | Relationship | Target Feature | Data / State Passed | Condition |
|---|---|---|---|---|
| MEMBERSHIP_QUOTA-F01 | prerequisite / trigger | Next feature in this module | Module state and actor context | Previous feature succeeds and business rules pass |
| Cross-module | dependency | Related module DD | Entitlement, ownership, audit, or event state | Dependency module is available and not blocked by open questions |

---

<a id="membership_quota-f01"></a>
# MEMBERSHIP_QUOTA-F01 — Dựng quyền hiệu lực

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Tạo access state dùng chung cho UI/route/use-case/API. |
| Actor chính | System, Member |
| Actor phụ / hệ thống | Auth, payment |
| Trigger | Login, app resume, package change |
| Phạm vi | Build entitlement from trusted source. |
| Không thuộc feature | Client-only paid access. |
| Requirement nguồn | BD M06 luồng dựng quyền, AC-07/AC-08, UC-06 |
| Rule áp dụng | MEMBERSHIP_QUOTA-BR01 |
| View liên quan | MEMBERSHIP_QUOTA-V01 |
| Function liên quan | MEMBERSHIP_QUOTA-FN01 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 6/M06, 13, 16.1 AC-04..AC-08, Appendix A UC-06. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Gói thành viên & quota được cập nhật và có thể truy vết tới BD M06 luồng dựng quyền, AC-07/AC-08, UC-06. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. System, Member mở MEMBERSHIP_QUOTA-V01 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=membership_product; Name=Membership Product; Purpose=Cấu hình gói; Attributes=plan code, price, quota, version, effective time; Relationships=Creates entitlement}, @{Id=membership_entitlement; Name=Membership Entitlement; Purpose=Quyền gói; Attributes=user, plan, start/end, source payment; Relationships=Used by gates}, @{Id=usage_quota_ledger; Name=Usage Quota Ledger; Purpose=Lịch sử quota; Attributes=quota type, period, request id, status; Relationships=Used by AI and schedule}.
4. Actor thực hiện hành động: Login, app resume, package change.
5. MEMBERSHIP_QUOTA-FN01 kiểm tra MEMBERSHIP_QUOTA-BR01 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| MEMBERSHIP_QUOTA-F01-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | MEMBERSHIP_QUOTA-TC01 |
| MEMBERSHIP_QUOTA-F01-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | MEMBERSHIP_QUOTA-TC01 |
| MEMBERSHIP_QUOTA-F01-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | MEMBERSHIP_QUOTA-TC01 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| MEMBERSHIP_QUOTA-BR01 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | MEMBERSHIP_QUOTA-E-main | Dữ liệu nghiệp vụ chính của Gói thành viên & quota | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | MEMBERSHIP_QUOTA-API01 | Contract dự kiến cho MEMBERSHIP_QUOTA-FN01 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD M06 luồng dựng quyền, AC-07/AC-08, UC-06, feature tạo đúng outcome: Tạo access state dùng chung cho UI/route/use-case/API..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] MEMBERSHIP_QUOTA-V01 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
---

<a id="membership_quota-f02"></a>
# MEMBERSHIP_QUOTA-F02 — Kiểm soát quota Free

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Chặn vượt quota và không trừ sai khi dependency lỗi. |
| Actor chính | Free |
| Actor phụ / hệ thống | AI modules |
| Trigger | AI Chat hoặc tạo lịch trình |
| Phạm vi | Check/increment quota ledger. |
| Không thuộc feature | Rate limit kỹ thuật ngoài quota. |
| Requirement nguồn | BD M06 quota, AC-04/AC-05 |
| Rule áp dụng | MEMBERSHIP_QUOTA-BR02 |
| View liên quan | MEMBERSHIP_QUOTA-V02 |
| Function liên quan | MEMBERSHIP_QUOTA-FN02 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 6/M06, 13, 16.1 AC-04..AC-08, Appendix A UC-06. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Gói thành viên & quota được cập nhật và có thể truy vết tới BD M06 quota, AC-04/AC-05. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Free mở MEMBERSHIP_QUOTA-V02 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=membership_product; Name=Membership Product; Purpose=Cấu hình gói; Attributes=plan code, price, quota, version, effective time; Relationships=Creates entitlement}, @{Id=membership_entitlement; Name=Membership Entitlement; Purpose=Quyền gói; Attributes=user, plan, start/end, source payment; Relationships=Used by gates}, @{Id=usage_quota_ledger; Name=Usage Quota Ledger; Purpose=Lịch sử quota; Attributes=quota type, period, request id, status; Relationships=Used by AI and schedule}.
4. Actor thực hiện hành động: AI Chat hoặc tạo lịch trình.
5. MEMBERSHIP_QUOTA-FN02 kiểm tra MEMBERSHIP_QUOTA-BR02 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| MEMBERSHIP_QUOTA-F02-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | MEMBERSHIP_QUOTA-TC02 |
| MEMBERSHIP_QUOTA-F02-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | MEMBERSHIP_QUOTA-TC02 |
| MEMBERSHIP_QUOTA-F02-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | MEMBERSHIP_QUOTA-TC02 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| MEMBERSHIP_QUOTA-BR02 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | MEMBERSHIP_QUOTA-E-main | Dữ liệu nghiệp vụ chính của Gói thành viên & quota | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | MEMBERSHIP_QUOTA-API02 | Contract dự kiến cho MEMBERSHIP_QUOTA-FN02 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD M06 quota, AC-04/AC-05, feature tạo đúng outcome: Chặn vượt quota và không trừ sai khi dependency lỗi..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] MEMBERSHIP_QUOTA-V02 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
