Commit de xuat: docs(worklog): ghi nhan khong lap mon trong tuan

# Worklog - Không lặp món trong lịch một tuần

## Thời gian

- Ngày: 2026-10-13
- Bắt đầu: khoảng 21:35
- Kết thúc: 22:03
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding
- Module chính: M02 `PERSONAL_SCHEDULE_AI`
- Yêu cầu gốc: Mọi món trong lịch ăn tuần phải khác nhau; không thể đổi mã catalog để lặp lại cùng tên món.

## Đã làm

- Duy trì kiểm tra duy nhất xuyên tuần trong normalizer theo `meal_code` và tên món đã chuẩn hóa; từ chối tên catalog rỗng.
- Cập nhật prompt để gửi tên món đã dùng cùng mã đã dùng và cấm lặp cả hai.
- Siết local fallback cả ngày để loại mã/tên đã dùng trong tuần và tránh trùng giữa các slot.
- Giữ fallback từng bữa theo kiểm tra của normalizer; fallback thử tiếp ứng viên khi mã/tên đã xuất hiện.
- Tăng staging prompt version để request dở theo quy tắc cũ không được tái sử dụng.
- Ánh xạ lỗi thiếu ứng viên duy nhất và lỗi lặp mã/tên thành mã chẩn đoán rõ ràng.
- Đồng bộ assertion/fixture kiểm thử hiện có với quy tắc mới; không thêm test case mới.
- Ghi feature note và cập nhật M02 handoff.

## File code/docs đã sửa

- `lib/app_versions/v1/features/meal_plan/data/models/meal_plan_ai_normalizer.dart` - xác thực tên catalog không rỗng và từ chối mã/tên đã dùng trong tuần.
- `lib/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart` - gửi tên món đã dùng và hướng dẫn model tránh trùng.
- `lib/app_versions/v1/services/ai/ai_service.dart` - fallback cả ngày chỉ chọn mã/tên chưa dùng.
- `lib/app_versions/v1/services/ai/generated_plan_service.dart` - đổi staging version và ánh xạ lỗi chính sách mới.
- `test/features/meal_plan/data/meal_plan_ai_normalizer_test.dart` - cập nhật kỳ vọng không cho phép mã đã dùng.
- `test/app_versions/v1/services/ai/prompts/meal_plan_prompt_test.dart` - cập nhật kiểm tra copy prompt.
- `test/services/ai/ai_service_test.dart` - cập nhật kỳ vọng fail closed khi catalog eligible không còn món mới.
- `test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart` - fixture có đủ 7 lựa chọn cho mỗi slot.
- `test/app_versions/v1/features/meal_plan/meal_plan_unclassified_catalog_test.dart` - kiểm tra fallback qua API hiện hành và bỏ output fields cũ.
- `docs/features/ai-generated-plan/008-feature-weekly-meal-uniqueness.md` - mô tả quy tắc và ranh giới.
- `docs/checklist/checklist_complete_DD.md` - cập nhật bằng chứng M02.
- `docs/checklist/checklist_task_coding.md` - ghi handoff và kiểm tra QA còn lại.
- `.codex/history/` và generated task-skills - refresh bằng worklog learning script.

## Tài liệu liên quan

- `docs/features/ai-generated-plan/008-feature-weekly-meal-uniqueness.md`
- `docs/checklist/checklist_complete_DD.md`
- `docs/checklist/checklist_task_coding.md`

## Commands

- `dart format --set-exit-if-changed <9 file Dart trong phạm vi>`: PASS.
- `analyze_files` cho 4 file nguồn M02: PASS, `No errors`.
- `hot_reload` qua DTD trên app `nano_app`: PASS; không mở luồng tạo lịch.
- `.codex/tools/update_worklog_learning.ps1`: PASS; refreshed 19 deterministic history/task-skill files.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL do thiếu `docs/audit/source_truth_manifest.json` và stale path trong `.codex/history/WORKLOG_2026-08-16_meal_nutrition_estimation.md`/`.codex/task-skills/nabi-character/SKILL.md`; validator không báo lỗi ở tài liệu mới.
- `git diff --check`: PASS.
- `flutter test`: SKIPPED; không chạy suite trong phiên này.
- Fresh device QA, Gemini thật, Supabase sandbox: SKIPPED; hot reload chỉ xác nhận app nạp code, không request tạo lịch.

## Lỗi/Rủi ro

- Đã fix: model hoặc local fallback không được phép lặp món chỉ vì catalog gán mã khác.
- Chưa fix: luồng thay món thủ công chưa được ràng buộc với tập tên/mã đã có của tuần.
- Cần kiểm tra tiếp: QA tạo lịch 7 ngày trên thiết bị với hồ sơ tổng hợp để xác nhận 35 tên món khác nhau; xác nhận lỗi/tiếp tục khi danh sách đủ điều kiện không có đủ món khác nhau.

## Tỷ lệ hoàn thành

- Hoàn thành: source contract, prompt, fallback và staging policy.
- Đang đo: test/device/provider acceptance.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - validator và fallback cùng fail closed theo mã và tên món.
- Mức độ hoàn thành task: source implementation hoàn tất; runtime/provider acceptance còn chờ.
- Bằng chứng kiểm chứng: format, targeted analyzer và hot reload PASS; test suite và live generation chưa chạy.
- Điểm tốn token/chưa tối ưu: worktree có nhiều file bẩn; chỉ rà và sửa các đường liên quan M02.
- Cách tối ưu cho phiên sau: chạy các test prompt/normalizer/fallback/generated-plan đã sửa rồi tạo request QA tổng hợp một lần.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`.
