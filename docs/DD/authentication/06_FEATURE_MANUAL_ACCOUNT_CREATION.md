# DD-AUTH-FR-03 - Tạo tài khoản thủ công trong Supabase Dashboard

**BD nguồn:** AUTH-FR-03  
**Dependencies:** `05_FEATURE_PROFILE_BOOTSTRAP.md`, `13_ERROR_HANDLING_AND_DATA_RECOVERY.md`

## 1. Mục tiêu

Cho phép quản trị viên chuẩn bị account qua Supabase Dashboard mà không phá liên kết Auth/Profile và không bỏ qua security lifecycle.

## 2. Quy trình vận hành

```text
Supabase Dashboard
→ Authentication
→ Users
→ Add user / Create user
→ nhập email + password
→ chọn trạng thái email confirmation theo chính sách environment
→ Create
→ trigger tự tạo public profile rows
→ chạy verify query khi cần
```

## 3. Quy tắc bắt buộc

- Không insert trực tiếp vào `auth.users` trong Table Editor.
- Không insert `public.users` để “giả lập account”. Nếu thiếu identity Auth thì không thể login/session/RLS đúng.
- Không dùng service-role key ở Flutter để tạo account.
- Nếu tạo theo Admin API, chỉ gọi ở Edge Function/backend trusted.
- Không đặt `onboarding_status=completed` thủ công trừ khi có quy trình migration/operations được phê duyệt.

## 4. Dữ liệu hiển thị ban đầu

Sau create, admin có thể kiểm tra:

| Bảng | Dữ liệu mong đợi |
|---|---|
| `auth.users` | id, email, confirmation state |
| `public.users` | same id, email, tier free, `not_started` |
| `health_profiles` | one blank row for user_id |
| `lifestyle_habits` | one default row for user_id |

## 5. Failure / support procedure

1. Không thấy profile row: chạy `database/002_verify_auth_profile_integrity.sql`.
2. Xác nhận trigger/function tồn tại, không tự insert bằng Table Editor.
3. Chạy backfill/repair bằng SQL Editor quyền admin theo `13_ERROR_HANDLING_AND_DATA_RECOVERY.md`.
4. Ghi worklog issue; không “sửa tạm” ở Flutter.

## 6. Acceptance

TC-AUTH-07 trong `15_TEST_ACCEPTANCE_AND_TRACEABILITY.md`.
