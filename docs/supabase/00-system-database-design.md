Commit de xuat: docs(supabase): mo ta thiet ke csdl trung tam

# Thiết kế CSDL Supabase tổng thể

## Mục tiêu

Supabase là hệ quản trị dữ liệu trung tâm cho NanoBio/BioAI. Mọi quyền truy cập, gói thành viên, quota, Sale/referral, thanh toán, hoa hồng và dữ liệu cloud của người dùng phải dựa trên nguồn tin cậy từ Supabase hoặc backend/Edge Function.

## Trục người dùng

NanoBio có hai trục độc lập:

| Trục | Giá trị | Ý nghĩa |
| --- | --- | --- |
| Quyền sản phẩm | Guest, Free, Plus, FamilyPlus | Quyết định module, quota và phạm vi dữ liệu sức khỏe được dùng |
| Sale/referral | Không Sale, Sale active, Sale suspended | Quyết định quyền dùng mã giới thiệu và nhận hoa hồng |

Sale không phải gói thành viên. Một người dùng có thể là Free/Plus/FamilyPlus và đồng thời có hoặc không có trạng thái Sale.

## Định danh và ownership

- `auth.users` là định danh Supabase Auth, bao gồm user anonymous và user có email/phone/OAuth.
- `public.users.id = auth.users.id` là hồ sơ nghiệp vụ chính.
- `health_subjects` là người/hồ sơ sức khỏe được theo dõi:
  - `self`: hồ sơ của chính user.
  - `family_member`: hồ sơ thành viên gia đình trong FamilyPlus.
- Các bảng sức khỏe/lịch trình giữ `user_id` để tương thích app hiện tại và thêm `subject_id` để hỗ trợ FamilyPlus.
- Client chỉ được đọc/ghi subject mà RLS cho phép. FamilyPlus mở quyền qua `family_groups` và `family_members`, không mở bằng dữ liệu local.

## Nhóm bảng đề xuất

| Nhóm | Bảng chính | Ghi chú |
| --- | --- | --- |
| Auth/profile | `users`, `health_subjects` | Tạo từ trigger `auth.users`; có self subject |
| Health/onboarding | `health_profiles`, `lifestyle_habits`, `health_goals`, `health_conditions`, `food_allergies`, `medical_treatments`, `survey_answers` | Dữ liệu cá nhân hóa, theo subject |
| Schedule/AI | `meal_plans`, `daily_health_tasks`, `lifestyle_schedule_items`, `notifications`, `ai_insights`, `ai_recommendations` | Kết quả AI và trạng thái thực hiện |
| Tracking | `health_tracking_logs`, `nutrition_logs` | Dữ liệu người dùng ghi hằng ngày |
| Catalog | `meal_catalog`, `exercise_catalog`, `schedule_task_catalog` | App chỉ đọc; admin/migration ghi |
| Membership/quota | `membership_plans`, `membership_subscriptions`, `plan_entitlements`, `usage_quota_rules`, `usage_quota_counters`, `usage_events` | Nguồn dựng quyền và quota |
| FamilyPlus | `family_groups`, `family_members` | Ranh giới xem/sửa dữ liệu gia đình |
| Sale/referral | `sale_profiles`, `referral_codes`, `referral_relationships`, `payment_events`, `commission_rates`, `commission_records` | Tách khỏi membership |

## Quyền và quota

- Guest/V1: Anonymous Auth, chỉ dùng allowlist V1, sinh lịch trình AI sau onboarding đúng 1 lần.
- Free/V2: có AI Chat 3 câu/ngày và tạo lịch trình cá nhân 3 lần/tháng.
- Plus/V3: kế thừa Free, không bị hai quota Free nói trên.
- FamilyPlus/V3: kế thừa Plus và thêm quyền family theo `family_groups`/`family_members`.

Quota phải được kiểm tra trước khi gọi AI/service tốn tài nguyên. Client không được tự tăng quota counter trực tiếp; thao tác ghi quota nên đi qua RPC/Edge Function hoặc backend tin cậy.

## Payment và hoa hồng

- `payment_events` chỉ ghi bởi backend/webhook đáng tin cậy.
- Khi payment thành công, hệ thống tạo hoa hồng:
  - Tầng 1: referrer trực tiếp nhận 10%.
  - Tầng 2: referrer của referrer trực tiếp nhận 5%.
  - Tầng 3 trở đi không sinh hoa hồng.
- Nếu B không thanh toán nhưng C thanh toán, A vẫn có thể nhận 5% từ giao dịch của C theo quan hệ tầng 2.

## Điểm cần Product Owner xác nhận tiếp

- Guest “1 lần sinh lịch trình” được ràng buộc theo thiết bị, anonymous user hay tài khoản sau khi nâng cấp.
- Cơ chế link/nâng cấp Anonymous Auth sang tài khoản email/phone chính thức trong app.
- Chu kỳ gói Plus/FamilyPlus, quá hạn gói và downgrade.
- Giới hạn số thành viên FamilyPlus, quyền xem/sửa chi tiết và đồng ý chia sẻ dữ liệu sức khỏe.
- Điều kiện đăng ký/duy trì Sale, khóa Sale và chống gian lận referral.
- Quy trình refund/chargeback, payout hoa hồng và đối soát kế toán.
