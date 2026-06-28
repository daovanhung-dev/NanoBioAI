# List Features — REFERRAL_DIRECT / Sale & mã giới thiệu trực tiếp

## 0. Document Information

| Field | Value |
|---|---|
| Module | REFERRAL_DIRECT |
| Overall | [Overall.md](Overall.md) |
| Version | v1.0 |
| Last Updated | 2026-06-28 |
| Source | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 7/M12, 15, 16.2 AC-09/AC-10/AC-14, Appendix A UC-12..UC-14 |

## 1. Feature Inventory

| ID | Feature | Goal | Actor | Trigger | Priority | Source | Functions | Views | Status |
|---|---|---|---|---|---|---|---|---|---|
| REFERRAL_DIRECT-F01 | Đăng ký và duyệt Sale | Member đủ điều kiện trở thành Sale active sau Admin duyệt. | Member, Admin | Member gửi yêu cầu Sale | P0 | BD sections 7.2, AC-09, UC-12/UC-13 | REFERRAL_DIRECT-FN01 | REFERRAL_DIRECT-V01 | Draft |
| REFERRAL_DIRECT-F02 | Gắn mã giới thiệu trực tiếp | Tạo đúng một quan hệ Sale -> khách hợp lệ. | Guest, Member | Nhập mã giới thiệu | P0 | BD sections 7.3/7.4, AC-10/AC-14, UC-14 | REFERRAL_DIRECT-FN02 | REFERRAL_DIRECT-V02 | Draft |

## 2. Dependencies Between Features

| Source Feature | Relationship | Target Feature | Data / State Passed | Condition |
|---|---|---|---|---|
| REFERRAL_DIRECT-F01 | prerequisite / trigger | Next feature in this module | Module state and actor context | Previous feature succeeds and business rules pass |
| Cross-module | dependency | Related module DD | Entitlement, ownership, audit, or event state | Dependency module is available and not blocked by open questions |

---

<a id="referral_direct-f01"></a>
# REFERRAL_DIRECT-F01 — Đăng ký và duyệt Sale

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Member đủ điều kiện trở thành Sale active sau Admin duyệt. |
| Actor chính | Member, Admin |
| Actor phụ / hệ thống | Admin operations |
| Trigger | Member gửi yêu cầu Sale |
| Phạm vi | pending_review -> active/rejected. |
| Không thuộc feature | Auto activate without PO rule. |
| Requirement nguồn | BD sections 7.2, AC-09, UC-12/UC-13 |
| Rule áp dụng | REFERRAL_DIRECT-BR01 |
| View liên quan | REFERRAL_DIRECT-V01 |
| Function liên quan | REFERRAL_DIRECT-FN01 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 7/M12, 15, 16.2 AC-09/AC-10/AC-14, Appendix A UC-12..UC-14. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Sale & mã giới thiệu trực tiếp được cập nhật và có thể truy vết tới BD sections 7.2, AC-09, UC-12/UC-13. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Member, Admin mở REFERRAL_DIRECT-V01 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=sale_profile; Name=Sale Profile; Purpose=Quyền Sale; Attributes=status, code, activated_at, suspended_at; Relationships=Owns referral code}, @{Id=referral_relationship; Name=Referral Relationship; Purpose=Quan hệ Sale -> khách trực tiếp; Attributes=sale_id, customer_id, referral_code, locked_at, status; Relationships=Source for Sale points}.
4. Actor thực hiện hành động: Member gửi yêu cầu Sale.
5. REFERRAL_DIRECT-FN01 kiểm tra REFERRAL_DIRECT-BR01 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| REFERRAL_DIRECT-F01-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | REFERRAL_DIRECT-TC01 |
| REFERRAL_DIRECT-F01-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | REFERRAL_DIRECT-TC01 |
| REFERRAL_DIRECT-F01-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | REFERRAL_DIRECT-TC01 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| REFERRAL_DIRECT-BR01 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | REFERRAL_DIRECT-E-main | Dữ liệu nghiệp vụ chính của Sale & mã giới thiệu trực tiếp | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | REFERRAL_DIRECT-API01 | Contract dự kiến cho REFERRAL_DIRECT-FN01 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD sections 7.2, AC-09, UC-12/UC-13, feature tạo đúng outcome: Member đủ điều kiện trở thành Sale active sau Admin duyệt..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] REFERRAL_DIRECT-V01 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
---

<a id="referral_direct-f02"></a>
# REFERRAL_DIRECT-F02 — Gắn mã giới thiệu trực tiếp

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Tạo đúng một quan hệ Sale -> khách hợp lệ. |
| Actor chính | Guest, Member |
| Actor phụ / hệ thống | Sale profile, anti-fraud |
| Trigger | Nhập mã giới thiệu |
| Phạm vi | Validate code, self-referral, previous payment, duplicate. |
| Không thuộc feature | Indirect referral. |
| Requirement nguồn | BD sections 7.3/7.4, AC-10/AC-14, UC-14 |
| Rule áp dụng | REFERRAL_DIRECT-BR02 |
| View liên quan | REFERRAL_DIRECT-V02 |
| Function liên quan | REFERRAL_DIRECT-FN02 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 7/M12, 15, 16.2 AC-09/AC-10/AC-14, Appendix A UC-12..UC-14. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Sale & mã giới thiệu trực tiếp được cập nhật và có thể truy vết tới BD sections 7.3/7.4, AC-10/AC-14, UC-14. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Guest, Member mở REFERRAL_DIRECT-V02 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=sale_profile; Name=Sale Profile; Purpose=Quyền Sale; Attributes=status, code, activated_at, suspended_at; Relationships=Owns referral code}, @{Id=referral_relationship; Name=Referral Relationship; Purpose=Quan hệ Sale -> khách trực tiếp; Attributes=sale_id, customer_id, referral_code, locked_at, status; Relationships=Source for Sale points}.
4. Actor thực hiện hành động: Nhập mã giới thiệu.
5. REFERRAL_DIRECT-FN02 kiểm tra REFERRAL_DIRECT-BR02 và các rule bảo mật/audit liên quan.
6. Hệ thống lưu hoặc trả kết quả theo trạng thái hợp lệ.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| REFERRAL_DIRECT-F02-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | REFERRAL_DIRECT-TC02 |
| REFERRAL_DIRECT-F02-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | REFERRAL_DIRECT-TC02 |
| REFERRAL_DIRECT-F02-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | REFERRAL_DIRECT-TC02 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| REFERRAL_DIRECT-BR02 | Áp dụng rule module đã định nghĩa trong Overall.md, không định nghĩa lại ở UI. | 5 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | REFERRAL_DIRECT-E-main | Dữ liệu nghiệp vụ chính của Sale & mã giới thiệu trực tiếp | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | REFERRAL_DIRECT-API02 | Contract dự kiến cho REFERRAL_DIRECT-FN02 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Tiêu chí chấp nhận

- [ ] Với source BD sections 7.3/7.4, AC-10/AC-14, UC-14, feature tạo đúng outcome: Tạo đúng một quan hệ Sale -> khách hợp lệ..
- [ ] Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút.
- [ ] Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng.
- [ ] REFERRAL_DIRECT-V02 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied.
