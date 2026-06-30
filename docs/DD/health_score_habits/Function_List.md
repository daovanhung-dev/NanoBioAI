# Function List — HEALTH_SCORE_HABITS / Điểm sức khỏe & thói quen

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
| HEALTH_SCORE_HABITS-FN01 | calculateHealthScore | HEALTH_SCORE_HABITS-F01 | Use case / Service | planned:lib/app_versions/v2/features/health_scoring/application/health_score_habits_fn01.dart | Completion event or scheduled recalculation | Command + actor context | Result/Error | Audit/event when required | Approved - DD docs complete |
| HEALTH_SCORE_HABITS-FN02 | loadHabitProgress | HEALTH_SCORE_HABITS-F02 | Use case / Service | planned:lib/app_versions/v2/features/health_scoring/application/health_score_habits_fn02.dart | Open progress view | Command + actor context | Result/Error | Audit/event when required | Approved - DD docs complete |

---

<a id="health_score_habits-fn01"></a>
# HEALTH_SCORE_HABITS-FN01 — calculateHealthScore

## A. Định danh và trách nhiệm

| Trường | Nội dung |
|---|---|
| Feature cha | HEALTH_SCORE_HABITS-F01 |
| Layer | Use case / Service, called by controller/provider/API handler |
| Loại thực thi | Sync for validation and state read; async/job only when BD requires background processing |
| File dự kiến | planned:lib/app_versions/v2/features/health_scoring/application/health_score_habits_fn01.dart |
| Hàm export / endpoint | execute(command, actorContext) hoặc API contract tương ứng |
| Mục tiêu duy nhất | Tạo điểm từ lịch sử thực hiện theo công thức version hóa. |
| Không chịu trách nhiệm | Không tự chốt product questions; không truy cập trực tiếp UI hoặc storage ngoài layer được phép. |
| Được gọi bởi | HEALTH_SCORE_HABITS-V01 hoặc event/API source trong BD M08, section 9 |
| Gọi tiếp | Repository/datasource/service planned trong Import_File.md |
| Rule áp dụng | HEALTH_SCORE_HABITS-BR01 |

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
3. Tải entity liên quan: @{Id=health_score_ledger; Name=Health Score Ledger; Purpose=Điểm sức khỏe; Attributes=subject, source event, formula version, score; Relationships=Uses completion events}, @{Id=habit_progress; Name=Habit Progress; Purpose=Tiến độ thói quen; Attributes=subject, period, score, status; Relationships=Displayed on dashboard}.
4. Áp dụng HEALTH_SCORE_HABITS-BR01 và các rule cross-module từ BD sections 14, 15.
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
| HEALTH_SCORE_HABITS-FN-EV01-01 | Happy path cho HEALTH_SCORE_HABITS-FN01. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| HEALTH_SCORE_HABITS-FN-EV01-02 | Business rule violation cho HEALTH_SCORE_HABITS-BR01. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| HEALTH_SCORE_HABITS-FN-EV01-03 | Permission denied theo role/scope. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| HEALTH_SCORE_HABITS-FN-EV01-04 | Idempotency/retry nếu có ghi dữ liệu. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| HEALTH_SCORE_HABITS-FN-EV01-05 | Audit hoặc event được tạo khi BD yêu cầu. | Documented | Required in implementation/test phase; not executed in this DD docs pass |

---

<a id="health_score_habits-fn02"></a>
# HEALTH_SCORE_HABITS-FN02 — loadHabitProgress

## A. Định danh và trách nhiệm

| Trường | Nội dung |
|---|---|
| Feature cha | HEALTH_SCORE_HABITS-F02 |
| Layer | Use case / Service, called by controller/provider/API handler |
| Loại thực thi | Sync for validation and state read; async/job only when BD requires background processing |
| File dự kiến | planned:lib/app_versions/v2/features/health_scoring/application/health_score_habits_fn02.dart |
| Hàm export / endpoint | execute(command, actorContext) hoặc API contract tương ứng |
| Mục tiêu duy nhất | Hiển thị tiến độ theo lịch sử thực hiện. |
| Không chịu trách nhiệm | Không tự chốt product questions; không truy cập trực tiếp UI hoặc storage ngoài layer được phép. |
| Được gọi bởi | HEALTH_SCORE_HABITS-V02 hoặc event/API source trong BD M08 luồng |
| Gọi tiếp | Repository/datasource/service planned trong Import_File.md |
| Rule áp dụng | HEALTH_SCORE_HABITS-BR02 |

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
3. Tải entity liên quan: @{Id=health_score_ledger; Name=Health Score Ledger; Purpose=Điểm sức khỏe; Attributes=subject, source event, formula version, score; Relationships=Uses completion events}, @{Id=habit_progress; Name=Habit Progress; Purpose=Tiến độ thói quen; Attributes=subject, period, score, status; Relationships=Displayed on dashboard}.
4. Áp dụng HEALTH_SCORE_HABITS-BR02 và các rule cross-module từ BD sections 14, 15.
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
| HEALTH_SCORE_HABITS-FN-EV02-01 | Happy path cho HEALTH_SCORE_HABITS-FN02. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| HEALTH_SCORE_HABITS-FN-EV02-02 | Business rule violation cho HEALTH_SCORE_HABITS-BR02. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| HEALTH_SCORE_HABITS-FN-EV02-03 | Permission denied theo role/scope. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| HEALTH_SCORE_HABITS-FN-EV02-04 | Idempotency/retry nếu có ghi dữ liệu. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| HEALTH_SCORE_HABITS-FN-EV02-05 | Audit hoặc event được tạo khi BD yêu cầu. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
