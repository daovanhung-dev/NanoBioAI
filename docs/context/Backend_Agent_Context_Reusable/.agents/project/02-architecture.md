# Architecture — Modular Monolith FastAPI (baseline)

```text
new-backend/
├── AGENTS.md
├── .agents/                       # agent context & audit
├── app/
│   ├── __init__.py
│   ├── main.py                     # composition root: create_app(), routers, middleware
│   ├── api/
│   │   ├── __init__.py
│   │   └── v1.py                   # thin public HTTP routing
│   ├── core/
│   │   ├── config.py               # typed settings, secrets from env
│   │   ├── database.py             # engine, session factory, DI
│   │   ├── responses.py            # canonical API envelope, ApiError
│   │   ├── middleware.py           # trace, exception handlers
│   │   ├── trace.py
│   │   └── security/               # password, access token, refresh token
│   ├── modules/
│   │   └── <bounded_context>/
│   │       └── <feature>/
│   │           ├── __init__.py
│   │           ├── models.py       # Pydantic request/response
│   │           ├── validate.py     # pure special validation (optional)
│   │           ├── query.py        # SQL/DB operations, no commit
│   │           └── view.py         # business orchestration & transaction
│   ├── services/                   # external e-mail, object storage, AI, payments
│   └── utils/                      # pure/shared validation or transforms
├── migrations/                     # Alembic versions
├── tests/
│   ├── conftest.py
│   ├── core/
│   ├── modules/
│   └── integration/
├── docs/contracts/
├── pyproject.toml
├── uv.lock
├── .env.example
└── Dockerfile
```

> Cây trên là **target architecture**, agent phải tạo source tương ứng bằng prompt khởi tạo. Không bắt buộc mọi directory ngay từ ngày 1; tránh empty placeholder vô nghĩa.

## Dependency direction

`main/api -> modules/view -> modules/query -> core/database -> PostgreSQL`.
`view -> core/security|services` khi thực sự cần. `models -> utils pure`. `query` không import `api` hoặc `view`. External adapters phụ thuộc vào interfaces/protocols và config inject được.

## Request lifecycle

`Client -> middleware/trace -> router -> Pydantic models -> special validation -> use case/view -> DB queries/service -> commit/rollback -> response envelope -> middleware`.

1. Router parse body/path/query/header và gọi một use case, không chứa SQL/business rules.
2. `models.py`: type/required/field format/ranges/normalization.
3. `validate.py`: deterministic pure special rules khi contract yêu cầu.
4. `view.py`: authorization/domain invariants, query, integration orchestration, transaction lifecycle.
5. `query.py`: DB read/write với bound params, không commit/rollback/HTTP mapping.
6. `core/`: shared infrastructure; không đưa nghiệp vụ domain vào core.

## Boundaries

- Không import business code chéo module tùy tiện. Cross-module qua public use case/service và contract rõ ràng.
- IO-bound external API: client có timeout, test double, safe error mapping; dùng async khi end-to-end async, hoặc sync client trong def handler. Tránh blocking I/O trong async handler.
- Một FastAPI app process ban đầu là đủ cho modular monolith; chưa chọn microservices trước khi có lý do vận hành thật.
- Worker/outbox khi email, webhook hoặc publish event cần delivery/retry đáng tin cậy; không coi log message hay in-memory background tasks là durable queue.
- One-way dependencies, cấu hình inject qua dependency, không tạo global DB Session dùng chung request.

## Testable composition

`create_app(settings?, dependencies?)` để cho phép inject database factory và fake external services. Startup/shutdown quản lý lifespans, connection pooling và cleanup đúng thứ tự.
