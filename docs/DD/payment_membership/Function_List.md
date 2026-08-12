# Function List — PAYMENT_MEMBERSHIP / Thanh toán, xác minh và quyền gói

## 0. Layer Convention

`View -> Provider/Controller -> Use case -> Repository -> Datasource/API -> Supabase/SQLite`

Flutter never writes trusted payment/subscription/quota state directly.

## 1. Function Registry

| ID | Function | Actor | Responsibility | Status |
|---|---|---|---|---|
| PAYMENT_MEMBERSHIP-FN01 | createMembershipPayment | Member | Create/replay request with server-owned price/bank and canonical NB-only memo; enforce one open request. | Implemented |
| PAYMENT_MEMBERSHIP-FN03 | confirmMembershipTransfer | Member | Owner-only `awaiting_transfer -> pending_review`; no access grant. | Implemented |
| PAYMENT_MEMBERSHIP-FN04 | cancelMembershipPayment | Member | Owner-only cancel while awaiting transfer; canceled replay idempotent. | Implemented |
| PAYMENT_MEMBERSHIP-FN02 | reviewMembershipPayment | Finance/Super | Manual VCB review; approve/reject; finite renewal/switch + audit. | Implemented |
| PAYMENT_MEMBERSHIP-FN05 | refreshApprovedMembershipProjection | Client orchestration | After backend returns succeeded, reload trusted access and cloud user projection; invalidate Dashboard only after successful cloud sync. | Implemented |

## 2. PAYMENT_MEMBERSHIP-FN01 — createMembershipPayment

### Input

`plan_code`, `billing_cycle`, `idempotency_key`, `payer_full_name`.

The client does **not** provide amount, bank account, transfer reference or access status.

### Contract

1. Require `auth.uid()` and Plus/FamilyPlus + monthly/yearly values.
2. Lock `public.users` payer row.
3. Replay same provider-event/idempotency request when it exists.
4. If any open manual request (`awaiting_transfer`/`pending_review`) exists, return `MEMBERSHIP_PAYMENT_REQUEST_ALREADY_OPEN`.
5. Read active `membership_payment_prices` + `membership_payment_bank` config.
6. Generate `NB` + 12 uppercase hex; `transfer_memo := transfer_reference`.
7. Persist payer full name, plan/cycle and bank snapshot in metadata for display/reconciliation only.
8. Return `can_cancel=true` only for awaiting transfer.

### Tests

- Canonical NB format/reference-only content.
- Server-owned recipient/amount.
- Idempotent retry and one-open guard.
- No access before approval.

## 3. PAYMENT_MEMBERSHIP-FN03 — confirmMembershipTransfer

- Owner-only payment lookup.
- Require reference and memo to be exact/canonical and equal.
- `awaiting_transfer -> pending_review`; repeated pending_review confirmation is safe.
- Store confirmation timestamp/details for Admin reconciliation.
- Return `can_cancel=false`.
- Do not mutate subscription/access.

## 4. PAYMENT_MEMBERSHIP-FN04 — cancelMembershipPayment

- Owner-only `cancel_my_membership_payment_request(payment_event_id)`.
- `awaiting_transfer -> canceled` with canceled time/actor/reason metadata.
- Repeating on canceled returns the same terminal result.
- Any other state returns `PAYMENT_CANCELLATION_NOT_ALLOWED`.
- Cancel never invalidates/grants paid access.

## 5. PAYMENT_MEMBERSHIP-FN02 — reviewMembershipPayment

### Authorization

`admin_assert_payment_reviewer()` requires active `finance_admin` or `super_admin` and payment write capability. Legacy wildcard does not grant payment review to Support/Content/Operations.

### Input

`payment_event_id`, `decision`, `reason`, `idempotency_key`, `transfer_verified`.

### Contract

- Decision ∈ approve/reject; reason always required.
- Approve requires `transfer_verified=true` after VCB reconciliation.
- Only pending_review / legacy pending is reviewable.
- Same terminal decision is idempotent; conflicting terminal decision is rejected.
- Approve blocks if any active paid legacy subscription lacks `ends_at`.
- Cross-plan active subscription is canceled/superseded immediately and linked in metadata/audit.
- Same-plan active subscription extends from current `ends_at`.
- New/switch starts at review time.
- Period end = one calendar month/year from period start in `Asia/Ho_Chi_Minh`.
- Persist starts_at, ends_at, current_period_start, current_period_end.
- Approve -> payment succeeded + subscription link. Reject -> failed and no subscription creation.
- Audit contains actor via auth context, decision, reconciliation flag, reference, billing cycle, transition and superseded subscription IDs.

## 6. PAYMENT_MEMBERSHIP-FN05 — refreshApprovedMembershipProjection

1. Trigger only after payment response is `succeeded`, once per payment ID in controller lifetime.
2. Invalidate `effectiveAccessProvider` first; this remains authority.
3. Use existing authenticated cloud-sync to pull current Supabase user row including `subscription_tier` into SQLite.
4. Only after a successful sync invalidate `dashboardProvider` so membership label re-reads the trusted projection.
5. If cloud projection refresh fails, do not set a plan locally; normal cloud sync can retry.

## 7. Security / Idempotency Requirements

- Client direct INSERT/UPDATE/DELETE on payment/subscription/quota remains revoked.
- RLS prevents cross-user payment reads.
- Payer lock + partial unique index prevents multiple open requests; a two-session sandbox test is still required to prove concurrency behavior externally.
- No bank secret/service-role key in Flutter.
