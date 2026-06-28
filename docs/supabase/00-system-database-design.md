Commit de xuat: docs(supabase): cap nhat thiet ke he thong Supabase

# Supabase System Database Design

Supabase la he quan tri du lieu trung tam cho NanoBio/BioAI. Moi quyen truy
cap, goi thanh vien, quota, Sale/referral, thanh toan, diem Sale, Admin va du
lieu cloud cua nguoi dung phai dua tren nguon tin cay tu Supabase hoac
backend/Edge Function.

## Domain chinh

| Domain | Bang/RPC chinh | Ghi chu |
| --- | --- | --- |
| Auth/Profile | `users`, `health_subjects` | Lien ket `auth.users.id` |
| Health/Schedule | health, tracking, meal, task, schedule tables | RLS theo subject |
| Membership/Quota | `membership_plans`, `membership_subscriptions`, quota tables | Supabase/trusted backend la nguon quyen |
| FamilyPlus | `family_groups`, `family_members` | Khong mo quyen cheo neu thieu consent |
| Sale/referral | `sale_profiles`, `referral_codes`, `referral_relationships`, `payment_events`, `commission_rates`, `commission_records` | Sale doc lap voi membership |
| Admin | `admin_roles`, `admin_permissions`, `admin_user_roles`, `admin_audit_events`, config/report tables | Moi write nhay cam can permission va audit |

## Payment va diem Sale

- `payment_events` chi ghi boi backend/webhook dang tin cay hoac Admin RPC da
  kiem soat.
- Khi payment hop le thanh cong, he thong tao diem Sale direct-only:
  - Sale truc tiep cua khach thanh toan nhan 10% gia tri hop le.
  - Khong sinh hoa hong gian tiep hoac nhieu tang.
- Neu B khong phai khach truc tiep cua A, payment cua B khong tao diem Sale cho
  A.
- Refund/chargeback can tao reversal/adjustment theo policy rieng, khong sua
  lich su da chot.

## Bao mat va RLS

- Bat RLS cho toan bo bang public co du lieu nghiep vu.
- Flutter chi dung anon/session user, khong dung service-role key.
- Bang payment, commission, quota, Admin role, config va audit khong cho client
  ghi truc tiep.
- Admin UI an nut khong thay the permission/RLS/RPC backend.

## Trang thai draft

SQL trong `docs/supabase` la draft thiet ke. Can review va chay sandbox/staging
truoc khi tao migration production.
