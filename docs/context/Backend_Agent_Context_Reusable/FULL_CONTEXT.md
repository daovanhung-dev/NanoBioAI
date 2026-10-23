# FULL BACKEND AGENT CONTEXT — SINGLE-FILE EXPORT

_Bộ context gộp để đọc/copy; dùng ZIP nếu muốn Codex tự nhận diện root `AGENTS.md` + từng context page._


---

# FILE: `README.md`

# Backend Agent Context — Reusable FastAPI Template

> **Mục đích:** bộ tri thức/quy tắc dành cho coding agent (Codex, Claude Code, Cursor hoặc AI coding agent tương tự) để triển khai **một backend khác** theo phong cách đã kiểm chứng từ `Study2Work/apps/study-server`, nhưng **không sao chép nghiệp vụ, database, secret hoặc hạn chế kiến trúc cũ**.
>
> Snapshot nguồn đối chiếu: `daovanhung-dev/Study2Work`, branch `main`, đọc ngày **2026-10-22**. Đây là **agent context + template tài liệu**, **không phải ứng dụng FastAPI hoàn chỉnh/runnable**.

## Bắt đầu trong 3 bước

1. Giải nén vào root của một repository backend mới (để `AGENTS.md` ở root). Có thể tạo repo trắng trước. Không chép đè một `AGENTS.md` đã có mà chưa hợp nhất rule.
2. Điền các ô `TODO` tại `.agents/project/01-product-context.md` và quyết định tùy chọn trong `.agents/project/03-technology.md`.
3. Mở `prompts/01-bootstrap-with-codex.md`, gửi prompt đó cho agent có quyền đọc/ghi repo để yêu cầu **tạo source thực tế, chạy lệnh, viết test**.

```bash
# Đứng tại thư mục repository mới, sau khi giải nén bộ context:
python3 scripts/validate_agent_context.py
python3 scripts/select_worklogs.py --type coding --limit 3
```

## File nào làm nhiệm vụ gì?

- `AGENTS.md`: điểm vào **bắt buộc** cho agent.
- `.agents/AGENTS.md`: registry, trạng thái và thứ tự ưu tiên nguồn.
- `.agents/context-map.md`: đồ thị nạp context có chọn lọc.
- `.agents/project/`: rules kiến trúc, API, DB, security, testing, operations, conventions, workflows.
- `.agents/modules/`: quy ước module + template context một module.
- `.agents/worklog/`: history theo task, template nhật ký, cách preflight.
- `templates/`: cấu hình và contract **tham khảo**, không phải code triển khai đã được test.
- `prompts/`: prompt Codex để bootstrap, implement API, fix bug, chuyển đổi repo cũ.
- `scripts/`: 2 tiện ích Python stdlib để chọn worklog + kiểm tra cấu trúc agent context.
- `FULL_CONTEXT.md` (tại thư mục chứa ZIP, hoặc đi cùng gói): phiên bản đọc liền toàn bộ context.

## Những gì được giữ lại và được cải tiến

**Giữ từ Study Server:** FastAPI; Python typed; chia tầng `models.py -> validate.py -> query.py -> view.py -> router`; Session theo request; transaction thuộc use case; SQL bind parameters; JWT access + opaque refresh; Argon2id; shared response envelope + trace ID; tests, Ruff, mypy; worklog, evidence/state và coding workflow.

**Cải tiến đề xuất cho project mới (không khẳng định là runtime gốc):** `pydantic-settings` + env/secret manager; readiness **thực sự probe** DB và các dependency thiết yếu; Alembic migration quản lý được; cơ chế refresh rotation chống race; logging/metrics có kiểm soát, CI/CD, production hardening, phân biệt `sync`/`async` rõ ràng.

**Không sao chép:** bảng `users/courses` của Study2Work, API `/api/v1/auth/*`, role `STUDENT`, business code `DESIGN_*`, khóa JWT, DSN Neon, CORS domain, `DB_SCHEMA`, tài liệu UC/AC/DD đặc thù, 160 tests hay tuyên bố runtime `VERIFIED` của dự án cũ.

## Checklist sau khi tạo code mới

- Chạy được `uv sync`, `uv run ruff check .`, `uv run ruff format --check .`, `uv run mypy app`, `uv run pytest`.
- Endpoint OpenAPI và route thực có bằng chứng bằng test; readiness kiểm tra dependency theo quy ước mới.
- Database schema được quản lý bằng Alembic; migration ứng dụng được trên DB thử nghiệm từ trạng thái trống.
- Nghiệp vụ từ requirements của dự án mới; không dùng lại hardcoded API/domain của Study2Work.
- `python3 scripts/validate_agent_context.py` pass; log lại lệnh đã/không chạy.

## Phạm vi và an toàn

Đây là baseline để AI lập trình có kỷ luật, **không thay thế** threat modeling, review chuyên gia hoặc kiểm toán production. Các quy tắc được đưa ra theo ưu tiên: contract/requirements của **dự án mới** > source/test runtime của **dự án mới** > docs context mới > ví dụ trong gói.

---

# FILE: `AGENTS.md`

# Backend Agent Router — MANDATORY ENTRY

Dành cho AI coding agent làm việc trong **repository backend hiện tại**. Đừng tự mặc định đây là Study2Work.

## 0. Session preflight (bắt buộc, không bypass)

1. Đọc `AGENTS.md` (file này) -> `.agents/AGENTS.md` -> `.agents/context-map.md`.
2. Phân loại và ghi ngắn:
   ```yaml
   primary_task_type: coding | fix | docs | test | refactor | operations
   affected_modules: []
   cross_module_contracts: []
   requirement_source: "path / user request / ticket"
   ```
3. Chạy `python3 scripts/select_worklogs.py --type <primary_task_type> --limit 3`; **đọc thực sự** các log được chọn; nếu chưa có log thì ghi `shortage`, không bịa.
4. Đọc `.agents/project/INDEX.md`, rồi chỉ các file context liên quan đến task.
5. Trước sửa code, đọc source + tests + config + schema/migrations có liên quan trong repo hiện tại.

## 1. Source-of-truth order

1. Yêu cầu mới nhất của user, đã làm rõ business behavior và acceptance criteria.
2. Canonical API/domain contract **đã phê duyệt của dự án mới**.
3. Current implementation + verified runnable tests + executable config/schema.
4. Context `.agents/` của **dự án mới**.
5. Template/best practice chung.

