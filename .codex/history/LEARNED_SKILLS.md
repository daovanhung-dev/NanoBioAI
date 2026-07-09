# Learned Skills

Generated from the full worklog corpus. Read this after `.codex/AGENTS.md`.

## Canonical Work Types Seen

- docs-context - Context and docs update: 18 worklog(s)
- coding - Coding: 17 worklog(s)
- supabase-schema - Supabase schema and RLS: 8 worklog(s)
- bugfix - Direct bugfix: 7 worklog(s)
- docs-dd - Design docs: 5 worklog(s)
- test - Test and verification: 2 worklog(s)
- find-issues - Review and find issues: 1 worklog(s)
- create-todo - Create todo docs: 1 worklog(s)
- fix-issues - Fix documented issue: 1 worklog(s)
- refactor-scaffold - Scaffold refactor: 1 worklog(s)

## Frequent Modules

- unknown: 6
- M15 ADMIN_DASHBOARD, M16 ADMIN_OPS: 2
- docs/issues, docs/todo: 2
- authentication: 2
- docs/DD M01-M19: 2
- .codex: 2
- M08 HEALTH_SCORE_HABITS.: 1
- .codex/skills/create-dd-from-bd, .agents/skills/create-dd-from-bd, docs/DD: 1
- M12 REFERRAL_DIRECT, M14 SALE_POINTS: 1
- M15 ADMIN_DASHBOARD, M16 ADMIN_OPS.: 1
- docs/checklist, .codex/workflows/coding.md, .codex/tools/update_worklog_learning.ps1: 1
- lib/sale_referral, lib/services/supabase/sale,: 1

## Reusable Project Skills

- Route every task through one workflow in `.codex/workflows/`, one generated task-skill in `.codex/task-skills/`, and one primary domain in `.codex/domains/`.
- For auth/access work, preserve v1 guest/basic, v2 authenticated free, v3 planned paid, and sale/referral as an independent axis.
- For AI work, validate/normalize output, avoid real Gemini calls in tests, keep fallback behavior, and log only safe summaries.
- For dashboard work, read real data through providers/repositories/datasources; do not add production mock data.
- For DD work, trace BD -> BR/AC/UC -> DD and keep open product decisions as `Status: Draft`.
- For issue/todo work, keep find issue, create issue, create todo, fix issue, and test as separate modes.
- For Supabase work, treat SQL files as drafts until sandbox/staging verification is recorded.

## Command And Test Patterns

- Prefer targeted tests before full quick check.
- Docs-only tasks use `rg` checks and `git diff --check`; skip Flutter analyze/test unless runtime code changes.
- Native commands in `.codex/tool/*.ps1` must run through `Invoke-NativeCommand` so non-zero exit codes fail the script.
- If Flutter/Dart tools time out, record the blocker and check stale `dart`/`flutter` processes instead of inventing results.

## Post-Session Self Optimization

- End every substantial session with a worklog self-review: output quality, task completion, verification strength, token efficiency, and next-session optimization.
- After writing the worklog, run the history refresh script so `.codex/history/` and `.codex/task-skills/` learn from the new session.
- Before starting a task, read the matching canonical `.codex/task-skills/<task-key>.md` after selecting the workflow.
