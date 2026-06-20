# DD-AUTH-FR-12 - Xử lý lỗi và phục hồi dữ liệu cũ

**BD nguồn:** AUTH-FR-12  
**Dependencies:** `03_DATA_MODEL_RLS_AND_MIGRATIONS.md`, `database/002_verify_auth_profile_integrity.sql`

## 1. Error classification

| Code | Situation | User treatment | Technical action |
|---|---|---|---|
| `AUTH_INVALID_CREDENTIALS` | email/password invalid | neutral login message | no enumeration |
| `AUTH_EMAIL_UNVERIFIED` | confirmation pending | route verification | resend subject to cooldown |
| `AUTH_PROFILE_MISSING` | auth session but no base rows | temporary support/retry screen | server-side integrity check/repair |
| `AUTH_RLS_DENIED` | ownership policy rejects request | generic update/data access failure | investigate policy/session mismatch |
| `AUTH_TRIGGER_FAILED` | sign-up fails due trigger/db | create account temporarily unavailable | inspect DB logs, do not client patch |
| `AUTH_NETWORK` | transport timeout/offline | retry | idempotent retry behavior |
| `AUTH_RATE_LIMITED` | provider throttling | wait then retry | no automatic loop |
| `AUTH_DEEP_LINK_INVALID` | invalid verification/recovery callback | show retry or open email again | verify redirect allow-list |

## 2. Existing user backfill

Accounts existing before bootstrap trigger require server-side backfill:

1. Insert missing `public.users` from `auth.users`.
2. Insert missing `health_profiles` by `public.users.id`.
3. Insert missing `lifestyle_habits` by `public.users.id`.
4. Run integrity query and ensure no gaps remain.
5. Record migration/worklog evidence.

Do not make Flutter “repair” missing profile data with client insert, because client permissions are intentionally revoked and that would hide a database integrity failure.

## 3. Missing profile after login

- Keep session but do not route Dashboard.
- Render a friendly temporary state with retry/support action.
- Send safe observability event including current auth UUID only if privacy policy allows; no health form data.
- Operations runs integrity query; repair through SQL Editor/controlled migration.

## 4. Transaction/retry policy

- Auth signup: request retry may be appropriate, but no follow-up arbitrary DB inserts.
- Onboarding collection writes: idempotent upsert by natural unique constraints where available.
- Status completion: only after valid persisted data; keep `in_progress` on partial error.

## 5. Incident checklist

- [ ] Capture Supabase auth/database error code in secure logs.
- [ ] Confirm environment and migrations version.
- [ ] Run profile integrity verify query.
- [ ] Confirm RLS policy and authenticated JWT subject.
- [ ] Repair only server-side.
- [ ] Create issue under `docs/issues` and later TODO/fix workflow if bug is confirmed.
