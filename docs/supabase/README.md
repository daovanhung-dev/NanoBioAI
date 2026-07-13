Commit de xuat: docs(supabase): cap nhat bo cau hinh csdl Supabase

# Supabase Database Draft - NanoBio

Thu muc nay chua tai lieu va SQL draft de thiet ke Supabase lam nguon du
lieu tin cay cho NanoBio/BioAI.

## Nguyen tac chinh

- Supabase la nguon du lieu tin cay cho user, ho so suc khoe, lich trinh AI,
  goi thanh vien, quota, FamilyPlus, Sale/referral, payment event, diem Sale,
  Admin permission, audit, bằng chứng nhiệm vụ, Điểm chăm sóc và voucher.
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

## Rebuild local/sandbox bang mot file

Chay `config.sql` khi can xoa va dung lai Supabase local/sandbox tu dau.
File nay la destructive script: wipe `auth.users` bang cascade, drop/recreate
schema `public`, sau do tao lai schema/RLS/RPC/seed/dev users/Admin bootstrap.

- Khong chay `config.sql` tren production.
- Can quyen SQL Editor/postgres co the thao tac `auth.*` va `public`.
- Dev users mac dinh dung password `NanoBio@123456`:
  `dev.free@nanobio.local`, `dev.plus@nanobio.local`,
  `dev.family@nanobio.local`, `dev.admin@nanobio.local`.
- `dev.admin@nanobio.local` duoc bootstrap role `super_admin`.
- SQL khong deploy duoc Edge Function `delete-account`, Auth redirect URL hay
  payment webhook/provider. Migration 16 tạo bucket private
  `schedule-completion-proofs` và policy tương ứng; vẫn phải smoke test Storage
  trong sandbox theo `16-schedule-proof-storage.md`. Bucket private
  `sale-payout-proofs` cho minh chứng chi trả Sale vẫn được hướng dẫn riêng
  trong `13-sale-payout-storage.md`.

## File module tham chieu

`config.sql` la entrypoint rebuild chinh. Cac file module ben duoi la nguon
tham chieu/review de cap nhat `config.sql` khi schema, RLS, RPC hoac seed thay
doi:

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
7. `10-mobile-sync-and-sale-rpc.sql` - RPC snapshot dong bo local/cloud va
   shared guard `require_active_sale_user`. File nay khong con la nguon Sale
   RPC dang ky/dashboard; contract Sale final nam trong
   `12-sale-module-update.sql` va `config.sql`.
8. `11-admin-access-dashboard.sql` - Admin roles, permissions, dashboard, audit
   va RPC quan tri. `public.users.app_access_mode` quy dinh `user`, `admin` hoac
   `both`; `get_my_admin_session()` tra `can_use_user_app` de entrypoint hop nhat
   chon giao dien ma khong tao session Admin rieng.
9. `12-sale-module-update.sql` - Sale dang ky cho Admin duyet, attach ma gioi
   thieu, ledger diem va queue quy doi noi bo.
10. `13-membership-payment-request.sql` - RPC tao pending membership payment
   request tu client, idempotent va khong cap quyen truoc khi payment duyet.
11. `13-sale-payout-storage.md` - runbook bucket private cho anh minh chung
   chi tra Sale.
12. `07-seed-reference-data.sql` - seed du lieu tham chieu ban dau.
13. `09-dev-seed-membership-test-accounts.sql` - dev/sandbox only, tao account
   test Free/Plus/FamilyPlus co dinh; `config.sql` co dev seed rieng va them
   `dev.admin@nanobio.local`.
14. `14_mobile_sync_hotfix.sql` - hotfix snapshot sync khong insert NULL vao
   cot co default; logic nay da duoc fold vao `config.sql`.
15. `15-auth-sync-completion.sql` - migration khong pha huy cho atomic Auth V2 signup/referral; phai chay sandbox truoc va khong thay the bang `config.sql` tren remote/production.
16. `16-wellness-rewards.sql` - migration không phá hủy cho eligibility lịch,
   marker một request Guest/tài khoản và immutable batch Member, proof private,
   ledger server-owned, ví Điểm chăm sóc, catalog/kho mã voucher, đổi điểm
   atomic và Admin refund/audit.
17. `16-schedule-proof-storage.md` - runbook bucket bằng chứng private, contract
   begin/upload/finalize/undo và smoke test hai tài khoản.
18. `17-unified-app-role-surface.sql` - migration không phá hủy cho entrypoint
   hợp nhất, `app_access_mode` và output role-surface của Admin session.
19. `06-rls-policy-matrix.md` va `08-acceptance-checks.md` - kiem tra bao mat
   va nghiem thu.

Moi thay doi Supabase schema/RLS/RPC/seed/docs phai cap nhat `config.sql` cung
luc. Neu khong cap nhat duoc, ghi blocker trong worklog va khong claim rebuild
Supabase da san sang.

## Trang thai

`config.sql` la destructive rebuild script cho local/sandbox. Cac SQL module
con lai la draft de review va lam nguon cho migration Supabase chinh thuc. Chua
ap dung truc tiep len production neu chua duoc review bang moi truong
sandbox/staging.

## Nguon tham chieu

- BD chinh: `docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md`
- Auth BD/DD hien co: `docs/BD/authentication/` va `docs/DD/authentication/`
- Supabase Anonymous Auth: https://supabase.com/docs/guides/auth/auth-anonymous
- Supabase user management: https://supabase.com/docs/guides/auth/managing-user-data
- Supabase Row Level Security: https://supabase.com/docs/guides/database/postgres/row-level-security
- Supabase database migrations: https://supabase.com/docs/guides/deployment/database-migrations
