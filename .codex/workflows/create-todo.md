# Workflow - Create Todo

Use when the user asks to create todos from existing issues.

## Required Context

- `.codex/AGENTS.md`
- `.codex/DOCS_WORKFLOW.md`
- `.codex/ISSUE_TODO_WORKFLOW.md`
- The source issue docs in `docs/issues/`.

## Rules

- Do not edit runtime code.
- Do not test or fix the issue.
- Each todo must link to the issue, define a narrow fix goal, list file areas to inspect, commands to verify, and risks.

## Completion

- Create `docs/todo/<slug>/<NNN>-todo-<slug>.md`.
- Create worklog and refresh `.codex/history/`.
