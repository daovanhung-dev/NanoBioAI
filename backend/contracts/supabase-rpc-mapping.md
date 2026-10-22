# RPC, PostgREST, and Storage replacement inventory

This inventory is based on current app call sites, `admin-web/src/lib/admin-api.ts`,
and `docs/supabase/01_build_system.sql`. `DONE` means a local API with the main
source behavior exists; it does not mean the unchanged app or Admin Web calls it.
`PARTIAL` means the API covers only part of the source contract. No placeholder
route is published for a contract whose business rules are not ported.

## App RPCs

| # | Supabase RPC | Backend API or module | State |
|---:|---|---|---|
| 1 | `admin_cancel_reward_redemption` | — | NOT_YET_PORTED |
| 2 | `admin_get_payment_review_alert` | `GET /api/v1/admin/payments/review-alert` | PARTIAL: counts local manual transfer reviews |
| 3 | `admin_import_reward_codes` | — | NOT_YET_PORTED |
| 4 | `admin_list_audit_events` | `GET /api/v1/admin/audit-events` | PARTIAL: basic bounded listing, no source query filters |
| 5 | `admin_list_wellness_rewards_v2` | — | NOT_YET_PORTED |
| 6 | `admin_mark_reward_redemption_received` | — | NOT_YET_PORTED |
| 7 | `admin_search_users` | `GET /api/v1/admin/users/search` | PARTIAL: user and active membership summary; role permissions and full Admin Web fields differ |
| 8 | `admin_upsert_reward_offer_v2` | — | NOT_YET_PORTED |
| 9 | `attach_my_referral_code` | `POST /api/v1/auth/phone-signup` referral fields | PARTIAL: only signup-time attachment; no standalone attach API or active Sale profile model |
| 10 | `cancel_my_membership_payment_request` | `POST /api/v1/payments/membership-requests/{id}/cancel` | DONE for local manual transfer requests |
| 11 | `confirm_my_membership_payment_transfer` | `POST /api/v1/payments/membership-requests/{id}/confirm` | DONE for local manual transfer requests |
| 12 | `create_membership_payment_request` | `POST /api/v1/payments/membership-requests` | DONE when Ubuntu price and bank settings are supplied |
| 13 | `delete_sleep_safety_contact` | `DELETE /api/v1/sleep-safety/contacts/{id}` | DONE with owner check |
| 14 | `get_admin_dashboard_summary` | — | NOT_YET_PORTED |
| 15 | `get_my_admin_session` | `GET /api/v1/admin/session` | PARTIAL: local role list, not source permission projection |
| 16 | `get_my_familyplus_context` | `GET /api/v1/family-plus/context` | DONE with active FamilyPlus subscription check |
| 17 | `get_my_membership_payment_request` | `GET /api/v1/payments/membership-requests/me` | DONE for local manual transfer requests |
| 18 | `get_my_reward_code` | — | NOT_YET_PORTED |
| 19 | `get_my_sale_conversions` | — | NOT_YET_PORTED |
| 20 | `get_my_sale_dashboard` | — | NOT_YET_PORTED |
| 21 | `get_my_sale_direct_customers` | — | NOT_YET_PORTED |
| 22 | `get_my_sale_payout_profile` | — | NOT_YET_PORTED |
| 23 | `get_my_sale_point_ledger` | — | NOT_YET_PORTED |
| 24 | `get_my_sale_state` | — | NOT_YET_PORTED |
| 25 | `get_my_wellness_rank_summary` | — | NOT_YET_PORTED |
| 26 | `get_my_wellness_reward_summary` | — | NOT_YET_PORTED |
| 27 | `list_my_reward_catalog_v2` | — | NOT_YET_PORTED |
| 28 | `list_my_reward_redemptions_v2` | — | NOT_YET_PORTED |
| 29 | `list_my_wellness_point_history` | — | NOT_YET_PORTED |
| 30 | `redeem_my_reward_v2` | — | NOT_YET_PORTED |
| 31 | `remove_my_familyplus_member` | `DELETE /api/v1/family-plus/members/{member_id}` | DONE with owner and active-group check |
| 32 | `request_sale_participation` | — | NOT_YET_PORTED |
| 33 | `request_sale_point_conversion` | — | NOT_YET_PORTED |
| 34 | `sync_my_mobile_snapshot` | `GET/PUT /api/v1/cloud-sync/snapshot` | PARTIAL: allowlisted per-user JSON snapshot; Supabase subject, reward eligibility, and relational write semantics are not yet ported |
| 35 | `upsert_my_familyplus_group` | `PUT /api/v1/family-plus/group` | DONE with owner lock and active-plan check |
| 36 | `upsert_my_familyplus_member` | `PUT /api/v1/family-plus/members` | DONE with subject ownership, role and member-limit checks |
| 37 | `upsert_my_sale_payout_profile` | — | NOT_YET_PORTED |
| 38 | `upsert_sleep_safety_contact` | `POST/PUT /api/v1/sleep-safety/contacts` | DONE with owner checks |

## Other current Admin Web RPCs

The Admin Web also resolves RPC names dynamically by section/action. These are
additional contracts beyond the app's 38 literal RPC names. The payment list
and review flows have local API equivalents, limited to the new local manual
membership payment records; they do not migrate or expose historical Supabase
payment rows. `admin_list_payments` maps to `GET /api/v1/admin/payments` and is
PARTIAL. `admin_review_payment` maps to
`POST /api/v1/admin/payments/{payment_id}/review` and is PARTIAL: manual
transfers only, requires explicit bank reconciliation before approval, and
creates or renews local entitlement transactionally. The remaining contracts
are `NOT_YET_PORTED`: `admin_list_sales`, `admin_list_sale_point_conversions`, `admin_list_wellness_rewards`,
`admin_list_reconciliation_discrepancies`, `admin_list_plan_config_versions`,
`admin_list_report_catalog`, `admin_list_report_exports`,
`admin_update_user_status`, `admin_refund_or_cancel_payment`, `admin_review_sale_profile`,
`admin_adjust_sale_points`, `admin_review_sale_point_conversion`,
`admin_create_reconciliation_run`,
`admin_update_reconciliation_discrepancy_status`,
`admin_upsert_config_version`, `admin_request_report_export`,
`admin_upsert_reward_offer`, `admin_import_reward_codes`, and
`admin_cancel_reward_redemption`.

The Admin Web must be integrated in a later app/web phase. It still uses
Supabase Auth and RPC today; this backend does not make the unchanged client
switch automatically.

## Direct table and Storage access

| Supabase access | Backend replacement | State / limit |
|---|---|---|
| `users` profile reads | `GET/PATCH /api/v1/profile/me`, `GET /api/v1/account/me` | PARTIAL: self profile subset |
| `health_subjects` | created as self on local signup; used by FamilyPlus APIs | PARTIAL: self and owner-managed family subjects; no legacy subject import |
| `effective_user_access` | `GET /api/v1/membership/me` | PARTIAL: computed from local subscriptions; no Sale/anonymous legacy projection |
| `sleep_safety_runtime_config` | Ubuntu environment settings | PARTIAL: operational configuration is server-side and has no Admin Web editor API |
| `sleep_safety_contacts` | `/api/v1/sleep-safety/contacts` | DONE for owner CRUD and provider verification flows |
| `sale-payout-proofs` Storage bucket | `/api/v1/files/sale-payout-proofs` | PARTIAL: owner-scoped local files; no Admin Web reviewer download route yet |
