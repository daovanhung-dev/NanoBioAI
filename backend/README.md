# NanoBioAI self-hosted backend

FastAPI modular monolith under `src/nanobio_backend`, using synchronous SQLAlchemy and PostgreSQL. Backend context is in `.agents/`; Supabase source contracts are mapped in `.agents/modules/README.md` and `contracts/`.

## Local development

```bash
cd backend
cp .env.example .env
# Set JWT_SECRET_KEY, RATE_LIMIT_HMAC_KEY, EARLY_ACCESS_PHONE_HMAC_KEY
# and DATABASE_URL to local-only values. Do not use production credentials.
uv sync --locked
uv run alembic upgrade head
uv run uvicorn nanobio_backend.main:app --reload --host 127.0.0.1 --port 8000
```

The default database URL points to a local PostgreSQL database. Fast unit/API tests use disposable SQLite by default. To run the suite against PostgreSQL, set `NANOBIO_TEST_DATABASE_URL` to a disposable loopback PostgreSQL database whose name contains `test`; the test fixture drops and recreates its tables. The first registration creates a new local account. Supabase accounts/data are not imported.

## Ubuntu native PostgreSQL and systemd outline

These are deployment instructions only; this task has not run them on a server.

1. Install PostgreSQL from Ubuntu packages and keep it bound to localhost or a private interface:

   ```bash
   sudo apt update
   sudo apt install postgresql postgresql-contrib
   sudo -u postgres psql
   ```

   In `psql`, create a dedicated non-superuser role and database. `\password` prompts
   without putting the password in shell history:

   ```sql
   CREATE ROLE nanobio_app LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
   \password nanobio_app
   CREATE DATABASE nanobio OWNER nanobio_app;
   \q
   ```

2. Install the backend at `/opt/nanobio/backend`, create a locked service account
   `nanobio-backend`, and provision writable uploads at
   `/var/lib/nanobio-backend/uploads`.
3. Create `/etc/nanobio-backend/backend.env` from `.env.example`. Set
   `DATABASE_URL` to `postgresql+psycopg://nanobio_app:<URL-encoded-password>@127.0.0.1:5432/nanobio`,
   generate fresh values for `JWT_SECRET_KEY`, `RATE_LIMIT_HMAC_KEY`, and
   `EARLY_ACCESS_PHONE_HMAC_KEY`, then set owner `root:nanobio-backend` and mode
   `0640`. Put manual payment prices and bank details in
   `MEMBERSHIP_PAYMENT_PRICES_JSON` and `MEMBERSHIP_PAYMENT_BANK_JSON`; do not
   copy the Supabase seed bank account. Keep provider credentials absent until
   that provider is intentionally enabled.
4. Run `uv sync --locked` and `uv run alembic upgrade head` as a release step
   under the service account. Install `systemd/nanobio-backend.service`, then
   `systemctl daemon-reload` and `systemctl enable --now nanobio-backend`.
5. Put a TLS reverse proxy in front of `127.0.0.1:8000`, restrict request sizes
   and origins, and set forwarded-header trust only for the proxy addresses.
   The API rate limiter uses the direct socket peer; it does not trust arbitrary
   `X-Forwarded-For` values.
6. Check `curl --fail http://127.0.0.1:8000/health/live` and
   `curl --fail http://127.0.0.1:8000/health/ready`; readiness runs `SELECT 1`
   against PostgreSQL.

This repository change does not run these installation, migration, deployment, or backup commands on a server.

## Backups

Use a dedicated PostgreSQL backup service and a `.pgpass` file with mode
`0600`, not a password in shell history or a command argument. Define a libpq
service named by `PGSERVICE`, then schedule `scripts/backup_postgres.sh`. It
creates a custom-format dump with owner-only permissions and retention; encrypt
and copy it off-host according to the deployment policy. Restore a recent dump
into a new isolated PostgreSQL database periodically before treating backup as
verified. Back up `/var/lib/nanobio-backend/uploads` under the same protection.

## API surface

- OpenAPI: `/openapi.json`; docs UI: `/docs`.
- Liveness/readiness: `/health/live`, `/health/ready`.
- API base: `/api/v1`.
- All JSON responses use the documented envelope; protected APIs use bearer access JWTs.
- FamilyPlus: `GET /family-plus/context`, `PUT /family-plus/group`,
  `PUT /family-plus/members`, and `DELETE /family-plus/members/{id}` require an
  active `family_plus` subscription and enforce owner-scoped subject access.
- Legacy AI generation endpoints remain disabled and do not call Gemini.

## Quality commands

```bash
uv sync --locked
uv run ruff check .
uv run ruff format --check .
uv run mypy src/nanobio_backend
uv run pytest
python3 scripts/validate_agent_context.py
```
