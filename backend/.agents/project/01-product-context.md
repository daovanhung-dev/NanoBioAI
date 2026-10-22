# NanoBioAI Backend Product Context

## Project state

- Product: NanoBioAI / NamiAI health assistant.
- Backend goal: replace app, Admin Web and website calls to Supabase Auth, PostgREST, RPC, Storage and configured Edge Functions with self-hosted `/api/v1` APIs.
- This phase builds the backend only. Client migration, Supabase shutdown, deployment, production-data import, and data reconciliation are later phases.
- Existing Supabase users cannot sign in until a separately approved migration; local test data is disposable and synthetic.
- AI inference stays on-device. The legacy AI generation routes return `FEATURE_NOT_ENABLED`.

## Actors

| Actor | Trust boundary | Rights | Forbidden |
|---|---|---|---|
| Guest | Unauthenticated | Public early-access registration and source-approved public lookups | Read or mutate member/admin data |
| Member | Phone/password session | Own account, profile, sync snapshot, health, membership, sleep-safety and rewards | Read another member or grant access |
| Admin | Server-assigned role | Only actions allowed by role and audited | Trust client-supplied role or user identity |
| Service provider | Signed/configured integration | Narrow callback or verification contract | General database access |

## Business modules in scope

Auth/account, profile and cloud snapshot, access/membership/quotas, family, payment and Google Play verification, sale/referral, wellness rank/rewards, admin operations, early access, AI-content report, sleep safety, food evidence, and protected file storage. The current-source inventory is in `modules/README.md`.

## Source-backed limitations

- NIN/USDA food evidence uses external sources and requires provider configuration/network; it is distinct from model inference.
- Six empty Edge Function directories (`admin-backup-control`, `admin-purge-gmail-accounts`, `member-password-change-request`, `nutrition-food-composition`, `voice-chat-turn`, `voice-live-token`) are `NOT_FOUND`; no endpoints are created for them.
- Supabase's canonical SQL contains platform auth, RLS, storage, scheduler and broader schema objects. Port only reachable contracts; do not copy the entire schema as-is.
- Admin Web direct database/function usage is a migration target, but this phase does not edit its source.
