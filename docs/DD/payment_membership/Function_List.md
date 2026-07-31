# Function List — PAYMENT_MEMBERSHIP / Thanh toán, xác minh và quyền gói

## 0. Layer Convention

`	ext
View / Presentation
  -> Provider / Controller / API handler
  -> Use case / Service
  -> Repository
  -> Datasource / DAO / API client
  -> Database / External service
`

- Presentation must not call DAO/API/database directly.
- Business rules stay in use case/service or trusted backend policy.
- Financial, quota, family, Sale, and Admin writes require idempotency and audit.

## 1. Function Registry

| ID | Function / Use Case | Feature | Layer | Planned File | Trigger | Input | Output | Side Effect | Status |
|---|---|---|---|---|---|---|---|---|---|
| PAYMENT_MEMBERSHIP-FN01 | createMembershipPayment | PAYMENT_MEMBERSHIP-F01 | Use case / Service | lib/app_versions/v2/features/payments | Chọn gói/chu kỳ và yêu cầu thanh toán | plan, cycle, idempotency key, tên hiển thị SQLite | Mã NB, memo, số tiền, cấu hình nhận tiền | Tạo hoặc trả lại yêu cầu awaiting_transfer, không cấp quyền | Implemented - VietQR manual review |
| PAYMENT_MEMBERSHIP-FN03 | confirmMembershipTransfer | PAYMENT_MEMBERSHIP-F01 | Use case / Service | lib/app_versions/v2/features/payments | Khách bấm “Đã chuyển khoản” | payment event ID của chính khách | Yêu cầu pending_review | Lưu thời điểm xác nhận, không cấp quyền | Implemented - VietQR manual review |
| PAYMENT_MEMBERSHIP-FN02 | reviewMembershipPayment | PAYMENT_MEMBERSHIP-F02 | Use case / Service | lib/app_versions/admin/features/admin_panel | Admin đối chiếu VCB và duyệt/từ chối | payment ID, quyết định, lý do khi từ chối | succeeded hoặc failed | Audit; chỉ succeeded kích hoạt quyền | Implemented - VietQR manual review |

---

<a id="payment_membership-fn01"></a>
# PAYMENT_MEMBERSHIP-FN01 — createMembershipPayment

## A. Định danh và trách nhiệm

| Trường | Nội dung |
|---|---|
| Feature cha | PAYMENT_MEMBERSHIP-F01 |
| Layer | Use case / Service, called by controller/provider/API handler |
| Loại thực thi | Sync for validation and state read; async/job only when BD requires background processing |
| File dự kiến | planned:lib/app_versions/v2/features/payments/application/payment_membership_fn01.dart |
| Hàm export / endpoint | execute(command, actorContext) hoặc API contract tương ứng |
| Mục tiêu duy nhất | Member tạo hoặc khôi phục yêu cầu awaiting_transfer có mã đối soát và dữ liệu QR an toàn. |
| Không chịu trách nhiệm | Không tự chốt product questions; không truy cập trực tiếp UI hoặc storage ngoài layer được phép. |
| Được gọi bởi | PAYMENT_MEMBERSHIP-V01 hoặc event/API source trong BD sections 8.2, UC-15 |
| Gọi tiếp | Repository/datasource/service planned trong Import_File.md |
| Rule áp dụng | PAYMENT_MEMBERSHIP-BR01, PAYMENT_MEMBERSHIP-BR03 |

## B. Hợp đồng input/output

| Field | Type | Required | Validation | Nguồn | Nhạy cảm | Ví dụ |
|---|---|---:|---|---|---:|---|
| actor_id | UUID/string | Y | Actor phải có quyền theo BD sections 3 và 5 | Auth/session context | Y | current user/admin |
| command | Object | Y | Schema theo feature và business rule | UI/API/event | Depends | module-specific request |
| correlation_id | String | Y for writes | Unique per request/job | UI/API/job | N | retry-safe key |

| Tình huống | Kiểu output / HTTP | Nội dung | Consumer xử lý |
|---|---|---|---|
| Thành công | Result / 200 hoặc 201 | Entity/view model cập nhật | Refresh UI hoặc phát event sau commit |
| Validation lỗi | Error / 400 | Field or business validation code | Hiển thị lỗi an toàn |
| Không quyền | 401/403 | AUTH_REQUIRED hoặc FORBIDDEN | Redirect/hide action and log when needed |
| Conflict | 409 | DUPLICATE_OR_INVALID_STATE | Refresh state and prevent double write |
| Lỗi hệ thống | 500/503 | Safe error + correlation id | Retry/support flow |

## C. Luồng xử lý chi tiết

