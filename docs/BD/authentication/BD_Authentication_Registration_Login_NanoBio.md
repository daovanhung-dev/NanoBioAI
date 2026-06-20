# BD-AUTH-001 — Xác thực, Đăng ký, Đăng nhập và Khởi tạo hồ sơ người dùng

**Dự án:** NanoBio / BioAI  
**Phiên bản:** 1.0  
**Ngày ban hành:** 20/06/2026  
**Trạng thái:** Sẵn sàng triển khai  

## 1. Mục tiêu

Thiết kế đầy đủ chức năng tài khoản cho ứng dụng NanoBio/BioAI trên Supabase. Hệ thống phải đảm bảo một tài khoản xác thực được tạo trong `auth.users` luôn có hồ sơ nghiệp vụ tương ứng ở `public.users`, cùng một hồ sơ sức khỏe rỗng (`health_profiles`) và thói quen sống mặc định (`lifestyle_habits`).

Luồng chuẩn:

```text
Đăng ký Auth / tạo thủ công ở Dashboard
→ auth.users
→ PostgreSQL Trigger
→ public.users + health_profiles + lifestyle_habits
→ xác thực email (nếu bật)
→ đăng nhập
→ kiểm tra onboarding_status
→ Onboarding hoặc Dashboard
```

## 2. Phạm vi

Bao gồm: đăng ký email/mật khẩu, tạo user thủ công từ Supabase Dashboard, xác thực email, đăng nhập, khôi phục phiên, phân luồng Onboarding, cập nhật hồ sơ, quên/đổi mật khẩu, đăng xuất, yêu cầu xóa tài khoản, RLS và khởi tạo hồ sơ tự động.

Không bao gồm trong V1: đăng nhập Google/Apple/Facebook, 2FA, quản trị tenant/doanh nghiệp, phân quyền bác sĩ/nhân viên y tế.

## 3. Kiến trúc và nguyên tắc

- `auth.users` chỉ quản lý định danh và thông tin xác thực.
- `public.users` là hồ sơ nghiệp vụ ứng dụng và dùng cùng UUID với `auth.users.id`.
- Trigger `AFTER INSERT ON auth.users` tạo ba bản ghi nền trong cùng giao dịch.
- Client Flutter không được tự chèn `public.users`, `health_profiles`, `lifestyle_habits`.
- Dữ liệu còn lại chỉ phát sinh khi người dùng thực sự có hoạt động/dữ liệu.
- RLS bảo đảm mỗi user chỉ đọc/sửa/xóa dữ liệu có `user_id = auth.uid()`.
- Catalog dùng chung chỉ đọc từ app: `meal_catalog`, `exercise_catalog`, `schedule_task_catalog`.

## 4. Tác nhân

| Tác nhân | Vai trò |
|---|---|
| Người dùng chưa đăng nhập | Đăng ký, xác thực email, đăng nhập, quên mật khẩu |
| Người dùng đã đăng nhập | Hoàn tất onboarding, cập nhật hồ sơ, sử dụng dữ liệu cá nhân |
| Quản trị viên | Tạo tài khoản thủ công trong Supabase Dashboard; vận hành catalog; hỗ trợ xóa tài khoản qua backend |
| Supabase Auth | Quản lý email, mật khẩu, session, xác thực email, recovery link |
| PostgreSQL Trigger | Khởi tạo hồ sơ nghiệp vụ tự động |
| PostgreSQL RLS | Chặn mọi truy cập chéo dữ liệu giữa các tài khoản |

## 5. Mô hình dữ liệu tài khoản

| Thành phần | Mục đích | Khởi tạo | Quyền client |
|---|---|---|---|
| `auth.users` | Email, mật khẩu đã mã hóa, trạng thái xác thực, metadata | Supabase Auth | Không truy cập trực tiếp |
| `public.users` | Hồ sơ ứng dụng: tên, điện thoại, avatar, giới tính, năm sinh, gói dịch vụ, onboarding status | Trigger | Select/update bản thân; không insert/delete |
| `health_profiles` | Nghề nghiệp, chiều cao, cân nặng, BMI, huyết áp, đường huyết | Trigger | Select/update bản thân; không insert |
| `lifestyle_habits` | Thói quen ăn uống/sinh hoạt, chất lượng ngủ, mức vận động, lượng nước | Trigger | Select/update bản thân; không insert |

