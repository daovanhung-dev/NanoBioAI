# Open Risks

Default risk register. This file contains only risks that are still open or need verification. Raw extracted history lives in `RISK_HISTORY.md`.

## NB-RISK-001 Supabase sandbox/staging verification pending

- Severity: P1
- Status: Needs Verification
- Updated: 2026-07-12
- Evidence: `docs/worklog/2026-06-21/002-worklog-supabase-database-draft.md`; `docs/supabase/08-acceptance-checks.md`.
- Impact: Membership, quota, FamilyPlus, sale/referral, payment, and RLS behavior cannot be treated as production-ready until SQL/RLS is verified outside docs.
- Proposed handling: Run Supabase local or sandbox verification, record RLS smoke results for at least two users and family scopes, then update this risk with evidence.
- Owner/scope: Backend/Supabase implementation.
