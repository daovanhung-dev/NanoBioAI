# Workflow Registry

Pick exactly one primary workflow per session unless the user explicitly requests a multi-step chain.

| Workflow | Use for | File |
| --- | --- | --- |
| Context read | Read `.codex` or project context | `context-read.md` |
| Coding | Feature/change implementation | `coding.md` |
| Bugfix | Direct bug fix without issue/todo docs | `bugfix.md` |
| Fix issues | Fix a documented issue through todo | `fix-issues.md` |
| Test | Analyze/test/build without code fixes | `test.md` |
| Find issues | Audit/review and record issues | `find-issues.md` |
| Create issues | Convert findings into issue docs | `create-issues.md` |
| Create todo | Convert issues into todo docs | `create-todo.md` |
| Docs DD | Create/update/read DD from BD | `docs-dd.md` |
| Docs context | Update `.codex`, maps, checklists, project docs | `docs-context.md` |
| Refactor scaffold | Restructure version/module scaffolds | `refactor-scaffold.md` |
| Supabase schema | SQL/RLS/membership/quota/family/sale docs | `supabase-schema.md` |

Always update a worklog for code, tests, reviews, docs changes, issue/todo work, or substantial analysis.

## Common Session Rules

- After choosing the workflow, read `.codex/task-skills/README.md` and the matching `.codex/task-skills/<task-key>.md` if it exists.
- Before broad context reads or broad checks, ask how to save tokens while keeping or improving output quality.
- End substantial sessions with the self-review section from `.codex/history/SESSION_QUALITY_REVIEW.md`.
- After worklog changes, run `.codex/tools/update_worklog_learning.ps1` so history and task-skills learn from the session.
