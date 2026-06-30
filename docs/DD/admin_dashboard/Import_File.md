# Import File — ADMIN_DASHBOARD / Admin View / Dashboard

## 0. Dependency Rules

1. Presentation -> Provider/Controller -> Use case/Service -> Repository -> Datasource/API/DAO.
2. Presentation must not import SQLite DAO, Supabase raw client, or payment/referral backend directly.
3. Domain/use-case code must not import UI widgets or BuildContext.
4. Shared utilities must not contain module-specific business logic.
5. Secrets, service-role keys, payment evidence, and raw health data must not be hard-coded or committed.

## 1. Package / External Dependency Registry

| ID | Package / Service | Version / Plan | Source | Purpose | Owner | Security Note |
|---|---|---|---|---|---|---|
| ADMIN_DASHBOARD-DEP01 | Supabase / trusted backend | Planned contract | BD sections 13, 14, 17 | Auth, entitlement, RLS, Admin/Sale/payment data as applicable | Backend/Tech Lead | No service-role key in Flutter. |
| ADMIN_DASHBOARD-DEP02 | Flutter/Riverpod/GoRouter | Existing stack | .codex/AGENTS.md | Presentation, state, navigation | App team | Keep layer boundaries. |

## 2. File Map and Internal Contract

| File Path | Layer | Responsibility | Allowed Imports | Forbidden Imports | Public Export | Feature / Function |
|---|---|---|---|---|---|---|
| planned:lib/app_versions/v3/features/admin_dashboard/presentation/ | Presentation | Render views and dispatch user actions | Providers, view models, theme tokens, router | DAO, raw Supabase/payment clients, storage models | Screens/widgets | ADMIN_DASHBOARD-Vxx |
| planned:lib/app_versions/v3/features/admin_dashboard/application/ | Use case / Service | Orchestrate validation, authorization, business rules | Domain entities, repository interfaces, policies | Widgets, BuildContext, raw SQL/API client | execute(command, actorContext) | ADMIN_DASHBOARD-FNxx |
| planned:lib/app_versions/v3/features/admin_dashboard/domain/ | Domain | Entity and policy contracts | Pure Dart/value objects | UI, persistence implementation | Entities/policies | ADMIN_DASHBOARD-E-* |
| planned:lib/app_versions/v3/features/admin_dashboard/data/ | Repository/Datasource | Persist/integrate with local/trusted backend | Datasource/API/DAO contracts, mappers | UI widgets/controllers | Repository implementation | ADMIN_DASHBOARD-FNxx |
| planned:test/ | Test | Unit/integration/widget tests | Public contracts and fakes at correct layer | Production secrets or real payment/webhook payloads | Test fixtures | ADMIN_DASHBOARD-TCxx |

## 3. API / Datasource Dependencies

| ID | API / Datasource | Method / Event | Request | Response | Used By |
|---|---|---|---|---|---|
| ADMIN_DASHBOARD-API01 | `loadAdminDashboard` command / `rpc_admin_dashboard_load_admin_dashboard` trusted RPC when server-owned state is written | Use-case command handler; RPC only for financial, entitlement, quota, family, Sale, Admin, audit, or sensitive writes | actor_context, command DTO, correlation_id, idempotency_key for writes | Result/Error DTO, safe_user_message, domain_error_code, audit_ref for sensitive writes | ADMIN_DASHBOARD-FN01 |
| ADMIN_DASHBOARD-API02 | `openAdminDrilldown` command / `rpc_admin_dashboard_open_admin_drilldown` trusted RPC when server-owned state is written | Use-case command handler; RPC only for financial, entitlement, quota, family, Sale, Admin, audit, or sensitive writes | actor_context, command DTO, correlation_id, idempotency_key for writes | Result/Error DTO, safe_user_message, domain_error_code, audit_ref for sensitive writes | ADMIN_DASHBOARD-FN02 |
| ADMIN_DASHBOARD-API-AUDIT | Audit/event integration | Event after successful sensitive write | correlation_id, actor_id, action, entity_ref, reason, idempotency_key | audit_id, recorded_at, immutable action summary | Functions with side effects |

## 4. Entity / Model Dependencies

| Entity / Model | Intended File | Source | Used At |
|---|---|---|---|
| ADMIN_DASHBOARD-E-dashboard_metric | planned:lib/app_versions/v3/features/admin_dashboard/domain/ | Dashboard Metric | Features/functions/views in this module |
| ADMIN_DASHBOARD-E-admin_scope | planned:lib/app_versions/v3/features/admin_dashboard/domain/ | Admin Scope | Features/functions/views in this module |

## 5. Constants, Config and Feature Flags

| ID | Name | Source | Default | Who Can Change | Used By |
|---|---|---|---|---|---|
| ADMIN_DASHBOARD-CFG01 | Module enablement / rollout flag | Planned remote config or backend config | Disabled until release enabled; DD docs approved | Product Owner / Tech Lead | All features |
| ADMIN_DASHBOARD-CFG02 | Module-specific thresholds or policy | System Configuration entity or Admin managed policy version | Versioned default from accepted DD decisions; disabled only when feature flag is off | Super Admin/Admin role allowed by M16 with audit | Business rules |

## 6. Documented Dependency Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| ADMIN_DASHBOARD-IMP-EV01 | File map is updated when code is implemented. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| ADMIN_DASHBOARD-IMP-EV02 | No reverse layer imports. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| ADMIN_DASHBOARD-IMP-EV03 | No secrets or production payloads in source/tests/docs. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| ADMIN_DASHBOARD-IMP-EV04 | API/schema/RLS contracts are documented before coding. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| ADMIN_DASHBOARD-IMP-EV05 | Tests cover permission, business rule, duplicate/retry, and dependency failure. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
