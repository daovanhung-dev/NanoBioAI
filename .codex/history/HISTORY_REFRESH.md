# History Refresh

Run this after any session creates or updates `docs/worklog/**`.

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1
```

Outputs:

- `WORKLOG_INDEX.md`: full worklog inventory with canonical task keys.
- `LEARNED_SKILLS.md`: reusable project skills and command patterns.
- `OPEN_RISKS.md`: compact active risk register only.
- `RISK_HISTORY.md`: raw extracted historical risk/failure lines.
- `SESSION_QUALITY_REVIEW.md`: self-review template for future sessions.
- `.codex/task-skills/*.md`: generated canonical task-specific skills.
- `HISTORY_REFRESH.md`: this instruction file.

After refresh, run `.codex/tools/validate_codex_integrity.ps1` and include `.codex/history/*` plus `.codex/task-skills/*` in the docs/context diff.
