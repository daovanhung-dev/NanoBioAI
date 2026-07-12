# Task Skill - Fix documented issue

- Canonical key: fix-issues
- Workflow: .codex/workflows/fix-issues.md
- Generated from 2 worklog(s).

## When To Read

- Historical task type: fix-issues (2)

## Common Modules

- AI Chat service: 1
- v1 onboarding, AppLogger: 1

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

- [Worklog - Fix AI Chat dotenv uninitialized](../../docs/worklog/2026-06-19/011-worklog-fix-ai-chat-dotenv-uninitialized.md) - AI Chat service
- [Worklog - Fix onboarding sensitive snapshot logging](../../docs/worklog/2026-07-10/002-worklog-onboarding-sensitive-snapshot-logging.md) - v1 onboarding, AppLogger
