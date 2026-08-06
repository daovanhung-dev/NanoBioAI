# Open Risks

Default risk register. This file contains only risks that are still open or need verification. Raw extracted history lives in RISK_HISTORY.md.

## NB-RISK-001 Supabase sandbox/staging verification pending

- Severity: P1
- Status: Needs Verification
- Updated: 2026-07-31
- Evidence: docs/worklog/2026-06-21/002-worklog-supabase-database-draft.md; docs/supabase/08-acceptance-checks.md.
- Impact: Membership, quota, FamilyPlus, sale/referral, payment, and RLS behavior cannot be treated as production-ready until SQL/RLS is verified outside docs.
- Proposed handling: Run Supabase local or sandbox verification, record RLS smoke results for at least two users and family scopes, then update this risk with evidence.
- Owner/scope: Backend/Supabase implementation.

## NB-RISK-002 Nutrition catalog V17 runtime verification pending

- Severity: P1
- Status: Needs Verification
- Updated: 2026-08-02
- Evidence: docs/worklog/2026-08-02/001-worklog-nutrition-meal-catalog-voice-v17.md.
- Impact: SQLite V17 migration, Supabase RLS/RPC, voice native permissions and catalog cache cannot be treated as release-certified until targeted runtime tests pass.
- Proposed handling: run Flutter analyze/tests, V16-to-V17 migration tests, Supabase multi-user RLS matrix and Android/iOS device acceptance; keep all 163 source recipes ineligible until professional metadata approval.
- Owner/scope: Mobile + Backend/Supabase + nutrition content review.

## NB-RISK-003 Nabi Kinetic Aura runtime certification pending

- Severity: P1
- Status: Needs Verification
- Updated: 2026-08-05
- Evidence: docs/worklog/2026-08-05/002-worklog-nabi-kinetic-aura-coding.md; .codex/design/21_CODING_IMPLEMENTATION_STATUS.md.
- Impact: Motion, feedback, route transitions and shared primitive changes cannot be treated as release-certified until formatter, analyzer, targeted tests, APK build and real-device checks pass.
- Proposed handling: run targeted Dart format/analyze/tests first, then architecture tests, debug APK and Android device matrix covering Reduce Motion, text scale, frame timing and lifecycle.
- Owner/scope: Mobile Flutter/UI quality.

## NB-RISK-004 Physical Nabi SFX unavailable

- Severity: P2
- Status: Open
- Updated: 2026-08-05
- Evidence: docs/worklog/2026-08-05/001-worklog-nabi-kinetic-aura-design.md; docs/worklog/2026-08-05/002-worklog-nabi-kinetic-aura-coding.md.
- Impact: The app currently uses centralized platform system cues rather than the intended licensed Nabi micro-sound library; exact loudness, mixing and brand identity are not certified.
- Proposed handling: restore or create licensed SFX, review package size and platform playback, add an asset-backed adapter, then run sound-on/off/background/cooldown device tests.
- Owner/scope: Product audio + Mobile Flutter.

