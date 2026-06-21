# CODEX CHECKLIST

## Before Work

- [ ] Choose one workflow in `.codex/workflows/`.
- [ ] Choose one domain in `.codex/domains/` if task touches code/product.
- [ ] Read `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md`, and `.codex/history/LEARNED_SKILLS.md`.
- [ ] Read `.codex/task-skills/README.md` and the matching `.codex/task-skills/<task-key>.md` when present.
- [ ] Read `.codex/DOCS_WORKFLOW.md` if code/test/docs/review/issues/todo/DD/context changes are expected.
- [ ] Read `.codex/ISSUE_TODO_WORKFLOW.md` for issue/todo/fix-issue work.
- [ ] Read BD/DD only when workflow requires it or user asks for it.
- [ ] Use `rg` to confirm usage before changing public API, route, provider, callback, schema, or workflow contract.
- [ ] Ask: how can this task use fewer tokens while producing equal or better work?

## During Work

- [ ] Keep the patch scoped to the selected workflow.
- [ ] Preserve `Presentation -> Provider/Controller -> Repository -> Datasource -> DAO/API`.
- [ ] Do not add production mock/fake/sample data.
- [ ] Do not edit real `.env` or expose secrets unless explicitly requested.
- [ ] Do not trust client/local cache for membership, sale, referral, payment, commission, or quota.
- [ ] Keep user-facing copy Vietnamese, Nami tone, no internal technical terms.
- [ ] If schema changes: update version, migration, table, model, DAO, onCreate, datasource/repository, and tests.
- [ ] Before expanding context or running broad checks, confirm the added cost improves the result.

## After Work

- [ ] Run targeted checks for changed scope.
- [ ] Run quick/full check only when appropriate for runtime changes.
- [ ] Create/update worklog under `docs/worklog/<yyyy-mm-dd>/`.
- [ ] Add the worklog self-review: quality, completion, verification, token waste, next optimization, and task-skill to read next time.
- [ ] Create/update feature/fixbug/test/issue/todo/DD docs when relevant.
- [ ] If worklog changed, run `.codex/tools/update_worklog_learning.ps1`.
- [ ] Confirm `.codex/history/SESSION_QUALITY_REVIEW.md` and `.codex/task-skills/*` reflect new lessons when worklog changed.
- [ ] If `.codex` layout or repo tree changed, update `.codex/MAP_TREE.md`.
- [ ] Report files changed, docs changed, commands/results, remaining risk, and completion percentage.
