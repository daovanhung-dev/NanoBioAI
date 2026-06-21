# Workflow - Docs Context

Use for updating `.codex`, project maps, checklists, worklog learning, repo docs, or context rules.

## Required Context

- `.codex/README.md`
- `.codex/AGENTS.md`
- `.codex/PROJECT_MAP.md`
- `.codex/DOCS_WORKFLOW.md`
- `.codex/history/WORKLOG_INDEX.md`
- `.codex/history/LEARNED_SKILLS.md`
- `.codex/history/SESSION_QUALITY_REVIEW.md`
- `.codex/task-skills/README.md`

## Rules

- Prefer router/index files over large always-read files.
- Keep `.codex` ASCII unless a docs file is intended for Vietnamese user-facing output.
- Do not leave stale paths to missing files or old source roots.
- Preserve the workflow -> task-skill -> domain read order.
- Keep the token-saving question explicit in checklists and worklog templates.
- If context layout changes, update `.codex/MAP_TREE.md`.

## Completion

- Run stale-reference checks.
- Create worklog for the context update.
- Add the session self-review to the worklog.
- Run `.codex/tools/update_worklog_learning.ps1` after the worklog is created.
- Confirm `.codex/history/*` and `.codex/task-skills/*` updated as expected.
