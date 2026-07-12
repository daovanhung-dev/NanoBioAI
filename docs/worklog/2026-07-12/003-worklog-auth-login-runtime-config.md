Commit de xuat: docs(worklog): ghi nhan fix auth runtime config

# Worklog - Fix đăng nhập bị khóa do thiếu runtime config

## Thời gian

- Ngày: 2026-07-12
- Bắt đầu: 10:54
- Kết thúc: 11:05
- Timezone: Asia/Saigon

## Phạm vi

- Loại task: bugfix
- Module chính: M05 Authentication / App bootstrap config
- Yêu cầu gốc: màn đăng nhập đang báo chưa sẵn sàng; người dùng muốn đăng nhập được và không bị khóa.

## Đã làm

- Xác nhận root cause là bản chạy/build thông thường không nhận Supabase config dù `.env` local có dữ liệu.
- Thêm public auth config asset chỉ chứa bốn biến client an toàn.
- Cập nhật `AppEnv` để tự nạp fallback này trước khi Supabase khởi tạo.
- Giữ ưu tiên dart-define và dotenv local để hỗ trợ nhiều môi trường.
- Whitelist key nhằm ngăn khóa Gemini/service-role bị đóng gói.
- Xóa UTF-8 BOM khỏi `.env` để tránh mất `SUPABASE_URL` khi dùng `--dart-define-from-file`.
- Bổ sung regression/contract tests và cập nhật README.

## File code/docs đã sửa

- `lib/core/config/app_env.dart` - sửa - nạp public auth config từ assets.
- `assets/config/auth.env` - tạo - cấu hình Supabase client cho plain run/build.
- `.gitignore` - sửa - chỉ cho phép track public auth asset.
- `.env` - sửa - bỏ UTF-8 BOM, không đổi giá trị cấu hình.
- `test/core/config/app_env_test.dart` - sửa - test fallback config và không nạp Gemini key.
- `test/core/config/bundled_auth_config_contract_test.dart` - tạo - kiểm tra whitelist key.
- `README.md` - sửa - hướng dẫn run/build trực tiếp có đăng nhập.
- `docs/fixbug/auth-login-runtime-config/001-fixbug-auth-login-runtime-config.md` - tạo - ghi nhận bugfix.

## Tài liệu liên quan

- `docs/features/auth-login-unlock/001-feature-auth-login-unlock.md`
- `.codex/domains/access-membership-referral.md`

## Commands

- Kiểm tra key/placeholder `.env` bằng script mask: PASS.
- Kiểm tra UTF-8 BOM: PASS - đã loại bỏ.
- Kiểm tra public asset chỉ chứa whitelist: PASS.
- `dart format ...`: SKIPPED - không có Dart SDK.
- `flutter analyze ...`: SKIPPED - không có Flutter SDK.
- `flutter test ...`: SKIPPED - không có Flutter SDK.
- `.codex/tools/update_worklog_learning.ps1`: SKIPPED - không có PowerShell.

## Lỗi/Rủi ro

- Đã fix: plain run/build không còn thiếu Supabase client config.
- Chưa fix: chưa có bằng chứng compile/test/device trong môi trường hiện tại.
- Cần kiểm tra tiếp: chạy APK trên thiết bị và đăng nhập bằng tài khoản thật; xác nhận RLS/Supabase staging theo `OPEN_RISKS`.

## Tỷ lệ hoàn thành

- Hoàn thành: source-level fix, test source, docs và gói bàn giao.
- Đang dở: compile/analyze/widget test/device smoke.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - sửa nguyên nhân runtime thay vì chỉ bỏ disabled UI.
- Mức độ hoàn thành task: hoàn thành phần code; còn thiếu toolchain evidence.
- Bằng chứng kiểm chứng: asset whitelist, BOM check, bootstrap path và contract tests.
- Điểm tốn token/chưa tối ưu: thấp; chỉ đọc workflow bugfix, auth domain và file cấu hình liên quan.
- Cách tối ưu cho phiên sau: chạy targeted test trước, sau đó build debug và smoke login trên thiết bị.
- Task-skill cần đọc lần sau: `.codex/task-skills/bugfix.md`
