# Sale Referral Module

Sale/referral is an independent product axis, not a membership package and not
an app version. A user can have a membership package and may or may not have
active Sale status.

Current status:

- Placeholder feature folders exist for referral code, Sale dashboard,
  commission records, and trusted payment events.
- No client-only payment or commission logic is implemented.
- Future implementation must use a trusted backend or Supabase source for Sale
  status, referral relationships, payment success, and commission records.

Business guardrails from BD:

- Direct referral commission is 10% from successful package payment.
- Referral commission is direct-only; no indirect or multi-level payout.
- No commission is created from client-reported payment success.
