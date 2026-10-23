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
