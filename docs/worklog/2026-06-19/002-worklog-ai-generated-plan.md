Commit đề xuất: feat(dashboard): sinh thêm kế hoạch AI sau onboarding

# Worklog - AI sinh thêm kế hoạch sau onboarding

## Thời gian
- Ngày: 2026-06-19
- Bắt đầu: 09:21:00
- Kết thúc: 09:47:00
- Timezone: Asia/Saigon

## Phạm vi
- Loại task: feature
- Module chính: Dashboard, AI service, lifestyle schedule
- Yêu cầu gốc: thêm chức năng để AI tạo thêm dữ liệu cho người dùng sau onboarding, gồm thực đơn, bài tập, lịch trình và gắn vào UI hợp lý.

## Đã làm
- Thêm service dùng chung để sinh thêm 7 ngày kế hoạch từ ngày trống kế tiếp.
- Đổi callback sau onboarding sang dùng service mới để tránh nhân đôi luồng.
- Thêm CTA `Nami tạo thêm kế hoạch` trong hero Dashboard.
- Thêm trạng thái loading/success/error thân thiện trên Dashboard.
- Thêm hàm tìm ngày kế hoạch kế tiếp dựa trên meal plan và lifestyle schedule đã có.
- Sửa luồng sinh thêm để meal plan dùng cùng `profile.userId` với exercise/schedule, giúp lịch trình cá nhân gom đúng meal đã sinh.
- Đổi mốc sinh thêm sang ngày cuối cùng có `lifestyle_schedule_items`, để trường hợp đã có meal nhưng chưa có lịch trình vẫn được sinh lại đủ timeline.

## File code/docs đã sửa
- `lib/services/ai/generated_plan_service.dart` - tạo - service sinh meal, exercise, schedule và refresh notification.
- `lib/main.dart` - sửa - onboarding dùng lại service sinh kế hoạch.
- `lib/features/dashboard/presentation/controllers/dashboard_controller.dart` - sửa - thêm provider/action sinh thêm kế hoạch và invalidate dữ liệu liên quan.
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` - sửa - thêm CTA, loading và SnackBar.
- `lib/features/lifestyle_schedule/data/datasources/lifestyle_schedule_local_datasource.dart` - sửa - thêm hàm tính ngày trống kế tiếp.
- `docs/features/ai-generated-plan/001-feature-ai-generated-plan.md` - tạo/cập nhật - mô tả chức năng và lưu ý dùng cùng user id.
- `docs/worklog/2026-06-19/002-worklog-ai-generated-plan.md` - tạo/cập nhật - ghi nhận phiên và bản sửa lịch trình cá nhân.

## Tài liệu liên quan
- [AI sinh thêm kế hoạch sau onboarding](../../features/ai-generated-plan/001-feature-ai-generated-plan.md)

## Commands
- `dart format lib\services\ai\generated_plan_service.dart lib\features\lifestyle_schedule\data\datasources\lifestyle_schedule_local_datasource.dart lib\features\dashboard\presentation\controllers\dashboard_controller.dart lib\features\dashboard\presentation\pages\dashboard_page.dart lib\main.dart`: PASS
- `flutter test test/features/lifestyle_schedule`: PASS
- `flutter test test/features/dashboard`: PASS
- `flutter test test/services/ai`: FAIL lần đầu do Flutter tool crash khi chạy song song; PASS khi chạy lại tuần tự
- `flutter test test/features/lifestyle_schedule test/features/dashboard test/services/ai`: PASS sau khi sửa user id cho meal/schedule
- `dart analyze lib\services\ai\generated_plan_service.dart lib\features\lifestyle_schedule\data\datasources\lifestyle_schedule_local_datasource.dart lib\features\dashboard\presentation\controllers\dashboard_controller.dart lib\main.dart`: PASS
- `flutter test test/features/lifestyle_schedule test/features/dashboard test/services/ai`: PASS sau khi đổi mốc sinh thêm theo schedule
- `dart analyze lib\services\ai\generated_plan_service.dart lib\features\lifestyle_schedule\data\datasources\lifestyle_schedule_local_datasource.dart lib\features\dashboard\presentation\controllers\dashboard_controller.dart lib\main.dart`: PASS sau khi đổi mốc sinh thêm theo schedule
- `flutter analyze`: FAIL - repo còn nhiều warning/info sẵn có, không thấy lỗi biên dịch mới từ thay đổi này
- `powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1`: PASS theo exit code script, nhưng output có analyzer warnings và full test còn 2 failure
- `flutter test`: FAIL - 2 failure ở `test/architecture_preservation_property_test.dart` và `test/features/features_hub/features_hub_page_test.dart`

## Lỗi/Rủi ro
- Đã fix: thống nhất user id khi sinh meal và schedule; dùng lịch trình cá nhân làm mốc sinh thêm để tránh bỏ qua case meal-only.
- Chưa fix: full test suite còn 2 failure ngoài phạm vi trực tiếp.
- Cần kiểm tra tiếp: test thực tế trên thiết bị với quyền notification và tài khoản đã onboarding; nếu từng bấm bản cũ, bấm lại để sinh lại meal đúng user và lịch trình cá nhân.
