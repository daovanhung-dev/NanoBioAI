Commit đề xuất: fix(dashboard): đồng bộ kế hoạch mới với lịch trình và thực đơn

# Worklog - Đồng bộ lịch trình và thực đơn sau khi tạo dữ liệu mới

## Thời gian
- Ngày: 2026-06-19
- Bắt đầu: Không xác định trong phiên Codex
- Kết thúc: 2026-06-19 15:06:21 +07:00
- Timezone: Asia/Saigon

## Phạm vi
- Loại task: fix flow dữ liệu
- Module chính: Dashboard, Lifestyle Schedule, Meal Plan, Nutrition
- Yêu cầu gốc: Sau khi bấm tạo dữ liệu mới ở Dashboard và AI lưu dữ liệu vào SQLite, lịch trình hôm nay và thực đơn theo tuần phải hiển thị thông tin mới cập nhật.

## Đã làm
- Cho phép `GeneratedPlanService.generateNextPlan` nhận ngày bắt đầu tùy chọn và chế độ nối tiếp/thay thế.
- Nút tạo kế hoạch ở Dashboard tạo lại 7 ngày từ hôm nay thay vì chỉ nối thêm sau dữ liệu cuối.
- Thêm xóa lịch trình theo user và khoảng ngày để seed schedule mới không giữ item cũ trong cùng range.
- Dashboard timeline đọc thêm `lifestyle_schedule_items` hôm nay và dùng dữ liệu lịch trình làm nguồn chính.
- Invalidate thêm controller/provider của thực đơn tuần và dinh dưỡng sau khi tạo kế hoạch.
- Thêm test cho timeline đọc schedule hôm nay, chống duplicate meal, và xóa schedule theo date range.

## File code/docs đã sửa
- `lib/services/ai/generated_plan_service.dart` - sửa - thêm `startDate`, `appendAfterExisting` và replace range khi cần.
- `lib/features/dashboard/presentation/controllers/dashboard_controller.dart` - sửa - tạo kế hoạch từ hôm nay và invalidate đủ provider liên quan.
- `lib/features/lifestyle_schedule/data/daos/lifestyle_schedule_items_dao.dart` - sửa - thêm xóa theo user/date range.
- `lib/features/lifestyle_schedule/data/datasources/lifestyle_schedule_local_datasource.dart` - sửa - xóa range cũ trước khi seed schedule thay thế.
- `lib/features/dashboard/data/datasources/dashboard_dynamic_local_datasource.dart` - sửa - đọc schedule hôm nay vào timeline và dedupe meal/task trùng.
- `test/features/dashboard/data/dashboard_dynamic_local_datasource_test.dart` - sửa - thêm bảng schedule và test timeline.
- `test/features/lifestyle_schedule/data/lifestyle_schedule_dao_test.dart` - sửa - test xóa schedule theo range.
- `docs/worklog/2026-06-19/005-worklog-generated-plan-refresh.md` - tạo - ghi nhận phiên.

## Tài liệu liên quan
- Không phát sinh docs feature/fixbug/test/issue riêng.

## Commands
- `dart format <changed files>`: FAIL/BLOCKED - timeout sau 120 giây, không có output.
- `dart --version`: FAIL/BLOCKED - timeout sau 20 giây.
- `flutter test test\features\dashboard\data\dashboard_dynamic_local_datasource_test.dart test\features\lifestyle_schedule\data\lifestyle_schedule_dao_test.dart`: FAIL/BLOCKED - timeout sau 180 giây.
- `git diff --check -- <changed files>`: PASS - chỉ có cảnh báo LF/CRLF trên Windows, không có whitespace error.
- `.codex/tool/codex_quick_check.ps1`: SKIPPED - phụ thuộc Dart/Flutter đang timeout.

## Lỗi/Rủi ro
- Đã fix: Tạo kế hoạch từ Dashboard giờ bắt đầu từ hôm nay, thay thế meal/schedule trong 7 ngày, refresh Dashboard/Lịch trình/Thực đơn/Dinh dưỡng.
- Chưa fix: Dart/Flutter toolchain vẫn treo khi chạy format/version/test trong môi trường hiện tại.
- Cần kiểm tra tiếp: Chạy lại `dart format`, targeted tests và quick check sau khi xử lý nguyên nhân Dart/Flutter timeout.
