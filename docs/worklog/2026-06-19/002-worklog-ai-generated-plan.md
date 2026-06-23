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
- Thêm CTA `Nabitạo thêm kế hoạch` trong hero Dashboard.
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

## Cập nhật 10:25 - giảm lỗi Gemini 503

### Phạm vi

- Loại task: hardening
- Module chính: AI service
- Yêu cầu gốc: mở rộng fallback model pool, retry ngắn, cooldown model lỗi 503 và fallback local sớm.

### Đã làm

- Đổi default model sinh kế hoạch sang `gemini-3.1-flash-lite`.
- Thêm fallback mặc định: `gemini-3.5-flash`, `gemini-2.5-flash-lite`, `gemini-2.5-flash`.
- Thêm `GEMINI_PLAN_OVERFLOW_MODELS` để bật Pro/Preview thủ công khi cần.
- Giữ hỗ trợ legacy `GEMINI_MODEL` và `GEMINI_FALLBACK_MODELS` khi chưa có biến `GEMINI_PLAN_*`.
- Đổi chunk sinh kế hoạch 7 ngày thành 1 chunk meal và 1 chunk exercise để giảm số request Gemini.
- Đổi retry lỗi tạm thời sang mỗi model 1 lần, delay ngắn, model lỗi vào cooldown 3 phút.
- Khi tất cả model lỗi/cooldown, meal/exercise chuyển sang fallback local từ catalog thay vì ném lỗi quá tải lên UI.

### File code/docs đã sửa

- `lib/services/ai/ai_service.dart` - sửa - model pool, env mới, retry/cooldown và fallback local cho lỗi tạm thời.
- `test/services/ai/ai_service_test.dart` - sửa - test default model pool, overflow, failover, cooldown và fallback local.
- `.env.example` - sửa - thêm biến `GEMINI_PLAN_*`.
- `README.md` - sửa - cập nhật ví dụ env Gemini.
- `docs/features/ai-generated-plan/001-feature-ai-generated-plan.md` - sửa - ghi rõ cơ chế chịu tải AI.
- `docs/worklog/2026-06-19/002-worklog-ai-generated-plan.md` - sửa - ghi nhận cập nhật này.

### Commands

- `dart format lib\services\ai\ai_service.dart test\services\ai\ai_service_test.dart`: PASS
- `flutter test test/services/ai`: PASS
- `flutter test test/features/dashboard`: PASS
- `powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1`: PASS theo exit code script; output vẫn có analyzer warnings sẵn và full test còn 2 failure ngoài phạm vi.
- `dart format --set-exit-if-changed lib\services\ai\ai_service.dart test\services\ai\ai_service_test.dart`: PASS
- `dart analyze lib\services\ai\ai_service.dart test\services\ai\ai_service_test.dart`: PASS

### Lỗi/Rủi ro

- Đã fix: lỗi 503/quota/timeout không còn làm luồng sinh kế hoạch fail ngay khi hết model khả dụng; app dùng fallback local.
- Chưa fix: `.env` thật không được sửa theo quy tắc an toàn, nên môi trường local cần tự thêm `GEMINI_PLAN_*` nếu muốn dùng model pool mới thay vì legacy key.
- Cần kiểm tra tiếp: chạy thực tế trên thiết bị với API key thật để quan sát tỷ lệ `MODEL_COOLDOWN_SKIP`, `RETRY_EXHAUSTED` và `LOCAL_GEN` trong log.
