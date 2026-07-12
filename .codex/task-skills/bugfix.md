# Task Skill - Direct bugfix

- Canonical key: bugfix
- Workflow: .codex/workflows/bugfix.md
- Generated from 11 worklog(s).

## When To Read

- Historical task type: bugfix (8)
- Historical task type: fix (1)
- Historical task type: fix UI/copy (1)
- Historical task type: fix flow dữ liệu (1)

## Common Modules

- AI chat: 1
- Admin dashboard / Supabase RPC: 1
- Dashboard, Lifestyle Schedule, Meal Plan, Nutrition: 1
- M01 Onboarding, M05 AI, M11 FamilyPlus automated-only và: 1
- Nabi providers/UI, onboarding UI, shared Nabi widgets, release: 1
- config/env, app entrypoints, auth/AI env readers: 1
- lib/app_versions/v1/features/**/presentation: 1
- v1 dashboard daily score, v2 health_scoring placeholder, docs/worklog.: 1

## Work Pattern

- Start from the selected workflow, then this task skill, then one domain file.
- Prefer targeted `rg` and focused tests over broad reads/checks.
- Record exact evidence in the worklog and add the self-review section.
- Ask before expanding scope when BD/DD, issue/todo, or product decisions are missing.

## Token Optimization

- Ask: how can this task use fewer tokens while producing equal or better work?
- Read index/summary files before raw historical files.
- Stop reading when root cause, target files, and validation path are clear.
- Update this generated skill through the history refresh script, not by hand.

## Source Worklogs

- [Worklog - AI chat retry](../../docs/worklog/2026-06-19/003-worklog-ai-chat-retry.md) - AI chat
- [Worklog - Nabihóa copy UI](../../docs/worklog/2026-06-19/004-worklog-ui-nami-copy-polish.md) - lib/app_versions/v1/features/**/presentation
- [Worklog - Đồng bộ lịch trình và thực đơn sau khi tạo dữ liệu mới](../../docs/worklog/2026-06-19/005-worklog-generated-plan-refresh.md) - Dashboard, Lifestyle Schedule, Meal Plan, Nutrition
- [Worklog - Fix module flow P0](../../docs/worklog/2026-06-22/007-worklog-fix-module-flow.md) - v1 onboarding, generated plan service, v1/v2 router gate, v2 cloud sync test, docs/worklog.
- [Worklog - Fix health scoring zero flow](../../docs/worklog/2026-06-22/008-worklog-fix-health-scoring-flow.md) - v1 dashboard daily score, v2 health_scoring placeholder, docs/worklog.
- [Worklog - Admin dashboard login blocker](../../docs/worklog/2026-06-29/006-worklog-admin-dashboard-login.md) - Admin dashboard / Supabase RPC
- [Worklog - Auth validation null](../../docs/worklog/2026-07-09/001-worklog-auth-validation-null.md) - v2 authentication
- [Worklog - Fix auth login sync failure](../../docs/worklog/2026-07-10/001-worklog-auth-login-sync-failure.md) - v2 authentication, admin login, Supabase dev seed
- [Worklog - Fix env tracked and bundled](../../docs/worklog/2026-07-10/003-worklog-env-tracked-and-bundled.md) - config/env, app entrypoints, auth/AI env readers
- [Worklog - Release analyze cleanup](../../docs/worklog/2026-07-10/004-worklog-release-analyze-cleanup.md) - Nabi providers/UI, onboarding UI, shared Nabi widgets, release
- [Worklog - P0 baseline regression v2 + Admin](../../docs/worklog/2026-07-11/001-worklog-v2-admin-p0-baseline.md) - M01 Onboarding, M05 AI, M11 FamilyPlus automated-only và
