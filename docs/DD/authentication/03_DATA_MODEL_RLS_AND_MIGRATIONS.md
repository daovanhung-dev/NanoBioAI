# DD-AUTH-DB-001 - Mô hình dữ liệu, RLS và migration lifecycle

**BD nguồn:** AUTH-FR-02, AUTH-FR-05, AUTH-FR-06, AUTH-FR-07, AUTH-FR-11, AUTH-FR-12

## 1. Phân tách identity và hồ sơ nghiệp vụ

| Layer | Bảng | Owner | Mục đích |
|---|---|---|---|
| Identity | `auth.users` | Supabase Auth | email, password hash, phone, metadata, confirmation/session |
| App profile | `public.users` | User owns row `id = auth.uid()` | thông tin app và trạng thái onboarding |
| One-to-one health | `health_profiles` | User owns by `user_id` | chỉ số sức khỏe cơ bản |
| One-to-one habits | `lifestyle_habits` | User owns by `user_id` | thói quen sống |
| Collections | goals/allergies/conditions/survey/treatments/... | User owns by `user_id` | dữ liệu phát sinh sau onboarding |
| Shared catalogs | meal/exercise/schedule catalogs | Server/admin write | danh mục read-only cho client |

## 2. Schema lifecycle bắt buộc

`public.users` phải có ba trường điều phối route:

| Column | Type | Default | Mục đích |
|---|---|---:|---|
| `onboarding_status` | `text` | `not_started` | `not_started` / `in_progress` / `completed` |
| `onboarding_completed_at` | `timestamptz` | `NULL` | thời điểm hoàn thành |
| `last_login_at` | `timestamptz` | `NULL` | analytics/audit nhẹ, không dùng làm security token |

Migration chính thức nằm ở `database/001_add_auth_lifecycle_fields.sql`.

## 3. Trigger bootstrap

### Contract

**Tên function:** `public.handle_auth_user_created()`  
**Trigger:** `AFTER INSERT ON auth.users`  
**Tính chất:** `security definer`, idempotent, chạy cùng transaction tạo Auth user.

### Input tin cậy

- `new.id`, `new.email`, `new.phone`: chỉ từ `auth.users`.
- `new.raw_user_meta_data`: chỉ dùng cho display fields `full_name`, `avatar_url`, phone fallback; không dùng để cấp role hoặc xác định ownership.

### Output

| Bảng | Action | Khóa/giá trị |
|---|---|---|
| `public.users` | insert/upsert | `id = new.id`, tier `free`, onboarding `not_started` |
| `health_profiles` | insert do nothing | `user_id = new.id`, fields health null |
| `lifestyle_habits` | insert do nothing | `user_id = new.id`, boolean false, fields text null |

### Không được khởi tạo

Không tạo meal plan, task, notification, log, goal, allergy, condition, treatment, AI result. Các bảng này chỉ xuất hiện khi hành vi nghiệp vụ phát sinh dữ liệu thật.

## 4. Ownership và RLS

### `public.users`

```sql
-- select/update only current user
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id)
```

Sau khi trigger được triển khai, client phải bị `REVOKE INSERT` trên `public.users`.

### Bảng personal có `user_id`

```sql
-- SELECT / UPDATE / DELETE
using ((select auth.uid()) = user_id)
-- INSERT / UPDATE
with check ((select auth.uid()) = user_id)
```

Sau khi trigger được triển khai, client phải bị `REVOKE INSERT` trên `health_profiles` và `lifestyle_habits`; vẫn được `SELECT` + `UPDATE` row của chính họ.

### Catalog dùng chung

Authenticated client chỉ có `SELECT`. Ghi catalog chỉ từ migration, SQL Editor quyền admin, Edge Function hoặc backend trusted.

## 5. Invariants và validation database

- `public.users.id` foreign key tới `auth.users(id) on delete cascade`.
- `health_profiles.user_id` unique.
- `lifestyle_habits.user_id` unique.
- `users_completed_onboarding_has_time`: completed thì phải có timestamp.
- `onboarding_status` chỉ nhận ba enum string được quy định.
- Personal table có `user_id uuid not null default auth.uid()` nhưng repository vẫn phải chủ động lấy current UUID để log/debug và trả lỗi rõ ràng khi chưa đăng nhập.

## 6. Xóa account

Chỉ backend/Edge Function dùng Admin API xóa `auth.users`. Cascade xóa `public.users`, sau đó xóa toàn bộ personal data theo FK. Không tạo policy `DELETE` trên `public.users` cho authenticated client.

## 7. Điều kiện triển khai database

- Chạy schema base trước.
- Chạy auth bootstrap trigger patch.
- Chạy migration lifecycle fields.
- Chạy truy vấn verify integrity.
- Test account mới qua app và Supabase Dashboard.

Xem chi tiết trong `database/README.md`.
