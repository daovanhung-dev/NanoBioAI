Commit de xuat: docs(worklog): ghi nhan phien supabase database draft

# Worklog - Supabase database draft

## Thoi gian

- Ngay: 2026-06-21
- Bat dau: Khoang 13:00
- Ket thuc: 13:09
- Timezone: Asia/Saigon

## Pham vi

- Loai task: docs/coding
- Module chinh: Supabase database, membership, quota, FamilyPlus, Sale/referral
- Yeu cau goc: Doc BD project flow va tao cac file cau hinh CSDL Supabase tai `docs/supabase`.

## Da lam

- Tao bo tai lieu Supabase de Supabase la source of truth cho toan he thong.
- De xuat schema core Auth/Profile voi Anonymous Auth cho Guest va `health_subjects` cho FamilyPlus.
- De xuat schema health/schedule/AI/catalog giu ten bang tuong thich voi app hien co.
- De xuat schema membership/quota, FamilyPlus, Sale/referral/payment/commission.
- Tao ma tran RLS, seed reference data va checklist nghiem thu.

## File code/docs da sua

- `docs/supabase/README.md` - tao - huong dan doc/chay bo cau hinh Supabase.
- `docs/supabase/00-system-database-design.md` - tao - mo hinh tong the va assumption.
- `docs/supabase/01-core-auth-profile.sql` - tao - core Auth/Profile/subject/RLS.
- `docs/supabase/02-health-and-schedule.sql` - tao - health, schedule, AI, catalog.
- `docs/supabase/03-membership-quota.sql` - tao - membership, entitlement, quota.
- `docs/supabase/04-family-plus.sql` - tao - family group/member boundary.
- `docs/supabase/05-sale-referral-commission.sql` - tao - Sale/referral/payment/commission.
- `docs/supabase/06-rls-policy-matrix.md` - tao - ma tran RLS.
- `docs/supabase/07-seed-reference-data.sql` - tao - seed plan/quota/commission.
- `docs/supabase/08-acceptance-checks.md` - tao - checklist nghiem thu.
- `docs/worklog/2026-06-21/002-worklog-supabase-database-draft.md` - tao - ghi nhan phien.

## Tai lieu lien quan

- `docs/BD/project_flow/BD_Product_Flow_Membership_Sale.md`
- `docs/BD/authentication/BD_Authentication_Registration_Login_NanoBio.md`
- `docs/DD/authentication/database/prerequisites/20260620_nanobio_multitenant.sql`
- `docs/DD/authentication/database/prerequisites/20260620_02_auth_profile_bootstrap.sql`

## Commands

- `rg --files docs/supabase`: PASS - xac nhan du file da tao.
- `rg "create table|create policy|membership_plans|commission_records" docs/supabase`: PASS - xac nhan noi dung schema chinh.

## Loi/Rui ro

- Da fix: `docs/supabase` truoc do trong, chua co bo draft Supabase tong the cho membership/Sale/FamilyPlus.
- Chua fix: Chua chay SQL tren Supabase sandbox/staging.
- Can kiem tra tiep: Review SQL bang Supabase CLI/sandbox, chot PO cac diem payment, payout, FamilyPlus consent va anonymous upgrade.
