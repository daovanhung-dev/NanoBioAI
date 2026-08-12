# Import File — PAYMENT_MEMBERSHIP / Thanh toán, xác minh và quyền gói

## 0. Dependency Rules

1. Presentation -> Provider/Controller -> Use case -> Repository -> Datasource/API/DAO.
2. Presentation does not call SQLite DAO or raw Supabase client directly.
3. Flutter never contains service-role keys and never creates trusted payment success locally.
4. Membership/payment/quota authority is Supabase; SQLite is only a local projection/read-model.
5. Shared upgrade/reference normalization belongs in `lib/core/membership/` and must not import app-version code.

## 1. Package / External Dependency Registry

| Dependency | Purpose | Security note |
|---|---|---|
| Supabase | Auth, config, payment RPC, subscriptions, effective access, Admin audit | Trusted state; no service role in Flutter. |
| Riverpod | Controller/provider state and invalidation | No direct entitlement grant. |
| GoRouter | Canonical upgrade route | Query only selects initial UI plan. |
| qr_flutter | Render QR payload | Only server-returned canonical NB reference used as transfer content. |
| sqflite | Local user profile/read-model | Payer name + subscription label only; never payment authority. |

## 2. Implemented File Map

| File Path | Layer / Responsibility |
|---|---|
| `lib/core/membership/membership_upgrade_route.dart` | Shared plan normalization, canonical payment route and exact NB reference normalization. |
| `lib/shared/membership/presentation/membership_upgrade_navigation.dart` | Shared upgrade prompt/navigation. |
| `lib/app_versions/v2/features/payments/domain/entities/membership_payment_models.dart` | Payment request state + exact QR/copy reference boundary. |
| `lib/app_versions/v2/features/payments/application/` | Create/get/confirm/cancel use cases and payer-name read use case. |
| `lib/app_versions/v2/features/payments/data/` | Payment repository/RPC datasource + local payer-profile datasource. |
| `lib/app_versions/v2/features/payments/providers/membership_payment_providers.dart` | Payment lifecycle, idempotency, succeeded-only trusted/access projection refresh. |
| `lib/app_versions/v2/features/payments/presentation/pages/membership_payment_page.dart` | Plan/cycle UI, server details, QR/copy, cancel/confirm, poll/resume. |
| `lib/app_versions/v2/router/v2_router.dart` | Payment route consumes canonical shared plan normalizer. |
| `lib/app_versions/v3/router/v3_router.dart` | Standalone paid surface consumes same route normalizer. |
| `lib/app_versions/v2/features/cloud_sync/` | Existing authenticated server -> SQLite projection refresh; includes `subscription_tier`. |
| `lib/app_versions/v1/features/dashboard/providers/dashboard_provider.dart` | Invalidated after successful trusted projection pull so Dashboard re-reads SQLite. |
| `lib/app_versions/admin/features/admin_panel/` | Finance/Super-only payment section, queue, reconciliation confirm and mutations. |
| `docs/supabase/23-membership-payment-hardening.sql` | Non-destructive M13 hardening migration. |
| `docs/supabase/config.sql` | Disposable local/sandbox rebuild source with matching final contract. |
| `test/docs/fixtures/supabase_membership_payment_hardening_smoke.sql` | Rollback-only executable SQL acceptance fixture. |

## 3. Supabase RPC Contract

### Member

- `create_membership_payment_request(plan, cycle, idempotency, payer_full_name)`
- `get_my_membership_payment_request()`
- `confirm_my_membership_payment_transfer(payment_event_id)`
- `cancel_my_membership_payment_request(payment_event_id)`

All are authenticated owner-scoped. Price/bank/reference are server-owned.

### Admin

- `admin_get_payment_review_alert()`
- `admin_list_payments(query, limit)`
- `admin_review_payment(payment_event_id, decision, reason, idempotency_key, transfer_verified)`

Payment review RPCs require Finance/Super reviewer role even if a non-financial Admin holds wildcard legacy permission.

## 4. Trusted Projection Refresh

`payment succeeded -> invalidate effectiveAccessProvider -> authenticated cloud-sync pull -> SQLite users.subscription_tier -> invalidate dashboardProvider`

The client never copies `request.planCode` into SQLite as trusted access. A projection-sync failure leaves trusted effective access authoritative and retryable.

## 5. Test Map

| Test | Coverage |
|---|---|
| `test/core/membership/membership_upgrade_route_test.dart` | canonical plan route + exact NB normalizer |
| `test/core/membership/membership_upgrade_gate_contract_test.dart` | AI/schedule/Plus/FamilyPlus gates use shared route |
| `test/app_versions/v2/features/payments/membership_payment_test.dart` | domain/reference/idempotency/cancel contracts |
| `test/app_versions/v2/features/payments/providers/membership_payment_controller_test.dart` | succeeded-only effective-access + projection refresh |
| `test/app_versions/v2/features/payments/presentation/membership_payment_page_test.dart` | QR/copy/cancel/poll/fail-closed UI |
| Admin tests | role/reviewer/reconciliation UI payload |
| `test/docs/supabase_membership_payment_hardening_contract_test.dart` | migration/rebuild/smoke source contract |
| `test/docs/fixtures/supabase_membership_payment_hardening_smoke.sql` | executable transaction/RLS/review/subscription cases |

## 6. External Acceptance

Still required before production: full-checkout Flutter validation, disposable Supabase execution, true two-session concurrency, and VCB bank-app QR/manual reconciliation UAT.