Phải tách `EXPECTED_BEHAVIOR` vs `CURRENT_BEHAVIOR`. Khi lệch: ghi `DISCREPANCY`, không âm thầm thay contract hoặc khẳng định source là chuẩn.

## 2. Coding rules — MUST

- `app/main.py` compose FastAPI; router chỉ parse/request/DI; business ở `view.py`; parameterized SQL ở `query.py`; Pydantic contract ở `models.py`; `validate.py` chỉ chứa pure special rules.
- Các helper `core/` là infrastructure shared; helper `utils/` chỉ pure/reusable; external integration ở `services/`.
- Không tự sáng tác field/table/endpoint/role/business rule/HTTP status. Thiếu evidence: đề xuất rõ `ASSUMPTION` và ưu tiên yêu cầu/contract trước coding.
- Truy dấu: caller -> callee -> DB/external side effect -> response -> tests trước khi sửa một function có ảnh hưởng.
- Mọi truy vấn DB bind parameters. Không nối SQL từ request. Identifier động chỉ từ allowlist hoặc SQLAlchemy constructs an toàn.
- Session thuộc request/unit of work; **một owner của commit/rollback** trong use case. Helpers không commit.
- Thực thi authentication/authorization phía server; không dựa vào ẩn nút trên UI. Không ghi log secret/PII/sensitive bodies.
- Giữ nhất quán `success, businessCode, message, data, meta, traceId`; propagate `X-Trace-Id`; không rò internal exceptions.
- Thêm regression/happy-path/negative tests đúng mức; không sửa test chỉ để hợp thức hóa bug.
- Smallest necessary diff, không refactor scope khác; không thêm dependency khi chưa có lý do, license/safety review.
- API-facing handler có header comment ngắn `# API <method> <path>` ngay trước function nếu team đã chọn convention; comments theo *current behavior*, không tự sửa DD bằng comment.

## 3. Output contract của mỗi task

```text
SCOPE: ...
EVIDENCE_READ: ...
EXPECTED_BEHAVIOR: ...
CURRENT_BEHAVIOR: ...
CHANGE: ...
TESTS_RUN: <lệnh + pass/fail/not-run>
DISCREPANCIES/BLOCKERS: ...
CONTEXT_UPDATED: ...
HANDOFF: ...
```

Tạo/cập nhật `.agents/worklog/YYYY-MM-DD/<task-slug>.md`, bám `.agents/worklog/TEMPLATE.md`.

## 4. Finish gate

- Focused tests -> broader affected suite -> linter/formatter/type checker -> check security/schema/contract -> context validator.
- Không tuyên bố `VERIFIED` nếu chưa chạy kiểm tra hoặc không có bằng chứng quan sát được.
- Với changes ở architecture/schema/API/auth/dependency, cập nhật đúng page `.agents/project/` hoặc `.agents/modules/` cùng PR.
- Chạy `python3 scripts/validate_agent_context.py` sau khi chỉnh context.
- Không tự deploy, chạy migration production, xóa dữ liệu, rotation secret hay thay settings production nếu chưa được ủy quyền cụ thể.

---

# FILE: `.agents/AGENTS.md`

# Agent Context Registry

**Bộ này là quy tắc khởi tạo; mọi trạng thái dự án sau đây phải được đo/ghi bằng nguồn mới.**

## Vocabulary

| State | Diễn giải |
|---|---|
| `VERIFIED` | Đã kiểm tra bằng source và lệnh thực chạy tương ứng. |
| `SOURCE_BACKED` | Đã đọc source; chưa mặc nhiên suy ra runtime/test pass. |
| `EXPECTED_BEHAVIOR` | Nguồn requirement/contract được duyệt. |
| `CURRENT_BEHAVIOR` | Hành vi chứng minh được bằng code/test/config. |
| `UNWIRED` | Code có nhưng không được import/compose/call. |
| `NOT_FOUND` | Không có nguồn hoặc artifact yêu cầu. |
| `DECLARED_NOT_RUNNABLE` | Có declaration nhưng không chạy được. |
| `DISCREPANCY` | Expected và Current không giống nhau. |
| `BLOCKED` | Thiếu dependency, quyền, source, hoặc tool để xác minh. |
| `ASSUMPTION` | Giả định tạm, phải ghi và cần confirm trước khi quyết định nguy hiểm. |

## Navigation

- `.agents/context-map.md` — các topic context và luồng nạp.
- `.agents/project/INDEX.md` — index scope backend.
- `.agents/modules/README.md` — quy ước module.
- `.agents/modules/TEMPLATE.md` — template module context.
- `.agents/worklog/README.md` — audit trail cho mỗi task.
- `prompts/` — prompt điều khiển agent, **không** phải source-of-truth cao hơn current repo.

## Contract boundary

Không đem SQL, roles, database schema, URL, JWT keys, business codes hoặc DD/UC/AC từ Study2Work sang dự án mới. API mới bắt đầu bằng **contract do dự án mới xác định**. Chỉ sao chép framework/conventions đã lựa chọn sau khi đối chiếu tình hình hiện tại.

## Design choices

Sync SQLAlchemy mặc định cho logic CRUD thông thường; nếu cần async end-to-end thì thống nhất session/driver/query/api async một cách chủ ý, **không trộn blocking DB trong async handler**. Theo dõi lựa chọn thay đổi trong `.agents/project/03-technology.md` và ADR.

---

# FILE: `.agents/context-map.md`

# Agent Context Map

```text
AGENTS.md
  └─ .agents/AGENTS.md
      └─ .agents/context-map.md
          ├─ preflight: scripts/select_worklogs.py -> .agents/worklog/
          ├─ .agents/project/INDEX.md
          │   ├─ 01-product-context.md   (requirements, actors, scope)
          │   ├─ 02-architecture.md      (code ownership, DI)
          │   ├─ 03-technology.md        (stack/decision matrix)
          │   ├─ 04-coding-conventions.md
          │   ├─ 05-api-contract.md
          │   ├─ 06-validation.md
          │   ├─ 07-database.md
          │   ├─ 08-auth-security.md
          │   ├─ 09-error-observability.md
          │   ├─ 10-testing.md
          │   ├─ 11-devops-operations.md
          │   ├─ 12-task-workflows.md
          │   └─ 13-decisions.md
          ├─ .agents/modules/README.md -> TEMPLATE.md -> module doc
          └─ exact code + schema + config + tests + worklog
```

