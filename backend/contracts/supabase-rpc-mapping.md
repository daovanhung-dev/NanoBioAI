# Hosted contract replacement inventory

This is a source-to-backend map for the legacy RPCs, PostgREST tables and
Storage paths used by Flutter and Admin Web. It documents local source
coverage; it does not prove that the production server has been migrated,
deployed or cut over.

State meanings:

- `DONE`: a self-hosted route now handles the active client use case.
- `PARTIAL`: a route exists but differs from the old contract or needs a
  provider, production configuration, imported data or follow-up read path.
- `NO_CALLER`: the old contract has no current client caller and is kept only
  in the read-only archive.

## App RPCs

| # | Legacy RPC | Self-hosted route | State / limitation |
|---:|---|---|---|
| 1 | `admin_cancel_reward_redemption` | `POST /api/v1/admin/business/wellness-rewards` (`cancel`) | DONE; requires confirmation that a voucher was revoked externally |
| 2 | `admin_get_payment_review_alert` | `GET /api/v1/admin/payments/review-alert` | PARTIAL; counts local manual-transfer reviews, not imported historical payments |
| 3 | `admin_import_reward_codes` | `POST /api/v1/admin/business/wellness-rewards` (`import_codes`) | DONE; voucher codes are hashed for duplicate checks and stored for issuance |
| 4 | `admin_list_audit_events` | `GET /api/v1/admin/audit-events` | PARTIAL; bounded list, source filters are not all exposed |
| 5 | `admin_list_wellness_rewards_v2` | `GET /api/v1/admin/business/wellness-rewards` | DONE for bounded offer/redemption listing |
| 6 | `admin_mark_reward_redemption_received` | `POST /api/v1/admin/business/wellness-rewards` (`mark_received`) | DONE for physical rewards in redeemed state |
| 7 | `admin_search_users` | `GET /api/v1/admin/users/search` | PARTIAL; local user and membership projection, not every historical Admin column |
| 8 | `admin_upsert_reward_offer_v2` | `POST /api/v1/admin/business/wellness-rewards` (`upsert_offer`) | DONE for the current mobile/Admin Web offer fields |
| 9 | `attach_my_referral_code` | `POST /api/v1/sale/referrals/attach` | DONE; active referral code, one referral per member and device reuse checks |
| 10 | `cancel_my_membership_payment_request` | `POST /api/v1/payments/membership-requests/{id}/cancel` | DONE for local manual transfers |
| 11 | `confirm_my_membership_payment_transfer` | `POST /api/v1/payments/membership-requests/{id}/confirm` | DONE for local manual transfers |
| 12 | `create_membership_payment_request` | `POST /api/v1/payments/membership-requests` | DONE when server price and bank settings are configured |
| 13 | `delete_sleep_safety_contact` | `DELETE /api/v1/sleep-safety/contacts/{id}` | DONE with owner check |
| 14 | `get_admin_dashboard_summary` | `GET /api/v1/admin/dashboard` | DONE for current backend metrics and date filters |
| 15 | `get_my_admin_session` | `GET /api/v1/admin/session` | DONE; roles and server-derived permission projection |
| 16 | `get_my_familyplus_context` | `GET /api/v1/family-plus/context` | DONE with active FamilyPlus subscription check |
| 17 | `get_my_membership_payment_request` | `GET /api/v1/payments/membership-requests/me` | DONE for local manual transfers |
| 18 | `get_my_reward_code` | `GET /api/v1/wellness/rewards/redemptions/{id}/code` | DONE for the caller's eligible redemption |
| 19 | `get_my_sale_conversions` | `GET /api/v1/sale/conversions` | DONE for the active Sale member |
| 20 | `get_my_sale_dashboard` | `GET /api/v1/sale/dashboard` | DONE; payment counts use the backend payment ledger |
| 21 | `get_my_sale_direct_customers` | `GET /api/v1/sale/customers` | DONE for the active Sale member |
| 22 | `get_my_sale_payout_profile` | `GET /api/v1/sale/payout-profile` | DONE for the active Sale member |
| 23 | `get_my_sale_point_ledger` | `GET /api/v1/sale/point-ledger` | DONE for the active Sale member |
| 24 | `get_my_sale_state` | `GET /api/v1/sale/me` | DONE |
| 25 | `get_my_wellness_rank_summary` | `GET /api/v1/wellness/rank/summary` | DONE for server-computed rank |
| 26 | `get_my_wellness_reward_summary` | `GET /api/v1/wellness/rewards/summary` | DONE |
| 27 | `list_my_reward_catalog_v2` | `GET /api/v1/wellness/rewards/offers` | DONE for eligible and currently available offers |
| 28 | `list_my_reward_redemptions_v2` | `GET /api/v1/wellness/rewards/redemptions` | DONE |
| 29 | `list_my_wellness_point_history` | `GET /api/v1/wellness/rewards/history` | DONE |
| 30 | `redeem_my_reward_v2` | `POST /api/v1/wellness/rewards/redemptions` | DONE with server wallet locking and idempotency |
| 31 | `remove_my_familyplus_member` | `DELETE /api/v1/family-plus/members/{id}` | DONE with owner and active-group checks |
| 32 | `request_sale_participation` | `POST /api/v1/sale/participation` | DONE; Admin approval is separate |
| 33 | `request_sale_point_conversion` | `POST /api/v1/sale/conversions` | DONE with server balance/config checks |
| 34 | `sync_my_mobile_snapshot` | `GET/PUT /api/v1/cloud-sync/snapshot`; `/api/v1/schedule-rewards/*` | PARTIAL; allowlisted snapshots plus explicit reward APIs; production import and cutover are pending |
| 35 | `upsert_my_familyplus_group` | `PUT /api/v1/family-plus/group` | DONE with owner lock and active-plan check |
| 36 | `upsert_my_familyplus_member` | `PUT /api/v1/family-plus/members` | DONE with subject ownership, role and member-limit checks |
| 37 | `upsert_my_sale_payout_profile` | `PUT /api/v1/sale/payout-profile` | DONE for the active Sale member |
| 38 | `upsert_sleep_safety_contact` | `POST/PUT /api/v1/sleep-safety/contacts` | DONE with owner checks |

