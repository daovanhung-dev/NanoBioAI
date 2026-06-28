# Sale Referral Module

Sale/referral is an independent product axis, not a membership package and not
an app version. A user can have a membership package and may or may not have
active Sale status.

Current status:

- Sale UI uses a Clean Architecture path under `lib/sale_referral`: domain
  models/repository, Supabase datasource, Riverpod providers and presentation.
- Runtime reads Sale state, direct customers, point ledger and conversion queue
  only through Supabase RPC contracts.
- Payment success, point creation, Sale approval and conversion review remain
  trusted backend/Admin responsibilities; Flutter never creates those records
  by writing tables directly.

Business guardrails from BD:

- Direct referral commission is 10% from successful package payment.
- Referral commission is direct-only; no indirect or multi-level payout.
- No commission is created from client-reported payment success.
- Sale registration creates a pending request; Admin approval is required before
  an active referral code is allocated.
