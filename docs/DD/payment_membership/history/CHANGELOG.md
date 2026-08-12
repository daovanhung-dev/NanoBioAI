# CHANGELOG — PAYMENT_MEMBERSHIP / Thanh toán, xác minh và quyền gói

## [v1.4] - 2026-08-12

### Changed

- Hardened VietQR transfer content to the immutable `NB + 12 uppercase hex` reference only; payer name/plan/cycle stay separate metadata/display.
- Added owner-only cancellation before transfer confirmation and one-open-request-per-user locking/unique constraint contract.
- Restricted payment alert/queue/review to active `finance_admin` and `super_admin`; Support/Content/Operations are denied even with legacy wildcard permissions.
- Made approve require explicit VCB reconciliation confirmation and reason; reject still requires reason; review remains idempotent/audited.
- Documented finite membership periods: same-plan renewal from active expiry, immediate Plus ↔ FamilyPlus switch, calendar month/year in Asia/Ho_Chi_Minh, and fail-closed legacy `ends_at` remediation.
- Added succeeded-only trusted access + existing cloud projection refresh so Dashboard membership labels reload from Supabase-derived SQLite data instead of client-assigned plan state.
- Added exact NB/gate/controller/widget contract tests and rollback-only Supabase M13 payment hardening smoke source.

### Validation

- This patch contains source and acceptance-test definitions. Full-checkout Flutter execution, Supabase sandbox execution/two-session concurrency and VCB bank-app UAT remain required and must not be claimed as passed without external evidence.

## [v1.3] - 2026-07-31
### Changed
- Documented the initial VietQR Vietcombank flow: server-generated immutable NB reference, client QR presentation, member transfer confirmation, and manual VCB reconciliation.
- Added `awaiting_transfer -> pending_review -> succeeded/failed` and retained legacy pending review compatibility.
- Added the explicit boundary: no receipt upload, bank API, bank-balance display, or webhook; only Admin approval activates a package.

## [v1.2] - 2026-06-30
### Changed
- Marked PAYMENT_MEMBERSHIP DD docs as approved/docs-complete and separated runtime/sandbox evidence from DD completeness.

## [v1.1] - 2026-06-30
### Decisions
- Q-03 listed-price commission base.
- Q-04 monthly/yearly renewal policy.
- Q-05 refund/cancel/chargeback point reversal policy.
- Q-11 FamilyPlus owner-portion commission.
- Q-17 manual payment approval.

## [v1.0] - 2026-06-28
### Added
- Initial M13 DD from BD-BIOAI-PRODUCT-FLOW-002.
