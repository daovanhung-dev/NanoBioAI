# Worklog Learning

NanoBio uses worklogs as the project memory. The agent should learn from generated summaries, not by loading every raw worklog on every task.

## Read Rule

Read:

- `.codex/history/WORKLOG_INDEX.md` for the full worklog inventory.
- `.codex/history/LEARNED_SKILLS.md` for reusable project skills and command patterns.
- `.codex/task-skills/README.md` and the matching task-skill for the selected workflow/task.
- `.codex/history/OPEN_RISKS.md` when the task touches release readiness, Supabase, auth, DD status, or testing.
- `.codex/history/SESSION_QUALITY_REVIEW.md` before writing the end-of-session worklog self-review.

Open raw `docs/worklog/**/*.md` only when the selected workflow needs exact historical evidence.

## Refresh Rule

After any session creates or updates `docs/worklog/**`, run:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1
```

Then include `.codex/history/*` in docs/context changes.
Also include `.codex/task-skills/*` when the generated task skills change.

## Self-Optimization Rule

Every substantial worklog must record:

- output quality,
- task completion,
- verification strength,
- token waste or unnecessary context,
- how to optimize the next similar session,
- which `.codex/task-skills/<task-key>.md` should be read next time.
