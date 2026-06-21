Commit de xuat: docs(supabase): lap checklist nghiem thu Supabase

# Checklist nghiệm thu Supabase

## Chuẩn bị

- Tạo môi trường Supabase sandbox/staging, không chạy trực tiếp production.
- Bật Supabase Anonymous Sign-Ins nếu chọn quản lý Guest bằng Anonymous Auth.
- Chạy các SQL theo thứ tự trong `README.md`.
- Chuẩn bị ít nhất 3 user test: A, B, C. Nên có thêm một anonymous guest để kiểm tra V1.
- Dùng SQL Editor/admin hoặc backend test có service role cho bước seed/payment giả lập. Không đưa service role key vào Flutter.

## Auth và bootstrap

- [ ] Tạo user email mới, kiểm tra có đúng 1 dòng trong `auth.users`, `public.users`, `health_subjects`.
- [ ] Tạo anonymous user, kiểm tra `users.product_access_status = 'guest'` và có self `health_subjects`.
- [ ] User mới có dòng nền trong `health_profiles` và `lifestyle_habits` sau khi chạy `02-health-and-schedule.sql`.
- [ ] User A không đọc được `users`, `health_subjects` hoặc health data của user B.
- [ ] Client không insert/delete được `public.users`.

## Health, schedule và catalog

- [ ] User A tạo/cập nhật onboarding data của subject self thành công.
- [ ] User A tạo meal plan, daily task, lifestyle schedule item và tracking log cho subject self thành công.
- [ ] User B không đọc/sửa/xóa được record của subject A.
- [ ] Authenticated user đọc được catalog active.
- [ ] Client không insert/update/delete được catalog.

## Membership và quota

- [ ] Seed có đủ plan `free`, `plus`, `family_plus`.
- [ ] User Free có quota `ai_chat_message` 3 lượt/ngày.
- [ ] User Free có quota `personal_schedule_generation` 3 lượt/tháng.
- [ ] Hàm `can_consume_quota` trả true khi counter trong giới hạn và false khi vượt giới hạn.
- [ ] User Plus/FamilyPlus không bị chặn bởi hai quota Free trong BD.
- [ ] Client không insert/update/delete được `membership_subscriptions`, `plan_entitlements`, `usage_quota_counters`, `usage_events`.

## FamilyPlus

- [ ] Tạo family group bằng backend/admin cho chủ gói FamilyPlus.
- [ ] Tạo subject family member và family member mapping.
- [ ] Chủ family đọc được dữ liệu subject thành viên.
- [ ] Member không thuộc family không đọc được dữ liệu subject đó.
- [ ] Member có `can_view = true` đọc được dữ liệu được chia sẻ.
- [ ] Member không có `can_edit` không sửa được dữ liệu subject khác.

## Sale/referral/commission

- [ ] Tạo Sale active cho A và referral code cho A bằng backend/admin.
- [ ] Gắn quan hệ A giới thiệu B; payment thành công của B tạo commission 10% cho A.
- [ ] Cho B thành Sale active, gắn quan hệ B giới thiệu C; payment thành công của C tạo commission 10% cho B và 5% cho A.
- [ ] Tầng 3 không tạo commission.
- [ ] Nếu B không có payment kỳ này nhưng C có payment thành công, commission từ C vẫn sinh cho B và A theo tầng 1/2.
- [ ] Client không insert/update/delete được `payment_events`, `commission_records`, `sale_profiles`, `referral_relationships`.

## Tiêu chí hoàn tất

- RLS không lộ dữ liệu chéo user hoặc chéo family.
- Các bảng server-only không ghi được từ client.
- Trigger signup không làm lỗi tạo account trong sandbox.
- SQL seed chạy lại được nhiều lần mà không nhân bản dữ liệu.
- Các điểm chưa chốt trong `00-system-database-design.md` được ghi thành BD/DD bổ sung trước khi vận hành thật.
