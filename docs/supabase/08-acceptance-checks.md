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

## Mobile snapshot sync (SQLite <-> Supabase)

- [ ] Nâng SQLite app lên database v9, kiểm tra có `sync_outbox`, `sync_runtime_state` và trigger cho các bảng user-owned.
- [ ] Guest hoàn tất onboarding + tạo account cloud mới: snapshot local được đẩy qua `sync_my_mobile_snapshot`, sau đó local dùng auth UUID và có đủ meal/task.
- [ ] Account đã có onboarding/meal/task cloud: đăng nhập lại phải lấy cloud đè SQLite; Guest cache pending không ghi đè cloud.
- [ ] Account mới không có onboarding và không có Guest cache: `onboarding_status` giữ chưa hoàn tất, UI đi vào onboarding.
- [ ] Hoàn tất/sửa task, score, profile, lịch hoặc notification khi online: marker outbox được đẩy lên cloud; khi offline marker retry sau khi có mạng.
- [ ] Write xảy ra trong lúc snapshot RPC đang chạy không bị xóa marker; phải được đồng bộ ở lần drain tiếp theo.
- [ ] Client thử ghi `product_access_status`, `sale_status`, payment, commission, quota hay subject của user khác qua payload: RPC phải bỏ qua/từ chối.

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

### Sale participation và cloud-direct UI

- [ ] User chưa Sale chỉ thấy CTA tham gia trong Settings; nút chuyển sang Sale chỉ hiện khi `sale_status = active`.
- [ ] User chọn đồng ý điều lệ: `sale_profiles` lưu `terms_version`, `terms_accepted_at`; trigger đồng bộ `users.sale_status`; referral code active được tạo.
- [ ] Sale `active` gọi được dashboard/tree/leaderboard RPC và chỉ thấy dữ liệu đã mask/aggregate.
- [ ] Sale `none`, `suspended`, `closed` không gọi được dashboard/tree/leaderboard RPC.
- [ ] Flutter không lưu sale profile, referral relationship, payment event hay commission record trong SQLite; Sale UI đọc cloud RPC trực tiếp.
- [ ] Kiểm tra nghiệp vụ/pháp lý trước payout thật: không tính thưởng vì tuyển người, không cam kết thu nhập, hoa hồng chỉ theo payment hợp lệ và có xử lý refund/chargeback.

## Tiêu chí hoàn tất

- RLS không lộ dữ liệu chéo user hoặc chéo family.
- Các bảng server-only không ghi được từ client.
- Trigger signup không làm lỗi tạo account trong sandbox.
- SQL seed chạy lại được nhiều lần mà không nhân bản dữ liệu.
- Các điểm chưa chốt trong `00-system-database-design.md` được ghi thành BD/DD bổ sung trước khi vận hành thật.