1. Parse command và kiểm tra schema.
2. Xác thực actor, role, package entitlement, Sale/Admin scope nếu có.
3. Tải entity liên quan: @{Id=payment_transaction; Name=Payment Transaction; Purpose=Giao dịch gói; Attributes=user, plan, amount, status, transaction reference; Relationships=Source for entitlement and commission}, @{Id=payment_approval; Name=Payment Approval; Purpose=Lịch sử duyệt payment; Attributes=payment, admin, decision, reason, time; Relationships=Audit and entitlement source}, @{Id=membership_entitlement; Name=Membership Entitlement; Purpose=Quyền gói; Attributes=plan, start/end, source payment; Relationships=Used by access gates}.
4. Áp dụng PAYMENT_MEMBERSHIP-BR01 và các rule cross-module từ BD sections 14, 15.
5. Thực thi transaction/idempotency: Yes - write operations that affect quyền, tiền, điểm, quota, family scope, or audit must commit atomically.
6. Ghi audit nếu có tác động quyền, tiền, điểm, cấu hình, dữ liệu gia đình hoặc export.
7. Trả Result chuẩn hóa, không trả raw stack trace, raw payment evidence, secret, hoặc health PII không cần thiết.

### VietQR-specific contract

- Backend dùng auth.uid() làm người thanh toán và tự tính số tiền theo gói/chu kỳ; client không thể ghi đè giá, tài khoản nhận hoặc mã giao dịch.
- Backend sinh mã duy nhất NB + 12 ký tự hex, snapshot memo và thông tin nhận tiền: Vietcombank, BIN 970436, tài khoản 1026806174, tên QR LE PHU THACH.
- Tên từ SQLite chỉ dùng để tạo phần tên của memo; thiếu tên thì UI không gọi tạo yêu cầu.
- Retry cùng idempotency key trả lại cùng yêu cầu/mã, không tạo giao dịch hoặc quyền trùng.

## D. Transaction, side effect và độ tin cậy

| Nội dung | Quy định |
|---|---|
| Transaction boundary | Yes - write operations that affect quyền, tiền, điểm, quota, family scope, or audit must commit atomically. |
| Event/outbox | Phát event sau commit khi feature tạo quyền, quota, notification, point, report hoặc audit. |
| Retry | Retry theo correlation_id/request_id; retry không tạo bản ghi trùng. |
| Fallback / compensation | Khi dependency lỗi, giữ trạng thái hiện tại hoặc tạo adjustment/reversal theo BD nếu tài chính đã chốt. |
| Observability | Log an toàn gồm module, function ID, actor type, status, correlation id; không log secret/PII/raw payment. |

## E. Documented Function Test Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| PAYMENT_MEMBERSHIP-FN-EV01-01 | Happy path cho PAYMENT_MEMBERSHIP-FN01. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| PAYMENT_MEMBERSHIP-FN-EV01-02 | Business rule violation cho PAYMENT_MEMBERSHIP-BR01. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| PAYMENT_MEMBERSHIP-FN-EV01-03 | Permission denied theo role/scope. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| PAYMENT_MEMBERSHIP-FN-EV01-04 | Idempotency/retry nếu có ghi dữ liệu. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| PAYMENT_MEMBERSHIP-FN-EV01-05 | Audit hoặc event được tạo khi BD yêu cầu. | Documented | Required in implementation/test phase; not executed in this DD docs pass |

---

<a id="payment_membership-fn02"></a>
# PAYMENT_MEMBERSHIP-FN02 — reviewMembershipPayment

## A. Định danh và trách nhiệm

| Trường | Nội dung |
|---|---|
| Feature cha | PAYMENT_MEMBERSHIP-F02 |
| Layer | Use case / Service, called by controller/provider/API handler |
| Loại thực thi | Sync for validation and state read; async/job only when BD requires background processing |
| File dự kiến | planned:lib/app_versions/v2/features/payments/application/payment_membership_fn02.dart |
| Hàm export / endpoint | execute(command, actorContext) hoặc API contract tương ứng |
| Mục tiêu duy nhất | Sau khi tự đối chiếu VCB, kích hoạt quyền hoặc từ chối payment có lý do/audit. |
| Không chịu trách nhiệm | Không tự chốt product questions; không truy cập trực tiếp UI hoặc storage ngoài layer được phép. |
| Được gọi bởi | PAYMENT_MEMBERSHIP-V02 hoặc event/API source trong BD sections 8.4, AC-07/AC-08/AC-20/AC-21, UC-16 |
| Gọi tiếp | Repository/datasource/service planned trong Import_File.md |
| Rule áp dụng | PAYMENT_MEMBERSHIP-BR02, PAYMENT_MEMBERSHIP-BR05 |

## B. Hợp đồng input/output

| Field | Type | Required | Validation | Nguồn | Nhạy cảm | Ví dụ |
|---|---|---:|---|---|---:|---|
| actor_id | UUID/string | Y | Actor phải có quyền theo BD sections 3 và 5 | Auth/session context | Y | current user/admin |
| command | Object | Y | Schema theo feature và business rule | UI/API/event | Depends | module-specific request |
| correlation_id | String | Y for writes | Unique per request/job | UI/API/job | N | retry-safe key |

