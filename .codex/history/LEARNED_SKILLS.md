# Learned Skills

Generated from the full worklog corpus. Read this after `.codex/AGENTS.md`.

## Canonical Work Types Seen

- docs-context - Context and docs update: 47 worklog(s)
- coding - Coding: 29 worklog(s)
- bugfix - Direct bugfix: 27 worklog(s)
- supabase-schema - Supabase schema and RLS: 18 worklog(s)
- test - Test and verification: 9 worklog(s)
- docs-dd - Design docs: 5 worklog(s)
- find-issues - Review and find issues: 3 worklog(s)
- fix-issues - Fix documented issue: 2 worklog(s)
- refactor-scaffold - Scaffold refactor: 2 worklog(s)
- create-todo - Create todo docs: 1 worklog(s)

## Frequent Modules

- unknown: 34
- .codex: 2
- docs/issues, docs/todo: 2
- authentication: 2
- docs/DD M01-M19: 2
- M15 ADMIN_DASHBOARD, M16 ADMIN_OPS: 2
- M05 AI / runtime configuration / onboarding: 2
- M05 AI / AI Chat / runtime configuration: 2
- UI / Theme / NabiCopy, toan bo app surfaces: 2
- M07 AI_CHAT / Sequential Voice Plus: 2
- Dashboard, AI service, lifestyle schedule: 1
- AI chat: 1

## Reusable Project Skills

- Route every task through one workflow in `.codex/workflows/`, one generated task-skill in `.codex/task-skills/`, and one primary domain in `.codex/domains/`.
- Treat reachable wiring as current behavior: one main, a composed user router, an Admin surface selected by backend access, and Sale/referral as an independent axis.
- For AI work, use the current Gemini REST/Dio clients, validate/normalize output, avoid real network calls in tests, and keep safe fallback behavior.
- For dashboard work, read real data through providers/repositories/datasources; do not add production mock data.
- For DD work, preserve IDs but separate implementation status from runtime/sandbox verification and cite reachable source.
- For issue/todo work, keep find issue, create issue, create todo, fix issue, and test as separate modes.
- For Supabase work, treat `01_build_system.sql` and `02_seed_data.sql` as the local/sandbox source of truth, and keep sandbox/staging behavior unverified until execution evidence exists.

## Command And Test Patterns

- Prefer targeted tests before full quick check.
- Docs-only tasks use source-truth/link checks and `git diff --check`; skip Flutter analyze/test unless Dart source or tests changed.
- Native commands in `.codex/tool/*.ps1` must run through `Invoke-NativeCommand` so non-zero exit codes fail the script.
- If Flutter/Dart tools are unavailable, record `UNVERIFIED`; never invent runtime evidence.

## Post-Session Self Optimization

- End every substantial session with a worklog self-review: output quality, task completion, verification strength, token efficiency, and next-session optimization.
- After writing the worklog, run the deterministic history refresh so `.codex/history/` and `.codex/task-skills/` learn from the session.
- Before starting a task, read the matching canonical `.codex/task-skills/<task-key>.md` after selecting the workflow.
