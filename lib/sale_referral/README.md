# Sale Referral Module

Sale/referral is an independent product axis, separate from membership tier and
app version. The authenticated mobile client reads and writes through the
versioned NanoBio backend API. Referral approvals, payment state, commission,
and conversion review remain server/Admin responsibilities; the client never
creates trusted financial records directly.

Business guardrails:

- Direct referral commission is 10% of an eligible successful package payment.
- Referral commission is direct-only; no indirect or multi-level payout.
- No commission is created from client-reported payment success.
- Sale registration creates a pending request; Admin approval is required
  before an active referral code is allocated.

Production data import and cutover are separate from this source migration.
