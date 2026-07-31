# List Features — PAYMENT_MEMBERSHIP / Thanh toán, xác minh và quyền gói

## 0. Document Information

| Field | Value |
|---|---|
| Module | PAYMENT_MEMBERSHIP |
| Overall | [Overall.md](Overall.md) |
| Version | v1.3 |
| Last Updated | 2026-07-31 |
| Source | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 8/M13, 14.4, 15, 16.1 AC-07/AC-08, 16.3 AC-20/AC-21, Appendix A UC-15/UC-16 |

## 1. Feature Inventory

| ID | Feature | Goal | Actor | Trigger | Priority | Source | Functions | Views | Status |
|---|---|---|---|---|---|---|---|---|---|
| PAYMENT_MEMBERSHIP-F01 | VietQR mua/gia hạn gói | Member tạo yêu cầu VietQR, chuyển tiền và xác nhận để chờ duyệt. | Member | Chọn mua/gia hạn gói | P0 | BD sections 8.2, UC-15 | PAYMENT_MEMBERSHIP-FN01, PAYMENT_MEMBERSHIP-FN03 | PAYMENT_MEMBERSHIP-V01 | Implemented - VietQR manual review |
| PAYMENT_MEMBERSHIP-F02 | Admin duyệt/từ chối payment | Admin đối chiếu VCB rồi kích hoạt quyền hoặc từ chối có lý do/audit. | Admin with payments.write | Banner/hàng chờ thanh toán | P0 | BD sections 8.4, AC-07/AC-08/AC-20/AC-21, UC-16 | PAYMENT_MEMBERSHIP-FN02 | PAYMENT_MEMBERSHIP-V02 | Implemented - VietQR manual review |

## 2. Dependencies Between Features

| Source Feature | Relationship | Target Feature | Data / State Passed | Condition |
|---|---|---|---|---|
| PAYMENT_MEMBERSHIP-F01 | prerequisite / trigger | Next feature in this module | Module state and actor context | Previous feature succeeds and business rules pass |
| Cross-module | dependency | Related module DD | Entitlement, ownership, audit, or event state | Dependency module is available and accepted decision/evidence gates are satisfied |

---

<a id="payment_membership-f01"></a>
# PAYMENT_MEMBERSHIP-F01 — Tạo thanh toán mua/gia hạn gói

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Member tạo yêu cầu VietQR có mã đối soát, chuyển tiền rồi xác nhận để chờ duyệt. |
| Actor chính | Member |
| Actor phụ / hệ thống | Membership product |
| Trigger | Chọn mua/gia hạn gói |
| Phạm vi | Create/recover awaiting_transfer, render QR, copy memo, and confirm transfer. |
| Không thuộc feature | Receipt upload, bank API, webhook, automatic reconciliation, or bank-balance display. |
| Requirement nguồn | BD sections 8.2, UC-15 |
| Rule áp dụng | PAYMENT_MEMBERSHIP-BR01, PAYMENT_MEMBERSHIP-BR03, PAYMENT_MEMBERSHIP-BR04 |
| View liên quan | PAYMENT_MEMBERSHIP-V01 |
| Function liên quan | PAYMENT_MEMBERSHIP-FN01 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 8/M13, 14.4, 15, 16.1 AC-07/AC-08, 16.3 AC-20/AC-21, Appendix A UC-15/UC-16. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Thanh toán, xác minh và quyền gói được cập nhật và có thể truy vết tới BD sections 8.2, UC-15. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Member mở PAYMENT_MEMBERSHIP-V01 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=payment_transaction; Name=Payment Transaction; Purpose=Giao dịch gói; Attributes=user, plan, amount, status, transaction reference; Relationships=Source for entitlement and commission}, @{Id=payment_approval; Name=Payment Approval; Purpose=Lịch sử duyệt payment; Attributes=payment, admin, decision, reason, time; Relationships=Audit and entitlement source}, @{Id=membership_entitlement; Name=Membership Entitlement; Purpose=Quyền gói; Attributes=plan, start/end, source payment; Relationships=Used by access gates}.
4. Ứng dụng lấy full_name từ SQLite theo đúng Supabase user ID; thiếu tên thì chặn tạo QR.
5. Actor chọn gói/chu kỳ. PAYMENT_MEMBERSHIP-FN01 tạo hoặc trả lại yêu cầu awaiting_transfer cùng mã NB, memo, giá và cấu hình Vietcombank do server quyết định.
6. UI hiển thị QR, số tiền, mã/nội dung chuyển khoản; khách chuyển tiền rồi bấm “Đã chuyển khoản”.
7. PAYMENT_MEMBERSHIP-FN03 chuyển yêu cầu của chính khách sang pending_review; UI hiển thị đang chờ duyệt và không làm mới quyền.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| PAYMENT_MEMBERSHIP-F01-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | PAYMENT_MEMBERSHIP-TC01 |
| PAYMENT_MEMBERSHIP-F01-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | PAYMENT_MEMBERSHIP-TC01 |
| PAYMENT_MEMBERSHIP-F01-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | PAYMENT_MEMBERSHIP-TC01 |
| PAYMENT_MEMBERSHIP-F01-ALT02 | SQLite thiếu full_name | Không gọi tạo yêu cầu | Không ghi | Hướng dẫn cập nhật hồ sơ | PAYMENT_MEMBERSHIP-TC01 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| PAYMENT_MEMBERSHIP-BR01/BR03/BR04 | Áp dụng rule module đã định nghĩa trong Overall.md; QR/display chỉ dùng dữ liệu backend trả về. | 5-7 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | PAYMENT_MEMBERSHIP-E-main | Dữ liệu nghiệp vụ chính của Thanh toán, xác minh và quyền gói | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | PAYMENT_MEMBERSHIP-API01 | Contract dự kiến cho PAYMENT_MEMBERSHIP-FN01 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Documented Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| PAYMENT_MEMBERSHIP-AC01-01 | Với source BD sections 8.2, UC-15, feature tạo đúng outcome: QR VietQR, mã đối soát bất biến và xác nhận chờ duyệt không cấp quyền. | Documented | Implemented; sandbox/UAT bank scan remains required |
| PAYMENT_MEMBERSHIP-AC01-02 | Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| PAYMENT_MEMBERSHIP-AC01-03 | Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| PAYMENT_MEMBERSHIP-AC01-04 | PAYMENT_MEMBERSHIP-V01 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied. | Documented | Required in implementation/test phase; not executed in this DD docs pass |

