# Worklog 002 - M13 QR rebuild

Date: 2026-08-13
Module: M13 `PAYMENT_MEMBERSHIP`
Workflow: coding / bugfix

## Goal

Rebuild membership VietQR creation so Supabase is the single authority for the
payment reference, transfer content, amount and receiving account. Mobile must
be able to create a QR even when the local payer profile is missing or stale.

## Implementation

- Added private Supabase function `generate_membership_payment_reference()`.
  It returns `NB` + 12 uppercase hexadecimal characters and checks the payment
  table before returning a candidate.
- Rebuilt canonical `create_membership_payment_request(plan, cycle,
  idempotency)` RPC. It reads the authenticated profile server-side, returns an
  existing open request idempotently, reads active price/bank configuration,
  creates the payment and snapshots the trusted transfer data.
- Added a four-argument compatibility wrapper for older mobile builds; the
  caller-provided payer name is ignored.
- Flutter's canonical RPC sends only plan/cycle/idempotency; a guarded PGRST202 fallback keeps the previous four-argument Supabase RPC usable during rollout.
- Payment controller no longer blocks creation on local/full-name availability.
- Restored strict `^NB[0-9A-F]{12}$` validation and fail-closed server response
  validation before rendering a transfer QR.
- Hardened VietQR builder input validation while retaining the NAPAS merchant
  account hierarchy and `QRIBFTTA` service code.
- Added SQL contract smoke and Flutter QR builder coverage.

## Security / access

Creating a QR or confirming a transfer does not grant Plus/FamilyPlus access.
The existing `pending_review -> succeeded` trusted review path remains the only
payment path that may drive membership entitlement refresh.

## Validation status

- Static patch checks: completed in the generation environment.
- Flutter/Dart execution: not available in the generation container; run
  `VERIFY_PATCH.ps1` in the NanoBio development environment.
- Supabase live/sandbox execution: requires the target project; run migration 25
  then smoke 26 before production rollout.
