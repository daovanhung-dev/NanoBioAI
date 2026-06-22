# Context Router

Use this reference to select the minimum context pack.

## Default Read Pack

Always read:

- `.codex/AGENTS.md`
- `.codex/PROJECT_MAP.md`
- `.codex/history/LEARNED_SKILLS.md`
- `.codex/task-skills/README.md`

Then read one workflow from `.codex/workflows/`, the matching generated task-skill when present, and one domain from `.codex/domains/` when a domain is clear.

Read `.codex/history/OPEN_RISKS.md` only for release readiness, auth, Supabase, DD status, or testing. Do not read `.codex/history/RISK_HISTORY.md`, `.codex/MAP_TREE.md`, raw worklogs, raw source, raw tests, or all DD files unless the selected workflow requires them.

## Request To Workflow

| User intent | Workflow |
| --- | --- |
| "doc context", "read .codex", no task type | `context-read.md` |
| build, implement, add feature, code from BD/DD | `coding.md` |
| fix a concrete bug directly | `bugfix.md` |
| fix issue/todo | `fix-issues.md` |
| run tests, verify, analyze, build | `test.md` |
| audit, review, find bugs | `find-issues.md` |
| create issue docs | `create-issues.md` |
| create todo from issues | `create-todo.md` |
| create/update/read DD from BD | `docs-dd.md` |
| update .codex/docs/checklist/project map/history | `docs-context.md` |
| scaffold/refactor version folders | `refactor-scaffold.md` |
| Supabase SQL/RLS/membership/quota/family/sale schema | `supabase-schema.md` |

## Expansion Rule

- If the workflow is not named by the user, infer it from the requested output, not from implementation convenience.
- If multiple workflows are requested, finish them in order and keep boundaries explicit.
- Do not read raw source trees, raw worklogs, `.codex/history/RISK_HISTORY.md`, `.codex/MAP_TREE.md`, or all DD files unless the selected workflow requires it.
- Before expanding context, ask how to save tokens while preserving or improving output quality.
