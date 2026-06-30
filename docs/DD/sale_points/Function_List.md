# Function List — SALE_POINTS / Điểm Sale & quy đổi

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
| SALE_POINTS-FN01 | creditSalePointsForApprovedPayment | SALE_POINTS-F01 | Use case / Service | planned:lib/sale_referral/sale_points/application/sale_points_fn01.dart | payment_approved event | Command + actor context | Result/Error | Audit/event when required | Approved - DD docs complete |
| SALE_POINTS-FN02 | requestAndReviewSalePointConversion | SALE_POINTS-F02 | Use case / Service | planned:lib/sale_referral/sale_points/application/sale_points_fn02.dart | Sale submits conversion request | Command + actor context | Result/Error | Audit/event when required | Approved - DD docs complete |

---

<a id="sale_points-fn01"></a>
# SALE_POINTS-FN01 — creditSalePointsForApprovedPayment

## A. Định danh và trách nhiệm

| Trường | Nội dung |
|---|---|
| Feature cha | SALE_POINTS-F01 |
| Layer | Use case / Service, called by controller/provider/API handler |
| Loại thực thi | Sync for validation and state read; async/job only when BD requires background processing |
| File dự kiến | planned:lib/sale_referral/sale_points/application/sale_points_fn01.dart |
| Hàm export / endpoint | execute(command, actorContext) hoặc API contract tương ứng |
| Mục tiêu duy nhất | Sale nhận 10% từ payment hợp lệ của khách trực tiếp. |
| Không chịu trách nhiệm | Không tự chốt product questions; không truy cập trực tiếp UI hoặc storage ngoài layer được phép. |
| Được gọi bởi | SALE_POINTS-V01 hoặc event/API source trong BD sections 7.5/7.6/12.1, AC-11..AC-16, UC-17 |
| Gọi tiếp | Repository/datasource/service planned trong Import_File.md |
| Rule áp dụng | SALE_POINTS-BR01 |

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
3. Tải entity liên quan: @{Id=sale_commission_ledger; Name=Sale Commission Ledger; Purpose=Ledger hoa hồng/Điểm Sale; Attributes=payment, sale, rate 10%, base amount, points, status; Relationships=Unique per payment}, @{Id=sale_point_balance; Name=Sale Point Balance; Purpose=Số dư tính toán; Attributes=available, held, converted, reversed; Relationships=Derived from ledger}, @{Id=sale_point_conversion; Name=Sale Point Conversion; Purpose=Yêu cầu đổi điểm; Attributes=sale, points, rate, money, status, payout info; Relationships=Reviewed by Admin}.
4. Áp dụng SALE_POINTS-BR01 và các rule cross-module từ BD sections 14, 15.
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
| SALE_POINTS-FN-EV01-01 | Happy path cho SALE_POINTS-FN01. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| SALE_POINTS-FN-EV01-02 | Business rule violation cho SALE_POINTS-BR01. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| SALE_POINTS-FN-EV01-03 | Permission denied theo role/scope. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| SALE_POINTS-FN-EV01-04 | Idempotency/retry nếu có ghi dữ liệu. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| SALE_POINTS-FN-EV01-05 | Audit hoặc event được tạo khi BD yêu cầu. | Documented | Required in implementation/test phase; not executed in this DD docs pass |

---

<a id="sale_points-fn02"></a>
# SALE_POINTS-FN02 — requestAndReviewSalePointConversion

## A. Định danh và trách nhiệm

| Trường | Nội dung |
|---|---|
| Feature cha | SALE_POINTS-F02 |
| Layer | Use case / Service, called by controller/provider/API handler |
| Loại thực thi | Sync for validation and state read; async/job only when BD requires background processing |
| File dự kiến | planned:lib/sale_referral/sale_points/application/sale_points_fn02.dart |
| Hàm export / endpoint | execute(command, actorContext) hoặc API contract tương ứng |
| Mục tiêu duy nhất | Sale yêu cầu đổi điểm và Admin xử lý có giữ/trừ điểm đúng một lần. |
| Không chịu trách nhiệm | Không tự chốt product questions; không truy cập trực tiếp UI hoặc storage ngoài layer được phép. |
| Được gọi bởi | SALE_POINTS-V02 hoặc event/API source trong BD section 7.10, AC-17/AC-18, UC-18/UC-19 |
| Gọi tiếp | Repository/datasource/service planned trong Import_File.md |
| Rule áp dụng | SALE_POINTS-BR02 |

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
3. Tải entity liên quan: @{Id=sale_commission_ledger; Name=Sale Commission Ledger; Purpose=Ledger hoa hồng/Điểm Sale; Attributes=payment, sale, rate 10%, base amount, points, status; Relationships=Unique per payment}, @{Id=sale_point_balance; Name=Sale Point Balance; Purpose=Số dư tính toán; Attributes=available, held, converted, reversed; Relationships=Derived from ledger}, @{Id=sale_point_conversion; Name=Sale Point Conversion; Purpose=Yêu cầu đổi điểm; Attributes=sale, points, rate, money, status, payout info; Relationships=Reviewed by Admin}.
4. Áp dụng SALE_POINTS-BR02 và các rule cross-module từ BD sections 14, 15.
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
| SALE_POINTS-FN-EV02-01 | Happy path cho SALE_POINTS-FN02. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| SALE_POINTS-FN-EV02-02 | Business rule violation cho SALE_POINTS-BR02. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| SALE_POINTS-FN-EV02-03 | Permission denied theo role/scope. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| SALE_POINTS-FN-EV02-04 | Idempotency/retry nếu có ghi dữ liệu. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| SALE_POINTS-FN-EV02-05 | Audit hoặc event được tạo khi BD yêu cầu. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
