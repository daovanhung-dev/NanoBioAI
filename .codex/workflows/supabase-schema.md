# Workflow - Supabase Schema

Use for Supabase SQL, RLS, membership/quota, FamilyPlus, sale/referral, payment, or seed docs.

## Required Context

- `.codex/AGENTS.md`
- `.codex/PROJECT_MAP.md`
- `.codex/domains/access-membership-referral.md`
- `docs/supabase/README.md`
- `docs/supabase/config.sql`
- Directly relevant SQL/MD file in `docs/supabase/`
- Related BD/DD when behavior is being defined.

## Rules

- Supabase/trusted backend is the source of truth for membership, sale status, referral tree, payment success, commission, and quota counters.
- Flutter never stores service-role keys or writes server-only tables directly.
- RLS must protect cross-user and cross-family data.
- SQL draft files are not production migrations until reviewed in sandbox/staging.
- `docs/supabase/config.sql` is the single local/sandbox rebuild entrypoint.
  Any schema/RLS/RPC/seed/docs change under `docs/supabase` must update it in
  the same change.
- If `docs/supabase/config.sql` cannot be updated, record the blocker in the
  worklog and do not claim the Supabase state is rebuild-ready.

## Completion

- Update acceptance/checklist docs when schema or RLS changes.
- Confirm `docs/supabase/config.sql` contains the current final contract for the
  changed Supabase objects.
- Run docs-only SQL grep checks; do not claim live Supabase verification unless actually run.
- Create worklog and refresh `.codex/history/`.
