Commit de xuat: docs(supabase): cap nhat bo cau hinh csdl Supabase

# Supabase Database Draft - NanoBio

Thu muc nay chua tai lieu va SQL draft de thiet ke Supabase lam nguon du
lieu tin cay cho NanoBio/BioAI.

## Nguyen tac chinh

- Supabase la nguon du lieu tin cay cho user, ho so suc khoe, lich trinh AI,
  goi thanh vien, quota, FamilyPlus, Sale/referral, payment event, diem Sale,
  Admin permission va audit.
- SQLite trong app chi la cache/offline/local-first cho trai nghiem V1; khong
  dung SQLite, route param, SharedPreferences hay UI state de mo quyen tra phi,
  Sale, Admin hoac diem Sale.
- `auth.users` quan ly dinh danh. `public.users` la ho so nghiep vu dung cung
  UUID voi `auth.users.id`.
- `users.subscription_tier` chi la read-model tuong thich. Nguon dung de dung
  quyen la `membership_subscriptions`, `plan_entitlements`, Sale status va
  Admin permission rieng.
- Payment event, commission, membership entitlement, Sale status, Admin
  permission va quota counter chi duoc ghi boi trusted backend, Edge Function,
  SQL migration hoac Admin workflow da kiem soat.
- Sale theo BD v2.0 la direct-only: Sale nhan 10% tu payment hop le cua khach
  duoc gioi thieu truc tiep; khong co tang gian tiep.

## Thu tu doc/chay de xuat

1. `00-system-database-design.md` - doc truoc de hieu domain va pham vi.
2. `01-core-auth-profile.sql` - nen Auth, `public.users`, `health_subjects`,
   trigger va RLS loi.
3. `02-health-and-schedule.sql` - du lieu suc khoe, lich trinh, catalog va RLS
   theo subject.
4. `03-membership-quota.sql` - goi Free/Plus/FamilyPlus, entitlement, quota,
   usage event.
5. `04-family-plus.sql` - nhom gia dinh va quyen xem/sua theo FamilyPlus.
6. `05-sale-referral-commission.sql` - Sale/referral, payment event va hoa hong
   Sale truc tiep 10%.
7. `10-mobile-sync-and-sale-rpc.sql` - RPC snapshot dong bo local/cloud va RPC
   Sale truc tiep.
8. `11-admin-access-dashboard.sql` - Admin roles, permissions, dashboard, audit
   va RPC quan tri.
9. `07-seed-reference-data.sql` - seed du lieu tham chieu ban dau.
10. `09-dev-seed-membership-test-accounts.sql` - dev/sandbox only, tao account
   test Free/Plus/FamilyPlus co dinh.
11. `06-rls-policy-matrix.md` va `08-acceptance-checks.md` - kiem tra bao mat
   va nghiem thu.

## Trang thai

Tat ca SQL trong thu muc nay la draft de review va lam nguon cho migration
Supabase chinh thuc. Chua ap dung truc tiep len production neu chua duoc review
bang moi truong sandbox/staging.

## Nguon tham chieu

- BD chinh: `docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md`
- Auth BD/DD hien co: `docs/BD/authentication/` va `docs/DD/authentication/`
- Supabase Anonymous Auth: https://supabase.com/docs/guides/auth/auth-anonymous
- Supabase user management: https://supabase.com/docs/guides/auth/managing-user-data
- Supabase Row Level Security: https://supabase.com/docs/guides/database/postgres/row-level-security
- Supabase database migrations: https://supabase.com/docs/guides/deployment/database-migrations
