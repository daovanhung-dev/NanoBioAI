Commit de xuat: docs(worklog): ghi nhan loc bang chung lich ca nhan

# Worklog - Cải thiện độ an toàn và độ chính xác lịch cá nhân

## Thời gian

- Ngày: 2026-10-13
- Bắt đầu: thời điểm bắt đầu không được lưu trong trạng thái bàn giao
- Kết thúc: 12:54
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: triển khai kế hoạch đã duyệt.
- Module chính: SQLite v30, tạo lịch AI, lọc món/bài vận động và Edge Function tra cứu bằng chứng thực phẩm.
- Yêu cầu gốc: dùng dữ liệu SQLite và nguồn được duyệt để chọn lịch wellness phù hợp; lọc ràng buộc tại thiết bị; không ghi lịch dở dang.

## Đã làm

- Thêm migration v30, cache bằng chứng thực phẩm và tùy chọn vận động cục bộ; giữ nguyên mã/hash của 163 món và trạng thái dữ liệu thiếu.
- Thêm lọc ứng viên theo bữa, dị ứng, sức khỏe, mục tiêu, nguyên liệu cần tránh, giới hạn cơ thể và dụng cụ. Sửa chuẩn hóa hai slot `morning_snack` và `afternoon_snack` bị loại nhầm.
- Thu gọn prompt món bằng cách gửi từng bản ghi một lần và dùng mảng mã tham chiếu theo slot; giới hạn request thực tế ở 32.000 ký tự. Prompt không gửi hồ sơ cá nhân.
- Thêm Edge Function `nabi-food-evidence`, giới hạn đầu vào tên nguyên liệu, ánh xạ provenance/đơn vị và fallback USDA khi nguồn NIN lỗi hoặc không khớp.
- Bổ sung kiểm tra chặn ghi lịch khi thiếu ứng viên và cập nhật snapshot phiên bản SQLite trong context dự án lên v30.

## File code/docs đã sửa

- `lib/core/storage/localdb/migrations/migration_v30.dart` - thêm schema v30 và trạng thái an toàn mặc định.
- `lib/app_versions/v1/features/meal_plan/domain/services/meal_candidate_selector.dart` - lọc ràng buộc món và chuẩn hóa loại bữa.
- `lib/app_versions/v1/features/lifestyle_schedule/domain/services/exercise_candidate_selector.dart` - lọc bài vận động theo hồ sơ/tùy chọn cục bộ.
- `lib/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart` - gửi tối đa 10 ứng viên mỗi bữa, tránh lặp chi tiết và giữ prompt gọn.
- `lib/app_versions/v1/services/ai/prompts/exercise_tasks_prompt.dart` - giới hạn prompt vào ứng viên và hướng dẫn wellness chung.
- `supabase/functions/nabi-food-evidence/` - tra cứu nguồn được duyệt, fallback NIN sang USDA và kiểm thử.
- `test/` - kiểm tra migration, lọc slot, prompt, lịch khách và lỗi thiếu ứng viên.
- `.codex/AGENTS.md`, `.codex/domains/sqlite.md` - cập nhật phiên bản SQLite hiện hành.
- `docs/features/ai-generated-plan/003-feature-personalized-plan-safety-evidence.md` - ghi nhận kiến trúc và giới hạn.

## Tài liệu liên quan

- `docs/features/ai-generated-plan/001-feature-ai-generated-plan.md`
- `docs/features/ai-generated-plan/002-feature-sqlite-catalog-context.md`
- `docs/features/ai-generated-plan/003-feature-personalized-plan-safety-evidence.md`

## Commands

- `flutter analyze`: PASS - không có lỗi phân tích tĩnh.
- `flutter test` cho model, DAO, migration v27-v30, selector món/bài và `generated_plan_service_auth_test.dart`: PASS - 31 kiểm tra.
- `flutter test test/services/ai/ai_service_test.dart --plain-name 'AI prompts'`: PASS - 7 kiểm tra prompt và giới hạn.
- `flutter test test/services/ai/ai_service_test.dart`: FAIL - 14 kiểm tra hiện hữu về log/API key/retry; nhóm kiểm tra prompt riêng vẫn PASS.
- `deno fmt --check supabase/functions/nabi-food-evidence`: PASS.
- `deno check` và `deno test` cho hai Edge Function: PASS - 20 kiểm tra.
- `deno fmt --check supabase/functions/nabi-ai-generate/handler.ts`: FAIL - file hiện tại dùng dấu nháy đơn; formatter Deno đề nghị chuẩn hóa dấu nháy trên các dòng không thuộc thay đổi giới hạn request.
- Tra cứu trực tiếp NIN cho “gạo tẻ”: PASS - HTTP 200, có 5 bản ghi và cấu trúc trường khớp adapter sau khi bổ sung so khớp bí danh.
- `git diff --check`: PASS.
- `.codex/tools/update_worklog_learning.ps1`: PASS - tạo lại 19 tệp history/task-skill xác định.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL - thiếu `docs/audit/source_truth_manifest.json` và có tham chiếu đường dẫn cũ trong worklog/task-skill khác.
- Hot reload qua DTD: không khả dụng - đã kết nối DTD IDE nhưng không có app Flutter đang chạy/kết nối.

## Lỗi/Rủi ro

- Đã sửa: slot bữa phụ bị loại do so sánh chuỗi có/không có dấu gạch dưới; prompt món lặp chi tiết và vượt giới hạn khi có 10 mã ở mỗi slot; NIN lỗi không chuyển sang USDA.
- Đã xác minh nguồn NIN trực tiếp trả HTTP 200; adapter nhận bí danh trong tên thực phẩm.
- Chưa deploy Supabase Edge Function; chưa xác minh secret `USDA_FDC_API_KEY` hoặc tra cứu trực tiếp trên môi trường triển khai.
- Dữ liệu bệnh/dị ứng hiện tại chưa được rà soát đầy đủ; người có ràng buộc có thể không nhận được lịch cho tới khi metadata được bổ sung.
- Chưa có app Flutter chạy dưới DTD nên không có bằng chứng hot reload/thiết bị.

## Tỷ lệ hoàn thành

- Hoàn thành: thay đổi mã và kiểm tra cục bộ trong phạm vi kế hoạch.
- Đang dở: xác minh môi trường Supabase triển khai và kiểm tra thiết bị; hai việc này không nằm trong quyền triển khai hiện tại.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - kiểm thử phát hiện và sửa lỗi lọc hai bữa phụ, đồng thời xác nhận lỗi nguồn NIN không làm mất fallback USDA.
- Mức độ hoàn thành task: hoàn thành triển khai cục bộ; chưa có bằng chứng runtime/production.
- Bằng chứng kiểm chứng: analyzer sạch; 31 kiểm tra SQLite/model/selector/service, 7 kiểm tra prompt, 20 kiểm tra Deno; 14 kiểm tra không liên quan trong suite AI tổng thể còn lỗi.
- Điểm tốn token/chưa tối ưu: runner Flutter cục bộ cần `LD_LIBRARY_PATH=/tmp/nanoai-ffi` vì môi trường thiếu tên thư viện FFI `libsqlite3.so`.
- Cách tối ưu cho phiên sau: kiểm tra trạng thái DTD và cấu hình secret/server trước khi bắt đầu xác minh live.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`.
