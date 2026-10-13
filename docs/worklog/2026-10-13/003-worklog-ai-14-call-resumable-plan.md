Commit de xuat: docs(worklog): ghi nhan lich AI 14 luot co the tiep tuc

# Worklog - Lịch AI 14 lượt có thể tiếp tục

## Thời gian

- Ngày: 2026-10-13
- Bắt đầu: không được lưu chính xác trong trạng thái phiên
- Kết thúc: 14:17
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: triển khai kế hoạch đã duyệt.
- Module chính: M02 tạo lịch cá nhân, SQLite v31, prompt món ăn và vận động.
- Yêu cầu gốc: chia lịch 7 ngày thành 14 lượt AI tuần tự; lưu phần đã xác thực để tiếp tục sau gián đoạn; chỉ ghi lịch chính khi hoàn tất.

## Đã làm

- Kết nối `GeneratedPlanService` với 14 lượt tuần tự: mỗi ngày tạo đúng 5 bữa rồi 2 hoạt động. AI chỉ trả mã/ngày/loại bữa; chuẩn hóa và nạp chi tiết từ catalog SQLite.
- Gửi tóm tắt gọn các bản ghi hoạt động đã qua bộ lọc cục bộ; giữ hồ sơ sức khỏe và định danh ngoài prompt. Kiểm tra giới hạn 32.000 ký tự cho prompt và payload backend.
- Thêm SQLite staging gắn với request, dấu vân tay đầu vào/catalog và phiên bản prompt; tiếp tục phần còn thiếu khi dấu vân tay khớp, bỏ staging khi dữ liệu nguồn thay đổi.
- Dừng và giữ staging khi gặp HTTP 429 hoặc quá 18 lần gọi trong một phiên. Kiểm tra quota một lần ở cấp kế hoạch; ghi 35 bữa, 14 hoạt động và trạng thái thành công trong một transaction khi đủ dữ liệu.
- Nối migration v31, metadata nguồn/rà soát bài tập và seeder 24 mã M32 ở trạng thái inactive/pending review; giữ 16 bài M02 hiện hành và không thay dữ liệu nguồn 163 món.
- Cập nhật tài liệu tính năng, checklist M02, snapshot SQLite v31 và worklog.

## File code/docs đã sửa

- `lib/app_versions/v1/services/ai/generated_plan_service.dart` - chạy lịch theo ngày, xác thực/chuẩn hóa và lưu các phần staging.
- `lib/app_versions/v1/services/ai/generated_plan_request_store.dart` - lưu staging, giới hạn phiên gọi và commit SQLite nguyên tử.
- `lib/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart`, `lib/app_versions/v1/services/ai/prompts/exercise_tasks_prompt.dart` - prompt catalog tóm tắt, đầu ra mã tối giản, kiểm tra giới hạn.
- `lib/core/storage/localdb/migrations/migration_v31.dart`, `lib/core/storage/localdb/seeders/fitness_exercise_sqlite_seeder.dart` - migration v31 và nhập bài tập M32 chưa duyệt.
- `test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart`, `test/app_versions/v1/services/ai/generated_plan_request_store_test.dart`, `test/services/ai/ai_service_test.dart`, kiểm thử migration/catalog/selector - bao phủ tạo theo ngày, giới hạn prompt, resume, migration và lọc.
- `.codex/AGENTS.md`, `.codex/domains/sqlite.md` - cập nhật phiên bản SQLite hiện hành.
- `docs/features/ai-generated-plan/004-feature-ai-14-call-resumable-plan.md` - mô tả luồng, trạng thái catalog và giới hạn xác minh.
- `docs/checklist/checklist_complete_DD.md`, `docs/checklist/checklist_task_coding.md` - cập nhật trạng thái/bằng chứng M02.

## Tài liệu liên quan

- `docs/features/ai-generated-plan/002-feature-sqlite-catalog-context.md`
- `docs/features/ai-generated-plan/003-feature-personalized-plan-safety-evidence.md`
- `docs/features/ai-generated-plan/004-feature-ai-14-call-resumable-plan.md`

## Commands

