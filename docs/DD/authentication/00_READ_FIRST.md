# 00 - Đọc trước khi làm việc với Authentication

**Module:** Authentication, Registration, Login and User Profile Bootstrap  
**Nguồn yêu cầu:** `references/BD_AUTH_001.md`  
**Trạng thái DD:** Ready for implementation

## 1. Quy tắc không được phá vỡ

1. `auth.users` là nguồn sự thật duy nhất cho email, mật khẩu, session và trạng thái xác thực email.
2. `public.users.id` phải đúng bằng `auth.users.id`.
3. Trigger database, không phải Flutter client, tạo `public.users`, `health_profiles`, `lifestyle_habits` khi Auth tạo user.
4. Client không được `insert` trực tiếp ba bản ghi nền trên.
5. Dữ liệu cá nhân luôn bị giới hạn bởi RLS với `auth.uid()`.
6. Chưa hoàn thành onboarding không được vào Dashboard.
7. Xóa tài khoản phải được thực hiện từ backend/Edge Function, không dùng service-role key trong Flutter.
8. Không lưu mật khẩu, refresh token hoặc recovery token vào các bảng `public`.

## 2. Thứ tự đọc theo loại công việc

| Công việc | Bắt buộc đọc |
|---|---|
| Đăng ký | `03_DATA_MODEL_RLS_AND_MIGRATIONS.md` → `04_FEATURE_REGISTRATION.md` → `05_FEATURE_PROFILE_BOOTSTRAP.md` |
| Đăng nhập / AuthGate | `08_FEATURE_LOGIN_SESSION_AUTH_GATE.md` → `14_FLUTTER_LAYER_CONTRACTS.md` |
| Onboarding | `09_FEATURE_ONBOARDING_COMPLETION.md` → `03_DATA_MODEL_RLS_AND_MIGRATIONS.md` |
| Quên / đổi mật khẩu | `11_FEATURE_PASSWORD_RECOVERY_AND_CHANGE.md` |
| Tạo user thủ công Dashboard | `06_FEATURE_MANUAL_ACCOUNT_CREATION.md` → `database/002_verify_auth_profile_integrity.sql` |
| Xóa tài khoản | `12_FEATURE_LOGOUT_AND_ACCOUNT_DELETION.md` |
| Sửa lỗi data/profile thiếu | `13_ERROR_HANDLING_AND_DATA_RECOVERY.md` → `database/002_verify_auth_profile_integrity.sql` |
| Test/review | `15_TEST_ACCEPTANCE_AND_TRACEABILITY.md` |

## 3. Checklist trước khi code

- [ ] Đã xác định đúng mã FR trong `15_TEST_ACCEPTANCE_AND_TRACEABILITY.md`.
- [ ] Đã đọc tài liệu phụ thuộc theo bảng trên.
- [ ] Đã xác nhận migration lifecycle đã chạy trên Supabase.
- [ ] Không có code client nào insert vào `public.users`, `health_profiles`, `lifestyle_habits`.
- [ ] Không có service-role key trong Flutter hoặc `.env` client.
- [ ] Đã ghi rõ file sẽ sửa trong worklog trước khi thay đổi.

## 4. Quy tắc đọc tiết kiệm token cho Codex

Không đọc toàn bộ folder theo mặc định. Luôn đọc `00_READ_FIRST.md`, sau đó chỉ mở tài liệu của task và dependency trực tiếp. Chỉ đọc `references/BD_AUTH_001.md` khi DD chưa giải đáp yêu cầu hoặc khi cần truy vết business rule gốc.
