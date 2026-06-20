# DD-AUTH-FR-02 - Khởi tạo hồ sơ nghiệp vụ tự động

**BD nguồn:** AUTH-FR-02  
**Dependencies:** `03_DATA_MODEL_RLS_AND_MIGRATIONS.md`, `database/002_verify_auth_profile_integrity.sql`

## 1. Mục tiêu

Bảo đảm creation của Auth identity và hồ sơ nền là một transaction nhất quán, áp dụng như nhau cho Flutter sign-up, Dashboard create user và Admin API backend.

## 2. Trigger design

| Thuộc tính | Thiết kế |
|---|---|
| Event | `AFTER INSERT ON auth.users` |
| Execution | `FOR EACH ROW` |
| Function | `public.handle_auth_user_created()` |
| Security | `SECURITY DEFINER`, set search path an toàn |
| Idempotency | `public.users` upsert; 1-1 tables `ON CONFLICT DO NOTHING` |
| Atomicity | Trigger lỗi => Auth insert rollback |
| Scope | Chỉ baseline profile; không seed activity data |

## 3. Pseudocode

```text
on auth.users inserted as new:
  upsert public.users with id = new.id
    email = new.email
    phone = auth phone or metadata phone
    full_name = metadata.full_name or metadata.name
    avatar_url = metadata.avatar_url
    subscription_tier = free
    onboarding_status = not_started

  insert health_profiles(user_id = new.id) if missing
  insert lifestyle_habits(user_id = new.id) if missing
  return new
```

## 4. Database constraints required

- `public.users.id` primary key and FK to `auth.users(id)` with cascade.
- `health_profiles(user_id)` unique.
- `lifestyle_habits(user_id)` unique.
- RLS client insert revoked for the three baseline tables.

## 5. Edge cases

| Case | Expected behavior |
|---|---|
| User created via Dashboard | same trigger, same three base rows |
| Trigger re-run / migration rerun | no duplicated health/habits row |
| Metadata missing | nullable display fields; no failure |
| `public.users` exists but one-to-one rows missing | repair/backfill creates missing rows only |
| Trigger failure | no partially created Auth account |
| User changes email/phone in Auth | separate contact sync trigger or explicit profile consistency policy |

## 6. Observability

- Log trigger failures server-side only.
- SQL integrity query should count base row gaps.
- Do not expose internal DB exception or table names to end users.

## 7. Non-goals

- Không tạo goals, allergies, survey answers, tasks, notifications or health logs.
- Không phân quyền subscription/role theo metadata từ client.