## 6. Quy tắc dữ liệu khởi tạo

Khi tạo một `auth.users` mới:

1. Tạo `public.users` với `id = auth.users.id`.
2. Lấy `email`, `phone`, `full_name/name`, `avatar_url` từ Auth metadata khi có.
3. Mặc định `subscription_tier = 'free'`.
4. Tạo một dòng `health_profiles` rỗng cho `user_id` tương ứng.
5. Tạo một dòng `lifestyle_habits` với các boolean mặc định `false`, trường text để `NULL`.
6. Không tạo dòng rỗng ở các bảng lịch, meal plan, log, dị ứng, mục tiêu, điều trị, AI recommendation, notification… vì đó là dữ liệu phát sinh.
7. Toàn bộ thao tác trên nằm trong cùng transaction. Trigger lỗi thì tạo account thất bại; không có trường hợp Auth tạo thành công mà profile nền bị thiếu.

## 7. Bổ sung schema bắt buộc cho điều phối onboarding

`public.users` cần có thêm các trường:

```sql
alter table public.users
  add column if not exists onboarding_status text not null default 'not_started'
    check (onboarding_status in ('not_started', 'in_progress', 'completed')),
  add column if not exists onboarding_completed_at timestamptz,
  add column if not exists last_login_at timestamptz;

alter table public.users
  add constraint users_completed_onboarding_has_time
  check (onboarding_status <> 'completed' or onboarding_completed_at is not null);
```

Trạng thái:

- `not_started`: vừa tạo user, chưa mở onboarding.
- `in_progress`: đã vào onboarding nhưng chưa hoàn tất.
- `completed`: đã lưu đủ dữ liệu bắt buộc; truy cập Dashboard.

## 8. Chức năng

### AUTH-FR-01 — Đăng ký bằng email và mật khẩu

**Mục đích:** tạo tài khoản mới cho người dùng.

**Input:** email, password, confirm password, full name (khuyến nghị), phone (tùy chọn), chấp thuận điều khoản.

**Kiểm tra:** email hợp lệ; password tối thiểu 8 ký tự; password và confirm password khớp; email chưa tồn tại; người dùng đã chấp thuận điều khoản.

**Xử lý:** Flutter gọi `auth.signUp`; gửi metadata; Supabase Auth tạo `auth.users`; trigger tạo ba bản ghi nền; nếu xác thực email bật thì gửi email xác nhận.

**Kết quả:** hiển thị màn hình thông báo kiểm tra email. Khi email chưa xác thực, không vào Dashboard.

### AUTH-FR-02 — Khởi tạo hồ sơ nghiệp vụ tự động

**Mục đích:** đảm bảo 1 tài khoản Auth luôn có 1 hồ sơ ứng dụng và 2 hồ sơ một-một có thể cập nhật ngay.

**Cơ chế:** trigger `public.handle_auth_user_created()` với `AFTER INSERT ON auth.users`, `security definer`, không tin cậy dữ liệu từ Flutter để quyết định user id.

**Yêu cầu:** dùng `ON CONFLICT DO NOTHING/UPDATE` để idempotent; trigger chỉ tạo `users`, `health_profiles`, `lifestyle_habits`; không tạo dữ liệu giả.

### AUTH-FR-03 — Tạo tài khoản thủ công ở Supabase Dashboard

**Mục đích:** hỗ trợ admin tạo sẵn account cho người dùng.

**Luồng:** Authentication → Users → Add user/Create user → nhập email/password → tùy cấu hình xác nhận email → Supabase ghi `auth.users` → cùng trigger tạo profile nền.

**Quy tắc:** không insert trực tiếp vào bảng `auth.users` bằng Table Editor; không insert tay `public.users` như một thay thế cho Auth; Admin phải dùng Authentication UI hoặc Admin API chạy ở backend.

### AUTH-FR-04 — Xác thực email

Khi project bật Confirm email, tài khoản mới chỉ được coi là sẵn sàng sau khi xác thực link trong email. App phải dùng redirect/deep link đã khai báo tại Supabase để đưa người dùng trở về màn hình xác thực thành công. Người dùng có thể gửi lại email sau một khoảng thời gian giới hạn.

### AUTH-FR-05 — Đăng nhập

**Input:** email và password.

