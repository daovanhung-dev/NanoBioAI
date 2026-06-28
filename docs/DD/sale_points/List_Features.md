# List Features — SALE_POINTS / Điểm Sale & quy đổi

## 0. Document Information

| Field | Value |
|---|---|
| Module | SALE_POINTS |
| Overall | [Overall.md](Overall.md) |
| Version | v1.0 |
| Last Updated | 2026-06-28 |
| Source | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 7.5..7.10, 9, 12.1, 14.4, 16.2 AC-11..AC-18, Appendix A UC-17..UC-19 |

## 1. Feature Inventory

| ID | Feature | Goal | Actor | Trigger | Priority | Source | Functions | Views | Status |
|---|---|---|---|---|---|---|---|---|---|
| SALE_POINTS-F01 | Cộng Điểm Sale sau payment approved | Sale nhận 10% từ payment hợp lệ của khách trực tiếp. | System | payment_approved event | P0 | BD sections 7.5/7.6/12.1, AC-11..AC-16, UC-17 | SALE_POINTS-FN01 | SALE_POINTS-V01 | Draft |
| SALE_POINTS-F02 | Quy đổi Điểm Sale | Sale yêu cầu đổi điểm và Admin xử lý có giữ/trừ điểm đúng một lần. | Sale, Admin | Sale submits conversion request | P0 | BD section 7.10, AC-17/AC-18, UC-18/UC-19 | SALE_POINTS-FN02 | SALE_POINTS-V02 | Draft |

## 2. Dependencies Between Features

| Source Feature | Relationship | Target Feature | Data / State Passed | Condition |
|---|---|---|---|---|
| SALE_POINTS-F01 | prerequisite / trigger | Next feature in this module | Module state and actor context | Previous feature succeeds and business rules pass |
| Cross-module | dependency | Related module DD | Entitlement, ownership, audit, or event state | Dependency module is available and not blocked by open questions |

---

<a id="sale_points-f01"></a>
# SALE_POINTS-F01 — Cộng Điểm Sale sau payment approved

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Sale nhận 10% từ payment hợp lệ của khách trực tiếp. |
| Actor chính | System |
| Actor phụ / hệ thống | Payment, Referral |
| Trigger | payment_approved event |
| Phạm vi | Find relationship, compute, create ledger, update balance. |
| Không thuộc feature | Tier 2/5% or indirect tree. |
| Requirement nguồn | BD sections 7.5/7.6/12.1, AC-11..AC-16, UC-17 |
| Rule áp dụng | SALE_POINTS-BR01 |
| View liên quan | SALE_POINTS-V01 |
| Function liên quan | SALE_POINTS-FN01 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 7.5..7.10, 9, 12.1, 14.4, 16.2 AC-11..AC-18, Appendix A UC-17..UC-19. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Điểm Sale & quy đổi được cập nhật và có thể truy vết tới BD sections 7.5/7.6/12.1, AC-11..AC-16, UC-17. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. System mở SALE_POINTS-V01 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=sale_commission_ledger; Name=Sale Commission Ledger; Purpose=Ledger hoa hồng/Điểm Sale; Attributes=payment, sale, rate 10%, base amount, points, status; Relationships=Unique per payment}, @{Id=sale_point_balance; Name=Sale Point Balance; Purpose=Số dư tính toán; Attributes=available, held, converted, reversed; Relationships=Derived from ledger}, @{Id=sale_point_conversion; Name=Sale Point Conversion; Purpose=Yêu cầu đổi điểm; Attributes=sale, points, rate, money, status, payout info; Relationships=Reviewed by Admin}.
4. Actor thực hiện hành động: payment_approved event.
5. SALE_POINTS-FN01 kiểm tra SALE_POINTS-BR01 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| SALE_POINTS-F01-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | SALE_POINTS-TC01 |
| SALE_POINTS-F01-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | SALE_POINTS-TC01 |
| SALE_POINTS-F01-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | SALE_POINTS-TC01 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| SALE_POINTS-BR01 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | SALE_POINTS-E-main | Dữ liệu nghiệp vụ chính của Điểm Sale & quy đổi | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | SALE_POINTS-API01 | Contract dự kiến cho SALE_POINTS-FN01 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD sections 7.5/7.6/12.1, AC-11..AC-16, UC-17, feature tạo đúng outcome: Sale nhận 10% từ payment hợp lệ của khách trực tiếp..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] SALE_POINTS-V01 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
---

<a id="sale_points-f02"></a>
# SALE_POINTS-F02 — Quy đổi Điểm Sale

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Sale yêu cầu đổi điểm và Admin xử lý có giữ/trừ điểm đúng một lần. |
| Actor chính | Sale, Admin |
| Actor phụ / hệ thống | Audit, payout operations |
| Trigger | Sale submits conversion request |
| Phạm vi | Hold points, approve/reject/paid. |
| Không thuộc feature | Final tax/payout method. |
| Requirement nguồn | BD section 7.10, AC-17/AC-18, UC-18/UC-19 |
| Rule áp dụng | SALE_POINTS-BR02 |
| View liên quan | SALE_POINTS-V02 |
| Function liên quan | SALE_POINTS-FN02 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 7.5..7.10, 9, 12.1, 14.4, 16.2 AC-11..AC-18, Appendix A UC-17..UC-19. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Điểm Sale & quy đổi được cập nhật và có thể truy vết tới BD section 7.10, AC-17/AC-18, UC-18/UC-19. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Sale, Admin mở SALE_POINTS-V02 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=sale_commission_ledger; Name=Sale Commission Ledger; Purpose=Ledger hoa hồng/Điểm Sale; Attributes=payment, sale, rate 10%, base amount, points, status; Relationships=Unique per payment}, @{Id=sale_point_balance; Name=Sale Point Balance; Purpose=Số dư tính toán; Attributes=available, held, converted, reversed; Relationships=Derived from ledger}, @{Id=sale_point_conversion; Name=Sale Point Conversion; Purpose=Yêu cầu đổi điểm; Attributes=sale, points, rate, money, status, payout info; Relationships=Reviewed by Admin}.
4. Actor thực hiện hành động: Sale submits conversion request.
5. SALE_POINTS-FN02 kiểm tra SALE_POINTS-BR02 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| SALE_POINTS-F02-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | SALE_POINTS-TC02 |
| SALE_POINTS-F02-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | SALE_POINTS-TC02 |
| SALE_POINTS-F02-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | SALE_POINTS-TC02 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| SALE_POINTS-BR02 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | SALE_POINTS-E-main | Dữ liệu nghiệp vụ chính của Điểm Sale & quy đổi | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | SALE_POINTS-API02 | Contract dự kiến cho SALE_POINTS-FN02 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD section 7.10, AC-17/AC-18, UC-18/UC-19, feature tạo đúng outcome: Sale yêu cầu đổi điểm và Admin xử lý có giữ/trừ điểm đúng một lần..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] SALE_POINTS-V02 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