## Router by task

| Task | Context pages | Verify |
|---|---|---|
| Add endpoint | 01, 02, 04, 05, 06, 07, 10, 12 | HTTP, schema, auth, transaction |
| Auth / RBAC | 05, 06, 08, 09, 10 | token/session, 401/403, role/ownership |
| DB/migration | 02, 07, 10, 11 | migrate up/down or rollback plan, indexes |
| Fix bug | 02, 04, 09, 10, 12 | failing reproduction then regression |
| API integration | 05, 09, 11, 12 | producer/consumer and contract tests |
| Release/operations | 03, 08, 09, 10, 11 | backup, health, rollback, monitoring |
| Documentation | 01, 02, 05, 12, source/tests | source-backed statuses |

## Guardrails

Load progressively: read the minimum needed for the task, then follow dependencies. Cross-module concerns must identify producer, consumer, version and failure mode. `scripts/validate_agent_context.py` validates references, not code runtime.

---

# FILE: `.agents/modules/README.md`

# Business Module Context Registry

Create one `.agents/modules/<feature>.md` (copy `TEMPLATE.md`) when a business feature is approved/implemented.

## Responsibility map

```text
app/modules/<bounded_context>/<feature>/
    models.py     -> pure transport DTO/contracts
    validate.py   -> pure special contract validation (optional)
    query.py      -> bound SQL/DB helpers; never commit (optional)
    view.py       -> business orchestration & transaction owner
```

`app/api/v1.py` imports only exposed `view` function and request models. Bounded contexts can be nested by product domain; do not force `guest` or `student` namespaces from Study2Work.

## Module checklist

- Public function/route + HTTP contract
- Input fields and strict type/normalization
- Auth/ownership checks and business invariants
- SQL queries, indexes, affected tables, DB migrations
- External side effects, timeout/retry/idempotency
- Transaction ownership, rollback, concurrency behavior
- Response projection, business code and trace
- Happy/negative/integration tests
- Status + evidence links

Module context is a **navigation map**, not proof of implementation. Source + verified tests take precedence.

---

# FILE: `.agents/modules/TEMPLATE.md`

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

---

# FILE: `.agents/project/01-product-context.md`

# Product Context — Điền trước khi Codex viết code

> `PROJECT_STATUS: TEMPLATE_UNFILLED`. Không tạo schema/business rule khi TODO chưa được xác nhận.

## Metadata

- Project name: `TODO_PROJECT_NAME`
- Product vision/problem: `TODO_PRODUCT_GOAL`
- Runtime deployment type: `TODO_API_ONLY | API_AND_WORKERS | MODULAR_MONOLITH`
- Stakeholders/actors: `TODO_ACTORS`
- Target regions/privacy requirements: `TODO_REGION_COMPLIANCE`
- Nonfunctional priorities (latency, throughput, uptime, budget): `TODO_NFR`

## Actors / authorization

| Actor | Trust boundary | Rights | Forbidden actions |
|---|---|---|---|
| TODO | TODO | TODO | TODO |

## Business modules

| Module | Owner | Inputs | Outputs | DB tables | External deps | Status |
|---|---|---|---|---|---|---|
| TODO | TODO | TODO | TODO | TODO | TODO | `NOT_FOUND` |

## In/out of scope

- MVP scope: TODO
- Out of scope: TODO
- Data retention/deletion: TODO
- Regulatory/security constraints: TODO

## Contract sources

- `docs/contracts/*` hoặc API spec đã được duyệt: TODO
- Canonical schema/migrations source: TODO
- Ticket/AC/acceptance criteria: TODO

**Agent rule:** khi có yêu cầu làm nhanh nhưng thiếu chi tiết, tạo assumption minh bạch; tránh quyết định khó đảo ngược, đặc biệt schema, finance, auth, privacy. Không clone những business modules của Study2Work.

---

# FILE: `.agents/project/02-architecture.md`

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

---

# FILE: `.agents/project/03-technology.md`

# Technology Baseline & Decision Matrix

## Mặc định

| Area | Choice | Tại sao | Có thể thay? |
|---|---|---|---|
| Language | Python >=3.12 | typing / ecosystem | Có, ADR |
| API | FastAPI | routing + DI + OpenAPI | Có, ADR |
| Contracts | Pydantic v2 | input & output types | Có, ADR |
| Database | PostgreSQL | ACID, indexes, constraints | Có, ADR |
| DB toolkit | SQLAlchemy 2.x sync + psycopg 3 | explicit transactions; Study-derived style | Có, chọn đồng bộ/async chủ ý |
| Migrations | Alembic | versioned schema | Nên giữ nếu dùng SQLAlchemy |
| Env/config | pydantic-settings + secret store | no hardcoded secrets | Có equivalent |
| Hashing | Argon2id | password storage | Nên giữ hoặc audited alternative |
| JWT | PyJWT[crypto], ES256 khi có key management | verify iss/aud/exp | Có với threat model |
| Dependency management | uv + uv.lock | reproducible | Có |
| Unit/integration | pytest + HTTPX | fast and request tests | Có |
| Static quality | Ruff + mypy(strict) | maintainability | Có |
| Container | Docker | consistent runtime | Tùy deployment |

## Tùy chọn, chỉ thêm khi có use case

- **Redis**: cache, rate limit, pub/sub (không mặc định đảm bảo durable processing).
- **Object storage S3/MinIO**: media/upload; presigned URL, scanning, retention.
- **Queue/worker**: Celery/RQ/Arq/other khi có jobs/retries cần durability.
- **HTTPX**: outbound external APIs, explicit timeout/retry/idempotency.
- **OpenTelemetry**: distributed traces/metrics khi operations cần.
- **Ollama/LLM**: tích hợp riêng service adapter, không mặc định chạy trong request path.

## Phải quyết định từ đầu