**Xử lý:** Flutter gọi `auth.signInWithPassword`; nếu thành công nhận session; đọc `public.users`; ghi `last_login_at`; đọc `onboarding_status` để điều hướng.

**Điều hướng:** `completed` → Dashboard; `not_started`/`in_progress` → Onboarding ở bước còn dở; chưa xác thực email → màn hình xác thực email; lỗi credential → thông báo thân thiện, không tiết lộ email có tồn tại hay không.

### AUTH-FR-06 — Khôi phục phiên và điều hướng khởi động app

Khi app mở, AuthController lấy session hiện tại. Không có session → Welcome/Login. Có session → lấy `public.users`; nếu thiếu profile nền thì thông báo tạm thời và gửi sự kiện sửa dữ liệu server-side; không tự insert từ client. Dựa trên onboarding status để mở Onboarding hoặc Dashboard.

### AUTH-FR-07 — Hoàn thành Onboarding

Onboarding cập nhật dòng đã có sẵn trong `public.users`, `health_profiles`, `lifestyle_habits`; tạo dữ liệu tập hợp chỉ khi người dùng chọn/nhập: `health_goals`, `food_allergies`, `health_conditions`, `survey_answers`, `medical_treatments`.

Chỉ khi các trường bắt buộc hợp lệ mới set `onboarding_status='completed'` và `onboarding_completed_at=now()`.

### AUTH-FR-08 — Cập nhật hồ sơ sau onboarding

Người dùng cập nhật tên, avatar, giới tính, năm sinh, số điện thoại, thông tin sức khỏe cơ bản, thói quen; app cập nhật đúng dòng có id/user_id của user hiện hành. Không thay đổi email hoặc password trực tiếp trên `public.users`; hai nội dung đó đi qua Supabase Auth.

### AUTH-FR-09 — Quên và đổi mật khẩu

Quên mật khẩu: gửi recovery link tới email; user mở deep link; app kiểm tra recovery session và cho nhập mật khẩu mới + xác nhận. Đổi mật khẩu khi đã login: yêu cầu xác thực lại theo chính sách bảo mật của app, sau đó gọi Auth update password. Không lưu password trong bất kỳ bảng public nào.

### AUTH-FR-10 — Đăng xuất

Gọi `auth.signOut`, xóa session cục bộ, xóa cache dữ liệu nhạy cảm trên thiết bị, đưa về Welcome/Login. Không xóa dữ liệu cloud.

### AUTH-FR-11 — Xóa tài khoản

User gửi yêu cầu xóa; app yêu cầu xác nhận rõ ràng. Backend/Edge Function dùng service role gọi Admin API xóa `auth.users`. Khóa ngoại `ON DELETE CASCADE` xóa `public.users` và mọi bảng cá nhân. Client không có quyền delete `public.users` hay gọi service role.

### AUTH-FR-12 — Xử lý lỗi và phục hồi dữ liệu cũ

Với user tồn tại trước trigger, chạy backfill một lần để bổ sung `public.users`, `health_profiles`, `lifestyle_habits`. Với lỗi trigger trong đăng ký mới: rollback toàn bộ và ghi log server; không xử lý bằng client retry insert profile riêng lẻ.

## 9. Luồng nghiệp vụ chính

### 9.1 Đăng ký từ Flutter

```text
User → Register UI → AuthController → AuthRepository → Supabase Auth.signUp
Supabase Auth → insert auth.users → PostgreSQL trigger
Trigger → public.users + health_profiles + lifestyle_habits
Supabase Auth → email confirmation (nếu bật)
App → Verification screen → Sign in / authenticated session
```

### 9.2 Tạo account thủ công bằng Dashboard

```text
Admin → Authentication / Users / Create user
→ auth.users insert
→ same PostgreSQL trigger
→ public.users + health_profiles + lifestyle_habits
→ user đăng nhập app và bắt đầu onboarding
```

### 9.3 Đăng nhập và route

```text
Launch app → restore session
No session → Welcome/Login
Session exists → query public.users
email not verified → Verify Email
onboarding_status != completed → Onboarding
onboarding_status = completed → Dashboard
```

### 9.4 Hoàn tất onboarding

```text
Update public.users + health_profiles + lifestyle_habits
Insert/update selected goals/allergies/conditions/survey answers
Validate required fields
Update public.users.onboarding_status = completed
→ Dashboard
```

## 10. Bảng dữ liệu và thời điểm tạo

