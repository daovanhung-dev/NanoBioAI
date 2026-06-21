# Workflow - Test

Use when the user asks to test, analyze, verify, build, or run checks.

## Required Context

- `.codex/AGENTS.md`
- `.codex/PROJECT_MAP.md`
- `.codex/DOCS_WORKFLOW.md`
- `.codex/history/LEARNED_SKILLS.md`
- BD/DD only if the test is acceptance-oriented.
- Source and tests directly in scope.

## Rules

- Do not fix code in test workflow.
- Record failures with exact command, result, and likely owner.
- If a bug is found, create issue docs only when the user asked for issue creation or the workflow includes it.

## Commands

- Quick check: `powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1`
- Full/native check: `powershell -ExecutionPolicy Bypass -File .codex/tool/codex_check.ps1 -BuildApk`
- Targeted Flutter tests should run before full suite when scope is narrow.

## Completion

- Create/update `docs/test/<slug>/` for meaningful results.
- Create worklog and refresh `.codex/history/`.
