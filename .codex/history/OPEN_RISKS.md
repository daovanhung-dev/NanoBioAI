# Open Risks

Default risk register. This file contains only risks that are still open or need verification. Raw extracted history lives in `RISK_HISTORY.md`.

## NB-RISK-001 Supabase sandbox/staging verification pending

- Severity: P1
- Status: Needs Verification
- Updated: 2026-08-30
- Evidence: `docs/supabase/README.md`; `docs/supabase/01_build_system.sql`; `docs/worklog/2026-06-21/002-worklog-supabase-database-draft.md`.
- Impact: Membership, quota, FamilyPlus, sale/referral, payment, and RLS behavior cannot be treated as production-ready until SQL/RLS is executed outside docs.
- Proposed handling: Run the build system and seed data scripts in Supabase local/sandbox, record RLS smoke results for at least two users and family scopes, then update this risk with evidence.
- Owner/scope: Backend/Supabase implementation.