1. `DB_EXECUTION`: `SYNC` (default) hoặc `ASYNC` end-to-end; không trộn tùy hứng.
2. `DEPLOYMENT`: standalone / containers / Kubernetes; tác động health, config, shutdown.
3. `AUTH`: first-party JWT vs OIDC provider; claims/role policy và revoke semantics.
4. `TENANCY`: none / shared-db tenant key / isolated schemas/DB; ảnh hưởng mọi query.
5. `MIGRATION_OWNER`: migration pipeline, rollback strategy, seed và schema versioning.
6. `LOG_PRIVACY`: data classification, retention, audit and PII redaction.
7. `PERFORMANCE_SLO`: actual p95/p99 throughput goals; measurement first.

## Versions

Không freeze bừa phiên bản 'mới nhất' từ context. Khi bootstrap, agent đọc Python/runtime target rồi giải quyết phiên bản package **tương thích thực tế**, sinh `uv.lock`, chạy test và security dependency scan. `templates/pyproject.toml.example` chỉ là hướng dẫn.

---

# FILE: `.agents/project/04-coding-conventions.md`

# Coding Rules — Python Backend

## Style

- UTF-8, LF, final newline, no trailing spaces, Python indent 4.
- `snake_case` modules/functions/variables; `PascalCase` classes/Pydantic; `UPPER_SNAKE_CASE` constants.
- Type hints trên public APIs và nontrivial helpers; `mypy --strict` cho new code; tránh `Any` lan rộng.
- Ruff `E,F,I,B,UP,SIM`; line-length 100; double quotes; import sort tự động nhưng không sửa file ngoài scope.
- Constructor/DI rõ ràng; không tạo hidden global mutable state; lazy settings/factories được kiểm soát.
- Nếu SQL viết bằng text(), luôn đặt named parameters và type-safe outputs; không lắp chuỗi SQL từ input.
- Một function giải quyết một trách nhiệm. Chỉ tách abstractions khi mang lại lợi ích thực, tránh `ServiceFactoryManager` không cần thiết.

## Module 4-layer convention

| File | Allowed | Forbidden |
|---|---|---|
| `models.py` | Pydantic fields, validators pure, serialization | DB lookup, external calls |
| `validate.py` | named pure special business-format checks | SQL, time-dependent calls, `ApiError` HTTP effects |
| `query.py` | SQL constants/query functions, query results | `commit`, HTTP response, auth decisions |
| `view.py` | orchestration, authZ, errors, transactions | defining raw request schema, concatenating unsafe SQL |
| `api/v1.py` | route/DI/body/header/query binding | core business flow, DB SQL |

- Shared pure validations nằm ở `app/utils/validate.py`; giữ module-specific tại module trừ khi thực sự reuse.
- `models.py` là tên canonical cho dự án mới; không trộn `model.py` hoặc `schema.py` tùy từng module.
- Không invent rule email domain, password format, case-folding name, status defaults nếu contract không có.

## Comments, errors và naming

- Module/service docstrings mô tả intent/side effects/contract; comment chỉ cho logic khó hiểu hoặc business reason.
- Nếu team giữ API header: `# API POST /api/v1/example` ngay trên handler; không gắn cho helper.
- Không dùng catch-all `except Exception` sâu trong domain để giấu bug; chỉ error boundary xử lý lỗi không xác định.
- Không dùng `assert` làm user validation, không bỏ qua exception, không log password/token/raw email/body mặc định.
- APIs mới tuân `contracts` trong repo mới; tránh hardcode business-code prefix `DESIGN_` từ Study2Work.

## PR hygiene

- Diff tối thiểu, độc lập; không sửa whitespace toàn repo; tests cập nhật theo feature.
- Schema/API breaking change phải có rollout, migration/backward compatibility/documentation.
- Không commit generated caches (`__pycache__`, `.venv`, `.pytest_cache`, `.mypy_cache`), credentials, `.env`, DB dumps, log sensitive.

---

# FILE: `.agents/project/05-api-contract.md`

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

---

# FILE: `.agents/project/06-validation.md`

# Validation Strategy

## 4 validation levels

1. **Transport parsing** (FastAPI): header/query/path/body, type, missing fields -> 422/400.
2. **Basic DTO validation** (`models.py`): `EmailStr`, length/range, accepted enums, normalization thuần.
3. **Special pure rules** (`validate.py`): các quy tắc contract rõ ràng (prefix/regex/format). Trả `ValueError`/typed domain validation, không DB/IO/time/log.
4. **DB-backed business validation** (`view.py` + `query.py`): uniqueness, status, permissions, ownership, resource existence, state machine. Bảo vệ bằng DB constraint khi có race.

## Examples

| Rule | Correct home |
|---|---|
| `email` must be valid; trim surrounding whitespace | `models.py` + pure utils |
| Password must not be blank | `models.py` |
| Membership number has business prefix | `validate.py` **only if contract states** |
| Email already registered | `view.py` + database unique constraint |
| Actor owns resource | `view.py` + scoped SQL condition |
| Allowed status transition | `view.py` (state machine/domain service) |
| SQL query binds user-supplied values | `query.py` |

## Pitfalls

- Không gán mọi exception thành 422. Phân biệt invalid request vs internal/dependency failure.
- Nếu normalization mang nghĩa nghiệp vụ (email case insensitive, Unicode normalization), phải xác nhận contract trước; không thay password/case of other identifiers.
- Không gọi network/DB trong Pydantic validator.
- Không tạo duplicate uniqueness check chỉ ở app mà thiếu unique constraint/index; xử lý `IntegrityError` race an toàn.
- Validate cả response domain contract khi cần, không truyền thẳng row chưa lọc.
- Không viết test bẻ cong requirement cho vừa code.

---

# FILE: `.agents/project/07-database.md`

# Database, Queries, Transactions & Migrations

## Session / unit of work

- Baseline: SQLAlchemy 2.x **synchronous** Engine + `sessionmaker(autoflush=False, expire_on_commit=False)`.
- `get_db()` tạo 1 Session per request, đóng ở `finally`.
- `query.py` dùng Session từ caller; `execute_query/query_one/query_many` **không gọi commit**.
- `view.py`/use-case chịu trách nhiệm `commit()` sau khi toàn bộ business invariants thỏa; `rollback()` khi lỗi. Có thể dùng `with db.begin():` theo convention thống nhất.
- Không giữ transaction lâu trong lúc gọi provider HTTP, xử lý AI hoặc upload; cân nhắc outbox/saga khi cross-system cần độ bền.
- `pool_pre_ping`, pool sizing, statement timeout, connection disposal theo môi trường. Không tự áp `search_path` nếu driver/pooler không hỗ trợ; xác minh schema thực tế.

