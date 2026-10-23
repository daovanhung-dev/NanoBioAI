# Responses, Error Handling, Trace & Observability

## Response/error boundary

- Dùng `success_response()` và `ApiError`/`error_response()` để có envelope thống nhất theo `.agents/project/05-api-contract.md`.
- `ApiError` chứa `status_code`, stable `business_code`, safe `message`, `trace_id`, optional field errors/meta/headers.
- Middleware/map exception globally: typed app error; FastAPI request validation; HTTPException; unexpected exception. Không trả traceback/SQL/PII cho client.
- Validation errors đặt tại `meta.fieldErrors`. Business error là trạng thái đã biết; unexpected error = 500 và log internal diagnostic **đã scrub secrets**.

## Tracing & logs

- `X-Trace-Id` theo request; nhận UUID hợp lệ, không hợp lệ thì tạo mới, trả header ở response.
- Structured logs: timestamp UTC, service, environment, route template, method, HTTP status, latency, trace_id, event code; không log raw path param nhạy cảm.
- Propagate trace/correlation IDs qua outbound HTTP nếu contract hỗ trợ; không coi trace ID là auth token.
- Trace sampling và retention phụ thuộc môi trường; logs có rotation và access control.
- Không dựa chỉ vào exception counts: đo latency percentiles, failure by code, DB pool, queue delay, dependency timeout.

## Health endpoints

- `/health/live`: process/event loop responsiveness, **không probe DB**; tránh restart vì network chập chờn.
- `/health/ready`: probe lightweight các dependency **thiết yếu** (ví dụ `SELECT 1` DB), trả 503 khi không sẵn sàng; timeout thấp, không làm side effect.
- `/metrics` nếu cần phải bảo vệ/expose theo hạ tầng; không public secrets.
- Đây là cải tiến so với Study2Work source cũ, vốn chỉ báo database `configured` ở ready.

## External provider behavior

- Timeout cụ thể cho connect/read, bounded retries chỉ cho thao tác idempotent, exponential backoff + jitter khi phù hợp.
- Phân biệt 4xx upstream, 5xx, timeout, circuit breaker; map sang safe domain error, không expose provider payload.
- Queue + outbox cho delivery có retry; in-memory background task chỉ best-effort.
