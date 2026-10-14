# Worklog - Reproduce Member Phone Signup Failure

## Thời gian

- Ngày: 2026-10-14
- Bắt đầu: 18:42
- Kết thúc: 18:48
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: bugfix
- Module chính: M05 `AUTH_PROFILE_SYNC`, Supabase Auth member phone signup.
- Yêu cầu gốc: tái hiện lỗi không thể tạo tài khoản thành viên; sửa lỗi phân loại phản hồi Auth và xác minh đăng ký/đăng nhập.
- Mục tiêu: tìm nguyên nhân hosted Auth và sửa lỗi phân loại phản hồi Auth.

## Bằng chứng nguyên nhân

- Xác nhận runtime config đúng project `rnwohifdnylqfofkydfl`.
- Hosted Auth `/auth/v1/settings`: `external.phone=false`, `phone_autoconfirm=false`, `disable_signup=false`.
- Android device `220333QPG`: thao tác tạo tài khoản thất bại và trước bản vá hiển thị nhầm thông báo “Tài khoản bị khóa”.
- Local `supabase/config.toml` không cập nhật hosted Auth tự động.

## Đã sửa

- `SupabaseAuthErrorTranslator` phân loại lỗi có nội dung phone cùng disabled/not enabled thành lỗi cấu hình, trước nhánh lỗi tài khoản bị khóa.
- Thêm regression test cho `Phone signups are disabled`.
- Sau hot reload, thử lại trên Android: app không còn báo nhầm tài khoản bị khóa; app báo dịch vụ đăng nhập chưa sẵn sàng.

## Kiểm chứng

- `dart format --set-exit-if-changed` cho translator và test: PASS, 0 file thay đổi.
- `flutter test test/services/supabase/auth/supabase_auth_error_translator_test.dart`: PASS, 5 tests.
- `dart analyze lib/services/supabase/auth/supabase_auth_error_translator.dart test/services/supabase/auth/supabase_auth_error_translator_test.dart`: PASS, không có issue.
- Dart Tooling Daemon hot reload: PASS.
- Kiểm tra lại hosted Auth settings sau tái hiện: phone provider và auto-confirm vẫn OFF.
- Đăng ký tài khoản mới và đăng nhập SĐT chưa thể hoàn tất trong phiên này vì chưa có Dashboard browser hoặc Supabase Management API connector/token để cập nhật chính xác hai hosted Auth settings. Không chạy `supabase config push`, không thay đổi database hoặc project config khác.

## Trạng thái

- Source bug phân loại lỗi: đã sửa và có regression test.
- Gốc lỗi chặn signup: đã xác nhận là hosted Auth chưa bật phone provider; phone auto-confirm cũng đang tắt.
- Production acceptance tạo tài khoản rồi đăng nhập lại: CHƯA XONG, chờ khả năng cập nhật hosted Auth settings. User đã cho phép kiểm thử production; chưa cần xin thêm quyền cho đúng hai cờ đã nêu.

## Tự đánh giá

- Bằng chứng runtime trực tiếp đã tách rõ lỗi cấu hình provider khỏi tài khoản bị khóa.
- Không claim hoàn thành mục tiêu signup/login vì hosted config chưa đổi và chưa có đăng nhập thành công.
- Bước tiếp theo: cập nhật `external_phone_enabled=true` và `sms_autoconfirm=true` trên đúng project; xác minh lại settings; tạo tài khoản test trên app; đăng xuất rồi đăng nhập lại bằng chính SĐT/mật khẩu.
