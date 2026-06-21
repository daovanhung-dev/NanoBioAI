# DD-PRODUCT-FLOW-DB-001 - Data Model, Supabase, RLS và Migration

**BD/DD source:** `BD-BIOAI-PRODUCT-FLOW-001`, `docs/supabase/*`  
**Migration ID:** Draft từ `docs/supabase/*.sql`  
**Backward compatible:** Requires sandbox review  
**Status:** Draft  

## 1. Goal

Thiết kế data boundary để Supabase là source of truth cho Auth, profile, health subjects, membership, quota, FamilyPlus, Sale/referral, payment event và commission; SQLite chỉ là local/offline cache cho V1 và dữ liệu app.

## 2. Existing schema impact

| Object | Change | Compatibility | Data migration |
|---|---|---|---|
| `public.users` | Business profile, subscription read model, access status, sale status | Compatible nếu giữ `id = auth.users.id` | Backfill từ `auth.users` |
| `health_subjects` | Boundary cho self/family member | New table | Tạo self subject cho user cũ |
| Health/schedule tables | Thêm `subject_id` và ownership theo subject | Requires careful migration | Map existing local/cloud rows theo user/self subject |
| Membership/quota tables | Plans, subscriptions, entitlements, rules, counters, events | New trusted source | Seed reference data |
| Family tables | Groups/members | New V3 boundary | Backend-only mutation until DD Ready |
| Sale/payment/commission tables | Referral, payment, commission | New trusted source | Backend/webhook/admin only |

## 3. DDL / policy design

DD này không copy full SQL để tránh drift. SQL source nằm ở:

- `docs/supabase/01-core-auth-profile.sql`
- `docs/supabase/02-health-and-schedule.sql`
- `docs/supabase/03-membership-quota.sql`
- `docs/supabase/04-family-plus.sql`
- `docs/supabase/05-sale-referral-commission.sql`
- `docs/supabase/07-seed-reference-data.sql`

## 4. Ownership and RLS

| Operation | Role | Policy/permission | Expected result |
|---|---|---|---|
| Read own profile | authenticated | `users_select_own` | User chỉ đọc `public.users.id = auth.uid()` |
| Update profile fields | authenticated | update allowlist fields only | Không sửa tier/status/sale |
| Read/write health data | authenticated | `can_read_health_subject` / `can_write_health_subject` | Self/family allowed only |
| Read catalog | authenticated | read active catalog | Không ghi catalog từ client |
| Read membership/quota | authenticated | own subscription/counter; active plans/rules | Client chỉ đọc |
| Write membership/quota | trusted backend/admin | server-side only | Client bị revoke insert/update/delete |
| Read Sale/payment/commission | authenticated | related user only | Sale chỉ thấy dữ liệu liên quan |
| Write payment/commission | webhook/backend/admin | server-side only | Client không tự tạo payment success |

## 5. Transaction and idempotency

- Auth trigger phải idempotent: tạo `public.users` và self subject một lần.
- Seed reference data phải dùng `on conflict` để chạy lại an toàn.
- Payment events phải unique theo `(provider, provider_event_id)`.
- Commission records phải unique theo `(payment_event_id, receiver_user_id, level)`.
- Quota consumption cần RPC/Edge Function idempotency key trước khi Ready.

## 6. Rollback / recovery

- SQL draft chỉ chạy trên sandbox/staging trước production.
- Có verify query cho auth/profile gaps và RLS two-user smoke.
- Nếu trigger signup gây lỗi, rollback trigger trước rồi repair/backfill users bằng admin workflow.
- Payment/commission cần quy trình reversal cho refund/chargeback trước production.

## 7. Verification queries

- Dùng `docs/supabase/08-acceptance-checks.md`.
- Dùng `docs/DD/authentication/database/002_verify_auth_profile_integrity.sql` cho auth baseline.
- Thêm smoke theo TC-PF-20..TC-PF-25 trong `15_TEST_ACCEPTANCE_AND_TRACEABILITY.md`.

## 8. Test matrix

- Auth bootstrap: user email và anonymous user có profile/self subject.
- Cross-user RLS: User B không đọc/sửa data User A.
- Membership: Free/Plus/FamilyPlus effective access đúng.
- Quota: Free bị chặn khi vượt ngưỡng; Plus/FamilyPlus không bị quota Free.
- FamilyPlus: member ngoài family không đọc subject family.
- Sale/referral: payment success tạo đúng commission 10%/5%, không tạo tầng 3.

## 9. Open decisions

- Q-01/Q-02 ảnh hưởng Guest identity, anonymous upgrade và local-to-cloud sync.
- Q-04 ảnh hưởng period key/reset timezone của quota.
- Q-06 ảnh hưởng subscription expiry/downgrade.
- Q-07 ảnh hưởng FamilyPlus permission/consent schema.
- Q-09/Q-10 ảnh hưởng anti-fraud, refund, chargeback, payout và commission reversal.

