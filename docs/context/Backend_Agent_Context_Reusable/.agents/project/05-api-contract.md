# HTTP / API Contract

## Endpoint design

- Public API prefix `/api/v1`, internal API prefix `/internal/v1` **chỉ khi có internal auth riêng**.
- Resource nouns, predictable HTTP verbs, stable paths, meaningful idempotency.
- UTC timestamps ISO-8601; int/UUID ID theo domain; monetary values dùng Decimal/dùng string trong JSON khi cần giữ chính xác.
- OpenAPI được tạo từ real FastAPI code; snapshot/spec và tests phải đồng bộ.
- Pagination: `page >=1`, `size` giới hạn [1..100] theo use case; `total`, `total_pages`; SQL sort theo allowlist.
- `q`, filters, sort: nhập chuẩn hóa rõ ràng, không lắp tùy ý vào SQL ORDER BY.

## Canonical success envelope (normative cho dự án mới)

```json
{
  "success": true,
  "businessCode": "RESOURCE_RETRIEVED",
  "message": "OK",
  "data": {"id": 1},
  "meta": {},
  "traceId": "00000000-0000-4000-8000-000000000000"
}
```

## Canonical error envelope (normative cho dự án mới)

```json
{
  "success": false,
  "businessCode": "VALIDATION_ERROR",
  "message": "Dữ liệu đầu vào không hợp lệ.",
  "data": null,
  "meta": {
    "fieldErrors": [{"field": "email", "code": "INVALID_VALUE", "message": "Email không hợp lệ."}]
  },
  "traceId": "00000000-0000-4000-8000-000000000000"
}
```

**Lưu ý so với Study Server:** source cũ trả `{}` cho `data` lỗi khi không có data; guideline mô tả `null`. **Dự án mới phải chọn MỘT contract**. Bộ này mặc định `null` và đòi test chuẩn hóa.

## HTTP status guidance

| HTTP | Default meaning | Representative business code |
|---|---|---|
| 200 | read / synchronous successful update | `RESOURCE_RETRIEVED` / `RESOURCE_UPDATED` |
| 201 | created | `RESOURCE_CREATED` |
| 202 | async accepted; phải có job contract | `OPERATION_ACCEPTED` |
| 204 | no content, **không dùng envelope** | N/A |
| 400 | invalid protocol/request | `BAD_REQUEST` |
| 401 | missing/invalid authentication | `AUTHENTICATION_REQUIRED` |
| 403 | authenticated but denied | `ACCESS_DENIED` |
| 404 | resource missing; authorization-aware existence policy | `RESOURCE_NOT_FOUND` |
| 409 | unique conflict / state conflict | `STATE_CONFLICT` |
| 422 | typed validation | `VALIDATION_ERROR` |
| 429 | rate limited | `RATE_LIMITED` |
| 500 | unexpected internal error, no leak | `INTERNAL_SERVER_ERROR` |
| 503 | required dependency unavailable | `DEPENDENCY_UNAVAILABLE` |

Business codes là placeholder generic; contract mới xác định danh mục cuối cùng, không tự sinh code theo mỗi endpoint nếu không cần.

## Rules

- Response serializes only explicit safe fields, never `password_hash`, secret claims or ORM internal state.
- HTTP status code trên response thực phải khớp response schema; `ApiError` có status, businessCode, message, traceId.
- `X-Trace-Id` request/response; accept valid UUID or generate new; không dùng client-supplied arbitrary log key làm secret.
- `Idempotency-Key` cho mutating retriable operations khi contract quy định; enforce uniqueness+TTL+atomicity server-side.
- Auth: `Authorization: Bearer <token>` cho protected routes; OpenAPI security scheme; 401/403 tests.
- API compatibility: back-compat field additions vs breaking changes; version + migration.
- Không hardcode health với `ready=true` nếu DB không kiểm tra thật; phân biệt live vs ready rõ ràng.
