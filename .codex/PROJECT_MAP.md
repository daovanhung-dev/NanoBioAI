# PROJECT_MAP - NanoBio / BioAI

Use this file to route work to source, docs, tests, workflow, and domain context. Do not read broad trees until the selected workflow requires it.

## Source Roots

- App bootstrap: `lib/main.dart`, `lib/main_v2.dart`
- v1 guest/basic app: `lib/app_versions/v1/`
- v2 authenticated free app: `lib/app_versions/v2/`
- v3 Plus/FamilyPlus planned app: `lib/app_versions/v3/`
- Sale/referral independent axis: `lib/sale_referral/`
- Core constants/theme/storage/network/utils: `lib/core/`
- Shared services: `lib/services/`
- Shared widgets: `lib/shared/widgets/`
- Tests: `test/`
- BD/DD docs: `docs/BD/`, `docs/DD/`
- Supabase draft docs: `docs/supabase/`
- Issues/todo/worklog: `docs/issues/`, `docs/todo/`, `docs/worklog/`

## Workflow Routing

| Task                                 | Workflow                                | Domain                   |
| ------------------------------------ | --------------------------------------- | ------------------------ |
| Read project context                 | `.codex/workflows/context-read.md`      | optional                 |
| Implement feature/change             | `.codex/workflows/coding.md`            | matching domain          |
| Direct bug fix                       | `.codex/workflows/bugfix.md`            | matching domain          |
| Fix issue from todo                  | `.codex/workflows/fix-issues.md`        | matching domain          |
| Test/analyze/build                   | `.codex/workflows/test.md`              | matching domain          |
| Audit/review/find bugs               | `.codex/workflows/find-issues.md`       | matching domain          |
| Create issue docs                    | `.codex/workflows/create-issues.md`     | optional                 |
| Create todo docs                     | `.codex/workflows/create-todo.md`       | optional                 |
| Create/update/read DD                | `.codex/workflows/docs-dd.md`           | product/domain as needed |
| Update `.codex`/maps/checklists      | `.codex/workflows/docs-context.md`      | optional                 |
| Refactor scaffold/version boundaries | `.codex/workflows/refactor-scaffold.md` | access/membership        |
| Supabase schema/RLS/quota/sale       | `.codex/workflows/supabase-schema.md`   | access/membership        |

## Domain Routing

| Domain                                | Context                                        | Source/tests                                                                                   |
| ------------------------------------- | ---------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Dashboard / Health Score              | `.codex/domains/dashboard.md`                  | `lib/app_versions/v1/features/dashboard/`, `test/features/dashboard/`                          |
| Onboarding                            | `.codex/domains/onboarding.md`                 | `lib/app_versions/v1/features/onboarding/`, `test/app_versions/v1/features/onboarding/`        |
| AI / Meal / Exercise / Chat           | `.codex/domains/ai-service.md`                 | `lib/app_versions/v1/services/ai/`, meal/schedule/task/chat tests                              |
| Access / Auth / Membership / Referral | `.codex/domains/access-membership-referral.md` | `lib/app_versions/v2/`, `lib/app_versions/v3/`, `lib/sale_referral/`, `lib/services/supabase/` |
| Notification / Reminder               | `.codex/domains/notification.md`               | `lib/app_versions/v1/services/notifications/`, `test/services/notifications/`                  |
| SQLite / DAO / Migration              | `.codex/domains/sqlite.md`                     | `lib/core/storage/localdb/`, `test/core/storage/localdb/`                                      |
| UI / Theme / NabiCopy                 | `.codex/domains/ui-nami.md`                    | `lib/core/theme/`, feature presentation files                                                  |
| Daily Health Tracking                 | `.codex/domains/health-tracking.md`            | `lib/app_versions/v1/features/daily_health_tracking/`, `test/features/daily_health_tracking/`  |
| Lifestyle Schedule                    | `.codex/domains/lifestyle-schedule.md`         | `lib/app_versions/v1/features/lifestyle_schedule/`, `test/features/lifestyle_schedule/`        |

## Critical Files

Open only when relevant:

- `lib/app_versions/v1/router/v1_router.dart`
- `lib/app_versions/v1/router/v1_route_guards.dart`
- `lib/app_versions/v2/router/v2_router.dart`
- `lib/core/storage/localdb/database_service.dart`
- `lib/core/storage/localdb/database_version.dart`
- `lib/app_versions/v1/services/ai/ai_service.dart`
- `lib/app_versions/v1/services/ai/ai_chat_service.dart`
- `lib/app_versions/v1/services/ai/generated_plan_service.dart`
- `lib/app_versions/v1/services/notifications/notification_bootstrap.dart`
- `lib/app_versions/v1/services/notifications/notification_action_handler.dart`
- `test/architecture_version_boundary_test.dart`
- `test/architecture_preservation_property_test.dart`

## Search Commands

```powershell
rg "Provider|AsyncNotifier|Notifier|Repository|Datasource|Dao|DAO" lib/app_versions lib/services test
rg "CREATE TABLE|ALTER TABLE|databaseVersion|currentVersion|onCreate|migration" lib/core/storage/localdb test
rg "notification|payload|timezone|reminder|complete|skip" lib/app_versions/v1/services/notifications lib/app_versions/v1/features test
rg "Gemini|generateContent|validator|normalizer|catalog|fallback|dotenv|ChatSession" lib/app_versions/v1/services/ai lib/app_versions/v1/features test
rg "membership|subscription|tier|entitlement|referral|commission|sale|FamilyPlus|Plus" lib docs .codex
rg "import.*core/storage/localdb|import.*data/datasources" lib/app_versions/*/features/*/presentation
rg --files -g '!build/**' -g '!.dart_tool/**' -g '!.git/**'
```

## Docs Routing

- Product flow BD: `docs/BD/project_flow/BD_Product_Flow_Membership_Sale.md`
- DD creation guide: `docs/DD/DD_Module_Creation_Guide_EN.md`
- DD module template: `docs/DD/DD_Module_Template/README.md`
- Auth BD: `docs/BD/authentication/BD_Authentication_Registration_Login_NanoBio.md`
- DD checklist: `docs/checklist/checklist_create_DD.md`
- Supabase context: `docs/supabase/README.md`

Legacy product-flow/auth DD folders are not present in the current working tree. Create or update module DDs through the live DD guide/template unless the user provides a specific existing DD path.
