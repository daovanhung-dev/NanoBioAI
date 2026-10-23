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
