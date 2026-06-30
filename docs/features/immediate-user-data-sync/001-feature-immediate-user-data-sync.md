# Immediate user-data sync after local commits

Commit de xuat: `feat(sync): request an immediate outbox drain after user data writes`

## Status

Implemented in Flutter source. Supabase schema, RLS policies and RPC signatures are unchanged.

## Target behavior

After a committed persistent user-data action, the app should request a Supabase outbox drain immediately without delaying the UI. SQLite remains the durable first write. If the user is signed out, offline, or an RPC fails, the existing outbox marker remains available for the authenticated sync and retry flow.

## Covered high-priority flows

- onboarding completion after the initial plan is persisted;
- generated meal/schedule plan persistence;
- daily health task, water, mood and weight updates;
- normal lifestyle-schedule completion and linked meal/task updates;
- standalone meal completion;
- profile and avatar updates;
- notification complete/skip actions.

All remaining user-owned SQLite tables remain covered by existing outbox triggers and the application refresher. This is intentionally local-first: guest data is queued locally and is associated with the Supabase account during the existing authenticated guest-to-account sync flow.

## Design

`LocalUserDataSyncDispatcher` is a core, version-neutral post-commit signal. `main.dart` and `main_v2.dart` register the Supabase outbox drain once Supabase has initialized. V1 data sources signal only the core dispatcher, preserving the v1/v2 architecture boundary.

## Files

- `lib/core/storage/localdb/sync/local_user_data_sync_dispatcher.dart`
- `lib/services/supabase/cloud_sync/user_data_sync_outbox.dart`
- `lib/services/supabase/cloud_sync/user_data_sync_outbox_refresher.dart`
- `lib/main.dart`, `lib/main_v2.dart`
- onboarding, settings, daily tracking, schedule, meal, generated-plan and notification write paths.

## Non-goals / boundaries

- No service-role key or direct privileged client access is introduced.
- No change is made to payment, Sale, membership, quota or Admin authority.
- Device-only UI preferences without a Supabase domain contract are not promoted to cloud data by this change.
