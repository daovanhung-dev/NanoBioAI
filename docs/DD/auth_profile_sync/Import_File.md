# Import File — AUTH_PROFILE_SYNC / Xác thực, hồ sơ và đồng bộ Guest

## 0. Dependency Rules

1. Presentation -> Provider/Controller -> Use case/Service -> Repository -> Datasource/API/DAO.
2. Presentation must not import SQLite DAO, Supabase raw client, or payment/referral backend directly.
3. Domain/use-case code must not import UI widgets or BuildContext.
4. Shared utilities must not contain module-specific business logic.
5. Secrets, service-role keys, payment evidence, and raw health data must not be hard-coded or committed.

## 1. Package / External Dependency Registry

| ID | Package / Service | Version / Plan | Source | Purpose | Owner | Security Note |
|---|---|---|---|---|---|---|
| AUTH_PROFILE_SYNC-DEP01 | Supabase / trusted backend | Planned contract | BD sections 13, 14, 17 | Auth, entitlement, RLS, Admin/Sale/payment data as applicable | Backend/Tech Lead | No service-role key in Flutter. |
| AUTH_PROFILE_SYNC-DEP02 | Flutter/Riverpod/GoRouter | Existing stack | .codex/AGENTS.md | Presentation, state, navigation | App team | Keep layer boundaries. |

## 2. File Map and Internal Contract

| File Path | Layer | Responsibility | Allowed Imports | Forbidden Imports | Public Export | Feature / Function |
|---|---|---|---|---|---|---|
| planned:lib/app_versions/v2/features/auth/presentation/ | Presentation | Render views and dispatch user actions | Providers, view models, theme tokens, router | DAO, raw Supabase/payment clients, storage models | Screens/widgets | AUTH_PROFILE_SYNC-Vxx |
| planned:lib/app_versions/v2/features/auth/application/ | Use case / Service | Orchestrate validation, authorization, business rules | Domain entities, repository interfaces, policies | Widgets, BuildContext, raw SQL/API client | execute(command, actorContext) | AUTH_PROFILE_SYNC-FNxx |
| planned:lib/app_versions/v2/features/auth/domain/ | Domain | Entity and policy contracts | Pure Dart/value objects | UI, persistence implementation | Entities/policies | AUTH_PROFILE_SYNC-E-* |
| planned:lib/app_versions/v2/features/auth/data/ | Repository/Datasource | Persist/integrate with local/trusted backend | Datasource/API/DAO contracts, mappers | UI widgets/controllers | Repository implementation | AUTH_PROFILE_SYNC-FNxx |
| planned:test/ | Test | Unit/integration/widget tests | Public contracts and fakes at correct layer | Production secrets or real payment/webhook payloads | Test fixtures | AUTH_PROFILE_SYNC-TCxx |

## 3. API / Datasource Dependencies

| ID | API / Datasource | Method / Event | Request | Response | Used By |
|---|---|---|---|---|---|
| AUTH_PROFILE_SYNC-API01 | Planned module API/service | TBD by implementation DD/API contract | Actor context + command DTO | Result/Error DTO | AUTH_PROFILE_SYNC-FN01 |
| AUTH_PROFILE_SYNC-API02 | Audit/event integration | Event after successful sensitive write | correlation_id + entity/action summary | Recorded event/audit result | Functions with side effects |

## 4. Entity / Model Dependencies

| Entity / Model | Intended File | Source | Used At |
|---|---|---|---|
| AUTH_PROFILE_SYNC-E-app_user | planned:lib/app_versions/v2/features/auth/domain/ | App User | Features/functions/views in this module |
| AUTH_PROFILE_SYNC-E-guest_sync | planned:lib/app_versions/v2/features/auth/domain/ | Guest Sync Snapshot | Features/functions/views in this module |

## 5. Constants, Config and Feature Flags

| ID | Name | Source | Default | Who Can Change | Used By |
|---|---|---|---|---|---|
| AUTH_PROFILE_SYNC-CFG01 | Module enablement / rollout flag | Planned remote config or backend config | Draft / disabled until approved | Product Owner / Tech Lead | All features |
| AUTH_PROFILE_SYNC-CFG02 | Module-specific thresholds or policy | System Configuration entity when applicable | OPEN QUESTION if BD does not define | Admin/Super Admin with audit | Business rules |

## 6. Merge Checklist

- [ ] File map is updated when code is implemented.
- [ ] No reverse layer imports.
- [ ] No secrets or production payloads in source/tests/docs.
- [ ] API/schema/RLS contracts are documented before coding.
- [ ] Tests cover permission, business rule, duplicate/retry, and dependency failure.