## SQL

```python
# query.py — chỉ ví dụ, không phải schema thật của project
from sqlalchemy import text
from sqlalchemy.orm import Session

def get_widget_by_id(db: Session, widget_id: int):
    result = db.execute(
        text("SELECT id, name FROM widgets WHERE id = :widget_id"),
        {"widget_id": widget_id},
    )
    row = result.mappings().first()
    return dict(row) if row is not None else None
```

- SQL bind values; **không** f-string user input vào SQL text. For sort/column/table names use explicit allowlist / SQLAlchemy identifiers (không thể param identifiers).
- DB constraints: PK/FK/unique/check/NOT NULL/index; don't rely on Pydantic for persistence integrity.
- Truy vấn theo tenant/owner nếu app có tenancy; phải được enforce ngay SQL/transaction; audit các route.
- Tối ưu sau khi đo: EXPLAIN ANALYZE, índices theo predicate+join, keyset pagination nếu cần, tránh N+1, không select `*` dữ liệu nhạy cảm.

## Migration protocol (cho repo mới)

1. Mỗi schema change cần migration versioned và reviewable trong `migrations/versions/`.
2. Thử migrate DB disposable **từ rỗng**; với DB chứa data thử upgrade + backup/rollback/restore plan.
3. Destructive change dùng expand -> backfill -> contract, tránh drop columns đang chạy.
4. Không tự chạy migration trên production; xác nhận backup, rollout plan và owner.
5. Seed/test data tách khỏi migration schema; tuyệt đối không đưa credential thực vào seed.
6. Contract schema live chỉ VERIFIED sau khi query metadata/migrations (authorized, read-only), không suy luận từ DDL file.

## Transaction & concurrency

- Unique conflict: app precheck giúp UX nhưng unique index là nguồn bảo vệ thực; map race `IntegrityError` -> 409 có kiểm soát.
- Multi-step writes atomic trong cùng DB transaction.
- Refresh token rotation dùng conditional update/row lock hoặc compare-and-swap + insert dưới cùng transaction; có test concurrent replay.
- Khi cần distributed idempotency, đảm bảo database uniqueness + atomic state transition.

## SQLAlchemy sync vs async

Nếu `SYNC`: dùng `def` route handlers hoặc chạy blocking work trong threadpool có quản lý. Nếu `ASYNC`: async driver, AsyncSession, await I/O xuyên suốt, và ghi ADR. Không `await` query của sync Session và không trực tiếp block event loop trong `async def`.

---

# FILE: `.agents/project/08-auth-security.md`

# Authentication, Authorization & Security Baseline

## AuthN

- Password new hash: Argon2id; legacy bcrypt verification chỉ khi migration được phép. Không mã hóa reversible để lưu password.
- Access token JWT ngắn hạn, signed với algorithm allowlist; kiểm `exp`, `iat`, `iss`, `aud`, `sub`, `type`, `jti`, key rotation. Chỉ thêm `roles` khi business model đã xác nhận.
- ES256 có private/public key an toàn và rotation phù hợp; OIDC/JWKS nếu external identity provider. Không dùng client-chosen algorithm.
- Refresh token opaque random (cryptographically secure), lưu **HMAC hash** với pepper lấy từ secret manager; chỉ đưa raw token cho client lúc cấp.
- Rotation/revoke phải atomic; expired/replayed/revoked trả 401 an toàn, tránh lộ token trong log.
- Với browser cookies: quyết định Secure+HttpOnly+SameSite+CSRF defense; Bearer API khác cookie sessions, không kết hợp tùy hứng.

## AuthZ

- Authorization hoàn toàn server side. Kiểm role/scope và **resource ownership/tenant** trên từng protected operation.
- `401` nếu chưa xác thực; `403` nếu đã xác thực nhưng thiếu quyền. Trả 404 thay vì 403 để tránh resource enumeration khi policy đã quy định.
- Least privilege ở DB/user/service accounts; chỉ data tối thiểu và short lived credentials.
- Guard toàn bộ resource IDOR/BOLA: user không thể đổi path ID để truy cập đối tượng của người khác.

## Service protection

- CORS explicit allowlist, không `*` với credentials; HTTPS/TLS cho public traffic; secret rotation và least privilege.
- Rate limits cho login/register/refresh/password reset/upload; anti-bruteforce strategy không chặn nhầm user vô thời hạn.
- Validate uploads: type/signature, size, malware scanning khi phù hợp; không dùng filename nguyên bản làm path.
- SSRF: outbound URL allowlist/network egress policy; HTTPX timeouts, max redirects.
- SQL injection: bind parameters, fixed SQL identifiers; chống mass assignment/overposting bằng typed response/request models.
- Không log Authorization, tokens, passwords, DSN, private keys, sensitive bodies, full SQL params, PII trừ khi đã có chính sách xử lý dữ liệu.
- Cấu hình qua environment/secret manager và `SecretStr` hoặc equivalent; `.env.example` placeholders, `.env` gitignored; production config validate fail-fast.

## Security validation & review

- Authentication error paths + refresh replay tests + role/tenant isolation + injection/invalid enum + bad cookie/header + secret scan.
- Audit log cho high-impact actions (admin, credential, payment) nhưng chỉ lưu metadata tối thiểu.
- Dependency audit và SBOM khi release; threat model theo feature. `pydantic` không thay thế ownership check, DB constraints hoặc rate limits.
- Production credentials không được copy từ project gốc, local `.env` hoặc từ session logs vào agent output.

---

# FILE: `.agents/project/09-error-observability.md`

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

---

# FILE: `.agents/project/10-testing.md`

# Testing & Quality Gates

## Pyramid

1. **Unit:** pure `validate.py`, normalization, response, security token helpers, domain-state rules.
2. **Module/service:** view orchestration với fake DB/providers; test commit/rollback/error mapping.
3. **API HTTP:** `TestClient`/HTTPX, real FastAPI composition, status/envelope/trace/auth/Pydantic errors.
4. **DB integration:** disposable PostgreSQL (Docker/Testcontainers/CI service), migration up, constraints, transactions, tenant scoping, query correctness.
5. **Smoke:** startup, live, real ready probe, one representative route, resource cleanup.

## Mandatory scenarios per endpoint