| Tình huống | Kiểu output / HTTP | Nội dung | Consumer xử lý |
|---|---|---|---|
| Thành công | Result / 200 hoặc 201 | Entity/view model cập nhật | Refresh UI hoặc phát event sau commit |
| Validation lỗi | Error / 400 | Field or business validation code | Hiển thị lỗi an toàn |
| Không quyền | 401/403 | AUTH_REQUIRED hoặc FORBIDDEN | Redirect/hide action and log when needed |
| Conflict | 409 | DUPLICATE_OR_INVALID_STATE | Refresh state and prevent double write |
| Lỗi hệ thống | 500/503 | Safe error + correlation id | Retry/support flow |

## C. Luồng xử lý chi tiết

1. Parse command và kiểm tra schema.
2. Xác thực actor, role, package entitlement, Sale/Admin scope nếu có.
3. Tải entity liên quan: @{Id=payment_transaction; Name=Payment Transaction; Purpose=Giao dịch gói; Attributes=user, plan, amount, status, transaction reference; Relationships=Source for entitlement and commission}, @{Id=payment_approval; Name=Payment Approval; Purpose=Lịch sử duyệt payment; Attributes=payment, admin, decision, reason, time; Relationships=Audit and entitlement source}, @{Id=membership_entitlement; Name=Membership Entitlement; Purpose=Quyền gói; Attributes=plan, start/end, source payment; Relationships=Used by access gates}.
4. Áp dụng PAYMENT_MEMBERSHIP-BR02 và các rule cross-module từ BD sections 14, 15.
5. Thực thi transaction/idempotency: Yes - write operations that affect quyền, tiền, điểm, quota, family scope, or audit must commit atomically.
6. Ghi audit nếu có tác động quyền, tiền, điểm, cấu hình, dữ liệu gia đình hoặc export.
7. Trả Result chuẩn hóa, không trả raw stack trace, raw payment evidence, secret, hoặc health PII không cần thiết.

## D. Transaction, side effect và độ tin cậy

| Nội dung | Quy định |
|---|---|
| Transaction boundary | Yes - write operations that affect quyền, tiền, điểm, quota, family scope, or audit must commit atomically. |
| Event/outbox | Phát event sau commit khi feature tạo quyền, quota, notification, point, report hoặc audit. |
| Retry | Retry theo correlation_id/request_id; retry không tạo bản ghi trùng. |
| Fallback / compensation | Khi dependency lỗi, giữ trạng thái hiện tại hoặc tạo adjustment/reversal theo BD nếu tài chính đã chốt. |
| Observability | Log an toàn gồm module, function ID, actor type, status, correlation id; không log secret/PII/raw payment. |

## E. Documented Function Test Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| PAYMENT_MEMBERSHIP-FN-EV02-01 | Happy path cho PAYMENT_MEMBERSHIP-FN02. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| PAYMENT_MEMBERSHIP-FN-EV02-02 | Business rule violation cho PAYMENT_MEMBERSHIP-BR02. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| PAYMENT_MEMBERSHIP-FN-EV02-03 | Permission denied theo role/scope. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| PAYMENT_MEMBERSHIP-FN-EV02-04 | Idempotency/retry nếu có ghi dữ liệu. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| PAYMENT_MEMBERSHIP-FN-EV02-05 | Audit hoặc event được tạo khi BD yêu cầu. | Documented | Required in implementation/test phase; not executed in this DD docs pass |

---

<a id="payment_membership-fn03"></a>
# PAYMENT_MEMBERSHIP-FN03 — confirmMembershipTransfer

## A. Định danh và trách nhiệm

| Trường | Nội dung |
|---|---|
| Feature cha | PAYMENT_MEMBERSHIP-F01 |
| Layer | Use case / Service, called by member payment screen |
| Hàm export / endpoint | confirm_my_membership_payment_transfer(payment_event_id) |
| Mục tiêu duy nhất | Chuyển yêu cầu awaiting_transfer của chính khách sang pending_review sau khi khách bấm “Đã chuyển khoản”. |
| Không chịu trách nhiệm | Không kiểm tra tài khoản ngân hàng, không nhận biên lai, không kích hoạt quyền. |
| Rule áp dụng | PAYMENT_MEMBERSHIP-BR01, PAYMENT_MEMBERSHIP-BR04 |

## B. Hợp đồng và kiểm soát

- Chỉ auth.uid() trùng người tạo yêu cầu mới có thể xác nhận.
- Chỉ trạng thái awaiting_transfer được chuyển sang pending_review; yêu cầu pending cũ không được member sửa.
- Backend snapshot thời điểm khách xác nhận vào metadata; Admin queue/banner chỉ đếm pending_review.
- Nếu backend trả succeeded trong lần làm mới sau đó, ứng dụng mới làm mới quyền gói.

## C. Documented Function Test Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| PAYMENT_MEMBERSHIP-FN-EV03-01 | Khách chỉ xác nhận được yêu cầu của chính mình. | Documented | Required in implementation/test phase |
| PAYMENT_MEMBERSHIP-FN-EV03-02 | Xác nhận chỉ đưa yêu cầu vào pending_review, không kích hoạt quyền. | Documented | Required in implementation/test phase |
| PAYMENT_MEMBERSHIP-FN-EV03-03 | Admin chỉ duyệt/từ chối pending_review hoặc pending cũ theo quyền payments.write. | Documented | Required in implementation/test phase |
