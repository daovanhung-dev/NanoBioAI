# Workflow - Supabase Schema

Use for Supabase SQL, RLS, membership/quota, FamilyPlus, sale/referral, payment, or seed docs.

## Required Context

- `.codex/AGENTS.md`
- `.codex/PROJECT_MAP.md`
- `.codex/domains/access-membership-referral.md`
- `docs/supabase/README.md`
- `docs/supabase/01_build_system.sql`
- `docs/supabase/02_seed_data.sql`
- Directly relevant SQL/MD file in `docs/supabase/`
- Related BD/DD when behavior is being defined.

## Rules

- Supabase/trusted backend is the source of truth for membership, sale status, referral tree, payment success, commission, and quota counters.
- Flutter never stores service-role keys or writes server-only tables directly.
- RLS must protect cross-user and cross-family data.
- SQL draft files are not production migrations until reviewed in sandbox/staging.
- The local/sandbox rebuild is always `01_build_system.sql` followed by
  `02_seed_data.sql`; there is no generated aggregate entrypoint.
- Any schema/RLS/RPC/runtime/docs change under `docs/supabase` must update
  `01_build_system.sql` in the same change. Any destructive sandbox reset,
  catalog, configuration, account or fixture change must update
  `02_seed_data.sql` in the same change.
- If the owning canonical script cannot be updated, record the blocker in the
  worklog and do not claim the Supabase state is rebuild-ready.

## Completion

- Update acceptance/checklist docs when schema or RLS changes.
- Confirm the owning build or seed script contains the current final contract
  for the changed Supabase objects.
- Run docs-only SQL grep checks; do not claim live Supabase verification unless actually run.
- Create worklog and refresh `.codex/history/`.
