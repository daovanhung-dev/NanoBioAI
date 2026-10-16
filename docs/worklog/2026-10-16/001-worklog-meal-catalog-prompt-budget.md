Commit de xuat: feat(ai): gioi han kich thuoc tom tat catalog trong prompt

# Worklog - Ngân sách prompt cho catalog 3.000 món

## Thời gian

- Ngày: 2026-10-16
- Bắt đầu: khoảng 08:25
- Kết thúc: 08:50
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding
- Module chính: M02 `PERSONAL_SCHEDULE_AI`, meal catalog prompt.
- Yêu cầu gốc: Chuẩn bị khả năng gửi toàn bộ catalog khi mở rộng lên 3.000 món; người dùng sẽ cung cấp dữ liệu có license.

## Đã làm

- Thêm ngân sách 1.000.000 byte cho JSON catalog món trong prompt. Khi cần, rút ngắn đều các `nutrition_summary` trên ranh giới code point UTF-8, bỏ trường tóm tắt nếu ngân sách không còn chỗ, và giữ nguyên toàn bộ mã/tên món.
- Tăng staging prompt version từ v8 lên `personal_schedule_v9_catalog_prompt_byte_budget` để các lượt đang dở không trộn kết quả từ hai phiên bản ngữ cảnh.
- Đếm kích thước JSON theo từng hàng để tránh tạo thêm một chuỗi catalog đầy đủ chỉ nhằm đo byte. Nếu chỉ riêng mã/tên vượt ngân sách, phát sinh lỗi có thông điệp rõ thay vì âm thầm bỏ món.
- Cập nhật chỉ dẫn prompt, feature note và M02 checklist để mô tả chính xác phần tóm tắt có thể ngắn hơn. Sau khi AI chọn mã, ứng dụng vẫn nạp nội dung chi tiết từ SQLite.
- Chưa thêm dữ liệu món, ảnh, nguồn dinh dưỡng hoặc importer: bộ dữ liệu licensed chưa có trong workspace nên chưa thể kiểm tra cấu trúc, điều khoản hay mapping.

## File code/docs đã sửa

- `lib/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart` - giới hạn byte JSON, giữ trọn mã/tên và rút gọn tóm tắt khi cần.
- `lib/app_versions/v1/services/ai/generated_plan_service.dart` - đổi staging version để bắt đầu lại lượt cũ theo prompt mới.
- `docs/features/ai-generated-plan/005-feature-full-catalog-ai-context.md` - ghi rõ ngân sách prompt và ranh giới chi tiết cục bộ.
- `docs/checklist/checklist_complete_DD.md` - đồng bộ trạng thái nguồn M02 hiện tại.
- `docs/checklist/checklist_task_coding.md` - ghi nhận thay đổi prompt cùng các bước chờ bộ dữ liệu.
- `docs/worklog/2026-10-16/001-worklog-meal-catalog-prompt-budget.md` - bằng chứng và giới hạn xác minh phiên.

## Tài liệu liên quan

- `.codex/AGENTS.md`
- `.codex/workflows/coding.md`
- `.codex/task-skills/coding.md`
- `.codex/domains/ai-service.md`
- `.codex/DOCS_WORKFLOW.md`
- `docs/features/ai-generated-plan/005-feature-full-catalog-ai-context.md`

## Commands

- `dart format lib/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart lib/app_versions/v1/services/ai/generated_plan_service.dart`: PASS.
- `flutter analyze lib/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart lib/app_versions/v1/services/ai/generated_plan_service.dart`: PASS, không có issue.
- `flutter test`: SKIPPED — phiên này không yêu cầu chạy test.
- Dart Tooling Daemon discovery: PASS; không có app đang chạy để hot reload/restart.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL do thiếu `docs/audit/source_truth_manifest.json` và stale paths trong `.codex/history/WORKLOG_2026-08-16_meal_nutrition_estimation.md`, `.codex/task-skills/nabi-character/SKILL.md`.
- `git diff --check`: PASS.
- `.codex/tools/update_worklog_learning.ps1`: PASS, cập nhật 19 file history/task-skill sinh tự động.

## Lỗi/Rủi ro

- Đã fix: prompt không còn tuyên bố danh sách tóm tắt luôn nguyên vẹn; byte budget giữ tất cả mã/tên món.
- Chưa fix: chưa có catalog 3.000 món, license, ảnh, khẩu phần, nutrition provenance và kiểm tra duplicate/chất lượng dữ liệu.
- Cần kiểm tra tiếp: xác nhận kích thước byte/token bằng bộ dữ liệu thật; chạy prompt/normalizer/generation QA tổng hợp; kiểm tra device và Gemini/backend khi được cho phép.

## Tỷ lệ hoàn thành

- Hoàn thành: phần độc lập với nguồn dữ liệu — giới hạn prompt và cập nhật tài liệu.
- Đang dở: mục tiêu 3.000 món; chờ dữ liệu licensed từ người dùng.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt — mã và tên luôn được giữ, phép đo khớp JSON UTF-8 serialize, summary co lại theo ngân sách.
- Mức độ hoàn thành task: một phần — prompt được chuẩn bị; chưa có dữ liệu đầu vào để mở rộng catalog.
- Bằng chứng kiểm chứng: formatter và targeted analyzer PASS; không có test, Gemini, backend hoặc device evidence.
- Điểm tốn token/chưa tối ưu: đã nạp context theo router và chỉ mở các file M02 liên quan; lần sau chỉ cần rà license/schema của package được cung cấp.
- Cách tối ưu cho phiên sau: khi nhận package, đối chiếu trực tiếp schema `meal_catalog_v1.json`, license từng ảnh/dữ liệu và nutrition source trước khi import.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`.
