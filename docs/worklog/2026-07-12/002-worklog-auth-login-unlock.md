Commit de xuat: feat(auth): mo khoa dang nhap cho nguoi dung

# Worklog - Mở khóa đăng nhập người dùng

## Thời gian

- Ngày: 2026-07-12
- Timezone: Asia/Bangkok

## Phạm vi

- Loại task: coding
- Module chính: M05 `AUTH_PROFILE_SYNC`, Settings Guest entry, authenticated Android build.
- Yêu cầu gốc: đọc `AGENTS.md` và mở khóa cho phép người dùng đăng nhập.

## Đã làm

- Thêm `GuestAccountAccessCard` vào Cài đặt cho người dùng Guest.
- Thêm điều hướng đăng nhập/đăng ký và cho mục dữ liệu Guest mở màn đăng nhập.
- Ẩn đổi mật khẩu, đăng xuất, xóa tài khoản khi chưa có session.
- Thêm `currentAuthUserIdProvider` theo dõi auth event để Cài đặt cập nhật phản ứng.
- Thêm `tools/build_authenticated.ps1` để build APK/AAB với cấu hình Supabase đã kiểm tra.
- Cập nhật README và thêm widget/contract tests.

## File chính

- `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart`
- `lib/app_versions/v1/features/settings/presentation/widgets/guest_account_access_card.dart`
- `lib/app_versions/v2/features/auth/providers/auth_providers.dart`
- `tools/build_authenticated.ps1`
- `test/app_versions/v1/features/settings/guest_account_access_card_test.dart`
- `test/tools/build_authenticated_contract_test.dart`
- `README.md`

## Kiểm chứng

- PASS: kiểm tra `.env` hiện có đủ ba khóa auth bắt buộc mà không in giá trị.
- PASS: kiểm tra tĩnh import nội bộ, dấu ngoặc và chuỗi contract build.
- BLOCKED: `dart format`, `flutter analyze`, `flutter test`, APK build vì môi trường không có Flutter/Dart/PowerShell.
- Không claim production acceptance; vẫn cần chạy script build và smoke đăng nhập trên thiết bị.

## Việc tiếp theo

- Trên Windows chạy `powershell -ExecutionPolicy Bypass -File tools/build_authenticated.ps1 -Mode debug`.
- Cài APK và smoke Guest -> Cài đặt -> Đăng nhập -> Auth Gate -> đồng bộ có xác nhận.

## Tự đánh giá

- Chất lượng đầu ra: xử lý cả lối vào UI và nguyên nhân build thiếu Supabase, không hồi quy đưa `.env` vào assets.
- Mức độ hoàn thành: hoàn thành source-level; còn thiếu toolchain/device evidence.
- Bằng chứng: source contract, env key validation và test source.
- Token waste: thấp; chỉ đọc domain Auth, router, Settings và cấu hình liên quan.
- Tối ưu phiên sau: chạy targeted test/build trên máy có Flutter trước khi Supabase sandbox smoke.