| Nhóm | Bảng | Thời điểm |
|---|---|---|
| Identity / profile nền | `public.users`, `health_profiles`, `lifestyle_habits` | Trigger ngay sau tạo `auth.users` |
| Input onboarding tùy người dùng | `health_goals`, `food_allergies`, `health_conditions`, `survey_answers`, `medical_treatments` | Khi người dùng chọn/nhập |
| Dữ liệu lịch và kế hoạch | `daily_health_tasks`, `lifestyle_schedule_items`, `meal_plans`, `notifications` | Khi app/AI tạo lịch, nhiệm vụ, kế hoạch hoặc reminder |
| Theo dõi hằng ngày | `health_tracking_logs`, `nutrition_logs` | Khi người dùng ghi log |
| Kết quả AI | `ai_insights`, `ai_recommendations` | Khi AI đã tạo và được lưu |
| Catalog dùng chung | `meal_catalog`, `exercise_catalog`, `schedule_task_catalog` | Do admin/migration seed, không theo user |

## 11. Phân quyền và bảo mật

- RLS bật trên mọi bảng `public`.
- Bảng cá nhân chỉ cho phép `auth.uid() = id` hoặc `auth.uid() = user_id`.
- Sau khi triển khai trigger, app client không có quyền `insert` vào `public.users`, `health_profiles`, `lifestyle_habits`.
- Bảng catalog: chỉ `select` cho user đăng nhập; chỉ server/admin được ghi.
- Không nhúng `service_role key` trong Flutter.
- Không lưu mật khẩu, token recovery hoặc refresh token trong bảng nghiệp vụ.
- Không trả lỗi login quá chi tiết khiến lộ thông tin tài khoản.

## 12. Kiến trúc Flutter

```text
Presentation (Page / Riverpod Controller)
→ Domain Repository Contract
→ Data Repository
→ Supabase Auth / Remote Datasource
→ Supabase Auth + PostgreSQL/RLS
```

File trách nhiệm đề xuất:

- `features/auth/presentation/controllers/auth_controller.dart`: trạng thái form, gọi use case/repository, điều hướng.
- `features/auth/domain/repositories/auth_repository.dart`: hợp đồng đăng ký, login, logout, reset password.
- `features/auth/data/datasources/supabase_auth_remote_datasource.dart`: gọi `supabase.auth`.
- `features/cloud_sync/.../supabase_health_remote_datasource.dart`: cập nhật profile và dữ liệu onboarding sau login.
- `core/router`: AuthGate quyết định route theo session + onboarding status.

## 13. Tiêu chí nghiệm thu

1. Đăng ký account mới tạo đúng một dòng trong `auth.users`, `public.users`, `health_profiles`, `lifestyle_habits` với cùng UUID ownership.
2. Nếu trigger lỗi thì không còn account mới trong `auth.users`.
3. Tạo account ở Supabase Dashboard cũng tạo đủ profile nền.
4. User A không thể đọc/sửa/xóa row của user B dù cố gửi `user_id` của B.
5. User mới chưa onboarding không vào Dashboard.
6. User đã completed onboarding mở app đi thẳng Dashboard khi session hợp lệ.
7. Logout xóa session local nhưng không xóa cloud data.
8. Delete account qua backend xóa Auth user và toàn bộ personal data cascade.
9. Catalog hiển thị được cho user đã login nhưng client không insert/update/delete được.
10. Tài khoản cũ trước migration được backfill đủ ba row nền.

## 14. Kế hoạch triển khai

1. Chạy schema đa người dùng.
2. Chạy patch Auth → Profile Bootstrap.
3. Chạy migration onboarding status.
4. Cấu hình Supabase Auth: email template, redirect/deep link, password policy, email confirmation.
5. Thêm Auth datasource/repository/controller và AuthGate Flutter.
6. Chuyển phần Onboarding từ insert base profile sang update base profile.
7. Chạy test RLS với tối thiểu hai tài khoản.
8. Thực hiện backfill user cũ trước khi phát hành.

## 15. Tài liệu liên quan

- `supabase/20260620_nanobio_multitenant.sql`
- `supabase/20260620_02_auth_profile_bootstrap.sql`
- `lib/features/auth/data/datasources/supabase_auth_remote_datasource.dart`
- `lib/features/cloud_sync/data/datasources/supabase_health_remote_datasource.dart`
