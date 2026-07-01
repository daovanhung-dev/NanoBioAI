Commit đề xuất: feat(dashboard): thêm Nabicompanion cho trang chủ

# Worklog - Dashboard NabiCompanion

## Thời gian

- Ngày: 2026-06-19
- Bắt đầu: Không xác định trong phiên Codex
- Kết thúc: 2026-06-19 16:16:47 +07:00
- Timezone: Asia/Saigon

## Phạm vi

- Loại task: feature Dashboard/UI + data write path
- Module chính: `dashboard`, `daily_health_tracking`, `lifestyle_schedule`, `meal_plan`, `shared/widgets`
- Yêu cầu gốc: thêm Dashboard companion với Nabi, dùng dữ liệu SQLite sẵn có, không thêm schema, giữ write path qua controller/repository/datasource/DAO.

## Đã làm

- Mở rộng `DashboardDynamicEntity` với mood hôm nay, cân nặng hôm nay, trạng thái kế hoạch, chuỗi tự chăm sóc 7 ngày và metadata timeline `sourceType/sourceId/status/canComplete`.
- Đọc dữ liệu thật từ `health_tracking_logs`, `daily_health_tasks`, `lifestyle_schedule_items`, `meal_plans` để tính timeline, plan status và streak.
- Thêm write APIs cho daily task, mood, water, weight, schedule completion và meal completion.
- Nối `DashboardController` để dispatch quick action theo `sourceType` và invalidate các provider liên quan.
- Thêm companion UI tách riêng ở `dashboard_companion_widgets.dart`: summary, daily check-in, slow-day banner, next action, score breakdown sheet, plan status, streak, quick water và weight sheets.
- Refactor Nabichat FAB thành `DraggableAIChatButton`; menu shell chỉ hiện nút chat ở Dashboard tab, route `/dashboard` vẫn có nút standalone.
- Giữ AI chat route đi thẳng `RoutePaths.aiChat` vì route hiện tại chưa nhận context `extra`.

## File code/docs đã sửa

- `lib/features/dashboard/domain/entities/dashboard_dynamic_entity.dart` - sửa - thêm metadata và entity phụ cho companion.
- `lib/features/dashboard/data/datasources/dashboard_dynamic_local_datasource.dart` - sửa - đọc mood/weight, build timeline có source, tính plan status và streak.
- `lib/features/dashboard/domain/services/dashboard_companion_service.dart` - tạo - logic local cho next action, slow-day, summary và score breakdown.
- `lib/features/dashboard/presentation/controllers/dashboard_controller.dart` - sửa - thêm action write path và refresh provider.
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` - sửa - lắp UI companion vào Dashboard.
- `lib/features/dashboard/presentation/widgets/companion/dashboard_companion_widgets.dart` - tạo - widgets companion.
- `lib/shared/widgets/ai_chat_fab.dart` - sửa - thêm FAB draggable dùng chung.
- `lib/features/dashboard/presentation/pages/menu_page.dart` - sửa - dùng chat button chung, chỉ hiện ở tab Dashboard.
- `lib/features/daily_health_tracking/**` - sửa - thêm APIs complete task/mood/water/weight.
- `lib/features/lifestyle_schedule/**` - sửa - thêm complete schedule item by id.
- `lib/features/meal_plan/**` - sửa - thêm complete meal by id.
- `test/features/dashboard/**` - sửa/tạo - dynamic datasource và companion service tests.
- `test/features/daily_health_tracking/data/daily_health_tracking_local_datasource_write_test.dart` - tạo - write path tests.
- `test/features/lifestyle_schedule/data/lifestyle_schedule_completion_test.dart` - sửa - complete by id test.
- `test/features/meal_plan/data/meal_plan_completion_test.dart` - tạo - complete meal test.
- `docs/worklog/2026-06-19/006-worklog-dashboard-Nabi-companion.md` - tạo - ghi nhận phiên.
- `docs/features/dashboard_nami_companion/001-feature-dashboard-Nabi-companion.md` - tạo - mô tả feature.
- `docs/test/dashboard_nami_companion/001-test-dashboard-Nabi-companion.md` - tạo - ghi nhận test.

## Commands

- `dart format .`: PASS.
- `flutter analyze`: FAIL do repo đang tính warning/info là fatal; output gồm warning/info sẵn có, không thấy compile error mới.
- `flutter analyze --no-fatal-infos --no-fatal-warnings`: PASS, không có lỗi compile.
- `flutter test test/features/dashboard test/features/daily_health_tracking test/features/lifestyle_schedule test/features/meal_plan`: PASS, 46 tests passed.
- `git diff --check`: PASS, chỉ có warning LF/CRLF trên Windows.

## Ghi chú/Rủi ro

- `dart`/`flutter` timeout khi chạy trong sandbox, đã chạy validation ngoài sandbox sau khi được phê duyệt.
- `dart format .` format lại 36 file, bao gồm một số file đã modified sẵn trong worktree.
- TODO: AI chat route chưa support `extra`, nên Dashboard chỉ mở `RoutePaths.aiChat`; cần thêm route contract nếu muốn truyền dashboard context vào chat.
- TODO: score breakdown hiện là breakdown local từ metrics Dashboard, chưa phải công thức điểm persisted/có version.
