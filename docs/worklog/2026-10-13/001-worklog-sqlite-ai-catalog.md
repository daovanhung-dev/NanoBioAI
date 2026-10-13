Commit đề xuất: feat(ai): dùng catalog SQLite khi tạo lịch cá nhân

# Worklog - Dùng catalog SQLite cho lịch AI

## Thời gian

- Ngày: 2026-10-13
- Bắt đầu: Không ghi nhận chính xác
- Kết thúc: 09:35
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding
- Module chính: M02 PERSONAL_SCHEDULE_AI, SQLite catalog
- Yêu cầu gốc: seed 163 món vào SQLite, dừng refresh catalog từ Supabase, đưa chi tiết món ăn và bài tập vào prompt AI.

## Đã làm

- Tạo migration v29 và seeder dùng asset `meal_catalog_v1.json`; kiểm tra đủ 163 dòng, mã duy nhất, source hash và dữ liệu sau khi ghi.
- Seed catalog khi tạo mới SQLite; giữ transaction của callback tạo/nâng cấp.
- Xóa luồng tải catalog món từ Supabase ở startup, onboarding và dashboard; giữ cloud sync hồ sơ/kế hoạch cá nhân.
- Prompt món ăn gửi tên, loại, nguyên liệu, khẩu phần, dinh dưỡng, chủ đề, nhãn dị ứng/điều kiện và trạng thái dữ liệu của mọi món đang hoạt động.
- Prompt bài tập gửi tên, nhóm, mô tả, đơn vị, cường độ và giới hạn mục tiêu của mọi bài đang hoạt động.
- Bổ sung kiểm tra catalog cục bộ rỗng trước khi gọi AI; đầu ra vẫn xác thực bằng mã và normalizer hiện có.
- Cập nhật feature doc và version SQLite trong context dự án.

## File code/docs đã sửa

- `lib/core/storage/localdb/migrations/migration_v29.dart` - khôi phục catalog món bằng asset ở lần nâng cấp.
- `lib/core/storage/localdb/seeders/meal_catalog_seeder.dart` - seed và kiểm tra số dòng/mã/hash.
- `lib/core/storage/localdb/database_service.dart`, `database_version.dart` - seed cài mới và nâng version lên 29.
- `lib/main.dart`, `lib/app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart` - gỡ refresh catalog từ Supabase.
- `lib/app_versions/v1/services/ai/ai_service.dart`, `generated_plan_service.dart` - chặn catalog thiếu trước khi tạo lịch.
- `lib/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart`, `exercise_tasks_prompt.dart` - gửi chi tiết catalog SQLite vào prompt.
- `test/core/storage/localdb/meal_catalog_local_source_contract_test.dart`, `test/core/storage/localdb/migrations/migration_v29_test.dart`, `test/services/ai/ai_service_test.dart` - kiểm tra seed, prompt và thiếu catalog.
- `docs/features/ai-generated-plan/002-feature-sqlite-catalog-context.md` - mô tả luồng nguồn dữ liệu mới.
- `.codex/AGENTS.md`, `.codex/domains/sqlite.md` - cập nhật version SQLite 29.

## Commands

- `dart format <15 touched Dart paths>`: PASS - 6 file cần format.
- `dart format --set-exit-if-changed <15 touched Dart paths>`: PASS - không còn file cần format.
- `flutter analyze <13 touched source/test paths>`: PASS - không có issue.
- `flutter test test/services/ai/ai_service_test.dart --plain-name 'AI prompts'`: PASS - 3 tests.
- `flutter test test/services/ai/ai_service_test.dart --plain-name 'missing meal catalog fails before making an AI request'`: PASS.
- `flutter test test/services/ai/ai_service_test.dart --plain-name 'meal generation requests seven days in one chunk'`: PASS.
- `flutter test test/services/ai/ai_service_test.dart --plain-name 'exercise generation returns fourteen catalog-mapped tasks'`: PASS.
- `LD_LIBRARY_PATH=/tmp/nanobio-sqlite-lib flutter test test/core/storage/localdb/migrations/migration_v29_test.dart`: PASS. Liên kết tạm trỏ `libsqlite3.so` tới thư viện hệ thống có version.
- `flutter test test/core/storage/localdb/meal_catalog_local_source_contract_test.dart`: PASS - 2 tests.
- `LD_LIBRARY_PATH=/tmp/nanobio-sqlite-lib flutter test test/core/storage/localdb`: FAIL - một test ngoài thay đổi, `migration_v17_test`, kỳ vọng 40 meal rows nhưng nhận 0; các test còn lại, gồm migration v29, pass.
- `flutter test test/services/ai/ai_service_test.dart`: FAIL - các lỗi khác ở thông điệp lỗi, capture log, chat fallback/candidate expectations; test prompt mới và guard catalog rỗng pass khi chạy riêng.
- `git diff --check`: PASS.
- Dart hot reload/restart: SKIPPED - DTD đã kết nối nhưng hiện không có app Flutter nào chạy.
- `git diff --check`: chưa chạy tại thời điểm ghi worklog.

## Lỗi/Rủi ro

- Đã xử lý: test SQLite FFI ban đầu không tìm thấy tên thư viện `libsqlite3.so`; dùng symlink tạm trong `/tmp` tới `libsqlite3.so.0` để chạy test migration.
- Chưa fix: `migration_v17_test` có kỳ vọng cũ 40 món ở migration v17; không sửa logic migration đã phát hành ngoài phạm vi.
- Chưa fix: các lỗi trong suite AI nêu trên không liên quan tới prompt catalog theo phạm vi test riêng.
- Cần kiểm tra tiếp: device/runtime acceptance; nội dung dinh dưỡng ước tính và nhãn chưa rà soát vẫn không bảo đảm phù hợp y khoa.

## Tỷ lệ hoàn thành

- Hoàn thành: triển khai migration, prompt và gỡ runtime fetch; kiểm tra tập trung đã pass.
- Đang đo: chưa có device/runtime acceptance; test suites rộng còn lỗi ngoài phạm vi.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - giữ mã đầu ra và normalizer hiện có, chỉ mở rộng context catalog và chuyển nguồn seed.
- Mức độ hoàn thành task: triển khai xong trong phạm vi đã chốt.
- Bằng chứng kiểm chứng: migration v29, prompt, empty catalog guard, generation tests và targeted analyzer pass.
- Điểm tốn token/chưa tối ưu: lần chạy test toàn bộ ban đầu bị cản bởi tên thư viện SQLite FFI trong môi trường.
- Cách tối ưu cho phiên sau: chạy targeted FFI test với symlink tạm trước khi quét cả thư mục.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`.
