Commit de xuat: docs(supabase): tao bo cau hinh csdl Supabase

# Supabase Database Draft - NanoBio

Thư mục này chứa bộ tài liệu và SQL draft để thiết kế Supabase làm hệ quản trị dữ liệu trung tâm cho NanoBio/BioAI.

## Nguyên tắc chính

- Supabase là nguồn dữ liệu tin cậy cho toàn hệ thống: user, hồ sơ sức khỏe, lịch trình AI, gói thành viên, quota, FamilyPlus, Sale/referral, payment event và hoa hồng.
- SQLite trong app chỉ đóng vai trò cache/offline/local-first cho trải nghiệm V1; không dùng SQLite, route param, SharedPreferences hay UI state để mở quyền trả phí, Sale hoặc hoa hồng.
- Guest/V1 được quản lý bằng Supabase Anonymous Auth để mọi người dùng đều có `auth.users.id`. Khi người dùng đăng ký/đăng nhập thật, tài khoản được nâng cấp/liên kết theo cơ chế Supabase Auth.
- `auth.users` quản lý định danh. `public.users` là hồ sơ nghiệp vụ dùng cùng UUID với `auth.users.id`.
- `users.subscription_tier` chỉ là read-model tương thích cho app hiện tại. Nguồn đúng để dựng quyền là `membership_subscriptions`, `plan_entitlements` và trạng thái Sale riêng.
- Payment event, commission, membership entitlement, Sale status và quota counter chỉ được ghi bởi trusted backend, Edge Function, SQL migration hoặc admin workflow đã kiểm soát.

## Thứ tự đọc/chạy đề xuất

1. `00-system-database-design.md` - đọc trước để hiểu domain và phạm vi.
2. `01-core-auth-profile.sql` - nền Auth, `public.users`, `health_subjects`, trigger và RLS lõi.
3. `02-health-and-schedule.sql` - dữ liệu sức khỏe, lịch trình, catalog và RLS theo subject.
4. `03-membership-quota.sql` - gói Free/Plus/FamilyPlus, entitlement, quota, usage event.
5. `04-family-plus.sql` - nhóm gia đình và quyền xem/sửa theo FamilyPlus.
6. `05-sale-referral-commission.sql` - Sale/referral, payment event và hoa hồng 2 tầng.
7. `07-seed-reference-data.sql` - seed dữ liệu tham chiếu ban đầu.
8. `06-rls-policy-matrix.md` và `08-acceptance-checks.md` - kiểm tra bảo mật và nghiệm thu.

## Trạng thái

Các file SQL trong thư mục này là draft để review và làm nguồn cho migration Supabase chính thức. Chưa áp dụng trực tiếp lên Supabase production nếu chưa được review bằng môi trường sandbox/staging.

## Nguồn tham chiếu

- BD chính: `docs/BD/project_flow/BD_Product_Flow_Membership_Sale.md`
- Auth BD/DD hiện có: `docs/BD/authentication/` và `docs/DD/authentication/`
- Supabase Anonymous Auth: https://supabase.com/docs/guides/auth/auth-anonymous
- Supabase user management: https://supabase.com/docs/guides/auth/managing-user-data
- Supabase Row Level Security: https://supabase.com/docs/guides/database/postgres/row-level-security
- Supabase database migrations: https://supabase.com/docs/guides/deployment/database-migrations
