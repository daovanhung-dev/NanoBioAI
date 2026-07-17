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

- Unified app bootstrap and role-based surface selection: `lib/main.dart`, `lib/app/`
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

## Project DD Modules

Generated DD folders for docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md:

- docs/DD/onboarding_profile/: DD M01 ONBOARDING_PROFILE from BD-BIOAI-PRODUCT-FLOW-002.
- docs/DD/personal_schedule_ai/: DD M02 PERSONAL_SCHEDULE_AI from BD-BIOAI-PRODUCT-FLOW-002.
- docs/DD/dashboard_schedule/: DD M03 DASHBOARD_SCHEDULE from BD-BIOAI-PRODUCT-FLOW-002.
- docs/DD/basic_health_calculators/: DD M04 BASIC_HEALTH_CALC from BD-BIOAI-PRODUCT-FLOW-002.
- docs/DD/auth_profile_sync/: DD M05 AUTH_PROFILE_SYNC from BD-BIOAI-PRODUCT-FLOW-002.
- docs/DD/membership_quota/: DD M06 MEMBERSHIP_QUOTA from BD-BIOAI-PRODUCT-FLOW-002.
- docs/DD/ai_chat/: DD M07 AI_CHAT from BD-BIOAI-PRODUCT-FLOW-002.
- docs/DD/health_score_habits/: DD M08 HEALTH_SCORE_HABITS from BD-BIOAI-PRODUCT-FLOW-002.
- docs/DD/schedule_notifications/: DD M09 SCHEDULE_NOTIFICATIONS from BD-BIOAI-PRODUCT-FLOW-002.
- docs/DD/advanced_tracking_goals/: DD M10 ADVANCED_TRACKING_GOALS from BD-BIOAI-PRODUCT-FLOW-002.
- docs/DD/familyplus/: DD M11 FAMILYPLUS from BD-BIOAI-PRODUCT-FLOW-002.
- docs/DD/referral_direct/: DD M12 REFERRAL_DIRECT from BD-BIOAI-PRODUCT-FLOW-002.
- docs/DD/payment_membership/: DD M13 PAYMENT_MEMBERSHIP from BD-BIOAI-PRODUCT-FLOW-002.
- docs/DD/sale_points/: DD M14 SALE_POINTS from BD-BIOAI-PRODUCT-FLOW-002.
- docs/DD/admin_dashboard/: DD M15 ADMIN_DASHBOARD from BD-BIOAI-PRODUCT-FLOW-002.
- docs/DD/admin_operations/: DD M16 ADMIN_OPS from BD-BIOAI-PRODUCT-FLOW-002.
- docs/DD/reconciliation/: DD M17 RECONCILIATION from BD-BIOAI-PRODUCT-FLOW-002.
- docs/DD/reporting/: DD M18 REPORTING from BD-BIOAI-PRODUCT-FLOW-002.
- docs/DD/audit_security/: DD M19 AUDIT_SECURITY from BD-BIOAI-PRODUCT-FLOW-002.
- docs/DD/nabi_companion_notifications/: DD M30 NABI_COMPANION_NOTIFICATIONS from BD-NABI-NOTIFICATION-001.
