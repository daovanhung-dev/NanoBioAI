# NanoBio Agent Bridge

This repository is the NanoBio / NamiAI Flutter app. This root file is the
small Codex auto-discovery bridge; the detailed project context lives in
`.codex/`.

## Start Here

1. Read `.codex/AGENTS.md`.
2. Use `.codex/PROJECT_MAP.md` to choose the workflow, domain, and source area.
3. Read `.codex/history/LEARNED_SKILLS.md`.
4. Read exactly one workflow from `.codex/workflows/`.
5. Read `.codex/task-skills/README.md` and the matching task-skill if present.
6. Read one `.codex/domains/*.md` file only when the task touches app code or
   product behavior.

## Token Rules

- Prefer router/index files, targeted `rg`, and focused file reads.
- Do not read `.codex/MAP_TREE.md` unless checking inventory or changing layout.
- Do not read `.codex/history/RISK_HISTORY.md` unless exact historical evidence
  is required.
- Do not read raw `docs/worklog/**/*.md`, raw `lib/**`, raw `test/**`, or all of
  `docs/DD/**` unless the selected workflow requires it.

## Validation

- Docs/context-only changes use `.codex/tools/validate_codex_integrity.ps1`,
  targeted `rg` checks, and `git diff --check`.
- Runtime changes follow the validation commands in `.codex/AGENTS.md`.
