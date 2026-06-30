# Import File — ADVANCED_TRACKING_GOALS / Theo dõi nâng cao & mục tiêu

## 0. Dependency Rules

1. Presentation -> Provider/Controller -> Use case/Service -> Repository -> Datasource/API/DAO.
2. Presentation must not import SQLite DAO, Supabase raw client, or payment/referral backend directly.
3. Domain/use-case code must not import UI widgets or BuildContext.
4. Shared utilities must not contain module-specific business logic.
5. Secrets, service-role keys, payment evidence, and raw health data must not be hard-coded or committed.

## 1. Package / External Dependency Registry

| ID | Package / Service | Version / Plan | Source | Purpose | Owner | Security Note |
|---|---|---|---|---|---|---|
| ADVANCED_TRACKING_GOALS-DEP01 | Supabase / trusted backend | Planned contract | BD sections 13, 14, 17 | Auth, entitlement, RLS, Admin/Sale/payment data as applicable | Backend/Tech Lead | No service-role key in Flutter. |
| ADVANCED_TRACKING_GOALS-DEP02 | Flutter/Riverpod/GoRouter | Existing stack | .codex/AGENTS.md | Presentation, state, navigation | App team | Keep layer boundaries. |

## 2. File Map and Internal Contract

| File Path | Layer | Responsibility | Allowed Imports | Forbidden Imports | Public Export | Feature / Function |
|---|---|---|---|---|---|---|
| planned:lib/app_versions/v3/features/advanced_tracking/presentation/ | Presentation | Render views and dispatch user actions | Providers, view models, theme tokens, router | DAO, raw Supabase/payment clients, storage models | Screens/widgets | ADVANCED_TRACKING_GOALS-Vxx |
| planned:lib/app_versions/v3/features/advanced_tracking/application/ | Use case / Service | Orchestrate validation, authorization, business rules | Domain entities, repository interfaces, policies | Widgets, BuildContext, raw SQL/API client | execute(command, actorContext) | ADVANCED_TRACKING_GOALS-FNxx |
| planned:lib/app_versions/v3/features/advanced_tracking/domain/ | Domain | Entity and policy contracts | Pure Dart/value objects | UI, persistence implementation | Entities/policies | ADVANCED_TRACKING_GOALS-E-* |
| planned:lib/app_versions/v3/features/advanced_tracking/data/ | Repository/Datasource | Persist/integrate with local/trusted backend | Datasource/API/DAO contracts, mappers | UI widgets/controllers | Repository implementation | ADVANCED_TRACKING_GOALS-FNxx |
| planned:test/ | Test | Unit/integration/widget tests | Public contracts and fakes at correct layer | Production secrets or real payment/webhook payloads | Test fixtures | ADVANCED_TRACKING_GOALS-TCxx |

## 3. API / Datasource Dependencies

| ID | API / Datasource | Method / Event | Request | Response | Used By |
|---|---|---|---|---|---|
| ADVANCED_TRACKING_GOALS-API01 | `createAdvancedGoal` command / `rpc_advanced_tracking_goals_create_advanced_goal` trusted RPC when server-owned state is written | Use-case command handler; RPC only for financial, entitlement, quota, family, Sale, Admin, audit, or sensitive writes | actor_context, command DTO, correlation_id, idempotency_key for writes | Result/Error DTO, safe_user_message, domain_error_code, audit_ref for sensitive writes | ADVANCED_TRACKING_GOALS-FN01 |
| ADVANCED_TRACKING_GOALS-API02 | `loadGoalRoadmap` command / `rpc_advanced_tracking_goals_load_goal_roadmap` trusted RPC when server-owned state is written | Use-case command handler; RPC only for financial, entitlement, quota, family, Sale, Admin, audit, or sensitive writes | actor_context, command DTO, correlation_id, idempotency_key for writes | Result/Error DTO, safe_user_message, domain_error_code, audit_ref for sensitive writes | ADVANCED_TRACKING_GOALS-FN02 |
| ADVANCED_TRACKING_GOALS-API-AUDIT | Audit/event integration | Event after successful sensitive write | correlation_id, actor_id, action, entity_ref, reason, idempotency_key | audit_id, recorded_at, immutable action summary | Functions with side effects |

## 4. Entity / Model Dependencies

| Entity / Model | Intended File | Source | Used At |
|---|---|---|---|
| ADVANCED_TRACKING_GOALS-E-goal | planned:lib/app_versions/v3/features/advanced_tracking/domain/ | Advanced Goal | Features/functions/views in this module |
| ADVANCED_TRACKING_GOALS-E-roadmap_step | planned:lib/app_versions/v3/features/advanced_tracking/domain/ | Roadmap Step | Features/functions/views in this module |

## 5. Constants, Config and Feature Flags

| ID | Name | Source | Default | Who Can Change | Used By |
|---|---|---|---|---|---|
| ADVANCED_TRACKING_GOALS-CFG01 | Module enablement / rollout flag | Planned remote config or backend config | Disabled until release enabled; DD docs approved | Product Owner / Tech Lead | All features |
| ADVANCED_TRACKING_GOALS-CFG02 | Module-specific thresholds or policy | System Configuration entity or Admin managed policy version | Versioned default from accepted DD decisions; disabled only when feature flag is off | Super Admin/Admin role allowed by M16 with audit | Business rules |

## 6. Documented Dependency Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| ADVANCED_TRACKING_GOALS-IMP-EV01 | File map is updated when code is implemented. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| ADVANCED_TRACKING_GOALS-IMP-EV02 | No reverse layer imports. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| ADVANCED_TRACKING_GOALS-IMP-EV03 | No secrets or production payloads in source/tests/docs. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| ADVANCED_TRACKING_GOALS-IMP-EV04 | API/schema/RLS contracts are documented before coding. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| ADVANCED_TRACKING_GOALS-IMP-EV05 | Tests cover permission, business rule, duplicate/retry, and dependency failure. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
