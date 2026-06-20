# DD-AUTH-FR-08 - Cập nhật hồ sơ sau Onboarding

**BD nguồn:** AUTH-FR-08  
**Dependencies:** `03_DATA_MODEL_RLS_AND_MIGRATIONS.md`, `14_FLUTTER_LAYER_CONTRACTS.md`

## 1. Scope

Cho phép người dùng đã đăng nhập cập nhật display profile, thông tin sức khỏe cơ bản và thói quen. Những update này luôn target row tồn tại sẵn của user hiện hành.

## 2. Data ownership

| Cập nhật | Bảng/API đúng | Không được dùng |
|---|---|---|
| full name, avatar, gender, birth year | `public.users` | `auth.users` direct SQL |
| email | Supabase Auth update email flow | `public.users.email` như source of truth |
| password | Supabase Auth update password flow | bất kỳ bảng public nào |
| height/weight/BMI/occupation | `health_profiles` | insert profile row mới |
| habits | `lifestyle_habits` | insert habits row mới |
| phone | Auth update phone policy + profile sync | chỉ update một bên nếu product requires sync |

## 3. Update rules

- Repository uses current auth UUID implicitly through RLS; never takes a target arbitrary user id from UI.
- Validate numeric values before write.
- BMI should be recomputed from valid height/weight according to one shared utility; do not trust manually entered BMI if product decides calculated field.
- `updated_at` must be set server-side trigger, not by device clock.

## 4. Conflict/error behavior

- If update denied by RLS: treat as configuration/integrity problem, show recoverable generic failure.
- If session expires: route to auth/login and keep non-sensitive draft locally only when product policy permits.
- A failed profile update must not downgrade a completed onboarding status automatically.

## 5. Acceptance

TC-AUTH-24 đến TC-AUTH-26.
