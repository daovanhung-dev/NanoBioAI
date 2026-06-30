# Task Skill - Coding

- Canonical key: coding
- Workflow: .codex/workflows/coding.md
- Generated from 13 worklog(s).

## When To Read

- Historical task type: coding (8)
- Historical task type: coding/test/docs (3)
- Historical task type: feature (1)
- Historical task type: feature Dashboard/UI + data write path (1)

## Common Modules

- M15 ADMIN_DASHBOARD, M16 ADMIN_OPS: 2
- M01 ONBOARDING_PROFILE: 1
- v1 onboarding/splash/dashboard, v2 auth/membership/cloud sync, Supabase docs.: 1
- M02 PERSONAL_SCHEDULE_AI: 1
- unknown: 1
- M01 ONBOARDING_PROFILE, M05 AUTH_PROFILE_SYNC, local SQLite sync outbox: 1
- onboarding, dashboard: 1
- dashboard, daily_health_tracking, lifestyle_schedule, meal_plan, shared/widgets: 1

## Work Pattern

- Start from the selected workflow, then this task skill, then one domain file.
- Read docs/checklist/checklist_complete_DD.md first to identify DD module progress, blockers, and next step; then read docs/checklist/checklist_task_coding.md for prior-session coding notes.
- Before coding from a DD module, state the module, current progress percentages, blockers, and exact next task from the checklist.
- After coding, update docs/checklist/checklist_complete_DD.md and record upcoming work in docs/checklist/checklist_task_coding.md.
- Prefer targeted `rg` and focused tests over broad reads/checks.
- Record exact evidence in the worklog and add the self-review section.
- Ask before expanding scope when BD/DD, issue/todo, or product decisions are missing.

## Token Optimization

- Ask: how can this task use fewer tokens while producing equal or better work?
- Read index/summary files before raw historical files.
- Stop reading when root cause, target files, and validation path are clear.
- Update this generated skill through the history refresh script, not by hand.

## Source Worklogs

- [Worklog - AI sinh thêm kế hoạch sau onboarding](../../docs/worklog/2026-06-19/002-worklog-ai-generated-plan.md) - Dashboard, AI service, lifestyle schedule
- [Worklog - Dashboard NabiCompanion](../../docs/worklog/2026-06-19/006-worklog-dashboard-nami-companion.md) - dashboard, daily_health_tracking, lifestyle_schedule, meal_plan, shared/widgets
- [Worklog - Onboarding Dashboard Refresh](../../docs/worklog/2026-06-20/001-worklog-onboarding-dashboard-refresh.md) - onboarding, dashboard
- [Worklog - Authentication V2](../../docs/worklog/2026-06-20/002-worklog-authentication-v2.md) - authentication
- [Worklog - Authentication V2 Code Gaps](../../docs/worklog/2026-06-20/004-worklog-authentication-code-gaps.md) - authentication v2
- [Worklog - Riverpod Account State](../../docs/worklog/2026-06-21/005-worklog-riverpod-account-state.md) - Authentication v2, Settings account security
- [Worklog - Onboarding Auth Sync](../../docs/worklog/2026-06-21/006-worklog-onboarding-auth-sync.md) - v1 onboarding/splash/dashboard, v2 auth/membership/cloud sync, Supabase docs.
- [Worklog - M01 Onboarding Safe Hardening](../../docs/worklog/2026-06-28/006-worklog-m01-onboarding-safe-hardening.md) - M01 ONBOARDING_PROFILE
- [Worklog - M02 Runtime Guard](../../docs/worklog/2026-06-29/001-worklog-m02-runtime-guard.md) - M02 PERSONAL_SCHEDULE_AI
- [Worklog - M15/M16 Admin Contract Sync](../../docs/worklog/2026-06-29/004-worklog-m15-m16-admin-contract-sync.md) - M15 ADMIN_DASHBOARD, M16 ADMIN_OPS
- [Worklog - Admin UI Polish](../../docs/worklog/2026-06-29/007-worklog-admin-ui-polish.md) - M15 ADMIN_DASHBOARD, M16 ADMIN_OPS
- [Worklog — immediate user-data sync](../../docs/worklog/2026-06-30/001-worklog-immediate-user-data-sync.md) - unknown
