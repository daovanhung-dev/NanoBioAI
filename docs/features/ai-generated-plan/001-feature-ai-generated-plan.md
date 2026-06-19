Commit đề xuất: feat(dashboard): sinh thêm kế hoạch AI sau onboarding

# AI sinh thêm kế hoạch sau onboarding

## Mục tiêu
- Cho người dùng tạo thêm 7 ngày kế hoạch sau khi onboarding đã hoàn tất.
- Dữ liệu sinh thêm gồm thực đơn, bài tập, lịch trình sinh hoạt và nhắc nhở.

## Phạm vi
- Bao gồm: sinh thêm kế hoạch từ Dashboard, dùng ngày trống kế tiếp, không ghi đè dữ liệu cũ.
- Không bao gồm: chọn số ngày, ghi đè kế hoạch cũ, thêm bảng hoặc migration mới.

## Luồng hoạt động
1. Người dùng bấm `Nami tạo thêm kế hoạch` trên Dashboard.
2. App đọc hồ sơ mới nhất và tìm ngày sau cùng đã có lịch trình cá nhân.
3. App sinh thêm 7 ngày từ ngày trống kế tiếp.
4. App lưu meal plan, build lifestyle schedule, lưu schedule và refresh notification.
5. Dashboard refresh để hiện dữ liệu mới.

## Dữ liệu và lưu trữ
- Nguồn đọc: hồ sơ dashboard, daily health profile, AI catalog, meal/schedule đã có.
- Nơi ghi: `meal_plans`, `lifestyle_schedule_items`, notifications qua scheduler hiện có.
- Table/model/entity: `MealPlanModel`, `ExerciseTaskModel`, `LifestyleScheduleItemModel`.
- Migration/version: không đổi schema.
- Ghi chú: thực đơn, bài tập và lịch trình phải dùng cùng `profile.userId` để timeline cá nhân gom đúng dữ liệu.
- Ghi chú: mốc sinh thêm dựa trên `lifestyle_schedule_items`, không dựa trên meal-only, để có thể tự sửa trường hợp thực đơn đã sinh nhưng lịch trình chưa có.

## UI/UX
- Loading: nút CTA chuyển sang trạng thái `Nami đang chuẩn bị thêm kế hoạch cho bạn...`.
- Empty: nếu chưa có kế hoạch, bắt đầu từ ngày mai.
- Error: hiện SnackBar thân thiện, không lộ lỗi kỹ thuật.
- Success: hiện SnackBar `Nami đã thêm kế hoạch 7 ngày tiếp theo rồi nhé.`

## Files
- `lib/services/ai/generated_plan_service.dart` - thêm service dùng chung cho luồng sinh kế hoạch.
- `lib/main.dart` - onboarding dùng lại service sinh kế hoạch.
- `lib/features/dashboard/presentation/controllers/dashboard_controller.dart` - thêm action sinh thêm kế hoạch và refresh provider.
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` - thêm CTA trên hero Dashboard.
- `lib/features/lifestyle_schedule/data/datasources/lifestyle_schedule_local_datasource.dart` - tìm ngày trống kế tiếp.

## Kiểm chứng
- Command: `flutter test test/features/lifestyle_schedule`
- Kết quả: PASS
- Command: `flutter test test/features/dashboard`
- Kết quả: PASS
- Command: `flutter test test/services/ai`
- Kết quả: PASS khi chạy tuần tự
- Command: `dart analyze lib\services\ai\generated_plan_service.dart lib\features\lifestyle_schedule\data\datasources\lifestyle_schedule_local_datasource.dart lib\features\dashboard\presentation\controllers\dashboard_controller.dart lib\main.dart`
- Kết quả: PASS
- Command: `flutter analyze`
- Kết quả: FAIL do warning/info sẵn có trong repo, không thấy lỗi biên dịch mới
- Command: `powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1`
- Kết quả: script exit 0 nhưng output có analyzer warnings và `flutter test` full còn 2 failure sẵn có/ngoài phạm vi

## Liên kết
- Worklog: [Worklog AI sinh thêm kế hoạch](../../worklog/2026-06-19/002-worklog-ai-generated-plan.md)
- Test/Issue: không tạo issue riêng trong phiên này

## Rủi ro
- Full test suite hiện còn fail ở architecture preservation source-check và features hub off-screen tap, không thuộc trực tiếp tính năng này.
- Notification scheduling vẫn có thể fail theo môi trường/quyền hệ thống; service đã ghi log và không rollback dữ liệu đã sinh.
- Nếu người dùng từng bấm bản trước khi sửa, có thể đã có meal cũ không gắn đúng user; bấm lại sau bản sửa sẽ tạo meal đúng user và sinh được lịch trình cá nhân.
- Nếu từng có meal nhưng chưa có lịch trình, bấm lại sẽ bắt đầu từ mốc lịch trình hiện có hoặc ngày mai, thay meal trong khoảng sinh để build đủ timeline.
