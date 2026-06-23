Commit đề xuất: fix(ui): thổi hồn Nabicho copy và trạng thái UI

# Worklog - Nabihóa copy UI

## Thời gian

- Ngày: 2026-06-19
- Bắt đầu: Không xác định trong phiên Codex
- Kết thúc: 2026-06-19 14:15:23 +07:00
- Timezone: Asia/Saigon

## Phạm vi

- Loại task: fix UI/copy
- Module chính: `lib/features/**/presentation`
- Yêu cầu gốc: Rà soát toàn bộ UI, loại bỏ việc hiển thị mã nội bộ như SQLite/bảng/query/error thô, và chỉnh các view chưa có tinh thần Nami.

## Đã làm

- Thay copy người dùng đang lộ thuật ngữ nội bộ bằng thông điệp tiếng Việt có dấu, nhẹ nhàng theo persona Nami.
- Không còn đưa `error.toString()` hoặc `snapshot.error` trực tiếp ra UI người dùng.
- Ẩn mục công cụ dữ liệu dev trong Settings bằng `kDebugMode`.
- Làm mềm các placeholder Community, Sleep Tracking, Stress Tracking bằng card, icon, theme token và copy Nami.
- Chỉnh primitive `ErrorState` để mặc định dùng tiếng Việt và giọng Nabihơn.

## File code/docs đã sửa

- `lib/features/dashboard/presentation/pages/dashboard_page.dart` - sửa - loại copy mã bảng, raw error và copy hệ thống.
- `lib/features/other/presentation/pages/other_page.dart` - sửa - loại copy SQLite/AI table và raw error.
- `lib/features/profile/presentation/pages/profile_page.dart` - sửa - loại copy SQLite/bảng và raw error.
- `lib/features/settings/presentation/pages/settings_page.dart` - sửa - thay copy kỹ thuật và ẩn Dev tool trong release/user UI.
- `lib/features/settings/presentation/pages/dev_database_viewer_page.dart` - sửa - không hiển thị `snapshot.error` thô trong dev tool.
- `lib/features/meal_plan/presentation/pages/meal_plan_page.dart` - sửa - thay raw error bằng thông điệp Nami.
- `lib/features/daily_health_tracking/presentation/pages/daily_health_tracking_page.dart` - sửa - thay raw error bằng thông điệp Nami.
- `lib/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_page.dart` - sửa - thay raw error bằng thông điệp Nami.
- `lib/features/auth/presentation/pages/login_pages.dart` - sửa - thay snackbar lỗi đăng nhập thô bằng thông điệp Nami.
- `lib/features/community/presentation/pages/community_page.dart` - sửa - polish placeholder.
- `lib/features/sleep_tracking/presentation/pages/sleep_tracking_page.dart` - sửa - polish placeholder.
- `lib/features/stress_tracking/presentation/pages/stress_tracking_page.dart` - sửa - polish placeholder.
- `lib/core/theme/primitives/states/error_state.dart` - sửa - Việt hóa default title/retry label.
- `docs/worklog/2026-06-19/004-worklog-ui-nami-copy-polish.md` - tạo - ghi nhận phiên.

## Tài liệu liên quan

- Không phát sinh docs feature/fixbug/test/issue riêng.

## Commands

- `rg -n "SQLite|database|bảng|cột|health_goals|ai_insights|ai_recommendations|SharedPreferences|Supabase|local storage|error\\.toString\\(\\)|snapshot\\.error" lib/features -g "**/presentation/**/*.dart" -g "!**/dev_database_viewer_page.dart"`: PASS - chỉ còn import tới trang dev-only.
- `rg -n "meal_plans|daily_health_tasks|health_profiles|survey_answers|medical_treatments|food_allergies|lifestyle_habits|log sức khỏe|dữ liệu local|local của bạn|dữ liệu động" lib/features -g "**/presentation/**/*.dart" -g "!**/dev_database_viewer_page.dart"`: PASS - không còn kết quả.
- `rg -n "error\\.toString\\(\\)|snapshot\\.error|SnackBar\\(content: Text\\(e\\.toString\\(\\)\\)" lib/features -g "**/presentation/**/*.dart"`: PASS - không còn kết quả.
- `git diff --check -- <files đã sửa>`: PASS - chỉ có cảnh báo LF/CRLF trên Windows, không có whitespace error.
- `dart format <files đã sửa>`: FAIL/BLOCKED - timeout sau 120 giây, không có output.
- `dart --version`: FAIL/BLOCKED - timeout sau 30 giây.
- `dart --disable-dart-dev --version`: FAIL/BLOCKED - timeout sau 20 giây.
- `flutter --version`: FAIL/BLOCKED - timeout sau 20 giây.
- `flutter analyze`: SKIPPED - Dart/Flutter command đang timeout.
- `flutter test`: SKIPPED - Dart/Flutter command đang timeout.
- `.codex/tool/codex_quick_check.ps1`: SKIPPED - phụ thuộc Flutter/Dart đang timeout.

## Lỗi/Rủi ro

- Đã fix: UI người dùng không còn hiển thị raw error, mã bảng, hoặc thuật ngữ SQLite/DB ở các màn hình đã rà.
- Chưa fix: `DevDatabaseViewerPage` vẫn là công cụ kỹ thuật và còn thuật ngữ dev; trang này đã được ẩn khỏi Settings thường bằng `kDebugMode`.
- Cần kiểm tra tiếp: Dart/Flutter toolchain đang bị kẹt hoặc bị tiến trình nền chặn; cần chạy lại format/analyze/test sau khi xử lý các tiến trình `dart` chạy từ trước phiên.
