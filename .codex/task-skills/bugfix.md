# Task Skill - Direct bugfix

- Canonical key: bugfix
- Workflow: .codex/workflows/bugfix.md
- Generated from 5 worklog(s).

## When To Read

- Historical task type: bugfix (2)
- Historical task type: fix (1)
- Historical task type: fix flow dữ liệu (1)
- Historical task type: fix UI/copy (1)

## Common Modules

- v1 onboarding, generated plan service, v1/v2 router gate, v2 cloud sync test, docs/worklog.: 1
- v1 dashboard daily score, v2 health_scoring placeholder, docs/worklog.: 1
- Dashboard, Lifestyle Schedule, Meal Plan, Nutrition: 1
- AI chat: 1
- lib/app_versions/v1/features/**/presentation: 1

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
