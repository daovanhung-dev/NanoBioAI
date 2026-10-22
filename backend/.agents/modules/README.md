# Backend Module Inventory

## Supabase function inventory

| Source function | Backend API/module | Source status |
|---|---|---|
| `member-phone-signup` | `POST /api/v1/auth/phone-signup` | SOURCE_BACKED |
| `member-change-password` | `POST /api/v1/auth/change-password` | SOURCE_BACKED |
| `delete-account` | `DELETE /api/v1/account` | SOURCE_BACKED |
| `admin-create-account` | `POST /api/v1/admin/accounts` | SOURCE_BACKED |
| `admin-grant-membership` | `POST /api/v1/admin/memberships/grant` | SOURCE_BACKED |
| `admin-adjust-membership-period` | `POST /api/v1/admin/memberships/adjust-period` | SOURCE_BACKED |
| `admin-grant-membership-bulk` | `POST /api/v1/admin/memberships/bulk-grant` | SOURCE_BACKED |
| `admin-provision-accounts-bulk` | `POST /api/v1/admin/accounts/bulk-provision` | SOURCE_BACKED |
| `admin-user-management` | `/api/v1/admin/users/*` | SOURCE_BACKED |
| `admin-early-access-leads` | `/api/v1/admin/early-access/leads` | SOURCE_BACKED |
| `google-play-verify-purchase` | `POST /api/v1/payments/google-play/verify` | SOURCE_BACKED; provider credentials required |
| `register-early-access` | `POST /api/v1/early-access` | SOURCE_BACKED |
| `report-ai-content` | `POST /api/v1/ai-content-reports` | SOURCE_BACKED |
| `nabi-food-evidence` | `POST /api/v1/food/evidence` | SOURCE_BACKED; NIN/USDA providers |
| `sleep-safety-contact-verification` | `/api/v1/sleep-safety/contacts/verification` | SOURCE_BACKED; SMS provider required |
| `sleep-safety-dispatch` | `POST /api/v1/sleep-safety/dispatch` | SOURCE_BACKED; rollout/provider required |
| `sleep-safety-provider-webhook` | `/api/v1/webhooks/sleep-safety/{provider}` | SOURCE_BACKED; signature required |
| `nabi-ai-generate` | `POST /api/v1/ai/generate` | DECLARED_NOT_ENABLED; 503 by decision |
| `food-scan-analyze` | `POST /api/v1/food/scan/analyze` | DECLARED_NOT_ENABLED; 503 by decision |
| `admin-backup-control` | none | NOT_FOUND (empty source directory) |
| `admin-purge-gmail-accounts` | none | NOT_FOUND (empty source directory) |
| `member-password-change-request` | none | NOT_FOUND (empty source directory) |
| `nutrition-food-composition` | none | NOT_FOUND (empty source directory) |
| `voice-chat-turn` | none | NOT_FOUND (empty source directory) |
| `voice-live-token` | none | NOT_FOUND (empty source directory) |

The currently called RPC inventory (38 function names) and direct PostgREST/Storage access are part of the migration contract. See root `docs/supabase/README.md`, source call sites, and the backend API routers. This table records route mapping, not proof that every contract is runtime verified.

## Runtime module map

| Module | Responsibilities | Source-backed files |
|---|---|---|
| `auth` | Phone signup/login, Argon2id, refresh rotation, password update/logout, rate limits | `models.py`, `validate.py`, `query.py`, `view.py`, `router.py` |
| `account` | Owner profile read and confirmed account deletion | `models.py`, `view.py`, `router.py` |
| `profile` | Self profile fields | `models.py`, `view.py`, `router.py` |
| `membership` | Current local entitlement summary | `models.py`, `validate.py`, `query.py`, `view.py`, `router.py` |
| `family_plus` | Paid-plan group, owner-managed health subjects, member limits and membership context | `models.py`, `query.py`, `view.py`, `router.py` |
| `cloud_sync` | Versioned per-user snapshot with SQL-source column allowlists | `models.py`, `contract.py`, `validate.py`, `query.py`, `view.py`, `router.py` |
| `payments` | Google Play verification and local manual bank-transfer request lifecycle | `models.py`, `validate.py`, `query.py`, `view.py`, `router.py` |
| `admin` | Local roles, account/membership operations, audit, early-access lead management | `models.py`, `query.py`, `view.py`, `router.py` |
| `edge_api` | Early Access, food evidence, AI-content reports, Google Play route orchestration, disabled legacy AI | `models.py`, `view.py`, `router.py` |
| `sleep_safety` | Contacts, verification, dispatch, provider webhook | `models.py`, `validate.py`, `query.py`, `view.py`, `router.py` |
| `storage` | Local file upload/download/delete with owner scope | `query.py`, `view.py`, `router.py` |

See [`../../contracts/supabase-rpc-mapping.md`](../../contracts/supabase-rpc-mapping.md) for the full app RPC inventory and the additional dynamic Admin Web calls. Unported source contracts stay explicitly marked `NOT_YET_PORTED`.
