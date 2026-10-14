# Fixbug - Đăng ký SĐT bị báo nhầm tài khoản khóa

## Hiện tượng

Trên Android, gửi form tạo tài khoản bằng SĐT thất bại và hiện thông báo “Tài khoản bị khóa”. Người dùng chưa có tài khoản; đây là lỗi cấu hình Auth của project.

## Nguyên nhân

- Supabase production project `rnwohifdnylqfofkydfl` trả về `external.phone=false`, `phone_autoconfirm=false` và `disable_signup=false` khi kiểm tra `/auth/v1/settings`.
- Tại thời điểm tái hiện, app gọi Supabase Auth phone/password nhưng hosted phone provider đang tắt. Người dùng sau đó chọn giữ phone provider tắt; app hiện dùng alias nội bộ Email/Password Auth thay cho phone provider.
- `SupabaseAuthErrorTranslator` trước đây coi mọi lỗi chứa `disabled` là tài khoản bị khóa, bao gồm lỗi cấu hình phone signup bị tắt.

## Thay đổi trong repo

- Phân loại lỗi cấu hình phone rõ ràng trước nhánh tài khoản bị khóa, rồi chuyển luồng thành viên sang phone/password qua alias nội bộ do server tạo.
- Thêm regression test cho phản hồi `Phone signups are disabled` và xác nhận thông báo không bị phân loại thành tài khoản bị khóa.

## Kiểm chứng

- Android device `220333QPG`: tái hiện đăng ký thất bại trước sửa; sau sửa cùng đường đi hiển thị thông báo dịch vụ chưa sẵn sàng thay vì báo tài khoản bị khóa.
- `flutter test test/services/supabase/auth/supabase_auth_error_translator_test.dart`: PASS.
- `dart analyze` trên translator và test: PASS.
- Hot reload qua Dart Tooling Daemon: PASS.
- Live Auth settings được truy vấn lại và vẫn là `external.phone=false`, `phone_autoconfirm=false`, `disable_signup=false`.

## Trạng thái

Phân loại lỗi trong app đã sửa. Đăng ký và đăng nhập thành công chưa được nghiệm thu vì cấu hình hosted đang tắt phone provider và phone auto-confirm. Cần cập nhật riêng hai cờ Auth trên đúng project production, sau đó tạo tài khoản kiểm thử và xác minh đăng nhập qua app. Không dùng `supabase config push` vì lệnh đó áp cấu hình local rộng hơn hai cờ cần thay đổi.
