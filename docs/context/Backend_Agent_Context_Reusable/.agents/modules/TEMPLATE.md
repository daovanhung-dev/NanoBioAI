# Module: TODO_FEATURE_NAME

- Owner/bounded context: TODO
- Status: `NOT_FOUND | SOURCE_BACKED | VERIFIED | UNWIRED | DISCREPANCY`
- Requirement / API contract: TODO
- Source paths: TODO
- Tests: TODO

## Route surface

| Method | Path | Auth | Request | Response | Business codes |
|---|---|---|---|---|---|
| TODO | TODO | TODO | TODO | TODO | TODO |

## Flow

```text
HTTP -> models -> validate? -> view -> query/service -> DB/side effects -> response
```

## DB / external dependencies

- Tables, columns, FK, indexes, tenancy: TODO (schema evidence)
- External APIs/queue: TODO (failure modes/idempotency)
- Transaction owner: TODO

## Acceptance criteria and tests

- Happy: TODO
- Invalid input: TODO
- Auth/ownership: TODO
- Conflict/concurrency: TODO
- DB/provider failure and rollback: TODO

## Discrepancies / known gaps

- TODO
