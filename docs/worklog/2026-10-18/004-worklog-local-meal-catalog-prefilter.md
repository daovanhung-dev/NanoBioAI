Commit de xuat: feat(ai): loc mon cuc bo truoc khi tao lich

# Worklog - Lọc món cục bộ trước khi tạo lịch

## Thời gian

- Ngày: 2026-10-18
- Bắt đầu: đầu phiên triển khai hiện tại
- Kết thúc: 19:26, Asia/Ho_Chi_Minh
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding / test / docs
- Module chính: M02 PERSONAL_SCHEDULE_AI; tiến độ onboarding và tạo thêm lịch
- Yêu cầu gốc: lọc catalog trước AI theo suất ăn, mục tiêu, sức khỏe, dị ứng/món cần tránh; dừng nếu thiếu món độc nhất; hiển thị toàn bộ kết quả lọc ở màn chờ.
- Giới hạn: giữ nguyên các cờ duyệt catalog và thay đổi chưa commit ngoài phạm vi; không gọi AI thật, không sửa quota/Supabase.

## Đã làm

- Thêm `MealCatalogPrefilter` thuần Dart. Ưu tiên nhãn suất có sẵn; suy luận năm suất từ tên/nguyên liệu bằng quy tắc hữu hạn; loại tên mơ hồ và giữ riêng mã/tên đã phân loại trong progress.
- Áp dụng policy cá nhân trước khi AI nhận catalog. Khi hồ sơ có mục tiêu/tình trạng/dị ứng/món cần tránh mà bằng chứng liên quan chưa xác minh, món bị loại. Không dùng dinh dưỡng ước tính làm bằng chứng; trạng thái `is_plan_eligible`, review và provenance không bị đổi.
- Trên hai asset hiện tại, lọc cục bộ 3.163 món còn 3.113 cho hồ sơ rỗng: sáng 639 chính + 41 phụ, trưa 597 chính, chiều/tối 1.747 chính + 89 phụ. 50 món bị loại vì không phân loại rõ hoặc trùng tên/mã. Mỗi suất còn dư ít nhất 7 món độc nhất.
- Phát danh sách bất biến sau lọc trước lượt AI đầu tiên; sau đó giữ bước shortlist theo giới hạn ngữ cảnh. Nếu suất nào thiếu số món độc nhất theo số ngày yêu cầu, service dừng trước AI, ghi lịch và quota commit, đồng thời trả copy hướng dẫn người dùng.
- Dùng panel tiến độ chung cho onboarding và tạo thêm lịch. Panel hiển thị tổng số món, ghi chú AI có thể dùng shortlist nhỏ hơn, nhóm Sáng/Trưa/Chiều-Tối rồi Chính/Phụ, trạng thái rỗng và danh sách `ListView.builder` tải lười.
- Thêm test đơn vị bộ lọc, selector, prompt, service và UI; thêm test đọc toàn bộ hai asset thật để ghi nhận số lượng sau lọc.

## File code/docs đã sửa

- `lib/app_versions/v1/features/meal_plan/domain/services/meal_catalog_prefilter.dart` - mới - phân loại, lọc hồ sơ, khử trùng và đếm theo suất.
- `lib/app_versions/v1/features/meal_plan/domain/services/meal_candidate_selector.dart` - policy riêng cho lịch cá nhân và kiểm tra mục tiêu/tình trạng.
- `lib/app_versions/v1/services/ai/generated_plan_service.dart` - lọc và phát preview trước AI; dừng an toàn khi không đủ món.
- `lib/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart` - giữ nhãn suất khi tạo shortlist.
- `lib/shared/widgets/generated_plan_progress_panel.dart` - panel nhóm món lọc dùng chung.
- `lib/app_versions/v1/features/onboarding/` và `lib/app_versions/v1/features/dashboard/` - nối progress và hiển thị panel ở hai luồng.
- `lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_page.dart` - hiển thị thông báo thiếu ứng viên.
- `test/app_versions/v1/features/meal_plan/`, `test/app_versions/v1/services/ai/`, `test/app_versions/v1/features/onboarding/` - coverage cho bộ lọc, dừng trước AI, callback và UI hẹp/rỗng.
- `docs/features/ai-generated-plan/009-feature-local-meal-catalog-prefilter.md` - hành vi, số liệu hiện tại và giới hạn chứng cứ.
- `docs/checklist/checklist_complete_DD.md`, `docs/checklist/checklist_task_coding.md` - cập nhật bằng chứng M02 và việc còn chờ.

## Tài liệu liên quan

- M02: `docs/checklist/checklist_complete_DD.md`.
- Handoff coding: `docs/checklist/checklist_task_coding.md`.
- Feature: `docs/features/ai-generated-plan/009-feature-local-meal-catalog-prefilter.md`.

## Commands

- `dart format --set-exit-if-changed` trên 20 file Dart trong scope: PASS, không cần format lại.
- `flutter test test/app_versions/v1/features/meal_plan/meal_catalog_prefilter_test.dart test/app_versions/v1/features/meal_plan/meal_candidate_selector_test.dart test/app_versions/v1/services/ai/prompts/meal_plan_prompt_test.dart test/app_versions/v1/features/onboarding/onboarding_schedule_progress_panel_test.dart test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart`: PASS, 56 tests.
- Targeted `flutter analyze` cho 20 file nguồn/test trong scope: PASS, không có issue.
- `git diff --check`: PASS.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS, history/task-skill được làm mới.
- `flutter run -d chrome --no-pub`: PASS, app debug khởi động; Flutter Web báo thiếu asset `assets/.env` (HTTP 404). Hot reload qua Dart VM service: PASS.
- `flutter run -d linux --no-pub`: FAIL vì môi trường thiếu `clang++`; không ảnh hưởng kiểm tra Web.
- Kiểm tra tạo lịch thật trên Android/local AI và Supabase quota sandbox: chưa chạy.

## Lỗi/Rủi ro

- Đã sửa: tương thích `StateProvider` với Riverpod legacy export; kiểu nullable map-entry trong prompt; cast dư trong mapping lỗi.
- Chưa xác minh: inference local trên Android, quyền/provenance của 3.000 món, review công thức/dinh dưỡng/dị ứng và quota sandbox.
- Runtime Chrome ghi nhận `assets/.env` trả 404; generation không được mở trên web và không có request AI thật trong phiên.

## Tỷ lệ hoàn thành

- Hoàn thành: lọc trước AI, fail-closed khi thiếu evidence/ứng viên, callback progress, UI dùng chung, focused tests và tài liệu.
- Đang dở: smoke tạo lịch trên thiết bị có model local và xác minh quota sandbox; quyền và review dữ liệu catalog.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - scope được giữ; số lượng catalog được tính từ asset thật thay vì chỉ fixture.
- Mức độ hoàn thành task: hoàn thành phần code và kiểm chứng cục bộ theo plan; chưa có bằng chứng thiết bị/Supabase.
- Bằng chứng kiểm chứng: test toàn catalog 3.163 món, focused suite, analyzer, Chrome debug/hot reload.
- Điểm tốn token/chưa tối ưu: bản build Chrome đầu tiên cần một vòng sửa API provider/analyzer từ các thay đổi chưa commit đang có trong workspace.
- Cách tối ưu cho phiên sau: tiếp tục dùng test asset thật và test dừng trước quota; thiết lập toolchain Android để kiểm tra local inference.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
