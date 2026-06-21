# Workflow - Find Issues

Use for review, audit, bug hunt, release readiness checks, or risk analysis.

## Required Context

- `.codex/AGENTS.md`
- `.codex/PROJECT_MAP.md`
- `.codex/DOCS_WORKFLOW.md`
- `.codex/ISSUE_TODO_WORKFLOW.md`
- `.codex/history/OPEN_RISKS.md`
- One domain file or selected release hotspots.

## Rules

- Do not edit runtime code.
- Create issue docs only for evidence-backed bugs or risks.
- Evidence can be file/line, failing command, reproducible case, or architecture violation.
- Do not create todos unless the user asks for todo creation.

## Completion

- Create `docs/issues/<slug>/<NNN>-issue-<slug>.md` for each confirmed issue.
- Create worklog and refresh `.codex/history/`.
