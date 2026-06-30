# Function List — BASIC_HEALTH_CALC / Tính toán sức khỏe cơ bản

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
| BASIC_HEALTH_CALC-FN01 | runBasicHealthCalculator | BASIC_HEALTH_CALC-F01 | Use case / Service | planned:lib/app_versions/v1/features/health_calculators/application/basic_health_calculators_fn01.dart | Người dùng nhập dữ liệu và bấm tính | Command + actor context | Result/Error | Audit/event when required | Approved - DD docs complete |
| BASIC_HEALTH_CALC-FN02 | versionCalculatorFormula | BASIC_HEALTH_CALC-F02 | Use case / Service | planned:lib/app_versions/v1/features/health_calculators/application/basic_health_calculators_fn02.dart | Admin/PO phê duyệt công thức mới | Command + actor context | Result/Error | Audit/event when required | Approved - DD docs complete |

---

<a id="basic_health_calc-fn01"></a>
# BASIC_HEALTH_CALC-FN01 — runBasicHealthCalculator

## A. Định danh và trách nhiệm

| Trường | Nội dung |
|---|---|
| Feature cha | BASIC_HEALTH_CALC-F01 |
| Layer | Use case / Service, called by controller/provider/API handler |
| Loại thực thi | Sync for validation and state read; async/job only when BD requires background processing |
| File dự kiến | planned:lib/app_versions/v1/features/health_calculators/application/basic_health_calculators_fn01.dart |
| Hàm export / endpoint | execute(command, actorContext) hoặc API contract tương ứng |
| Mục tiêu duy nhất | Trả kết quả từ dữ liệu hợp lệ. |
| Không chịu trách nhiệm | Không tự chốt product questions; không truy cập trực tiếp UI hoặc storage ngoài layer được phép. |
| Được gọi bởi | BASIC_HEALTH_CALC-V01 hoặc event/API source trong BD M04 luồng, UC-03 |
| Gọi tiếp | Repository/datasource/service planned trong Import_File.md |
| Rule áp dụng | BASIC_HEALTH_CALC-BR01 |

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
3. Tải entity liên quan: @{Id=calculator_input; Name=Calculator Input; Purpose=Dữ liệu tính toán; Attributes=height, weight, age group, goal fields; Relationships=May derive from onboarding}, @{Id=formula_version; Name=Formula Version; Purpose=Version công thức; Attributes=code, version, status, effective_from; Relationships=Managed by admin if approved}.
4. Áp dụng BASIC_HEALTH_CALC-BR01 và các rule cross-module từ BD sections 14, 15.
5. Thực thi transaction/idempotency: Conditional - read-only flow does not need transaction; writes still require idempotency and audit.
6. Ghi audit nếu có tác động quyền, tiền, điểm, cấu hình, dữ liệu gia đình hoặc export.
7. Trả Result chuẩn hóa, không trả raw stack trace, raw payment evidence, secret, hoặc health PII không cần thiết.

## D. Transaction, side effect và độ tin cậy

| Nội dung | Quy định |
|---|---|
| Transaction boundary | Conditional - read-only flow does not need transaction; writes still require idempotency and audit. |
| Event/outbox | Phát event sau commit khi feature tạo quyền, quota, notification, point, report hoặc audit. |
| Retry | Retry theo correlation_id/request_id; retry không tạo bản ghi trùng. |
| Fallback / compensation | Khi dependency lỗi, giữ trạng thái hiện tại hoặc tạo adjustment/reversal theo BD nếu tài chính đã chốt. |
| Observability | Log an toàn gồm module, function ID, actor type, status, correlation id; không log secret/PII/raw payment. |

## E. Documented Function Test Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| BASIC_HEALTH_CALC-FN-EV01-01 | Happy path cho BASIC_HEALTH_CALC-FN01. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| BASIC_HEALTH_CALC-FN-EV01-02 | Business rule violation cho BASIC_HEALTH_CALC-BR01. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| BASIC_HEALTH_CALC-FN-EV01-03 | Permission denied theo role/scope. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| BASIC_HEALTH_CALC-FN-EV01-04 | Idempotency/retry nếu có ghi dữ liệu. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| BASIC_HEALTH_CALC-FN-EV01-05 | Audit hoặc event được tạo khi BD yêu cầu. | Documented | Required in implementation/test phase; not executed in this DD docs pass |

---

<a id="basic_health_calc-fn02"></a>
# BASIC_HEALTH_CALC-FN02 — versionCalculatorFormula

## A. Định danh và trách nhiệm

| Trường | Nội dung |
|---|---|
| Feature cha | BASIC_HEALTH_CALC-F02 |
| Layer | Use case / Service, called by controller/provider/API handler |
| Loại thực thi | Sync for validation and state read; async/job only when BD requires background processing |
| File dự kiến | planned:lib/app_versions/v1/features/health_calculators/application/basic_health_calculators_fn02.dart |
| Hàm export / endpoint | execute(command, actorContext) hoặc API contract tương ứng |
| Mục tiêu duy nhất | Đảm bảo thay đổi công thức có version và audit. |
| Không chịu trách nhiệm | Không tự chốt product questions; không truy cập trực tiếp UI hoặc storage ngoài layer được phép. |
| Được gọi bởi | BASIC_HEALTH_CALC-V02 hoặc event/API source trong BD M04 lưu ý, Q-14 |
| Gọi tiếp | Repository/datasource/service planned trong Import_File.md |
| Rule áp dụng | BASIC_HEALTH_CALC-BR02 |

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
3. Tải entity liên quan: @{Id=calculator_input; Name=Calculator Input; Purpose=Dữ liệu tính toán; Attributes=height, weight, age group, goal fields; Relationships=May derive from onboarding}, @{Id=formula_version; Name=Formula Version; Purpose=Version công thức; Attributes=code, version, status, effective_from; Relationships=Managed by admin if approved}.
4. Áp dụng BASIC_HEALTH_CALC-BR02 và các rule cross-module từ BD sections 14, 15.
5. Thực thi transaction/idempotency: Conditional - read-only flow does not need transaction; writes still require idempotency and audit.
6. Ghi audit nếu có tác động quyền, tiền, điểm, cấu hình, dữ liệu gia đình hoặc export.
7. Trả Result chuẩn hóa, không trả raw stack trace, raw payment evidence, secret, hoặc health PII không cần thiết.

## D. Transaction, side effect và độ tin cậy

| Nội dung | Quy định |
|---|---|
| Transaction boundary | Conditional - read-only flow does not need transaction; writes still require idempotency and audit. |
| Event/outbox | Phát event sau commit khi feature tạo quyền, quota, notification, point, report hoặc audit. |
| Retry | Retry theo correlation_id/request_id; retry không tạo bản ghi trùng. |
| Fallback / compensation | Khi dependency lỗi, giữ trạng thái hiện tại hoặc tạo adjustment/reversal theo BD nếu tài chính đã chốt. |
| Observability | Log an toàn gồm module, function ID, actor type, status, correlation id; không log secret/PII/raw payment. |

## E. Documented Function Test Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| BASIC_HEALTH_CALC-FN-EV02-01 | Happy path cho BASIC_HEALTH_CALC-FN02. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| BASIC_HEALTH_CALC-FN-EV02-02 | Business rule violation cho BASIC_HEALTH_CALC-BR02. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| BASIC_HEALTH_CALC-FN-EV02-03 | Permission denied theo role/scope. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| BASIC_HEALTH_CALC-FN-EV02-04 | Idempotency/retry nếu có ghi dữ liệu. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| BASIC_HEALTH_CALC-FN-EV02-05 | Audit hoặc event được tạo khi BD yêu cầu. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