---

<a id="payment_membership-f02"></a>
# PAYMENT_MEMBERSHIP-F02 — Admin duyệt/từ chối payment

## A. Mục đích và phạm vi

| Hạng mục | Nội dung |
|---|---|
| Mục tiêu nghiệp vụ | Admin tự đối chiếu VCB rồi kích hoạt quyền hoặc từ chối payment có lý do/audit. |
| Actor chính | Admin with payments.write |
| Actor phụ / hệ thống | Entitlement and Sale points |
| Trigger | Banner hoặc hàng chờ yêu cầu pending_review |
| Phạm vi | Approval/rejection after manual VCB reconciliation; legacy pending remains reviewable. |
| Không thuộc feature | Payout Sale, bank API, balance display, webhook, or automatic approval. |
| Requirement nguồn | BD sections 8.4, AC-07/AC-08/AC-20/AC-21, UC-16 |
| Rule áp dụng | PAYMENT_MEMBERSHIP-BR02, PAYMENT_MEMBERSHIP-BR05 |
| View liên quan | PAYMENT_MEMBERSHIP-V02 |
| Function liên quan | PAYMENT_MEMBERSHIP-FN02 |

## B. Điều kiện

| Loại | Nội dung |
|---|---|
| Tiền điều kiện | Actor có trạng thái và quyền phù hợp theo BD sections 3, 5 và module source BD sections 8/M13, 14.4, 15, 16.1 AC-07/AC-08, 16.3 AC-20/AC-21, Appendix A UC-15/UC-16. |
| Hậu điều kiện thành công | Dữ liệu/trạng thái của Thanh toán, xác minh và quyền gói được cập nhật và có thể truy vết tới BD sections 8.4, AC-07/AC-08/AC-20/AC-21, UC-16. |
| Hậu điều kiện thất bại | Không ghi dữ liệu một phần; trả thông báo nghiệp vụ an toàn và ghi audit khi tác động quyền, tiền, điểm, dữ liệu gia đình hoặc cấu hình. |
| Idempotency | Mọi thao tác tạo/sửa trạng thái quan trọng dùng request/correlation id hoặc khóa nghiệp vụ theo BD sections 14.4 và 15. |

## C. Luồng chính

