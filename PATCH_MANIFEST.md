# Auth Login Runtime Config Fix

## Mục tiêu

Sửa trạng thái **Đăng nhập chưa sẵn sàng** khi ứng dụng được chạy hoặc build
bằng lệnh Flutter thông thường.

## Nguyên nhân

`main.dart` cần Supabase URL và anon key trước khi khởi tạo auth. `.env` đầy đủ
không được đóng gói vào app, còn bản chạy/build trực tiếp không truyền
`--dart-define-from-file`, nên auth bị đánh dấu thiếu cấu hình và nút đăng nhập
bị khóa.

## Thay đổi chính

- Thêm `assets/config/auth.env` chỉ chứa public Supabase client config.
- `AppEnv` tự nạp fallback này từ assets.
- Giữ thứ tự ưu tiên: dart-define -> dotenv local -> public auth asset.
- Whitelist key để không đóng gói Gemini key hoặc service-role key.
- Loại bỏ UTF-8 BOM khỏi `.env` local.
- Thêm test cho config fallback và whitelist.

## Chạy và build

```powershell
flutter run -t lib/main.dart
flutter build apk --release -t lib/main.dart
```

Có thể tiếp tục dùng `tools/run_v2.ps1` và `tools/build_authenticated.ps1` để
validate hoặc ghi đè cấu hình theo môi trường.

## Kiểm tra đề xuất

```powershell
dart format lib/core/config/app_env.dart test/core/config/app_env_test.dart test/core/config/bundled_auth_config_contract_test.dart
flutter analyze lib/core/config/app_env.dart test/core/config/app_env_test.dart test/core/config/bundled_auth_config_contract_test.dart
flutter test test/core/config/app_env_test.dart test/core/config/bundled_auth_config_contract_test.dart test/app_versions/v2/features/auth/auth_pages_smoke_test.dart
```
