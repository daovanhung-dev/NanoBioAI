# Backend Task Workflow

1. Read this context map and the matching project/module context.
2. Trace the current caller to Supabase function/RPC/table/storage contract and tests/docs.
3. Record expected/current behavior separately; mark missing source `NOT_FOUND` rather than inventing rules.
4. Define route/schema/migration before implementation; keep router thin and business transaction in `view.py`.
5. Add focused tests, run backend quality commands, and report PostgreSQL-only checks accurately.
6. Update the canonical NanoBio `docs/worklog/` and refresh root `.codex/history/`.
7. Check final changed paths: app/web code and production data must remain untouched in this phase.
