Commit de xuat: feat(ai): gui catalog 3000 mon wellness cho AI

# Worklog - Tích hợp 3.000 món cho lịch AI wellness

## Thời gian

- Ngày: 2026-10-16
- Timezone: Asia/Ho_Chi_Minh
- Tiếp tục từ worklog `008-worklog-onboarding-schedule-candidate-pool-fix.md`.

## Phạm vi

- Loại task: coding, migration, focused tests, docs/context.
- Module: M02 `PERSONAL_SCHEDULE_AI`, SQLite meal catalog.
- Yêu cầu: theo chỉ thị mới của người dùng, cho AI nhận đủ mã/tên của 3.000 món workspace trong luồng lịch wellness; giữ nguyên 163 món cũ và JSON nguồn.
- Không gọi Gemini thật, không dùng hồ sơ sức khỏe thật, không deploy Edge Function hoặc thao tác dữ liệu production.

## Đã làm

- Đóng gói `assets/data/nabi_3000_mon_viet_moi.json` như Flutter asset; không sửa JSON nguồn. Catalog cài mới có 3.163 món và SQLite v36 nâng từ v35 theo kiểu insert-only, giữ hàng cũ/dữ liệu người dùng, xác minh hash candidate.
- Candidate giữ nguyên `is_active=true` từ nguồn nhưng `is_plan_eligible=false`, `unclassified`, `estimated_unverified`, `awaiting_professional_review`, `ai_generated_needs_review`; `is_active` không được dùng làm bằng chứng eligibility.
- Thêm policy `wellnessSchedule` riêng cho luồng tạo lịch. Prompt gửi đủ cặp `{code,name}` được selector cho phép; không gửi recipe, nguyên liệu, bước nấu hoặc dinh dưỡng candidate. Normalizer, fallback và final validation nhận cùng map eligible theo loại bữa; chi tiết được hydrate từ SQLite.
- Allergy metadata chưa xác minh, allergy không hỗ trợ/phân tích được và món người dùng yêu cầu tránh tiếp tục fail-closed. Nutrition chưa xác minh không được đưa vào snapshot hoặc hiển thị như giá trị đã biết. Policy strict vẫn chặn candidate.
- Nâng prompt staging version thành `personal_schedule_v12_unreviewed_wellness_candidates` để lượt tạo dở theo phiên bản catalog cũ không bị resume lẫn.
- Cập nhật feature doc, biên bản catalog, fixbug handoff, M02 checklists và worklog/history; không đổi Edge Function.

## Kiểm chứng

- `LD_LIBRARY_PATH=/tmp/nanobioai-sqlite-ffi flutter test test/core/storage/localdb/migrations/migration_v36_test.dart test/core/storage/localdb/migrations/migration_v29_test.dart test/core/storage/localdb/ai_catalog_schedule_bundle_test.dart test/core/storage/localdb/meal_catalog_local_source_contract_test.dart`: PASS, 6 tests. Bao gồm seed 3.163 món, upgrade v35, bảo toàn hàng/dữ liệu, hash và idempotency.
- `LD_LIBRARY_PATH=/tmp/nanobioai-sqlite-ffi flutter test test/app_versions/v1/features/meal_plan/meal_candidate_selector_test.dart test/app_versions/v1/features/meal_plan/presentation/utils/meal_detail_content_formatter_test.dart test/app_versions/v1/features/meal_plan/presentation/utils/meal_catalog_candidate_asset_gate_test.dart test/features/meal_plan/data/meal_plan_ai_normalizer_test.dart test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart`: PASS, 46 tests. Bao gồm toàn bộ 3.000 candidate, allergy fail-closed, hydrate và lịch tổng hợp commit thành công.
- `LD_LIBRARY_PATH=/tmp/nanobioai-sqlite-ffi flutter test test/services/ai/ai_service_test.dart --plain-name 'local fallback can use only explicitly eligible wellness candidates'`: PASS.
- `LD_LIBRARY_PATH=/tmp/nanobioai-sqlite-ffi flutter test test/services/ai/ai_service_test.dart --plain-name 'meal prompt excludes unreviewed candidates without schedule eligibility'`: PASS.
- `flutter build bundle --no-pub`: PASS. `build/flutter_assets/assets/data/nabi_3000_mon_viet_moi.json` khớp từng byte với nguồn; SHA-256 `7b861bb6bf777734660f8f578899d4a87915735e3f823a2b6d1b7d40cb4ece7d`.
- Kích thước nguồn JSON: 8.084.717 byte; serialization compact gồm 3.000 cặp candidate code/name: 321.212 byte UTF-8. Đây không phải số token/chi phí Gemini. Flutter asset bundle là 196 MB; chưa đo APK.
- `dart format --set-exit-if-changed` trên 25 file Dart liên quan: PASS sau khi format một test asset mới.
- `flutter analyze` trên 25 file Dart liên quan: PASS, không có vấn đề.
- `git diff --check`: PASS.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL on pre-existing repository issues: missing `docs/audit/source_truth_manifest.json` and stale backticked paths in generated history/task-skill entries; no path from this worklog was reported.

## Giới hạn và việc còn lại

- Người dùng đã chỉ thị gửi code/name candidate trong policy wellness; điều này không xác nhận quyền lưu trữ/phân phối, license recipe hoặc độ chính xác của công thức/dinh dưỡng.
- Không tuyên bố candidate đã được kiểm chứng chuyên môn/y khoa. Mọi trạng thái review từ nguồn vẫn giữ nguyên; không cho candidate vào policy strict.
- Chưa gọi Gemini thật, chưa chạy QA thiết bị, chưa kiểm tra quota/Supabase sandbox và chưa build APK. Kết quả chỉ chứng minh source, SQLite, test giả lập và Flutter asset bundle tại workspace.
- Việc review rights/provenance và dữ liệu cần thiết trước khi candidate được xem là đã xác minh hoặc dùng ngoài lịch wellness tổng quát vẫn còn mở.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: luồng truyền đủ mã/tên, hydrate chi tiết cục bộ và giữ các rào chắn allergy/nutrition có bằng chứng kiểm thử tập trung.
- Mức độ hoàn thành: yêu cầu tích hợp candidate vào runtime wellness và prompt đã hoàn tất ở source; external/device acceptance chưa thực hiện.
- Bằng chứng kiểm chứng: 54 focused tests qua 3 lượt chạy; analyzer, format, diff và asset bundle PASS.
- Hạn chế: chưa đo APK size và không có bằng chứng từ Gemini thật, thiết bị hoặc backend quota.
- Cách tối ưu phiên sau: nếu cần acceptance runtime, dùng sandbox và profile tổng hợp; tách kiểm tra token thực tế khỏi phép đo UTF-8 cục bộ.
- Task-skill dùng lần sau: `.codex/task-skills/coding.md`.
