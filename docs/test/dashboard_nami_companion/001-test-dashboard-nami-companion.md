Commit đề xuất: feat(dashboard): thêm Nami companion cho trang chủ

# Test - Dashboard Nami Companion

## Ngày chạy
- Ngày: 2026-06-19
- Timezone: Asia/Saigon
- Môi trường: Flutter 3.35.6, Dart 3.9.2

## Test đã thêm/cập nhật
- `test/features/dashboard/data/dashboard_dynamic_local_datasource_test.dart`
  - Timeline có `sourceType/sourceId/status/canComplete`.
  - Mood, weight, water đọc từ `health_tracking_logs`.
  - Plan status tính last date và remaining days.
  - 7-day self-care streak tính từ health log, completed task và completed meal.
- `test/features/dashboard/domain/dashboard_companion_service_test.dart`
  - Next action selection.
  - Slow-day prioritization theo category.
  - Daily summary copy.
  - Score breakdown groups.
- `test/features/daily_health_tracking/data/daily_health_tracking_local_datasource_write_test.dart`
  - Complete daily task by id.
  - Save mood/water/weight vào health log.
  - Add water sync matching water task.
- `test/features/lifestyle_schedule/data/lifestyle_schedule_completion_test.dart`
  - Complete schedule item by id.
- `test/features/meal_plan/data/meal_plan_completion_test.dart`
  - Complete meal by id.

## Commands và kết quả
- `dart format .`: PASS.
- `flutter analyze`: FAIL do warning/info sẵn có được tính là fatal; không thấy compile error mới trong output.
- `flutter analyze --no-fatal-infos --no-fatal-warnings`: PASS.
- `flutter test test/features/dashboard test/features/daily_health_tracking test/features/lifestyle_schedule test/features/meal_plan`: PASS, 46 tests passed.
- `git diff --check`: PASS, chỉ có warning LF/CRLF trên Windows.

## Ghi chú
- `dart`/`flutter` timeout trong sandbox, validation đã chạy ngoài sandbox sau khi được phê duyệt.
- Analyzer vẫn còn warning/info nên nếu CI dùng fatal warnings, cần xử lý lint nền riêng với feature này.
- TODO: AI chat route chưa support `extra`, chưa test truyền dashboard context vào chat.
- TODO: score breakdown là logic local từ metrics, chưa có test cho persisted score formula vì formula đó chưa tồn tại trong schema.
