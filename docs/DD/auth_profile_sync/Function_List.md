# Function List — AUTH_PROFILE_SYNC / Xác thực, hồ sơ và đồng bộ Guest

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
| AUTH_PROFILE_SYNC-FN01 | authenticateAndBuildAccess | AUTH_PROFILE_SYNC-F01 | Use case / Service | planned:lib/app_versions/v2/features/auth/application/auth_profile_sync_fn01.dart | Submit login/sign-up | Command + actor context | Result/Error | Audit/event when required | Draft |
| AUTH_PROFILE_SYNC-FN02 | syncGuestProfileToMember | AUTH_PROFILE_SYNC-F02 | Use case / Service | planned:lib/app_versions/v2/features/auth/application/auth_profile_sync_fn02.dart | Login after guest usage | Command + actor context | Result/Error | Audit/event when required | Draft |

---

<a id="auth_profile_sync-fn01"></a>
# AUTH_PROFILE_SYNC-FN01 — authenticateAndBuildAccess

## A. Định danh và trách nhiệm

| Trường | Nội dung |
|---|---|
| Feature cha | AUTH_PROFILE_SYNC-F01 |
| Layer | Use case / Service, called by controller/provider/API handler |
| Loại thực thi | Sync for validation and state read; async/job only when BD requires background processing |
| File dự kiến | planned:lib/app_versions/v2/features/auth/application/auth_profile_sync_fn01.dart |
| Hàm export / endpoint | execute(command, actorContext) hoặc API contract tương ứng |
| Mục tiêu duy nhất | Member có session và quyền hiệu lực đúng. |
| Không chịu trách nhiệm | Không tự chốt product questions; không truy cập trực tiếp UI hoặc storage ngoài layer được phép. |
| Được gọi bởi | AUTH_PROFILE_SYNC-V01 hoặc event/API source trong BD M05 luồng đăng ký/đăng nhập |
| Gọi tiếp | Repository/datasource/service planned trong Import_File.md |
| Rule áp dụng | AUTH_PROFILE_SYNC-BR01 |

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
3. Tải entity liên quan: @{Id=app_user; Name=App User; Purpose=Hồ sơ app liên kết auth; Attributes=auth_user_id, account status, package status, sale status; Relationships=Owns profile and entitlements}, @{Id=guest_sync; Name=Guest Sync Snapshot; Purpose=Dữ liệu chuyển local-cloud; Attributes=local key, sync status, conflict policy; Relationships=Links Guest Profile to App User}.
4. Áp dụng AUTH_PROFILE_SYNC-BR01 và các rule cross-module từ BD sections 14, 15.
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

- [ ] Happy path cho AUTH_PROFILE_SYNC-FN01.
- [ ] Business rule violation cho AUTH_PROFILE_SYNC-BR01.
- [ ] Permission denied theo role/scope.
- [ ] Idempotency/retry nếu có ghi dữ liệu.
- [ ] Audit hoặc event được tạo khi BD yêu cầu.
---

<a id="auth_profile_sync-fn02"></a>
# AUTH_PROFILE_SYNC-FN02 — syncGuestProfileToMember

## A. Định danh và trách nhiệm

| Trường | Nội dung |
|---|---|
| Feature cha | AUTH_PROFILE_SYNC-F02 |
| Layer | Use case / Service, called by controller/provider/API handler |
| Loại thực thi | Sync for validation and state read; async/job only when BD requires background processing |
| File dự kiến | planned:lib/app_versions/v2/features/auth/application/auth_profile_sync_fn02.dart |
| Hàm export / endpoint | execute(command, actorContext) hoặc API contract tương ứng |
| Mục tiêu duy nhất | Liên kết dữ liệu local với tài khoản mà không mất lịch trình/hồ sơ. |
| Không chịu trách nhiệm | Không tự chốt product questions; không truy cập trực tiếp UI hoặc storage ngoài layer được phép. |
| Được gọi bởi | AUTH_PROFILE_SYNC-V02 hoặc event/API source trong BD M05 Guest -> Member |
| Gọi tiếp | Repository/datasource/service planned trong Import_File.md |
| Rule áp dụng | AUTH_PROFILE_SYNC-BR02 |

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
3. Tải entity liên quan: @{Id=app_user; Name=App User; Purpose=Hồ sơ app liên kết auth; Attributes=auth_user_id, account status, package status, sale status; Relationships=Owns profile and entitlements}, @{Id=guest_sync; Name=Guest Sync Snapshot; Purpose=Dữ liệu chuyển local-cloud; Attributes=local key, sync status, conflict policy; Relationships=Links Guest Profile to App User}.
4. Áp dụng AUTH_PROFILE_SYNC-BR02 và các rule cross-module từ BD sections 14, 15.
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

- [ ] Happy path cho AUTH_PROFILE_SYNC-FN02.
- [ ] Business rule violation cho AUTH_PROFILE_SYNC-BR02.
- [ ] Permission denied theo role/scope.
- [ ] Idempotency/retry nếu có ghi dữ liệu.
- [ ] Audit hoặc event được tạo khi BD yêu cầu.
