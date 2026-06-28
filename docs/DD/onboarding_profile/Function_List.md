# Function List — ONBOARDING_PROFILE / Onboarding & Hồ sơ sức khỏe

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
| ONBOARDING_PROFILE-FN01 | saveOnboardingProfile | ONBOARDING_PROFILE-F01 | Use case / Service | planned:lib/app_versions/v1/features/onboarding/application/onboarding_profile_fn01.dart | Mở app lần đầu hoặc hồ sơ chưa hoàn tất | Command + actor context | Result/Error | Audit/event when required | Draft |
| ONBOARDING_PROFILE-FN02 | completeOnboardingAndHandoff | ONBOARDING_PROFILE-F02 | Use case / Service | planned:lib/app_versions/v1/features/onboarding/application/onboarding_profile_fn02.dart | Người dùng xác nhận màn tổng rà soát | Command + actor context | Result/Error | Audit/event when required | Draft |

---

<a id="onboarding_profile-fn01"></a>
# ONBOARDING_PROFILE-FN01 — saveOnboardingProfile

## A. Định danh và trách nhiệm

| Trường | Nội dung |
|---|---|
| Feature cha | ONBOARDING_PROFILE-F01 |
| Layer | Use case / Service, called by controller/provider/API handler |
| Loại thực thi | Sync for validation and state read; async/job only when BD requires background processing |
| File dự kiến | planned:lib/app_versions/v1/features/onboarding/application/onboarding_profile_fn01.dart |
| Hàm export / endpoint | execute(command, actorContext) hoặc API contract tương ứng |
| Mục tiêu duy nhất | Người dùng hoàn tất dữ liệu đầu vào tối thiểu. |
| Không chịu trách nhiệm | Không tự chốt product questions; không truy cập trực tiếp UI hoặc storage ngoài layer được phép. |
| Được gọi bởi | ONBOARDING_PROFILE-V01 hoặc event/API source trong BD M01, AC-01, UC-01 |
| Gọi tiếp | Repository/datasource/service planned trong Import_File.md |
| Rule áp dụng | ONBOARDING_PROFILE-BR01 |

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
3. Tải entity liên quan: @{Id=guest_profile; Name=Guest Profile; Purpose=Hồ sơ local trước đăng nhập; Attributes=local key, first schedule flag, onboarding status; Relationships=May sync to App User}, @{Id=onboarding_profile; Name=Onboarding Profile; Purpose=Dữ liệu cá nhân hóa; Attributes=owner, subject, profile version, completion status; Relationships=Used by Personal Plan and Health Calculator}.
4. Áp dụng ONBOARDING_PROFILE-BR01 và các rule cross-module từ BD sections 14, 15.
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

- [ ] Happy path cho ONBOARDING_PROFILE-FN01.
- [ ] Business rule violation cho ONBOARDING_PROFILE-BR01.
- [ ] Permission denied theo role/scope.
- [ ] Idempotency/retry nếu có ghi dữ liệu.
- [ ] Audit hoặc event được tạo khi BD yêu cầu.
---

<a id="onboarding_profile-fn02"></a>
# ONBOARDING_PROFILE-FN02 — completeOnboardingAndHandoff

## A. Định danh và trách nhiệm

| Trường | Nội dung |
|---|---|
| Feature cha | ONBOARDING_PROFILE-F02 |
| Layer | Use case / Service, called by controller/provider/API handler |
| Loại thực thi | Sync for validation and state read; async/job only when BD requires background processing |
| File dự kiến | planned:lib/app_versions/v1/features/onboarding/application/onboarding_profile_fn02.dart |
| Hàm export / endpoint | execute(command, actorContext) hoặc API contract tương ứng |
| Mục tiêu duy nhất | Đánh dấu hồ sơ đủ điều kiện để sinh lịch trình. |
| Không chịu trách nhiệm | Không tự chốt product questions; không truy cập trực tiếp UI hoặc storage ngoài layer được phép. |
| Được gọi bởi | ONBOARDING_PROFILE-V02 hoặc event/API source trong BD M01 luồng chính, AC-01 |
| Gọi tiếp | Repository/datasource/service planned trong Import_File.md |
| Rule áp dụng | ONBOARDING_PROFILE-BR02 |

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
3. Tải entity liên quan: @{Id=guest_profile; Name=Guest Profile; Purpose=Hồ sơ local trước đăng nhập; Attributes=local key, first schedule flag, onboarding status; Relationships=May sync to App User}, @{Id=onboarding_profile; Name=Onboarding Profile; Purpose=Dữ liệu cá nhân hóa; Attributes=owner, subject, profile version, completion status; Relationships=Used by Personal Plan and Health Calculator}.
4. Áp dụng ONBOARDING_PROFILE-BR02 và các rule cross-module từ BD sections 14, 15.
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

- [ ] Happy path cho ONBOARDING_PROFILE-FN02.
- [ ] Business rule violation cho ONBOARDING_PROFILE-BR02.
- [ ] Permission denied theo role/scope.
- [ ] Idempotency/retry nếu có ghi dữ liệu.
- [ ] Audit hoặc event được tạo khi BD yêu cầu.