## Additional Admin Web contracts

| Admin operation | Self-hosted route | State / limitation |
|---|---|---|
| List sales, conversions, wellness rewards, reconciliation, plans/config and reports | `GET /api/v1/admin/business/{section}` | DONE for bounded source data; report exports are requests, not generated files |
| Update user status | `PATCH /api/v1/admin/users/{id}/status` | DONE with audit reason and idempotency |
| Review Sale profile and conversion | `POST /api/v1/admin/business/{section}` | DONE; payment proof links are protected and role scoped |
| Adjust Sale points | `POST /api/v1/admin/business/sale-conversions` | DONE with audit and idempotency |
| Create reconciliation run and update discrepancy | `POST /api/v1/admin/business/reconciliation` | PARTIAL; run currently snapshots the local pending-review queue, not an external provider reconciliation |
| Upsert config version | `POST /api/v1/admin/business/config` | PARTIAL; versioned business config is separate from process environment settings such as Sleep Safety provider credentials |
| Request report export | `POST /api/v1/admin/business/reports` | PARTIAL; creates a requested export row; no completed export worker is configured |
| Review manual payment / refund or cancel | `/api/v1/admin/payments/{id}/review` and `/reversal` | PARTIAL; manual transfer only, no external Google Play refund call |
| Upload payout proof | `POST /api/v1/files/sale-payout-proofs` | DONE with file signature, size and owner checks |
| Download payout proof | `GET /api/v1/admin/files/sale-payout-proofs/{id}` | DONE for Finance/Super Admin and only while linked to a conversion |

## Direct table and Storage access

| Legacy access | Backend replacement | State / limitation |
|---|---|---|
| `users` profile reads/writes | `/api/v1/profile/me`, `/api/v1/account/me`, Admin user routes | PARTIAL; only supported profile fields are writable |
| `health_subjects` | Self subject on signup; owner-scoped FamilyPlus APIs | PARTIAL; legacy subjects are not imported until a separate cutover |
| `effective_user_access` | `GET /api/v1/membership/me` | DONE for backend-owned subscriptions; imported legacy membership remains pending |
| `sleep_safety_runtime_config` | Server environment settings | PARTIAL; no live Admin editor for provider secrets/settings |
| Sleep Safety contacts/preferences/sessions/events | `/api/v1/sleep-safety/*` | PARTIAL; owner-scoped history reads and writes are present; legacy history import is pending the final data cutover |
| `schedule-completion-proofs` Storage | `/api/v1/schedule-rewards/completions/{id}/proof` and `/proof/admin` | DONE for owner and Operations Admin access; transfer of historical objects is pending |
| `sale-payout-proofs` Storage | `/api/v1/files/sale-payout-proofs` and protected Admin download route | DONE for new files; historical object transfer is pending |

## Cutover status

The mobile, Admin Web and Early Access source now use the self-hosted API path;
runtime/build source audit is a separate verification from production behavior.
The production backend remains on an earlier Alembic revision, public HTTPS
port 443 is unreachable, and this task has not deployed migrations, imported
the final snapshot or Storage objects, frozen Supabase writes, or distributed
the rebuilt APK. Existing installed clients therefore continue to depend on
Supabase until a separate distribution/cutover.
