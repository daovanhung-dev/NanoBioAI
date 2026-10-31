# Legacy Supabase Function to Backend API Map

The former project inventory is archived under `docs/archive/legacy-supabase/project/`. This table is a historical mapping aid; the backend source and tests define current behavior. Nothing in the archive is deployed by the runtime or release workflow.

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
| `nabi-ai-generate` | `POST /api/v1/ai/generate` and `/api/v1/ai/generate/stream` (requires authenticated session and enabled Ollama service) |
| `food-scan-analyze` | `POST /api/v1/food/scan/analyze` (requires authenticated eligible membership and enabled Ollama vision service) |

The historical tree has 25 function directories including `_shared`; 19 were configured. Empty or unconfigured functions have no active client caller and are not part of the server API. Local XiaoZhi voice remains a separate device contract.
