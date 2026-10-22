# Backend Context Map

## Required for every backend task

1. `AGENTS.md` at repository root, then `backend/AGENTS.md`.
2. This map and `project/INDEX.md`.
3. `../docs/context/Backend_Agent_Context_Reusable/README.md` when changing the baseline or resolving reusable rules.
4. `project/01-product-context.md`, plus the smallest matching domain module note.
5. The active source, migration, tests, and the canonical NanoBio `docs/worklog` index.

## Routing

| Task | Read next |
|---|---|
| API or domain behavior | `project/02-architecture.md`, `project/05-api-contract.md`, matching module note, source function/call site |
| PostgreSQL or migration | `project/07-database.md`, relevant schema contract in `docs/supabase/01_build_system.sql`, migration and query code |
| Login, roles, tokens | `project/08-auth-security.md`, auth module and related Supabase function source |
| Runtime/Ubuntu | `project/11-devops-operations.md`, `.env.example`, systemd unit |
| Tests/quality | `project/06-validation.md`, `project/10-testing.md`, backend test config |

## Scope fence

Backend work lives under `backend/`; agent routing may be updated under `.codex/`; the canonical worklog is under `docs/worklog/`. Do not change `lib/`, `admin-web/`, `web/`, or import production data unless a later task explicitly expands scope.
