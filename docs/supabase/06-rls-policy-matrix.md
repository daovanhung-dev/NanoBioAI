Commit de xuat: docs(supabase): cap nhat ma tran rls

# Ma tran RLS Supabase

## Nguyen tac

- Bat RLS cho toan bo bang `public` co du lieu nghiep vu.
- Flutter chi dung `anon key`/session user, khong dung `service_role`.
- Bảng quyền, payment, commission, Sale status, Admin role/config, quota,
  eligibility, bằng chứng, ví và ledger Điểm chăm sóc chỉ ghi qua trusted
  backend, Edge Function, SQL job hoặc RPC được kiểm soát.
- UI an nut khong thay the kiem soat o route/use-case/RLS/backend.

## Ma tran quyen

| Nhom bang | Client doc | Client ghi | Trusted backend/Admin | Ghi chu |
| --- | --- | --- | --- | --- |
| `users` | User doc ho so cua minh | Chi update profile/onboarding cua minh | Tao qua Auth trigger, cap nhat access/status | Client khong sua package/Sale/Admin status hoac `app_access_mode` |
| `health_subjects` | Owner, linked user hoac FamilyPlus member duoc phep | Owner/member co quyen edit | Co the backfill subject | Boundary cho health va family data |
| Health/onboarding | Theo `can_read_health_subject(subject_id)` | Theo `can_write_health_subject(subject_id)` | Co the ho tro/backfill | Khong lo du lieu cheo user |
| Schedule/AI/tracking | Theo subject duoc phep | Theo subject duoc phep | Co the import/sync | Bao gom meal/task/schedule/log/AI insight |
| Eligibility/attempt/proof nhiệm vụ | Owner đọc metadata của mình; không đọc marker Guest/Member | Không ghi bảng trực tiếp; chỉ RPC register/begin/finalize/undo | RPC khóa dòng và chuyển trạng thái | Marker server-owned ghim một request Guest/tài khoản và một immutable batch/Member request; canonical manifest gồm ID/ngày/giờ/source; eligibility sao chép mốc giờ |
| Storage `schedule-completion-proofs` | Owner đọc đúng object path đã được server cấp | Chỉ INSERT JPEG <= 5 MB đúng path; không UPDATE/DELETE | Service role dọn theo account-deletion/retention | Bucket private, `upsert: false`, User A không đọc/upload path User B |
| Wallet/allocation/`wellness_point_ledgers` | Owner đọc projection của mình | Không; ledger append-only và bị loại khỏi snapshot push/delete | Reward/Redeem/Admin refund RPC ghi trong transaction | Điểm cũ +1/-1 thành +10/-10 lịch sử không quy đổi; điểm v2 pending/available/expiry version hóa |
| Catalog ưu đãi | Authenticated user đọc offer active, đúng gói qua RPC | Không | Admin có `wellness_rewards.write` upsert | Copy title/description bắt buộc tiếng Việt có dấu |
| Kho mã voucher | Không grant đọc raw inventory | Không | Admin import qua RPC; redeem chọn `FOR UPDATE SKIP LOCKED` | `code_hash` unique toàn cục giữa mọi offer; mã chỉ trả cho owner sau cấp; mã hủy chuyển `retired`, không nhập lại kho |
| Giao dịch đổi điểm | Owner đọc giao dịch của mình, lấy code qua RPC riêng | Không | Redeem atomic; Admin hủy/refund có reason/audit | Không giới hạn số lượt ngoài điểm, eligibility offer và tồn kho |
| Catalog | Authenticated user doc | Khong | Migration/Admin ghi | Du lieu dung chung |
| Membership/quota | User doc du lieu cua minh; plan/rule active doc chung | Khong | Payment backend/Admin ghi | Client khong tu tang quota |
| FamilyPlus | Owner/member duoc phep doc | Khong o draft nay | Backend xac thuc FamilyPlus/consent ghi | Can test chong lo family data |
| Sale/referral | Sale/referrer/referred doc phan lien quan; Sale doc summary khach truc tiep qua RPC | Chi goi RPC attach ma gioi thieu/upsert payout profile co guard | Backend/Admin ghi | Sale requires paid Plus/FamilyPlus; attach co email/phone/device/payment-history guard |
| `payment_events` | Payer doc giao dich cua minh | Khong | Webhook/backend/Admin ghi | Khong tin Flutter bao thanh toan thanh cong |
| `commission_rates` | Authenticated user doc rate active | Khong | Migration/Admin ghi | Direct-only 10% |
| `commission_records` | Receiver doc diem Sale cua minh | Khong | Trigger/backend/Admin ghi | Chi tao tu payment approved; tinh theo list-price/base snapshot; diem giu 24h truoc khi kha dung |
| `sale_point_conversions` | Sale doc yeu cau quy doi cua minh; Admin co `sales.write` doc qua queue RPC | Khong ghi bang truc tiep | Sale/Admin RPC co config, idempotency va audit | Khong tich hop payout provider that trong app |
| `sale_payout_profiles` | Khong grant doc truc tiep; Sale/Admin doc qua RPC | Khong ghi bang truc tiep | Sale RPC upsert, Admin queue RPC doc snapshot | Chua CCCD + bank; proof anh o private Storage `sale-payout-proofs` |
| `sale_point_adjustments` | Admin co `points.write` doc qua RPC | Khong | Admin RPC ghi | Dieu chinh thu cong can 1 Admin, reason, idempotency va audit |
| Admin roles/config/audit/reconciliation | Admin co permission doc | Khong | Admin RPC ghi | Moi write nhay cam can audit; reconciliation khong overwrite ledger lich su |

## Quy tac trien khai app

- Khi can thao tac membership/payment/Sale/family/Admin, app goi RPC/backend
  duoc thiet ke rieng; presentation/controller khong ghi bang truc tiep.
- Admin action quan trong can `reason`, actor, timestamp, idempotency key va
  audit log.
- Admin voucher dùng permission riêng `wellness_rewards.read/write`; audit nhập
  kho chỉ lưu thống kê, không lưu raw voucher code.
- Sale dashboard chi hien thi khach truc tiep qua RPC summary: ho ten, tuoi, so
  dien thoai, tom tat health conditions cua self subject va so lieu tong hop;
  khong hien raw daily logs, AI content, secret, payment evidence hay raw
  payment payload.