- Happy path; missing fields/type/length/format; invalid pagination/sort/filter.
- Missing/expired/malformed token, wrong role, cross-user/tenant resource.
- Not found, duplicate conflict, invalid state transition, concurrency race where applicable.
- DB down/timeout, provider failure, rollback, double-submit and idempotency where applicable.
- No secrets/PII leak in response/log; `traceId` and `X-Trace-Id` consistent.
- Result mapping only safe fields, contract stable; ensure real HTTP status.

## Commands

```bash
uv sync
uv run ruff check .
uv run ruff format --check .
uv run mypy app
uv run pytest -q
python3 scripts/validate_agent_context.py
```

- Run a single test file while iterating; full affected suite then full suite as available.
- Unit tests không thay thế actual DB/migration integration tests.
- Test fixture uses fake secrets and isolated DB; NEVER production DB. Disallow external network by default in tests; explicit opt-in smoke only.
- `pytest` pass không đủ chứng minh toàn production; ghi coverage limitations và non-executed checks.

## Evidence categories

- `VERIFIED`: command run in current checkout, record command+exit+date/commit.
- `NOT_RUN`: not executed; **không** đồng nghĩa pass.
- `BLOCKED`: dependency/tool/DB unavailable.
- `DECLARED_NOT_RUNNABLE`: test declared nhưng syntax/deps/import ngăn chạy.

## CI minimum

1. dependency/lock install;
2. formatting/lint/typecheck;
3. unit/API tests;
4. PostgreSQL integration + migration validation;
5. vulnerability and secret scans;
6. image/container smoke when applicable.

Không chạy production migration trong CI test job; unit/integration DB phải cô lập.

---

# FILE: `.agents/project/11-devops-operations.md`

# Configuration, Deployment & Operations

## Config

- New project default: `pydantic-settings` đọc environment variables; local `.env` chỉ khi developer chọn và được gitignore. `.env.example` toàn placeholder.
- Secrets qua runtime env/secret manager, KHÔNG nằm trong Git tracked constants. Secrets typed with `SecretStr`, không log hoặc dump config.
- Bắt buộc tách `local`, `test`, `staging`, `production`; fail-fast khi thiếu signing key/DB URL ở production.
- `DATABASE_URL`, JWT secret/key, refresh pepper và credentials phải là per environment; rotate procedure documented.

## Runtime

- Uvicorn/Gunicorn workers cấu hình theo benchmark, không cố định số lượng từ template.
- Reverse proxy/ingress terminate HTTPS, enforce trusted proxy headers only for trusted hops; restrict docs in production theo policy.
- Docker multi-stage/minimal non-root image, pinned lockfile, resource limits, graceful shutdown, probes. Không bake `.env` vào image.
- DB pool size theo instance x worker count; tránh thổi quá connection limits của Neon/pooler.
- Redis/object storage/queue optional, chỉ provision khi sản phẩm cần.

## Delivery process

1. PR review + tests/scan pass.
2. Deploy to staging; migration safety check; backup/restore drill for destructive changes.
3. Canary/rolling release khi cần; monitor error rate/p95/DB health.
4. Rollback application path; database backward-compatible migration by expand/contract.
5. Incident playbook: service owner, alerts, logs/tracing, runbook and escalation.

## Security operations

- Never print token/private key/DSN; redact secrets from crash reporting/CI artifacts.
- RBAC on production dashboard/DB, least privilege service account; audit manual interventions.
- No direct prod DB writes, schema drops, destructive deployment or secret rotation without authorized change request.

## Readiness strategy

`/health/live` = app process is alive. `/health/ready` = app can serve requests dependent on essentials, e.g. DB SELECT 1 within bounded timeout. LLM/email providers should generally not block ready unless essential to the whole app; report them separately.

---

# FILE: `.agents/project/12-task-workflows.md`

# Agent Coding Workflows

## Common preflight

1. `AGENTS.md` -> context map -> worklog selector. Read selected logs before deep edit.
2. Identify `primary_task_type`, owner module, contract, affected DB/external interfaces.
3. Write down **expected** behavior (requirement/contract) and **current** behavior (source/test/observed runtime).
4. Trace `caller -> callee -> DB/provider side effect -> response -> tests`.
5. Define smallest scoped implementation and how to verify.

## Coding a new API

`requirements -> API contract -> model fields -> pure validations -> DB contract/migration -> SQL with bound params -> view with auth/business/txn -> router/DI -> tests -> docs/context/worklog`.

- For no database feature, omit `query.py` unless useful; don't create empty placeholders solely to match template.
- Response business code/status mapping must be agreed before implementation. If not agreed, write a proposal and mark `ASSUMPTION`.

## Fixing a bug

`reproduce failing case -> collect evidence -> trace root cause across layers -> smallest fix -> regression test -> full related tests -> context/log update`.

- Do not randomly catch exceptions to silence test. Don't weaken tests to make broken behavior pass.

## Refactoring

`baseline tests -> establish behavior to preserve -> incremental refactor -> verify no API/schema side effects -> update context if ownership changed`.

## Documentation

`current source -> live tests/config/migration -> approved requirements -> docs update`. Mark `SOURCE_BACKED`, `UNWIRED`, `DISCREPANCY` truthfully.

## Delivery / release

`review -> lint/typecheck/test -> DB migration dry run -> security scan -> stage verify -> rollback preparation -> deploy only with authorization -> monitor`.

## Required final handoff

```text
SCOPE:
REQUIREMENT/CONTRACT:
CURRENT SOURCE:
FILES CHANGED:
IMPACTED INTERFACES:
VERIFICATION (exact commands + outcomes):
DISCREPANCIES/ASSUMPTIONS:
CONTEXT/WORKLOG UPDATED:
REMAINING BLOCKERS:
```

Never claim tests passed if commands weren't run. Context validator checks docs wiring only, not backend correctness.

---

# FILE: `.agents/project/13-decisions.md`

# Decisions, Tradeoffs & Deviations

## Defaults (not immutable)

