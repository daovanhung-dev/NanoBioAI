Commit de xuat: test(auth-sync): bo sung regression Auth V2 Admin va M05

# Test - Auth V2, Admin access và đồng bộ M05

## Trạng thái

- Code và test source đã được cập nhật.
- Không đánh dấu production PASS khi chưa chạy Flutter SDK, Supabase sandbox và Android device.

## Automated coverage

### Auth V2

- Callback cold/warm dùng một coordinator và phân loại email confirmation/password recovery.
- Protected route, session expiry/sign-out và invalidate dữ liệu user.
- Referral metadata + device fingerprint được gửi trực tiếp trong `signUp`.
- UI không còn attach referral sau signup.
- Error copy không lộ chi tiết hạ tầng.

### Sync regression

- Round-trip có `personal_schedule_ai_requests` với khóa `request_id`.
- Pending outbox luôn được xử lý trước pull.
- Push lỗi/pending marker bỏ qua pull và giữ local.
- Pull lỗi giữ local, ghi durable retry.
- Local write xuất hiện trong lúc pull chặn transaction replace cache.
- Single-flight cho auth/startup/resume/connectivity.
- Sign-out pending và force sign-out giữ marker.
- Guest fresh merge/defer/established-cloud confirmation và sync status UI.

### Admin

- Restore active Admin session -> `authorized`.
- Restore session không có role -> sign-out -> `unauthorized`.
- Server báo role bị thu hồi -> sign-out -> `unauthorized`.
- Session hết hạn -> không gọi Admin session RPC.
- Backend config thiếu -> support/error state, không crash.

### SQL contract

- `15-auth-sync-completion.sql` có atomic trigger, referral/device metadata, active Sale, direct-only và collision guards.
- Migration xuất hiện đúng một lần trong `config.sql`.
- `config.sql` chỉ dùng để rebuild local/sandbox, không chạy remote/production trong phiên này.

## Lệnh cần chạy khi có Flutter/Supabase/device

```text
dart format --output=none --set-exit-if-changed <changed dart files>
flutter analyze <targeted paths>
flutter test test/app_versions/v2/features/auth
flutter test test/app_versions/v2/features/cloud_sync
flutter test test/app_versions/admin
flutter test test/docs/supabase_admin_contract_test.dart
flutter analyze
flutter test --reporter compact
flutter build apk --debug -t lib/main_v2.dart
flutter build apk --debug -t lib/main_admin.dart
git diff --check
```

## Supabase sandbox acceptance còn PENDING

- Signup hợp lệ tạo đúng một `auth.users`, `public.users`, self subject.
- Referral không hợp lệ không để lại auth user/profile mồ côi.
- Guest profile/meal/task/schedule/request ledger sync không mất hoặc nhân đôi.
- User A không đọc/ghi user B; payload không sửa server-owned fields.
- Sparse snapshot và retry idempotent.

## Device `12b304f9` còn PENDING

- Chạy đầy đủ `V2-M05-01..06`.
- Email confirmation và password recovery callback cold/warm.
- Admin login, restored session, role rejection và session expiry.
- Chỉ đổi trạng thái sang PASS khi có evidence theo regression matrix.
