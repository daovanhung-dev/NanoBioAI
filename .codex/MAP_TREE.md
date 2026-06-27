# MAP_TREE - NanoBio / BioAI

Compact inventory for routing. This file is not part of the default read pack.
Read it only when changing context layout, checking paths, or regenerating a
project inventory. Use `rg --files` for the current truth.

## Default Context Roots

- Root bridge: `AGENTS.md`
- Canonical agent entrypoint: `.codex/AGENTS.md`
- Source/router map: `.codex/PROJECT_MAP.md`
- Context read workflow: `.codex/workflows/context-read.md`
- Docs/context workflow: `.codex/workflows/docs-context.md`
- Worklog rules: `.codex/DOCS_WORKFLOW.md`
- Project-local skill: `.codex/skills/nanobio-project-agent/SKILL.md`
- Project-local DD creation skill: `.codex/skills/create-dd-from-bd/SKILL.md`
- Repo-discovered skill bridge: `.agents/skills/nanobio-project-agent/SKILL.md`
- Repo-discovered DD creation bridge: `.agents/skills/create-dd-from-bd/SKILL.md`

## .codex Layout

- `.codex/workflows/`: one primary workflow per task.
- `.codex/domains/`: one domain context when task touches code/product.
- `.codex/task-skills/`: generated canonical task skills.
- `.codex/history/`: generated memory from worklogs.
- `.codex/skills/nanobio-project-agent/`: canonical project skill and references.
- `.codex/skills/create-dd-from-bd/`: canonical DD-from-BD skill and reference.
- `.codex/tools/`: context/history validation and refresh scripts.
- `.codex/tool/`: Flutter/Dart validation wrappers.
- `.codex/playbooks/` and `.codex/workRule/`: legacy aliases only; not default context.

## Canonical Workflows

- `.codex/workflows/README.md`
- `.codex/workflows/context-read.md`
- `.codex/workflows/coding.md`
- `.codex/workflows/bugfix.md`
- `.codex/workflows/fix-issues.md`
- `.codex/workflows/test.md`
- `.codex/workflows/find-issues.md`
- `.codex/workflows/create-issues.md`
- `.codex/workflows/create-todo.md`
- `.codex/workflows/docs-dd.md`
- `.codex/workflows/docs-context.md`
- `.codex/workflows/refactor-scaffold.md`
- `.codex/workflows/supabase-schema.md`

## Domain Contexts

- `.codex/domains/README.md`
- `.codex/domains/dashboard.md`
- `.codex/domains/onboarding.md`
- `.codex/domains/ai-service.md`
- `.codex/domains/access-membership-referral.md`
- `.codex/domains/notification.md`
- `.codex/domains/sqlite.md`
- `.codex/domains/ui-nami.md`
- `.codex/domains/health-tracking.md`
- `.codex/domains/lifestyle-schedule.md`

## Generated Memory

- `.codex/history/WORKLOG_INDEX.md`: generated worklog inventory.
- `.codex/history/LEARNED_SKILLS.md`: reusable lessons and command patterns.
- `.codex/history/OPEN_RISKS.md`: compact active risks only.
- `.codex/history/RISK_HISTORY.md`: raw extracted risk evidence; do not read by default.
- `.codex/history/SESSION_QUALITY_REVIEW.md`: worklog self-review template.
- `.codex/history/HISTORY_REFRESH.md`: refresh instructions.
- `.codex/task-skills/README.md`: canonical task-skill index.
- `.codex/task-skills/LEGACY_TASK_KEY_MAP.md`: old task keys mapped to canonical keys.

Canonical task-skill files are: `coding.md`, `bugfix.md`, `fix-issues.md`,
`test.md`, `find-issues.md`, `create-issues.md`, `create-todo.md`,
`docs-dd.md`, `docs-context.md`, `refactor-scaffold.md`, and
`supabase-schema.md` under `.codex/task-skills/`.

## Validation And Refresh

- `.codex/tools/validate_codex_integrity.ps1`: validates `.codex` links,
  canonical task-skills, active risks, discovery bridges, and concrete paths.
- `.codex/tools/update_worklog_learning.ps1`: regenerates history and
  task-skill files after worklog changes.
- `.codex/tool/codex_quick_check.ps1`: quick Flutter/Dart check wrapper.
- `.codex/tool/codex_check.ps1`: full/native Flutter/Dart check wrapper.
- `.codex/tool/check_helpers.ps1`: shared PowerShell check helpers.

## Source Roots

- App bootstrap: `lib/main.dart`, `lib/main_v2.dart`
- v1 guest/basic: `lib/app_versions/v1/`
- v2 authenticated free: `lib/app_versions/v2/`
- v3 Plus/FamilyPlus planned: `lib/app_versions/v3/`
- Sale/referral independent axis: `lib/sale_referral/`
- Core shared code: `lib/core/`
- Shared services/widgets: `lib/services/`, `lib/shared/widgets/`
- Tests: `test/`
- Product/design docs: `docs/BD/`, `docs/DD/`, `docs/supabase/`
- Work tracking docs: `docs/issues/`, `docs/todo/`, `docs/worklog/`

## Inventory Commands

```powershell
rg --files .codex
rg --files .agents
rg --files docs -g '!docs/worklog/**'
rg --files lib test -g '!build/**' -g '!.dart_tool/**'
rg --files -g '!build/**' -g '!.dart_tool/**' -g '!.git/**'
```

## Maintenance Rule

If a context layout changes, update this compact map and run:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1
```
