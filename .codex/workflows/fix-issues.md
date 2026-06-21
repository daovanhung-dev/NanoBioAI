# Workflow - Fix Issues

Use only when the user asks to fix an existing issue/todo.

## Read Order

1. `.codex/AGENTS.md`
2. `.codex/PROJECT_MAP.md`
3. `.codex/DOCS_WORKFLOW.md`
4. `.codex/ISSUE_TODO_WORKFLOW.md`
5. Related `docs/issues/<slug>/...`
6. Related `docs/todo/<slug>/...`
7. One matching domain file.
8. Source and tests named by the todo, plus usage found by `rg`.

## Rules

- Fix only the documented issue.
- Do not create new feature behavior.
- Do not refactor unrelated modules.
- Do not create new issues/todos in this workflow; note out-of-scope risks in the worklog.

## Completion

- Create/update `docs/fixbug/<slug>/`.
- Create worklog and refresh `.codex/history/`.
- Run targeted tests only unless the todo explicitly requires broader validation.
