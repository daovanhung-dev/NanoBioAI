# Workflow - Supabase Schema

Use for Supabase SQL, RLS, membership/quota, FamilyPlus, sale/referral, payment, or seed docs.

## Required Context

- `.codex/AGENTS.md`
- `.codex/PROJECT_MAP.md`
- `.codex/domains/access-membership-referral.md`
- `docs/supabase/README.md`
- Directly relevant SQL/MD file in `docs/supabase/`
- Related BD/DD when behavior is being defined.

## Rules

- Supabase/trusted backend is the source of truth for membership, sale status, referral tree, payment success, commission, and quota counters.
- Flutter never stores service-role keys or writes server-only tables directly.
- RLS must protect cross-user and cross-family data.
- SQL draft files are not production migrations until reviewed in sandbox/staging.

## Completion

- Update acceptance/checklist docs when schema or RLS changes.
- Run docs-only SQL grep checks; do not claim live Supabase verification unless actually run.
- Create worklog and refresh `.codex/history/`.
