# API Contract: <feature> / <operation>

- Contract owner: TODO
- Status: `PROPOSED | APPROVED | IMPLEMENTED | VERIFIED`
- Method / path: `TODO /api/v1/TODO`
- Auth: `PUBLIC | JWT | OIDC | SERVICE`
- Role/ownership/tenant policy: TODO
- Idempotency strategy: TODO

## Input

| Source | Name | Type | Required | Normalization | Validation |
|---|---|---|---|---|---|
| body/query/path/header | TODO | TODO | TODO | TODO | TODO |

## Result

- Success HTTP: TODO
- `businessCode`: TODO
- `data` schema example: TODO
- Sensitive fields omitted: TODO

## Error mapping

| Condition | HTTP | businessCode | Safe message | Retryable |
|---|---|---|---|---|
| Validation | 422 | `VALIDATION_ERROR` | TODO | No |
| Unauthorized | 401 | `AUTHENTICATION_REQUIRED` | TODO | No |
| Forbidden | 403 | `ACCESS_DENIED` | TODO | No |
| Missing | 404 | `RESOURCE_NOT_FOUND` | TODO | No |
| Conflict | 409 | `STATE_CONFLICT` | TODO | No |
| Dependency failure | 503 | `DEPENDENCY_UNAVAILABLE` | TODO | Maybe |

## DB contract and behavior

- Tables/columns/constraints/indexes (must have DDL/migration evidence): TODO
- Transaction owner: TODO
- External effects: TODO
- Concurrency/race conditions: TODO
- Pagination/filter/sort if any: TODO

## Acceptance/test cases

- TODO
