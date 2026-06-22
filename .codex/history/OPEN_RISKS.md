# Open Risks

Default risk register. This file contains only risks that are still open or need verification. Raw extracted history lives in RISK_HISTORY.md.

## NB-RISK-001 Supabase sandbox/staging verification pending

- Severity: P1
- Status: Needs Verification
- Updated: 2026-06-22
- Evidence: docs/worklog/2026-06-21/002-worklog-supabase-database-draft.md; docs/supabase/08-acceptance-checks.md.
- Impact: Membership, quota, FamilyPlus, sale/referral, payment, and RLS behavior cannot be treated as production-ready until SQL/RLS is verified outside docs.
- Proposed handling: Run Supabase local or sandbox verification, record RLS smoke results for at least two users and family scopes, then update this risk with evidence.
- Owner/scope: Backend/Supabase implementation.

## NB-RISK-002 Product flow DD open decisions Q-01..Q-10

- Severity: P1
- Status: Blocked
- Updated: 2026-06-22
- Evidence: docs/worklog/2026-06-21/007-worklog-product-flow-dd-design.md; docs/DD/product_flow/00_READ_FIRST.md.
- Impact: Dependent implementation details for membership/payment/family/referral flows may be wrong if coded before product decisions are closed.
- Proposed handling: Product Owner/Tech Lead closes Q-01..Q-10, then update affected DD files from Draft to implementation-ready where appropriate.
- Owner/scope: Product/Tech Lead decision.

## NB-RISK-003 Multi-device snapshot conflict policy is not finalized

- Severity: P1
- Status: Needs Product Decision
- Updated: 2026-06-22
- Evidence: docs/features/cloud-sync-sale/001-feature-cloud-sync-sale.md; docs/worklog/2026-06-22/009-worklog-cloud-sync-sale.md.
- Impact: A cloud-wins login pull can overwrite unsynchronised changes from another device; the current full-snapshot design intentionally does not merge divergent histories.
- Proposed handling: Define per-table versioning/conflict rules and proof scenarios before enabling multi-device sync as a production promise.
- Owner/scope: Product/Tech Lead and Backend/Supabase implementation.

