Commit de xuat: docs(supabase): cap nhat ma tran rls

# Ma tran RLS Supabase

## Nguyen tac

- Bat RLS cho toan bo bang `public` co du lieu nghiep vu.
- Flutter chi dung `anon key`/session user, khong dung `service_role`.
- Bang quyen, payment, commission, Sale status, Admin role/config va quota
  counter chi ghi qua trusted backend, Edge Function, SQL job hoac Admin RPC.
- UI an nut khong thay the kiem soat o route/use-case/RLS/backend.

## Ma tran quyen

| Nhom bang | Client doc | Client ghi | Trusted backend/Admin | Ghi chu |
| --- | --- | --- | --- | --- |
| `users` | User doc ho so cua minh | Chi update profile/onboarding cua minh | Tao qua Auth trigger, cap nhat access/status | Client khong sua package/Sale/Admin status |
| `health_subjects` | Owner, linked user hoac FamilyPlus member duoc phep | Owner/member co quyen edit | Co the backfill subject | Boundary cho health va family data |
| Health/onboarding | Theo `can_read_health_subject(subject_id)` | Theo `can_write_health_subject(subject_id)` | Co the ho tro/backfill | Khong lo du lieu cheo user |
| Schedule/AI/tracking | Theo subject duoc phep | Theo subject duoc phep | Co the import/sync | Bao gom meal/task/schedule/log/AI insight |
| Catalog | Authenticated user doc | Khong | Migration/Admin ghi | Du lieu dung chung |
| Membership/quota | User doc du lieu cua minh; plan/rule active doc chung | Khong | Payment backend/Admin ghi | Client khong tu tang quota |
| FamilyPlus | Owner/member duoc phep doc | Khong o draft nay | Backend xac thuc FamilyPlus/consent ghi | Can test chong lo family data |
| Sale/referral | Sale/referrer/referred doc phan lien quan | Chi goi RPC attach ma gioi thieu co guard | Backend/Admin ghi | Sale doc lap membership |
| `payment_events` | Payer doc giao dich cua minh | Khong | Webhook/backend/Admin ghi | Khong tin Flutter bao thanh toan thanh cong |
| `commission_rates` | Authenticated user doc rate active | Khong | Migration/Admin ghi | Direct-only 10% |
| `commission_records` | Receiver doc diem Sale cua minh | Khong | Trigger/backend/Admin ghi | Chi tao tu payment event hop le; diem giu 24h truoc khi kha dung |
| `sale_point_conversions` | Sale doc yeu cau quy doi cua minh; Admin co `sales.write` doc qua queue RPC | Khong ghi bang truc tiep | Sale/Admin RPC co config, idempotency va audit | Khong tich hop payout provider that trong app |
| `sale_point_adjustments` | Admin co `points.write` doc qua RPC | Khong | Admin RPC ghi | Dieu chinh thu cong can 1 Admin, reason, idempotency va audit |
| Admin roles/config/audit/reconciliation | Admin co permission doc | Khong | Admin RPC ghi | Moi write nhay cam can audit; reconciliation khong overwrite ledger lich su |

## Quy tac trien khai app

- Khi can thao tac membership/payment/Sale/family/Admin, app goi RPC/backend
  duoc thiet ke rieng; presentation/controller khong ghi bang truc tiep.
- Admin action quan trong can `reason`, actor, timestamp, idempotency key va
  audit log.
- Sale dashboard chi hien thi ten khach truc tiep, thong tin co ban neu can
  (email/phone khi co trong profile nghiep vu) va so lieu tong hop; khong hien
  thi health data, AI content, secret, payment evidence hay raw payment payload.
