# Open Risks

Default risk register. This file contains only risks that are still open or need verification. Raw extracted history lives in RISK_HISTORY.md.

## NB-RISK-001 Supabase sandbox/staging verification pending

- Severity: P1
- Status: Needs Verification
- Updated: 2026-07-13
- Evidence: docs/worklog/2026-06-21/002-worklog-supabase-database-draft.md; docs/supabase/08-acceptance-checks.md.
- Impact: Membership, quota, FamilyPlus, sale/referral, payment, wellness rewards, private proof Storage, and RLS behavior cannot be treated as production-ready until SQL/RLS/Storage is verified outside docs.
- Proposed handling: Run Supabase local or sandbox verification, record RLS smoke results for at least two users and family scopes, then update this risk with evidence.
- Owner/scope: Backend/Supabase implementation.

## NB-RISK-003 Wellness rewards migration and rollout pending

- Severity: P1
- Status: Needs Verification
- Updated: 2026-07-13
- Evidence: `docs/supabase/16-wellness-rewards.sql`; `docs/supabase/16-schedule-proof-storage.md`; `docs/checklist/checklist_complete_DD.md`.
- Impact: Static contracts, full local config rebuild and local end-to-end/RLS smoke pass, but eligibility/proof rewards, append-only ledger, voucher inventory/redemption and Admin cancel/refund are not production evidence until migration 16, RPC, RLS and Storage are exercised in a real Supabase sandbox. Proof objects also need an account-deletion cleanup job.
- Proposed handling: Keep `wellness_rewards_rollout.enabled = false`; apply migration/config in sandbox; create and verify private bucket `schedule-completion-proofs`; run two-user path/RLS, direct-DML rejection, retry/two-device, expiry/FEFO/overspend, atomic inventory and cancel/refund/audit checks; verify account-deletion cleanup; import test catalog/codes; only then enable the flag.
- Owner/scope: Backend/Supabase, mobile/Admin release and QA.
