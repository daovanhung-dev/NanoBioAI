# Supabase replacement API inventory

Source inventory is `supabase/config.toml` plus each current `supabase/functions/<name>/index.ts` and handler. This contract maps configured routes. The backend source/tests are the runtime evidence; this inventory alone is not a verification claim.

| Edge Function | Backend API |
|---|---|
| `member-phone-signup` | `POST /api/v1/auth/phone-signup` |
| `member-change-password` | `POST /api/v1/auth/change-password` |
| `delete-account` | `DELETE /api/v1/account` |
| `admin-create-account` | `POST /api/v1/admin/accounts` |
| `admin-grant-membership` | `POST /api/v1/admin/memberships/grant` |
| `admin-adjust-membership-period` | `POST /api/v1/admin/memberships/adjust-period` |
| `admin-grant-membership-bulk` | `POST /api/v1/admin/memberships/bulk-grant` |
| `admin-provision-accounts-bulk` | `POST /api/v1/admin/accounts/bulk-provision/preview`, `/api/v1/admin/accounts/bulk-provision` |
| `admin-user-management` | `/api/v1/admin/users/{user_id}`, `/profile`, `/password-reset` |
| `admin-early-access-leads` | `GET /api/v1/admin/early-access/leads`, `PATCH /api/v1/admin/early-access/leads/{lead_id}` |
| `google-play-verify-purchase` | `POST /api/v1/payments/google-play/verify` |
| `register-early-access` | `POST /api/v1/early-access` |
| `report-ai-content` | `POST /api/v1/ai-content-reports` |
| `nabi-food-evidence` | `POST /api/v1/food/evidence` |
| `sleep-safety-contact-verification` | `POST /api/v1/sleep-safety/contacts/verification` |
| `sleep-safety-dispatch` | `POST /api/v1/sleep-safety/dispatch` |
| `sleep-safety-provider-webhook` | `POST /api/v1/webhooks/sleep-safety/generic_http` |
| `nabi-ai-generate` | `POST /api/v1/ai/generate` (503 `FEATURE_NOT_ENABLED`) |
| `food-scan-analyze` | `POST /api/v1/food/scan/analyze` (503 `FEATURE_NOT_ENABLED`) |

There are 25 function directories including `_shared`; 19 are configured. Six unconfigured, empty directories are intentionally `NOT_FOUND` and receive no route: `admin-backup-control`, `admin-purge-gmail-accounts`, `member-password-change-request`, `nutrition-food-composition`, `voice-chat-turn`, `voice-live-token`.
