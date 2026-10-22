# Technology Decisions

| Area | Selected |
|---|---|
| Language/API | Python 3.12+, FastAPI, Pydantic v2 |
| Database | Local PostgreSQL on Ubuntu |
| DB access | SQLAlchemy 2 synchronous + psycopg 3 |
| Migration | Alembic |
| Config | pydantic-settings from environment / protected env file |
| Password | Argon2id |
| Session | JWT access + opaque rotating refresh token |
| Storage | configured local directory, served only through ownership-checked APIs |
| Dependency/quality | uv, Ruff, mypy, pytest, HTTPX |
| Runtime | systemd service; native PostgreSQL service |

Do not copy Study Server's hard-coded connection/JWT constants. Do not add Gemini, Redis, containers, or a worker queue without a concrete approved use case. Use UTC for persisted timestamps.
