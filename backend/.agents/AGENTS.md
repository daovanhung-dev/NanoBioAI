# NanoBioAI Backend Agent Context

This is the source of truth for the self-hosted FastAPI backend. It adapts the reusable backend context at `../docs/context/Backend_Agent_Context_Reusable/` to NanoBioAI. It does not inherit Study2Work schemas, credentials, or product rules.

## Current decisions

- Modular monolith: FastAPI, Python 3.12+, Pydantic v2, sync SQLAlchemy 2, psycopg 3 and Alembic.
- PostgreSQL is installed and managed on Ubuntu; the API is managed by systemd. Local file storage is protected by authenticated routes.
- Public routes use `/api/v1`; canonical envelope fields are `success`, `businessCode`, `message`, `data`, `meta`, `traceId`; errors carry `data: null`.
- Request trace header is `X-Trace-Id`. Settings and credentials come from process environment or a protected Ubuntu environment file.
- Auth is first-party Vietnam phone/password, Argon2id, signed access JWT and opaque rotating refresh token. Supabase account import and production cutover are separate tasks.
- Flutter, Admin Mobile, Admin Web, and the Early Access website use the versioned FastAPI API through `API_BASE_URL`. NanoBio Flutter text, JSON, streaming, health analysis, voice replies, and Food Scan use authenticated backend AI with no local inference fallback. Nabi ESP retains local Whisper speech recognition and offline TTS; generated replies use the backend.
- The former Supabase project and SQL contracts are archived under `docs/archive/legacy-supabase/`; do not deploy or run them. Port only behavior that still has an active caller.
- Code changes do not authorize production deployment, data import, write-freeze, or APK distribution unless the user explicitly includes those actions.

## Rules

1. Follow `project/INDEX.md`, this map, and one matching module note.
2. Keep routers thin; domain modules use `models.py`, optional `validate.py`, optional `query.py`, and `view.py` for business/transaction orchestration.
3. Query functions never commit. Use one DB session per request and explicit transaction boundaries in views.
4. Enforce account ownership and admin permissions server-side. Never trust client-provided user IDs for self-service actions.
5. Add versioned migrations and focused tests for persistence, security, and transaction behavior. Never seed real user data.
6. Keep current behavior claims source-backed; distinguish `NOT_FOUND`, `UNWIRED`, `DECLARED_NOT_RUNNABLE`, `BLOCKED` and `VERIFIED`.
7. Keep NanoBio worklogs in `../docs/worklog/`; after a worklog, refresh `.codex/history/` using the repository workflow.

## Source priority

Current NanoBio runtime source and executable backend/migrations/tests > `docs/archive/legacy-supabase/` historical contract > this context > reusable examples. Study2Work is an architectural style reference only.
