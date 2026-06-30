# Import File — SALE_POINTS / Điểm Sale & quy đổi

## 0. Dependency Rules

1. Presentation -> Provider/Controller -> Use case/Service -> Repository -> Datasource/API/DAO.
2. Presentation must not import SQLite DAO, Supabase raw client, or payment/referral backend directly.
3. Domain/use-case code must not import UI widgets or BuildContext.
4. Shared utilities must not contain module-specific business logic.
5. Secrets, service-role keys, payment evidence, and raw health data must not be hard-coded or committed.

## 1. Package / External Dependency Registry

| ID | Package / Service | Version / Plan | Source | Purpose | Owner | Security Note |
|---|---|---|---|---|---|---|
| SALE_POINTS-DEP01 | Supabase / trusted backend | Planned contract | BD sections 13, 14, 17 | Auth, entitlement, RLS, Admin/Sale/payment data as applicable | Backend/Tech Lead | No service-role key in Flutter. |
| SALE_POINTS-DEP02 | Flutter/Riverpod/GoRouter | Existing stack | .codex/AGENTS.md | Presentation, state, navigation | App team | Keep layer boundaries. |

## 2. File Map and Internal Contract

| File Path | Layer | Responsibility | Allowed Imports | Forbidden Imports | Public Export | Feature / Function |
|---|---|---|---|---|---|---|
| planned:lib/sale_referral/sale_points/presentation/ | Presentation | Render views and dispatch user actions | Providers, view models, theme tokens, router | DAO, raw Supabase/payment clients, storage models | Screens/widgets | SALE_POINTS-Vxx |
| planned:lib/sale_referral/sale_points/application/ | Use case / Service | Orchestrate validation, authorization, business rules | Domain entities, repository interfaces, policies | Widgets, BuildContext, raw SQL/API client | execute(command, actorContext) | SALE_POINTS-FNxx |
| planned:lib/sale_referral/sale_points/domain/ | Domain | Entity and policy contracts | Pure Dart/value objects | UI, persistence implementation | Entities/policies | SALE_POINTS-E-* |
| planned:lib/sale_referral/sale_points/data/ | Repository/Datasource | Persist/integrate with local/trusted backend | Datasource/API/DAO contracts, mappers | UI widgets/controllers | Repository implementation | SALE_POINTS-FNxx |
| planned:test/ | Test | Unit/integration/widget tests | Public contracts and fakes at correct layer | Production secrets or real payment/webhook payloads | Test fixtures | SALE_POINTS-TCxx |

## 3. API / Datasource Dependencies

| ID | API / Datasource | Method / Event | Request | Response | Used By |
|---|---|---|---|---|---|
| SALE_POINTS-API01 | `creditSalePointsForApprovedPayment` command / `rpc_sale_points_credit_sale_points_for_approved_payment` trusted RPC when server-owned state is written | Use-case command handler; RPC only for financial, entitlement, quota, family, Sale, Admin, audit, or sensitive writes | actor_context, command DTO, correlation_id, idempotency_key for writes | Result/Error DTO, safe_user_message, domain_error_code, audit_ref for sensitive writes | SALE_POINTS-FN01 |
| SALE_POINTS-API02 | `requestAndReviewSalePointConversion` command / `rpc_sale_points_request_and_review_sale_point_conversion` trusted RPC when server-owned state is written | Use-case command handler; RPC only for financial, entitlement, quota, family, Sale, Admin, audit, or sensitive writes | actor_context, command DTO, correlation_id, idempotency_key for writes | Result/Error DTO, safe_user_message, domain_error_code, audit_ref for sensitive writes | SALE_POINTS-FN02 |
| SALE_POINTS-API-AUDIT | Audit/event integration | Event after successful sensitive write | correlation_id, actor_id, action, entity_ref, reason, idempotency_key | audit_id, recorded_at, immutable action summary | Functions with side effects |

## 4. Entity / Model Dependencies

| Entity / Model | Intended File | Source | Used At |
|---|---|---|---|
| SALE_POINTS-E-sale_commission_ledger | planned:lib/sale_referral/sale_points/domain/ | Sale Commission Ledger | Features/functions/views in this module |
| SALE_POINTS-E-sale_point_balance | planned:lib/sale_referral/sale_points/domain/ | Sale Point Balance | Features/functions/views in this module |
| SALE_POINTS-E-sale_point_conversion | planned:lib/sale_referral/sale_points/domain/ | Sale Point Conversion | Features/functions/views in this module |

## 5. Constants, Config and Feature Flags

| ID | Name | Source | Default | Who Can Change | Used By |
|---|---|---|---|---|---|
| SALE_POINTS-CFG01 | Module enablement / rollout flag | Planned remote config or backend config | Draft / disabled until approved | Product Owner / Tech Lead | All features |
| SALE_POINTS-CFG02 | Module-specific thresholds or policy | System Configuration entity or Admin managed policy version | Versioned default from accepted DD decisions; disabled only when feature flag is off | Super Admin/Admin role allowed by M16 with audit | Business rules |

## 6. Merge Checklist

- [ ] File map is updated when code is implemented.
- [ ] No reverse layer imports.
- [ ] No secrets or production payloads in source/tests/docs.
- [ ] API/schema/RLS contracts are documented before coding.
- [ ] Tests cover permission, business rule, duplicate/retry, and dependency failure.
