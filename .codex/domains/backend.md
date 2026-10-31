# Domain - Self-hosted Backend

## Source

- `backend/AGENTS.md`
- `backend/.agents/context-map.md`
- `backend/src/nanobio_backend/`
- `backend/alembic/`
- `backend/tests/`
- `docs/archive/legacy-supabase/project/functions/` and `docs/archive/legacy-supabase/sql/` for source-backed contracts

## Rules

- Read backend context before implementation. Keep the modular FastAPI layers and sync SQLAlchemy/PostgreSQL choice.
- Backend changes do not authorize edits to Flutter, Admin Web, website source, production data, or deployment.
- Port only current-source Supabase behavior; retain explicit `NOT_FOUND` for source-less functions and disabled AI routes as accepted in backend decisions.
- Keep NanoBio worklogs in `docs/worklog/` and update root `.codex/history/` after them.
