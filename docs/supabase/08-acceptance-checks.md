Commit de xuat: docs(supabase): cap nhat checklist nghiem thu Supabase

# Checklist nghiem thu Supabase

## Chuan bi

- Tao moi truong Supabase sandbox/staging, khong chay truc tiep production.
- Chay SQL theo thu tu trong `README.md`.
- Chuan bi user test A, B, C va mot Admin test co role phu hop.
- Dung SQL Editor/Admin/backend test co service role cho seed/payment gia lap.
  Khong dua service role key vao Flutter.

## Auth va health

- [ ] Tao user email moi, co dung mot dong trong `auth.users`, `public.users`,
  `health_subjects`.
- [ ] User A khong doc/sua duoc health data cua user B.
- [ ] Client khong insert/delete duoc `public.users`.

## Mobile snapshot sync

- [ ] Guest hoan tat onboarding + tao account cloud moi: snapshot local duoc day
  qua `sync_my_mobile_snapshot`, local dung auth UUID va co du meal/task.
- [ ] Client thu ghi package/Sale/payment/commission/quota/subject cua user khac
  qua payload: RPC phai bo qua hoac tu choi.

## Membership va quota

- [ ] Seed co du plan `free`, `plus`, `family_plus`.
- [ ] User Free co quota `ai_chat_message` 3 luot/ngay.
- [ ] User Free co quota `personal_schedule_generation` 3 luot/thang.
- [ ] Client khong insert/update/delete duoc subscription, quota counter hay
  usage event.

## FamilyPlus

- [ ] Tao family group bang backend/Admin cho chu goi FamilyPlus.
- [ ] Member khong thuoc family khong doc duoc subject family.
- [ ] Member co `can_view = true` doc duoc data duoc chia se; thieu `can_edit`
  thi khong sua duoc.

## Sale direct-only

- [ ] Tao Sale active cho A va referral code cho A bang backend/Admin.
- [ ] Gan quan he A gioi thieu B; payment thanh cong cua B tao commission 10%
  cho A.
- [ ] Cho B thanh Sale active, gan quan he B gioi thieu C; payment thanh cong
  cua C chi tao commission 10% cho B, khong tao commission cho A.
- [ ] Neu C la khach truc tiep cua B, payment cua C chi sinh commission cho B.
- [ ] Client khong insert/update/delete duoc `payment_events`,
  `commission_records`, `sale_profiles`, `referral_relationships`.
- [ ] Sale UI doc cloud RPC truc tiep, khong luu payment/referral/commission
  trong SQLite.

## Admin

- [ ] `super_admin`, `finance_admin`, `operations_admin` co permission dung ma
  tran.
- [ ] Admin dashboard chi tra metric theo permission.
- [ ] Finance Admin duyet/reject payment thanh cong, co reason/timestamp/actor
  va audit.
- [ ] Admin khong co `payments.write` goi `admin_review_payment` bi tu choi.
- [ ] Admin update Sale/user/config/report export deu ghi `admin_audit_events`.
- [ ] Flutter Admin khong co service-role key va khong ghi bang server-only truc
  tiep.

## Tieu chi hoan tat

- RLS khong lo du lieu cheo user/family.
- Bang server-only khong ghi duoc tu client.
- Trigger signup khong lam loi tao account trong sandbox.
- SQL seed chay lai duoc ma khong nhan ban du lieu.
- Khong claim production-ready neu chua co sandbox/staging verification.
