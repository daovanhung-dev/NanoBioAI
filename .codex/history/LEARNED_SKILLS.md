# Learned Skills

Generated from the full worklog corpus. Read this after `.codex/AGENTS.md`.

## Canonical Work Types Seen

- docs-context - Context and docs update: 94 worklog(s)
- coding - Coding: 45 worklog(s)
- supabase-schema - Supabase schema and RLS: 42 worklog(s)
- bugfix - Direct bugfix: 38 worklog(s)
- test - Test and verification: 28 worklog(s)
- find-issues - Review and find issues: 10 worklog(s)
- docs-dd - Design docs: 6 worklog(s)
- fix-issues - Fix documented issue: 3 worklog(s)
- refactor-scaffold - Scaffold refactor: 2 worklog(s)
- create-todo - Create todo docs: 1 worklog(s)

## Frequent Modules

- unknown: 55
- catalog nabi_3000_mon_viet_moi.json.: 6
- M32 FITNESS_TRAINING: 5
- M31 SLEEP_SAFETY_MONITORING: 3
- M31 SLEEP_SAFETY_MONITORING.: 3
- M02 PERSONAL_SCHEDULE_AI, meal catalog.: 3
- catalog nabi_3000_mon_viet_moi.json và meal-plan UI.: 3
- catalog nabi_3000_mon_viet_moi.json và asset thực đơn.: 3
- .codex: 2
- docs/issues, docs/todo: 2
- authentication: 2
- docs/DD M01-M19: 2

## Reusable Project Skills

- Route every task through one workflow in `.codex/workflows/`, one generated task-skill in `.codex/task-skills/`, and one primary domain in `.codex/domains/`.
- Treat reachable wiring as current behavior: one main, a composed user router, an Admin surface selected by backend access, and Sale/referral as an independent axis.
- For AI work, use the provider-neutral local runtime, validate/normalize output, avoid model downloads in tests, and keep prompts/responses out of logs.
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
