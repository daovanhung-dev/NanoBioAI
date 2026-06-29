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

- [ ] User Free bi chan dang ky Sale; user Plus/FamilyPlus active gui yeu cau
  Sale thi trang thai la `pending`; chi sau khi Admin approve moi thanh
  `active` va co referral code.
- [ ] Gan quan he A gioi thieu B bang `attach_my_referral_code` trong luc dang
  ky tai khoan; self/email/phone/device trung, user da co relationship hoac
  payment history khong gan duoc trong app.
- [ ] Trusted payment recorder chi tao `pending`; chi sau khi Admin duyet thu
  cong payment moi thanh `succeeded`, kich hoat goi va bat dau giu diem 24h.
- [ ] Payment thanh cong cua B tao commission/diem 10% theo gia niem yet/base
  snapshot cho A o trang thai pending/hold; Sale chi quy doi duoc sau
  `available_at` 24h.
- [ ] Yeu cau quy doi diem bi tu choi khi diem van trong 24h hold hoac Sale
  chua co CCCD + thong tin tai khoan ngan hang.
- [ ] Hoan/huy/chargeback tao `sale_point_adjustments` am ngay, khong overwrite
  `commission_records`; so du Sale co the am va bu bang diem tuong lai.
- [ ] Admin queue quy doi hien thong tin payout, QR payload va co the luu path
  anh minh chung trong private bucket `sale-payout-proofs` khi mark paid.
- [ ] Cho B thanh Sale active, gan quan he B gioi thieu C; payment thanh cong
  cua C chi tao commission 10% cho B, khong tao commission cho A.
- [ ] Neu C la khach truc tiep cua B, payment cua C chi sinh commission cho B.
- [ ] Neu Sale bi `suspended` hoac `closed`, payment moi cua khach cu khong sinh
  commission/diem moi cho Sale do.
- [ ] Client khong insert/update/delete duoc `payment_events`,
  `commission_records`, `sale_profiles`, `referral_relationships`,
  `sale_point_conversions`, `sale_payout_profiles`.
- [ ] Khi `sale_point_conversion.enabled = false` hoac thieu config, Sale UI
  chi hien trang thai chua mo quy doi; khi bat config thi Sale tao duoc yeu cau
  quy doi va Admin co `sales.write` duyet qua RPC co audit.
- [ ] Sale UI doc cloud RPC truc tiep, khong luu payment/referral/commission
  trong SQLite.

## Admin

- [ ] `super_admin`, `finance_admin`, `operations_admin` deu la Admin active
  full capability qua RPC/backend co audit; Flutter khong ghi truc tiep bang
  server-only.
- [ ] Admin dashboard dung filter thoi gian `Asia/Ho_Chi_Minh` va metric co
  drill-down theo section.
- [ ] Finance Admin duyet/reject payment thanh cong, co reason/timestamp/actor
  va audit.
- [ ] Payment approval bat buoc thu cong; `record_trusted_payment_event` khong
  duoc grant cho Flutter roles va khong auto-approve.
- [ ] Admin dieu chinh thu cong Diem Sale qua RPC co reason/idempotency/audit;
  chi can mot Admin duyet.
- [ ] Admin tao/list/classify reconciliation discrepancy qua RPC; adjustment
  tao ledger rieng, khong overwrite lich su.
- [ ] Admin update Sale/user/config/report export deu ghi `admin_audit_events`.
- [ ] Flutter Admin khong co service-role key va khong ghi bang server-only truc
  tiep.

## Tieu chi hoan tat

- RLS khong lo du lieu cheo user/family.
- Bang server-only khong ghi duoc tu client.
- Trigger signup khong lam loi tao account trong sandbox.
- SQL seed chay lai duoc ma khong nhan ban du lieu.
- Khong claim production-ready neu chua co sandbox/staging verification.