- `flutter analyze <49 Dart path còn tồn tại trong phạm vi thay đổi>`: PASS - 49 mục, không có issue.
- `flutter test test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart`: PASS - 16 kiểm thử, gồm luồng 14 lượt, resume sau 429 và 35/14 kết quả.
- `env LD_LIBRARY_PATH=/tmp/nanoai-ffi flutter test test/app_versions/v1/services/ai/generated_plan_request_store_test.dart`: PASS - SQLite in-memory xác nhận staging, giới hạn 18 lần gọi và vô hiệu hóa khi fingerprint đổi. Lượt đầu không có biến thư viện này nên FFI không nạp được `libsqlite3.so`; chạy lại với biến môi trường thì đạt.
- `flutter test test/services/ai/ai_service_test.dart --plain-name 'AI prompts'`: PASS - 8 kiểm thử; prompt asset thật đủ 163 món nằm dưới 32.000 ký tự.
- `flutter test test/services/ai/ai_service_test.dart --plain-name 'day API'`: PASS - 3 kiểm thử API tạo lịch theo ngày.
- `env LD_LIBRARY_PATH=/tmp/nanoai-ffi flutter test test/core/storage/localdb/migrations/migration_v27_test.dart test/core/storage/localdb/migrations/migration_v28_test.dart test/core/storage/localdb/migrations/migration_v29_test.dart test/core/storage/localdb/migrations/migration_v30_test.dart test/core/storage/localdb/migrations/migration_v31_test.dart`: PASS - 6 kiểm thử, chuỗi migration thực tế chạy đến v31.
- `env LD_LIBRARY_PATH=/tmp/nanoai-ffi flutter test test/app_versions/v1/features/meal_plan/meal_candidate_selector_test.dart test/app_versions/v1/features/lifestyle_schedule test/core/storage/localdb/ai_catalog_models_test.dart test/core/storage/localdb/meal_catalog_local_source_contract_test.dart test/core/storage/localdb/food_evidence_dao_test.dart`: PASS - 15 kiểm thử selector, catalog, local source và evidence DAO.
- `flutter test test/services/ai/ai_service_test.dart`: FAIL - 14 kiểm thử về log/API key, chuẩn hóa và phân loại lỗi AI Chat; nhóm prompt và API theo ngày nêu trên PASS.
- `dart format --set-exit-if-changed <49 Dart path còn tồn tại trong phạm vi thay đổi>`: PASS - 49 file, không còn file cần format. Lần đầu danh sách Git còn có 3 file đã xóa; lần chạy cuối chỉ truyền file còn tồn tại.
- `git diff --check`: PASS.
- `/home/daovanhung/.local/bin/pwsh -NoProfile -File .codex/tools/update_worklog_learning.ps1`: PASS - cập nhật 19 file history/task-skill xác định.
- `/home/daovanhung/.local/bin/pwsh -NoProfile -File .codex/tools/validate_codex_integrity.ps1`: FAIL - thiếu `docs/audit/source_truth_manifest.json` và có tham chiếu cũ trong worklog/task-skill liên quan Nabi; đây là lỗi ngoài file của task.
- DTD/hot reload: đã tìm và kết nối DTD của VS Code nhưng không có app Flutter đang chạy/kết nối; vì vậy không thể hot reload/restart hoặc xác nhận trên thiết bị.

## Lỗi/Rủi ro

- Đã sửa: vòng merge staging thiếu tăng chỉ số ngày; test 7 ngày bắt được loop sai và luồng đã được kiểm tra lại.
- Chưa sửa: suite AIService tổng thể hiện fail 14 kiểm thử liên quan logging/API key/AI Chat; các nhóm prompt catalog và API theo ngày đều pass.
- Chưa xác minh: gọi Gemini thật, Supabase sandbox/deploy, quota backend live, khởi động lại trên thiết bị và hoàn tất lịch ngoài SQLite in-memory.
- Catalog món hiện có nhiều trường chưa xác minh; bộ lọc vẫn dừng fail-closed khi một ràng buộc người dùng cần dữ liệu mà catalog chưa có.
- 24 bài tập M32 vẫn pending review/inactive; không được chọn cho đến khi hoàn tất rà soát.

## Tỷ lệ hoàn thành

- Hoàn thành: triển khai cục bộ và kiểm thử tập trung cho 14 lượt, staging/tiếp tục, prompt, migration và selector.
- Đang dở: xác minh Gemini trực tiếp, Supabase sandbox/deploy, quota backend live và tạo lịch trên thiết bị; DTD không có app đang chạy để hot reload.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - luồng tạo một ngày/lượt được kiểm tra với asset thật và staging SQLite; không suy ra AI hiểu tuyệt đối catalog.
- Mức độ hoàn thành task: triển khai mã, tài liệu và kiểm tra cục bộ đã hoàn tất; live/device acceptance chưa có.
- Bằng chứng kiểm chứng: 49 kiểm tra tập trung pass, analyzer 49 mục sạch, formatter và diff check pass; suite AIService tổng thể còn 14 lỗi legacy; chưa có live/device acceptance.
- Điểm tốn token/chưa tối ưu: suite AIService tổng thể chứa log/chat cases ngoài luồng tạo lịch; nhóm test theo tên giúp cô lập bằng chứng có liên quan.
- Cách tối ưu cho phiên sau: bắt đầu từ worklog này và chỉ làm live/device acceptance còn thiếu; không lặp lại suite đã có kết quả PASS trừ khi mã đổi.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`.
