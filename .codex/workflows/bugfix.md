# Workflow - Bugfix

Use for a concrete bug fix when there is no existing issue/todo pair.

## Required Context

- `.codex/AGENTS.md`
- `.codex/PROJECT_MAP.md`
- `.codex/DOCS_WORKFLOW.md`
- `.codex/history/LEARNED_SKILLS.md`
- One domain file matching the failing module.
- Existing tests or nearest affected test folder.

## Rules

- Reproduce or confirm the root cause before patching.
- Keep the patch minimal and scoped to the failing behavior.
- If a different bug is discovered, do not fix it unless it blocks the requested fix; record it separately if needed.
- User-facing error/copy stays Vietnamese, Nabitone, no internal technical terms.

## Completion

- Add/update focused regression tests when practical.
- Create `docs/fixbug/<slug>/` if the bug fix is meaningful.
- Create worklog and refresh `.codex/history/`.
