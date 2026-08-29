# Account deletion

The app calls the `delete-account` Edge Function with an authenticated JWT and
an explicit `{ "confirm": true }` body. The function can delete only the
authenticated subject through Supabase Admin API. Before that call it removes
files below the authenticated user's prefix in the private
`schedule-completion-proofs` bucket; a Storage failure aborts the operation so
the Auth row is not deleted while owned objects remain.

The canonical SQL keeps ordinary user-owned rows cascading with
`public.users`. A before-delete trigger
`anonymize_deleted_user_records`:

- removes `user_id` from Google Play ledger rows so financial reconciliation
  does not retain an account identifier;
- clears AI report installation ID, note and original message snapshot;
- leaves only a non-reusable `[deleted-account]` marker and operational ledger
  fields.

Runtime deletion is not marked PASS until a sandbox test confirms the Edge
Function, auth deletion, database trigger and post-delete reads in separate
sessions.

The outside-app deletion page is specified in
`ACCOUNT_DELETION_PUBLIC_PAGE.md`. This repository has no web host or
deployment credential, so its public URL remains `BLOCKED_EXTERNAL` until the
product owner publishes it and wires `ACCOUNT_DELETION_URL` into the release
configuration and Settings UI.

## Retention matrix

| Domain | Reference | Rebuild behavior | Evidence query | Status |
| --- | --- | --- | --- | --- |
| Profile, health, meals, schedules, sleep and notifications | `owner_user_id`, `user_id`, or `created_by` | Cascade/delete with `public.users` | `select count(*) ... where <user-column> = <deleted-user>` | Static contract; sandbox open |
| Membership entitlement and quota | `user_id` | Cascade/delete; entitlement is recomputed from trusted rows | Query `membership_subscriptions`, `usage_events`, and quota ledgers | Static contract; sandbox open |
| Google Play purchase ledger | `user_id` | Set to `NULL` by `anonymize_deleted_user_records()`; retain token hash, product, state and timestamps for reconciliation | `select user_id from public.google_play_purchase_ledger where ...` | Static contract; retention-policy decision required |
| AI content reports | `user_id`, `message_id`, `installation_id` | Clear account linkage and free-text snapshot; retain only `[deleted-account]` marker and moderation state | `select user_id, message_id, installation_id, message_snapshot ...` | Static contract; sandbox open |
| Referral, Sale and family records | owner/member/referrer/reviewer FKs | FK-specific cascade or `SET NULL` in canonical build | Query every FK in `01_build_system.sql` for the deleted UUID | Static contract; sandbox open |
| Audit/security history | actor/reviewer FKs | `SET NULL` where retained for operational accountability | Query `admin_audit_events` and security tables | Static contract; legal retention decision required |
| Storage metadata/objects | owner path or metadata user ID | Edge Function removes account-owned schedule-proof objects before Auth deletion; other operational buckets require an explicit ownership review | List the user's storage prefix before/after deletion | Source-ready; sandbox open |

The matrix intentionally does not invent a legal retention period. Before
production, Privacy/Legal must approve the retained purchase, moderation and
audit fields and their retention duration.
