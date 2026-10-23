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
