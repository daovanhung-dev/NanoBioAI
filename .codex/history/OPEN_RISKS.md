# Open Risks

Default risk register. This file contains only risks that are still open or need verification. Raw extracted history lives in `RISK_HISTORY.md`.

## NB-RISK-001 Supabase sandbox/staging verification pending

- Severity: P1
- Status: Needs Verification
- Updated: 2026-08-29
- Evidence: `docs/supabase/README.md`; `docs/supabase/01_build_system.sql`; `docs/worklog/2026-06-21/002-worklog-supabase-database-draft.md`.
- Impact: Membership, quota, FamilyPlus, sale/referral, payment, and RLS behavior cannot be treated as production-ready until SQL/RLS is executed outside docs.
- Proposed handling: Run the build system and seed data scripts in Supabase local/sandbox, record RLS smoke results for at least two users and family scopes, then update this risk with evidence.
- Owner/scope: Backend/Supabase implementation.

## NB-RISK-002 Google Play purchase and release signing evidence pending

- Severity: P0
- Status: Blocked on external access
- Updated: 2026-08-29
- Evidence: `docs/release/google_play/RELEASE_EVIDENCE_MATRIX.md`; Play Billing source/tests.
- Impact: Real internal-track purchase, acknowledgement, renewal/cancellation and release AAB cannot be claimed until Play Console products, tester account and signing metadata are available.
- Proposed handling: Configure all four subscription products, run a real purchase/replay test, build the release-signed AAB, and attach Play Console evidence.
- Owner/scope: Release/Play Console.

## NB-RISK-003 AI/Supabase runtime deployment evidence pending

- Severity: P1
- Status: Needs Verification
- Updated: 2026-08-29
- Evidence: `supabase/functions/nabi-ai-generate`; `supabase/functions/report-ai-content`; `test/docs/fixtures/supabase_google_play_ai_deletion_smoke.sql`.
- Impact: Backend AI generation, guest reporting, rate limits, deletion anonymization and provider-secret configuration are source-covered but not runtime-proven in this workspace.
- Proposed handling: Deploy functions to a disposable sandbox, run handler tests plus authenticated/guest HTTP checks, and record logs/results without secrets.
- Owner/scope: Backend/Supabase implementation.

## NB-RISK-004 Play legal pages and declaration evidence pending

- Severity: P0
- Status: Blocked on external access
- Updated: 2026-08-29
- Evidence: `docs/release/google_play/PRIVACY_POLICY_PUBLIC_PAGE.md`; `docs/release/google_play/ACCOUNT_DELETION_PUBLIC_PAGE.md`; `docs/release/google_play/DATA_SAFETY_MAPPING.md`; `docs/release/google_play/HEALTH_APPS_DECLARATION.md`; `lib/core/config/app_env.dart`.
- Impact: The source exposes release-configured legal links, but Play Console submission cannot be completed until a real HTTPS privacy policy/account-deletion page, support contact, and final Data Safety/Health answers are published and verified.
- Proposed handling: Publish both pages, wire `PRIVACY_POLICY_URL` and `ACCOUNT_DELETION_URL` in the release config, verify them from an incognito browser, then submit the matching declarations.
- Owner/scope: Product/Privacy/Release.
