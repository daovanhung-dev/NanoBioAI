Commit de xuat: docs(supabase): mo ta ma tran rls

# Ma trận RLS Supabase

## Nguyên tắc

- Bật RLS cho toàn bộ bảng `public`.
- Client Flutter chỉ dùng `anon key`/session user, không dùng `service_role`.
- Bảng quyền, payment, commission, Sale status và quota counter chỉ ghi qua trusted backend, Edge Function, SQL job hoặc admin workflow.
- UI ẩn nút không thay thế kiểm soát ở route/use-case/RLS/backend.

## Ma trận quyền

| Nhóm bảng | Client đọc | Client ghi | Trusted backend/admin | Ghi chú |
| --- | --- | --- | --- | --- |
| `users` | User đọc hồ sơ của chính mình | Chỉ update trường hồ sơ/onboarding cho chính mình | Tạo qua Auth trigger, cập nhật tier/status | Không cho client sửa `subscription_tier`, `product_access_status`, `sale_status` |
| `health_subjects` | Owner, linked user hoặc FamilyPlus member được phép | Owner hoặc member có quyền edit | Có thể tạo/backfill subject | Là boundary cho dữ liệu sức khỏe và FamilyPlus |
| Health/onboarding | Theo `can_read_health_subject(subject_id)` | Theo `can_write_health_subject(subject_id)` | Có thể backfill/sửa dữ liệu hỗ trợ | Bao gồm profile, habits, goals, conditions, allergy, treatment, survey |
| Schedule/AI/tracking | Theo subject được phép | Theo subject được phép | Có thể import/sync | Bao gồm meal plan, daily task, schedule, notification, logs, AI insight |
| Catalog | Authenticated user đọc | Không | Migration/admin ghi | Dữ liệu dùng chung |
| `membership_plans` | Authenticated user đọc plan active | Không | Migration/admin ghi | Seed từ file reference |
| `plan_entitlements` | Authenticated user đọc entitlement active | Không | Migration/admin ghi | Không lấy entitlement từ client |
| `membership_subscriptions` | User đọc subscription của chính mình | Không | Payment backend/admin ghi | Trigger sync `users.subscription_tier` |
| `usage_quota_rules` | Authenticated user đọc rule active | Không | Migration/admin ghi | Rule Free/Plus/FamilyPlus |
| `usage_quota_counters`, `usage_events` | User đọc usage của chính mình | Không | RPC/Edge/backend ghi | Client không tự tăng quota |
| `family_groups`, `family_members` | Owner/member được phép đọc | Không ở draft này | Backend xác thực FamilyPlus/consent ghi | Cần DD riêng cho add/remove member |
| `sale_profiles`, `referral_codes` | Sale user đọc dữ liệu của mình | Không | Admin/backend ghi | Sale độc lập membership |
| `referral_relationships` | Referrer hoặc referred đọc liên quan tới mình | Không | Backend/admin ghi khi gắn referral | Chặn self-referral bằng constraint |
| `payment_events` | Payer đọc giao dịch của mình | Không | Webhook/backend ghi | Không tin Flutter báo thanh toán thành công |
| `commission_rates` | Authenticated user đọc rate active | Không | Migration/admin ghi | 10% tầng 1, 5% tầng 2 |
| `commission_records` | Receiver đọc hoa hồng của mình | Không | Trigger/backend ghi | Chỉ tạo từ payment event thành công |

## Quy tắc triển khai app

- Khi user chưa có session thật, app dùng Supabase Anonymous Auth để có `auth.uid()`.
- Khi user đăng ký/đăng nhập, app không tự insert `public.users`; trigger đảm nhận bootstrap.
- Khi cần dùng feature có quota, app gọi use-case kiểm tra quota trước khi gọi AI.
- Khi cần thao tác membership/payment/Sale/family, app gọi backend/RPC được thiết kế riêng; không ghi bảng trực tiếp từ presentation/controller.

## Rủi ro cần kiểm tra khi review SQL

- Anonymous Auth dùng role `authenticated`, nên policy phải phân biệt `product_access_status = guest` ở tầng use-case/backend.
- FamilyPlus mở quyền chéo qua function `can_read_health_subject`/`can_write_health_subject`; cần test kỹ để không lộ dữ liệu ngoài family.
- Trigger từ `auth.users` nếu lỗi sẽ làm signup lỗi; cần test staging trước production.
- Payment/commission cần thêm quy trình xử lý refund/chargeback trước khi vận hành thật.
