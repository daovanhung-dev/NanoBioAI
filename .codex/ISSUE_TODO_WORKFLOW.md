# ISSUE_TODO_WORKFLOW - Issue And Todo Modes

Use this file only for issue/todo/find/fix workflows. Keep modes separate.

## Modes

| Mode | Workflow | Allowed | Not allowed |
| --- | --- | --- | --- |
| `find-issues` | `.codex/workflows/find-issues.md` | Review/audit, create issue docs with evidence | Code fixes, todos |
| `create-issues` | `.codex/workflows/create-issues.md` | Convert findings into issue docs | Code fixes, todos |
| `create-todo` | `.codex/workflows/create-todo.md` | Convert issue docs into todo docs | Code fixes, tests |
| `fix-issues` | `.codex/workflows/fix-issues.md` | Fix one documented issue through its todo | New features, unrelated refactor |
| `test` | `.codex/workflows/test.md` | Run/analyze/record tests | Code fixes |

## Issue Docs

Location:

```text
docs/issues/<issue-slug>/<NNN>-issue-<issue-slug>.md
```

Issue must include:

- `Commit de xuat: docs(issue): ghi nhan loi <slug>`
- Summary.
- Expected vs actual when applicable.
- Severity: blocker/high/medium/low.
- Reproduction or verification steps.
- Evidence: file/line, failing command, log summary, or test.
- Impact.
- Suggested fix direction without code patch.

## Todo Docs

Location:

```text
docs/todo/<todo-slug>/<NNN>-todo-<todo-slug>.md
```

Todo must include:

- Link to source issue.
- Fix goal and non-goals.
- Ordered task checklist.
- Files to inspect/change.
- Verification commands.
- Risks.

## Fix Issue Flow

1. Read issue.
2. Read matching todo.
3. Read matching workflow and domain.
4. Confirm root cause with targeted source/tests.
5. Patch the smallest scope that closes the issue.
6. Create/update `docs/fixbug/<slug>/`.
7. Create worklog.
8. Refresh `.codex/history/`.

Do not create new issue/todo in a fix-issue session; record out-of-scope risks in the worklog.