| ADR | Default | Status | Reason |
|---|---|---|---|
| ADR-000 | Modular monolith | `PROPOSED` | Keep deploy/ownership simple until measured needs |
| ADR-001 | FastAPI + Python 3.12+ | `PROPOSED` | Study-derived stack |
| ADR-002 | PostgreSQL + SQLAlchemy sync | `PROPOSED` | Explicit transaction model |
| ADR-003 | `models/validate/query/view` | `PROPOSED` | Easy code ownership and agent navigation |
| ADR-004 | Pydantic Settings env/secrets | `PROPOSED` | Correct limitation of Study hardcoded constants |
| ADR-005 | JWT access + opaque refresh | `PROPOSED` | Conditional on authentication requirements |
| ADR-006 | JSON envelope + trace ID | `PROPOSED` | Stable client contract |

Copy `templates/adr-template.md` to `docs/adr/NNN-short-title.md` to accept/modify a decision.

## Approval criteria for deviations

- Requirement/performance/operational evidence, alternatives, security impact, migration impact.
- Update architecture/tech/context pages and tests in same PR.
- No hidden switch to async DB, Redis persistence, microservices, OAuth, or full ORM from raw SQL without explicit reasoning.

---

# FILE: `.agents/project/INDEX.md`

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

---

# FILE: `.agents/worklog/README.md`

# Worklogs for AI Coding Agents

Every task (`coding`, `fix`, `docs`, `test`, `refactor`, `operations`) writes `.agents/worklog/YYYY-MM-DD/<task-slug>.md` with the template below.

## Preflight

```bash
python3 scripts/select_worklogs.py --type coding --limit 3
```

Read selected worklogs **before editing**; the selector provides paths, not evidence read. If fewer than 3 matching logs exist, record shortage. Exact `primary_task_type` match; no substitution with other types. Avoid bloated logs: 1 useful handoff per task.

## Must record

- Prior logs read and learnings
- Expected/current behavior and source
- Caller/callee/DB/provider/response/tests trace
- Changes, affected interfaces and assumptions
- Actual verification commands with `PASS|FAIL|NOT_RUN|BLOCKED`
- Context update, blockers and handoff

Do not store credentials, PII, raw secret-bearing logs or private payloads in worklogs.

---

# FILE: `.agents/worklog/TEMPLATE.md`

---
task_id: "YYYY-MM-DD-short-name"
date: "YYYY-MM-DD"
primary_task_type: "coding | fix | docs | test | refactor | operations"
affected_modules: []
cross_module_contracts: []
status: "PLANNED | IN_PROGRESS | VERIFIED | PARTIAL | BLOCKED"
---

# Worklog: <task title>

## PRIOR_WORKLOG_REVIEW

- selector_command:
- selected_paths_read:
- lessons_carried_forward:
- shortage:

## EXPECTED_BEHAVIOR

- Latest requirement:
- Approved contract/acceptance:

## CURRENT_BEHAVIOR

- Source/config/schema:
- Runnable tests:
- Live verification status:

## SOURCE_TRACE

```text
caller -> callee -> DB/external side effect -> response -> tests
```

## DISCREPANCY / UNWIRED / BLOCKED

| Item | Evidence | Status | Impact |
|---|---|---|---|
| | | | |

## CHANGES

- Files changed:
- Contract/API/schema impact:
- Context updated:
- Assumptions:

## VERIFICATION

| Command | Actual outcome | Status |
|---|---|---|
| | | `PASS | FAIL | NOT_RUN | BLOCKED` |

## HANDOFF

- Remaining blockers:
- Next action/owner:

---

# FILE: `REFERENCE_SOURCE.md`

# Provenance — Study2Work source vs reusable recommendations

**Source reference:** https://github.com/daovanhung-dev/Study2Work/tree/main (reviewed 2026-10-22). Do not assume HEAD has not changed; check current source when implementing.

## Source-backed patterns observed

- `AGENTS.md`, `.agents/AGENTS.md`, `.agents/context-map.md`: agent routing, exact scope reading, expected/current distinction, worklog preflight, no invented contracts.
- `.agents/server-study/AGENTS.md`, `.agents/server-study/INDEX.md`: Study FastAPI API scope, status vocabulary and tests context.
- `apps/study-server/app/main.py`, `app/api/v1.py`: composition root, trace middleware, thin router, DI and endpoints.
- `apps/study-server/app/modules/guest/api_01_auth_register/{models,query,view}.py`: 4-layer approach, duplicate checking, Argon2id, transaction in view.
- `apps/study-server/app/modules/guest/api_03_auth_login/{models,query,view}.py`: access/refresh flow and refresh session persistence.
- `apps/study-server/app/core/{database,responses,middleware}.py`: sync SQLAlchemy session, safe envelope, trace handling.
- `apps/study-server/app/core/security/{password,access_token,refresh_token}.py`: Argon2id, JWT, opaque HMAC refresh.
- `apps/study-server/pyproject.toml`: >=3.12, FastAPI, Pydantic, SQLAlchemy, Ruff, mypy strict, pytest.
- `.agents/worklog/{README,TEMPLATE}.md`, `.agents/project/{conventions,workflows}.md`: task evidence and trace/verification.

## Changes/strengthening intentionally made for a *new* project

- `pydantic-settings` env/secret handling instead of Study runtime's committed `app/core/constants.py` configuration.
- Real DB readiness probe (`SELECT 1` or DB health) instead of Study `database: configured` label.
- Enforced Alembic migrations & disposable DB tests rather than presuming source DDL is live.
- Standardized **error `data: null`** (Study runtime may return `{}`; intentionally choose one for new API).
- Production RBAC/IDOR/concurrent refresh/observability/CI/deployment requirements not necessarily present in Study code.
- Generic business codes (`RESOURCE_*`) instead of Study-specific `DESIGN_*`.

## Never migrate into a new project from source by default

- Existing business schema or module actors (`STUDENT`, `MENTOR`, classes, courses).
- Real database URL/Neon DSN/JWT signing keys/refresh pepper/email provider secrets.
- Live DB assumptions, original migration numbering, platform-specific loopback port 3003.
- Old backend-specific hardcoded constants, stale DD/OpenAPI, or claimed verification state.

---

# FILE: `prompts/01-bootstrap-with-codex.md`

# Prompt: Khởi tạo Backend mới từ Agent Context

Bạn là Senior Backend Architect + Senior Python/FastAPI Engineer. Làm việc **trực tiếp trong repository hiện tại**, không động chạm repository Study2Work.

