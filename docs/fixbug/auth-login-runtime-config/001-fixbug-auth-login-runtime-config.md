Commit de xuat: fix(auth): nap public Supabase config cho moi cach run va build

# Fixbug - Đăng nhập bị khóa ở bản chạy/build thông thường

## Triệu chứng

- Màn hình đăng nhập hiển thị **Đăng nhập chưa sẵn sàng**.
- Nút **Tiếp tục** bị vô hiệu hóa dù `.env` trong thư mục dự án có cấu hình Supabase.
- Lỗi xuất hiện khi chạy hoặc build bằng lệnh Flutter thông thường, không truyền `--dart-define-from-file`.

## Nguyên nhân gốc

- `.env` đã được loại khỏi Flutter assets để tránh đóng gói cả khóa Gemini và các biến riêng tư.
- `AppEnv` chỉ đọc `--dart-define` hoặc dotenv asset, vì vậy bản chạy/build trực tiếp không nhận được `SUPABASE_URL` và `SUPABASE_ANON_KEY`.
- File `.env` hiện tại còn có UTF-8 BOM ở đầu, có thể khiến khóa đầu tiên không được nhận ổn định khi truyền qua công cụ build.

## Cách sửa

- Tạo `assets/config/auth.env` chỉ chứa bốn biến client được phép:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - `AUTH_EMAIL_REDIRECT_URL`
  - `AUTH_CONFIRM_EMAIL_REQUIRED`
- `AppEnv.loadOptionalDotEnv()` nạp thêm file public auth config từ `rootBundle`.
- Thứ tự ưu tiên vẫn là `--dart-define` -> `.env` local -> public auth asset.
- Parser whitelist toàn bộ key để không thể vô tình đóng gói `GEMINI_API_KEY`, service-role key hoặc biến riêng tư khác.
- Loại bỏ UTF-8 BOM khỏi `.env` local để script `--dart-define-from-file` đọc ổn định.
- Giữ cơ chế khóa an toàn khi Supabase thật sự không thể khởi tạo; không chỉ bật nút giả khi backend chưa sẵn sàng.

## Kết quả mong đợi

- `flutter run -t lib/main.dart` có thể khởi tạo Supabase và bật nút đăng nhập.
- `flutter build apk --release -t lib/main.dart` tạo bản cài đặt có thể đăng nhập mà không cần script riêng.
- Script `tools/run_v2.ps1` và `tools/build_authenticated.ps1` vẫn dùng được để ghi đè cấu hình theo môi trường.

## Kiểm chứng

- PASS: public auth asset tồn tại và chỉ có bốn key whitelist.
- PASS: `.env` không còn UTF-8 BOM.
- PASS: `pubspec.yaml` đã khai báo `assets/config/`.
- PASS: kiểm tra tĩnh cho thấy `main.dart` nạp `AppEnv` trước khi khởi tạo Supabase.
- BLOCKED: chưa chạy `dart format`, `flutter analyze`, `flutter test` và APK smoke vì môi trường hiện tại không có Flutter/Dart.
