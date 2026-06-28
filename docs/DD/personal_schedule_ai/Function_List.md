# Function List — PERSONAL_SCHEDULE_AI / AI Lịch trình cá nhân

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
| PERSONAL_SCHEDULE_AI-FN01 | generateInitialGuestPlan | PERSONAL_SCHEDULE_AI-F01 | Use case / Service | planned:lib/app_versions/v1/services/ai/application/personal_schedule_ai_fn01.dart | Onboarding completed | Command + actor context | Result/Error | Audit/event when required | Draft |
| PERSONAL_SCHEDULE_AI-FN02 | generateMemberPlanWithQuota | PERSONAL_SCHEDULE_AI-F02 | Use case / Service | planned:lib/app_versions/v1/services/ai/application/personal_schedule_ai_fn02.dart | Member yêu cầu tạo lịch trình mới | Command + actor context | Result/Error | Audit/event when required | Draft |

---

<a id="personal_schedule_ai-fn01"></a>
# PERSONAL_SCHEDULE_AI-FN01 — generateInitialGuestPlan

## A. Định danh và trách nhiệm

| Trường | Nội dung |
|---|---|
| Feature cha | PERSONAL_SCHEDULE_AI-F01 |
| Layer | Use case / Service, called by controller/provider/API handler |
| Loại thực thi | Sync for validation and state read; async/job only when BD requires background processing |
| File dự kiến | planned:lib/app_versions/v1/services/ai/application/personal_schedule_ai_fn01.dart |
| Hàm export / endpoint | execute(command, actorContext) hoặc API contract tương ứng |
| Mục tiêu duy nhất | Guest hoàn tất onboarding nhận lịch trình đầu tiên. |
| Không chịu trách nhiệm | Không tự chốt product questions; không truy cập trực tiếp UI hoặc storage ngoài layer được phép. |
| Được gọi bởi | PERSONAL_SCHEDULE_AI-V01 hoặc event/API source trong BD M02 Guest flow, AC-01, AC-02, UC-02 |
| Gọi tiếp | Repository/datasource/service planned trong Import_File.md |
| Rule áp dụng | PERSONAL_SCHEDULE_AI-BR01 |

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
3. Tải entity liên quan: @{Id=personal_plan; Name=Personal Plan; Purpose=Lịch trình AI; Attributes=owner, subject, version, status, AI source; Relationships=Has Plan Items}, @{Id=plan_item; Name=Plan Item; Purpose=Bữa ăn/bài tập/mốc lịch; Attributes=plan id, time, type, status; Relationships=Used by dashboard and notification}, @{Id=ai_request; Name=AI Request; Purpose=Theo dõi request/quota; Attributes=request_id, type, status, quota impact; Relationships=Linked to quota ledger}.
4. Áp dụng PERSONAL_SCHEDULE_AI-BR01 và các rule cross-module từ BD sections 14, 15.
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

## E. Test checklist

- [ ] Happy path cho PERSONAL_SCHEDULE_AI-FN01.
- [ ] Business rule violation cho PERSONAL_SCHEDULE_AI-BR01.
- [ ] Permission denied theo role/scope.
- [ ] Idempotency/retry nếu có ghi dữ liệu.
- [ ] Audit hoặc event được tạo khi BD yêu cầu.
---

<a id="personal_schedule_ai-fn02"></a>
# PERSONAL_SCHEDULE_AI-FN02 — generateMemberPlanWithQuota

## A. Định danh và trách nhiệm

| Trường | Nội dung |
|---|---|
| Feature cha | PERSONAL_SCHEDULE_AI-F02 |
| Layer | Use case / Service, called by controller/provider/API handler |
| Loại thực thi | Sync for validation and state read; async/job only when BD requires background processing |
| File dự kiến | planned:lib/app_versions/v1/services/ai/application/personal_schedule_ai_fn02.dart |
| Hàm export / endpoint | execute(command, actorContext) hoặc API contract tương ứng |
| Mục tiêu duy nhất | Member tạo lịch trình mới theo quota hoặc quyền Plus/FamilyPlus. |
| Không chịu trách nhiệm | Không tự chốt product questions; không truy cập trực tiếp UI hoặc storage ngoài layer được phép. |
| Được gọi bởi | PERSONAL_SCHEDULE_AI-V02 hoặc event/API source trong BD M02 Member flow, AC-05, AC-06, UC-08 |
| Gọi tiếp | Repository/datasource/service planned trong Import_File.md |
| Rule áp dụng | PERSONAL_SCHEDULE_AI-BR02 |

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
3. Tải entity liên quan: @{Id=personal_plan; Name=Personal Plan; Purpose=Lịch trình AI; Attributes=owner, subject, version, status, AI source; Relationships=Has Plan Items}, @{Id=plan_item; Name=Plan Item; Purpose=Bữa ăn/bài tập/mốc lịch; Attributes=plan id, time, type, status; Relationships=Used by dashboard and notification}, @{Id=ai_request; Name=AI Request; Purpose=Theo dõi request/quota; Attributes=request_id, type, status, quota impact; Relationships=Linked to quota ledger}.
4. Áp dụng PERSONAL_SCHEDULE_AI-BR02 và các rule cross-module từ BD sections 14, 15.
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

## E. Test checklist

- [ ] Happy path cho PERSONAL_SCHEDULE_AI-FN02.
- [ ] Business rule violation cho PERSONAL_SCHEDULE_AI-BR02.
- [ ] Permission denied theo role/scope.
- [ ] Idempotency/retry nếu có ghi dữ liệu.
- [ ] Audit hoặc event được tạo khi BD yêu cầu.