1. Đọc `AGENTS.md`, `.agents/AGENTS.md`, `.agents/context-map.md`, toàn bộ `.agents/project/` và `.agents/modules/README.md` để hiểu guideline; đọc worklogs theo preflight.
2. Đọc `.agents/project/01-product-context.md` để lấy domain/actors/requirements. Nếu còn `TODO`, **không tự bịa nghiệp vụ**: bootstrap **core infrastructure và 1 endpoint generic health/hello**; tạo `docs/OPEN_DECISIONS.md` ghi các dữ kiện còn thiếu. Chỉ ask nếu không thể hoàn thành một hành động an toàn có ích.
3. Sử dụng modular-monolith FastAPI Python >=3.12, uv, Pydantic v2, PostgreSQL + SQLAlchemy 2 sync + psycopg 3, Alembic, Ruff, mypy strict, pytest; optional service chỉ khi cần. Tạo code hoàn chỉnh, không để placeholder import làm app lỗi.
4. Tạo `app/main.py:create_app`, core/config qua pydantic-settings env, database DI/session lifecycle, trace middleware, canonical response/error, `/health/live` và `/health/ready` (ready dùng bounded DB probe), structured safe logging.
5. Tạo minimal example `modules` theo 4-layer `models.py / validate.py? / query.py? / view.py`, **chỉ khi có feature contract**. Không import bảng/role/API từ Study2Work.
6. Cấu hình `.gitignore`, `.env.example` giả lập, `pyproject.toml`, `uv.lock`, Alembic migrations, Dockerfile production-safe, README commands. Không đưa secret vào code/fixtures/docs/log.
7. Tạo pytest tests cho create_app, errors/envelopes, trace, health live/ready mock DB, config validation; DB integration nếu có local PostgreSQL/CI. Tạo GitHub Actions CI hoặc pipeline tương ứng nếu repo có CI được xác nhận.
8. Chạy thực tế `uv sync`, `uv run ruff check .`, `uv run ruff format --check .`, `uv run mypy app`, `uv run pytest` và `python3 scripts/validate_agent_context.py`; fix lỗi trong scope, log chính xác command/outcome.
9. Ghi worklog và cập nhật context module khi triển khai. Cuối cùng trả lời: tree + decisions + các lệnh pass/fail/not-run + blockers + khuyến nghị tiếp theo.

Lưu ý: Không clone source secrets, không tự tạo tables/users/roles không có requirement, không triển khai feature business ngẫu nhiên. Không claim production-ready nếu chưa security/CI/integration review.

---

# FILE: `prompts/02-implement-api.md`

# Prompt: Implement một API theo Backend Rules

Task: `<DÁN REQUIREMENT / API CONTRACT / ACCEPTANCE CRITERIA Ở ĐÂY>`

Bạn là Senior Backend Engineer. Thực hiện trong repo hiện tại:

1. Theo `AGENTS.md` và worklog preflight. Xác định module owner, contract và expected/current.
2. Trace route -> model -> special validation -> view -> query -> schema/transaction/service -> response -> tests.
3. Nếu contract đủ, implement tối thiểu theo layer chuẩn; không viết SQL trong router, không DB IO trong validate; query bound parameters; view sở hữu transaction; authorization/ownership phía server.
4. Nếu cần schema: tạo/review Alembic migration, unique/FK/index, rollback strategy, test DB disposable. Không tự sửa production DB.
5. Giữ error envelope, trace ID, HTTP/business code theo contract; không leak secret.
6. Viết happy/422/401/403/404/409/500 hoặc 503 phù hợp, dependency failures/concurrency khi có; chạy focused + full suite + lint/typecheck.
7. Cập nhật context module và worklog. Báo `VERIFIED | NOT_RUN | BLOCKED` thành thật cùng file paths.

Không tự tạo nghiệp vụ ngoài requirement. Với lỗ hổng contract: ghi discrepancy/assumption trước.

---

# FILE: `prompts/03-fix-bug.md`

# Prompt: Diagnose and Fix Backend Bug

Bug description: `<PASTE LOG / REPRO STEPS / EXPECTED VS ACTUAL>`

1. Đọc `AGENTS.md`, context liên quan, worklog preflight cùng type `fix`.
2. Tạo failing test/repro case trước khi sửa (nếu khả thi).
3. Trace exact owner: client/HTTP -> router -> models/validate -> view -> query/DB/external -> response -> exceptions -> tests.
4. Tìm **root cause**, không 'fix' symptom bằng catch-all/bỏ validation/bỏ assertion.
5. Minimal patch only, giữ compatibility trừ khi ticket yêu cầu thay đổi.
6. Regression tests + affected suite + ruff/mypy; kiểm tra commit/rollback, auth, trace, errors và secrets.
7. Cập nhật worklog, context nếu semantic changed; cuối cùng mô tả root cause, patch, test evidence, unresolved risks.

---

# FILE: `prompts/04-adapt-existing-backend.md`

# Prompt: Áp dụng Agent Context vào backend đã tồn tại

Repository hiện có có thể **khác** chuẩn Study Server. Không rewrite toàn bộ chỉ vì template gợi ý.

1. Đọc `AGENTS.md`/context hiện tại; inventory file tree, stack, runtime, configs, tests, API contracts, DB migrations.
2. Lập matrix `CURRENT vs TARGET` cho routing, modules, validation, transactions, security, error contract, tests/CI.
3. Phân loại target: `ADOPT` (có giá trị), `ADAPT` (tương đương), `SKIP` (không phù hợp). Có ADR cho thay đổi lớn.
4. Chỉ tạo `.agents/project/` cần thiết, cập nhật theo source có thật; không bịa trạng thái VERIFIED, không triển khai placeholder.
5. Đề xuất lộ trình incremental, breaking API/schema rollout; không đổi sync sang async, raw SQL sang ORM, JWT sang OAuth tùy tiện.
6. Chỉ thực thi migration/refactor được yêu cầu; chạy tests trước/sau và bàn giao đầy đủ.

---

# FILE: `templates/adr-template.md`

# ADR NNN: <decision title>

- Date: YYYY-MM-DD
- Status: `PROPOSED | ACCEPTED | SUPERSEDED`
- Decision owner: TODO

## Context/problem

TODO

## Alternatives considered

1. TODO
2. TODO

## Decision

TODO

## Consequences

- Security:
- DB/API migration:
- Performance:
- Testing and operations:

## Evidence / links

- TODO

---

# FILE: `templates/api-contract-template.md`

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
