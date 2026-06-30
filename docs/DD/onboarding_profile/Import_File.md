# Import File — ONBOARDING_PROFILE / Onboarding & Hồ sơ sức khỏe

## 0. Dependency Rules

1. Presentation -> Provider/Controller -> Use case/Service -> Repository -> Datasource/API/DAO.
2. Presentation must not import SQLite DAO, Supabase raw client, or payment/referral backend directly.
3. Domain/use-case code must not import UI widgets or BuildContext.
4. Shared utilities must not contain module-specific business logic.
5. Secrets, service-role keys, payment evidence, and raw health data must not be hard-coded or committed.

## 1. Package / External Dependency Registry

| ID | Package / Service | Version / Plan | Source | Purpose | Owner | Security Note |
|---|---|---|---|---|---|---|
| ONBOARDING_PROFILE-DEP01 | Supabase / trusted backend | Planned contract | BD sections 13, 14, 17 | Auth, entitlement, RLS, Admin/Sale/payment data as applicable | Backend/Tech Lead | No service-role key in Flutter. |
| ONBOARDING_PROFILE-DEP02 | Flutter/Riverpod/GoRouter | Existing stack | .codex/AGENTS.md | Presentation, state, navigation | App team | Keep layer boundaries. |

## 2. File Map and Internal Contract

| File Path | Layer | Responsibility | Allowed Imports | Forbidden Imports | Public Export | Feature / Function |
|---|---|---|---|---|---|---|
| planned:lib/app_versions/v1/features/onboarding/presentation/ | Presentation | Render views and dispatch user actions | Providers, view models, theme tokens, router | DAO, raw Supabase/payment clients, storage models | Screens/widgets | ONBOARDING_PROFILE-Vxx |
| planned:lib/app_versions/v1/features/onboarding/application/ | Use case / Service | Orchestrate validation, authorization, business rules | Domain entities, repository interfaces, policies | Widgets, BuildContext, raw SQL/API client | execute(command, actorContext) | ONBOARDING_PROFILE-FNxx |
| planned:lib/app_versions/v1/features/onboarding/domain/ | Domain | Entity and policy contracts | Pure Dart/value objects | UI, persistence implementation | Entities/policies | ONBOARDING_PROFILE-E-* |
| planned:lib/app_versions/v1/features/onboarding/data/ | Repository/Datasource | Persist/integrate with local/trusted backend | Datasource/API/DAO contracts, mappers | UI widgets/controllers | Repository implementation | ONBOARDING_PROFILE-FNxx |
| planned:test/ | Test | Unit/integration/widget tests | Public contracts and fakes at correct layer | Production secrets or real payment/webhook payloads | Test fixtures | ONBOARDING_PROFILE-TCxx |

## 3. API / Datasource Dependencies

| ID | API / Datasource | Method / Event | Request | Response | Used By |
|---|---|---|---|---|---|
| ONBOARDING_PROFILE-API01 | `saveOnboardingProfile` command / `rpc_onboarding_profile_save_onboarding_profile` trusted RPC when server-owned state is written | Use-case command handler; RPC only for financial, entitlement, quota, family, Sale, Admin, audit, or sensitive writes | actor_context, command DTO, correlation_id, idempotency_key for writes | Result/Error DTO, safe_user_message, domain_error_code, audit_ref for sensitive writes | ONBOARDING_PROFILE-FN01 |
| ONBOARDING_PROFILE-API02 | `completeOnboardingAndHandoff` command / `rpc_onboarding_profile_complete_onboarding_and_handoff` trusted RPC when server-owned state is written | Use-case command handler; RPC only for financial, entitlement, quota, family, Sale, Admin, audit, or sensitive writes | actor_context, command DTO, correlation_id, idempotency_key for writes | Result/Error DTO, safe_user_message, domain_error_code, audit_ref for sensitive writes | ONBOARDING_PROFILE-FN02 |
| ONBOARDING_PROFILE-API-AUDIT | Audit/event integration | Event after successful sensitive write | correlation_id, actor_id, action, entity_ref, reason, idempotency_key | audit_id, recorded_at, immutable action summary | Functions with side effects |

## 4. Entity / Model Dependencies

| Entity / Model | Intended File | Source | Used At |
|---|---|---|---|
| ONBOARDING_PROFILE-E-guest_profile | planned:lib/app_versions/v1/features/onboarding/domain/ | Guest Profile | Features/functions/views in this module |
| ONBOARDING_PROFILE-E-onboarding_profile | planned:lib/app_versions/v1/features/onboarding/domain/ | Onboarding Profile | Features/functions/views in this module |

## 5. Constants, Config and Feature Flags

| ID | Name | Source | Default | Who Can Change | Used By |
|---|---|---|---|---|---|
| ONBOARDING_PROFILE-CFG01 | Module enablement / rollout flag | Planned remote config or backend config | Disabled until release enabled; DD docs approved | Product Owner / Tech Lead | All features |
| ONBOARDING_PROFILE-CFG02 | Module-specific thresholds or policy | System Configuration entity or Admin managed policy version | Versioned default from accepted DD decisions; disabled only when feature flag is off | Super Admin/Admin role allowed by M16 with audit | Business rules |

## 6. Documented Dependency Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| ONBOARDING_PROFILE-IMP-EV01 | File map is updated when code is implemented. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| ONBOARDING_PROFILE-IMP-EV02 | No reverse layer imports. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| ONBOARDING_PROFILE-IMP-EV03 | No secrets or production payloads in source/tests/docs. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| ONBOARDING_PROFILE-IMP-EV04 | API/schema/RLS contracts are documented before coding. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| ONBOARDING_PROFILE-IMP-EV05 | Tests cover permission, business rule, duplicate/retry, and dependency failure. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
