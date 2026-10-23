# Backend Project Index

Đọc `01-product-context.md` trước khi implement nghiệp vụ. Backend mới không được nhận nghiệp vụ từ Study2Work.

| File | Quyết định / thông tin nắm giữ |
|---|---|
| `01-product-context.md` | Domain, actors, module ownership, non-goals, requirements |
| `02-architecture.md` | Layering, dependency boundaries, transaction ownership |
| `03-technology.md` | Languages, libraries, optional stack, selection |
| `04-coding-conventions.md` | Naming, import, comment, clean code |
| `05-api-contract.md` | URL, HTTP, envelope, pagination, statuses, versioning |
| `06-validation.md` | Pure validation vs business rule vs DB checks |
| `07-database.md` | Schema, query, transaction, migration, performance |
| `08-auth-security.md` | AuthN, AuthZ, tokens, access control, secrets |
| `09-error-observability.md` | Exceptions, tracing, logging, telemetry |
| `10-testing.md` | pytest plan, fixtures, negative scenarios, gates |
| `11-devops-operations.md` | Env, Docker, CI/CD, deploy/rollback |
| `12-task-workflows.md` | Coding/fix/docs/test/delivery procedure |
| `13-decisions.md` | ADR record / deviations from baseline |

**Priority:** requirement/contract mới > current code/tests/config > context được xác nhận > recommended baseline. Context có thể stale; khi stale phải đọc source thật.
