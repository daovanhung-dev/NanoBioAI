# Import File — PERSONAL_SCHEDULE_AI / AI Lịch trình cá nhân

## 0. Dependency Rules

1. Presentation -> Provider/Controller -> Use case/Service -> Repository -> Datasource/API/DAO.
2. Presentation must not import SQLite DAO, Supabase raw client, or payment/referral backend directly.
3. Domain/use-case code must not import UI widgets or BuildContext.
4. Shared utilities must not contain module-specific business logic.
5. Secrets, service-role keys, payment evidence, and raw health data must not be hard-coded or committed.

## 1. Package / External Dependency Registry

| ID | Package / Service | Version / Plan | Source | Purpose | Owner | Security Note |
|---|---|---|---|---|---|---|
| PERSONAL_SCHEDULE_AI-DEP01 | Supabase / trusted backend | Planned contract | BD sections 13, 14, 17 | Auth, entitlement, RLS, Admin/Sale/payment data as applicable | Backend/Tech Lead | No service-role key in Flutter. |
| PERSONAL_SCHEDULE_AI-DEP02 | Flutter/Riverpod/GoRouter | Existing stack | .codex/AGENTS.md | Presentation, state, navigation | App team | Keep layer boundaries. |

## 2. File Map and Internal Contract

| File Path | Layer | Responsibility | Allowed Imports | Forbidden Imports | Public Export | Feature / Function |
|---|---|---|---|---|---|---|
| planned:lib/app_versions/v1/services/ai/presentation/ | Presentation | Render views and dispatch user actions | Providers, view models, theme tokens, router | DAO, raw Supabase/payment clients, storage models | Screens/widgets | PERSONAL_SCHEDULE_AI-Vxx |
| planned:lib/app_versions/v1/services/ai/application/ | Use case / Service | Orchestrate validation, authorization, business rules | Domain entities, repository interfaces, policies | Widgets, BuildContext, raw SQL/API client | execute(command, actorContext) | PERSONAL_SCHEDULE_AI-FNxx |
| planned:lib/app_versions/v1/services/ai/domain/ | Domain | Entity and policy contracts | Pure Dart/value objects | UI, persistence implementation | Entities/policies | PERSONAL_SCHEDULE_AI-E-* |
| planned:lib/app_versions/v1/services/ai/data/ | Repository/Datasource | Persist/integrate with local/trusted backend | Datasource/API/DAO contracts, mappers | UI widgets/controllers | Repository implementation | PERSONAL_SCHEDULE_AI-FNxx |
| planned:test/ | Test | Unit/integration/widget tests | Public contracts and fakes at correct layer | Production secrets or real payment/webhook payloads | Test fixtures | PERSONAL_SCHEDULE_AI-TCxx |

## 3. API / Datasource Dependencies

| ID | API / Datasource | Method / Event | Request | Response | Used By |
|---|---|---|---|---|---|
| PERSONAL_SCHEDULE_AI-API01 | Planned module API/service | TBD by implementation DD/API contract | Actor context + command DTO | Result/Error DTO | PERSONAL_SCHEDULE_AI-FN01 |
| PERSONAL_SCHEDULE_AI-API02 | Audit/event integration | Event after successful sensitive write | correlation_id + entity/action summary | Recorded event/audit result | Functions with side effects |

## 4. Entity / Model Dependencies

| Entity / Model | Intended File | Source | Used At |
|---|---|---|---|
| PERSONAL_SCHEDULE_AI-E-personal_plan | planned:lib/app_versions/v1/services/ai/domain/ | Personal Plan | Features/functions/views in this module |
| PERSONAL_SCHEDULE_AI-E-plan_item | planned:lib/app_versions/v1/services/ai/domain/ | Plan Item | Features/functions/views in this module |
| PERSONAL_SCHEDULE_AI-E-ai_request | planned:lib/app_versions/v1/services/ai/domain/ | AI Request | Features/functions/views in this module |

## 5. Constants, Config and Feature Flags

| ID | Name | Source | Default | Who Can Change | Used By |
|---|---|---|---|---|---|
| PERSONAL_SCHEDULE_AI-CFG01 | Module enablement / rollout flag | Planned remote config or backend config | Draft / disabled until approved | Product Owner / Tech Lead | All features |
| PERSONAL_SCHEDULE_AI-CFG02 | Module-specific thresholds or policy | System Configuration entity when applicable | OPEN QUESTION if BD does not define | Admin/Super Admin with audit | Business rules |

## 6. Merge Checklist

- [ ] File map is updated when code is implemented.
- [ ] No reverse layer imports.
- [ ] No secrets or production payloads in source/tests/docs.
- [ ] API/schema/RLS contracts are documented before coding.
- [ ] Tests cover permission, business rule, duplicate/retry, and dependency failure.