1. Admin mở PAYMENT_MEMBERSHIP-V02 hoặc entry point liên quan.
2. Hệ thống xác thực trạng thái đăng nhập/gói/vai trò theo quyền hiệu lực.
3. Hệ thống tải dữ liệu nguồn của module: @{Id=payment_transaction; Name=Payment Transaction; Purpose=Giao dịch gói; Attributes=user, plan, amount, status, transaction reference; Relationships=Source for entitlement and commission}, @{Id=payment_approval; Name=Payment Approval; Purpose=Lịch sử duyệt payment; Attributes=payment, admin, decision, reason, time; Relationships=Audit and entitlement source}, @{Id=membership_entitlement; Name=Membership Entitlement; Purpose=Quyền gói; Attributes=plan, start/end, source payment; Relationships=Used by access gates}.
4. Banner chỉ đếm pending_review, làm mới mỗi 30 giây, khi ứng dụng resume và khi Admin bấm làm mới.
5. Admin mở hàng chờ, kiểm tra mã, số tiền, memo và thời điểm khách xác nhận trong ứng dụng VCB.
6. PAYMENT_MEMBERSHIP-FN02 kiểm tra PAYMENT_MEMBERSHIP-BR02/BR05, duyệt hoặc từ chối có lý do/audit.
7. UI/API hiển thị kết quả, không lộ dữ liệu kỹ thuật hoặc dữ liệu nhạy cảm.

## D. Luồng thay thế và lỗi

| Mã luồng | Điều kiện | Hệ thống xử lý | Dữ liệu thay đổi | UI/API trả về | Test bắt buộc |
|---|---|---|---|---|---|
| PAYMENT_MEMBERSHIP-F02-ALT01 | Dữ liệu chưa đủ hoặc chưa đến trạng thái cho phép | Giữ trạng thái hiện tại và hướng dẫn bước cần làm tiếp | Không ghi thay đổi chính | Thông báo nghiệp vụ an toàn | PAYMENT_MEMBERSHIP-TC02 |
| PAYMENT_MEMBERSHIP-F02-ERR01 | Không đủ quyền hoặc sai phạm vi dữ liệu | Chặn ở route/use-case/API và ghi audit nếu là quyền nhạy cảm | Không ghi | Permission denied theo Nabitone | PAYMENT_MEMBERSHIP-TC02 |
| PAYMENT_MEMBERSHIP-F02-ERR02 | Dependency lỗi hoặc thao tác bị retry | Xử lý idempotent, không nhân đôi side effect | Không ghi trùng | Cho retry hoặc báo đang xử lý | PAYMENT_MEMBERSHIP-TC02 |

## E. Quy tắc nghiệp vụ áp dụng

| Rule ID | Cách feature áp dụng | Bước kiểm tra | Message/mã lỗi |
|---|---|---:|---|
| PAYMENT_MEMBERSHIP-BR02/BR05 | Áp dụng rule module đã định nghĩa trong Overall.md; chỉ Admin quyết định duyệt mới kích hoạt quyền. | 5-6 | BUSINESS_RULE_BLOCKED |

## F. Dữ liệu, API và event

| Loại | ID / tên | Vai trò trong feature | Đọc / Ghi | Ghi chú |
|---|---|---|---|---|
| Entity | PAYMENT_MEMBERSHIP-E-main | Dữ liệu nghiệp vụ chính của Thanh toán, xác minh và quyền gói | Read/Write theo feature | Planned logical entity, schema vật lý cần DD/Supabase riêng khi có coding. |
| API/Event | PAYMENT_MEMBERSHIP-API02 | Contract dự kiến cho PAYMENT_MEMBERSHIP-FN02 | Expose/Consume | Request/response phải được chốt trước implementation. |

## G. Documented Acceptance Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| PAYMENT_MEMBERSHIP-AC02-01 | Với source BD sections 8.4, AC-07/AC-08/AC-20/AC-21, UC-16, Admin đối chiếu VCB trước khi duyệt/từ chối có lý do/audit. | Documented | Implemented; sandbox/UAT bank reconciliation remains required |
| PAYMENT_MEMBERSHIP-AC02-02 | Khi quyền không hợp lệ, hệ thống chặn ở UI/route/use-case/API, không chỉ ẩn nút. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| PAYMENT_MEMBERSHIP-AC02-03 | Khi retry hoặc double click, không tạo dữ liệu/điểm/quyền trùng. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| PAYMENT_MEMBERSHIP-AC02-04 | PAYMENT_MEMBERSHIP-V02 có đủ Loading, Empty, Success, Business Error, System Error và Permission Denied. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
