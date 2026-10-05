Commit de xuat: docs(m32): tao BD DD va catalog draft che do luyen tap

# Worklog — M32 Chế độ luyện tập

## Thời gian

- Ngày: 2026-10-01
- Bắt đầu: khoảng 15:45
- Kết thúc: khoảng 16:30
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: feature/business design/catalog preparation
- Module chính: M32 FITNESS_TRAINING
- Yêu cầu gốc: thêm chế độ Gym-first tại FeatureHub, tạo chương trình 4 tuần, dùng Gemini backend, chuẩn bị catalog nguồn trước AI và giữ an toàn bản quyền.

## Đã làm

- Tạo BD M32 và DD module ở trạng thái Draft. Người dùng tự xác nhận vai trò PO và duyệt BD/DD v1.0 vào 2026-10-01; đã ghi nhận xác nhận trong bảng sign-off. Tech/QA/Clinical-Privacy vẫn Pending vì chưa có tên/ngày hoặc bằng chứng kiểm tra được.
- Định nghĩa quota M02, intake, adult gate, local M04 metrics, 28-day program, lịch 7 ngày, preview/confirm, weekly check-in và các ràng buộc AI/catalog.
- Tạo bộ candidate data chưa dùng trong runtime: 24 bài tập (16 Gym/8 home), 10 thiết bị, 35 recipe và 47 ingredient records.
- Ingredient records giữ FDC ID, tiếng Anh nguồn, dữ liệu dinh dưỡng theo 100 g và allergen tags. Recipe macro được tính số học từ ingredient records; có cảnh báo cần dietitian/clinical review.
- Tải bản FNDDS 2021-2023 tháng 10/2024 từ USDA FoodData Central; không dùng API key. Tạo 9 atlas ảnh gốc bằng imagegen, gồm 69 ô bài tập/thiết bị/món ăn và 4 icon nhóm thực phẩm; gắn từng ô về ID catalog. Ghi hai video ứng viên tìm qua Chrome; player error 153 nên không duyệt làm nguồn runtime.
- Cập nhật DD/checklist/source map và tạo feature handoff. Không sửa runtime, route, pubspec, Gemini operation, quota, schema hoặc schedule.

## Tệp code/docs đã sửa

- docs/BD/fitness_training/BD_NanoBio_Fitness_Training_M32_v1.0.md — tạo BD Draft và approval matrix.
- docs/DD/fitness_training/ — tạo DD, sơ đồ, candidate catalogs, image atlas, atlas-to-ID manifest và asset manifest.
- docs/features/fitness-training/001-feature-fitness-training.md — tạo feature handoff.
- docs/DD/README.md, docs/checklist/checklist_create_DD.md, checklist_complete_DD.md, checklist_task_coding.md, .codex/MAP_TREE.md — đăng ký M32 Draft và runtime gate.
- docs/worklog/2026-10-01/001-worklog-fitness-training-m32.md — ghi nhận phiên.

## Tài liệu liên quan

- docs/DD/personal_schedule_ai/ — quota/idempotency và lịch M02.
- docs/DD/basic_health_calculators/ — BMI/BMR/TDEE M04.
- docs/DD/onboarding_profile/ — nguồn hồ sơ M01.
- docs/DD/sleep_safety_monitoring/ — trạng thái M31.
- .codex/design/15_CODING_PLAN.md — phê duyệt bắt buộc trước hành vi module mới.
- USDA FoodData Central download/API guide, YouTube IFrame API và API Terms.

## Commands

- Catalog integrity check — PASS after atlas mapping; 47 unique FDC ingredients, 10 equipment, 24 exercises (16 gym/8 home), 35 recipes (7 per meal slot), all recipe refs and 69 art cells + 4 group icons resolve to matching IDs and existing PNGs.
- JSON/document check — PASS; 17 Markdown/diagram/JSON files have valid JSON and final newlines.
- git diff --check — PASS.
- pwsh -NoProfile -File .codex/tools/update_worklog_learning.ps1 — PASS; refreshed 19 deterministic history/task-skill files.
- pwsh -NoProfile -File .codex/tools/validate_codex_integrity.ps1 — FAIL on repository-wide findings outside M32: missing docs/audit/source_truth_manifest.json and stale backticked paths in existing generated worklog/task-skill files.
- Flutter tests/analyze — SKIPPED; no runtime source changed.
- Supabase sandbox/device/player smoke — SKIPPED; runtime gate remains closed.

## Lỗi/Rủi ro

- Đã fix: chỉ ghi PO Approved theo xác nhận rõ trong hội thoại, kèm việc tên hiển thị không được cung cấp; không suy diễn các approval khác. M32 vẫn Draft/Absent.
- Chưa fix: M32-Q01 adult-proof trust/retention; M32-Q02 clinical movement/nutrition screening; M32-Q03 member/FamilyPlus cloud schema/RLS/consent/deletion; M32-Q04 player/platform and QA matrix.
- Chưa hoàn tất: review dinh dưỡng/vận động, video embed review, QA platform matrix và cross-functional approvals.
- Cần kiểm tra tiếp: Tech/QA/Clinical-Privacy chốt M32-Q01–Q04; sau khi sign-off được ghi nhận mới bắt đầu code runtime và Supabase contract.

## Tỷ lệ hoàn thành

- Hoàn thành: BD/DD draft, candidate data and nutrient provenance, 9 atlas image files with per-record cells, Chrome video candidates, art-direction sample and approval gate.
- Đang dở: sign-off, recipe/movement/nutrition review, video embed review and all runtime feature work.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt cho vòng review vì status Draft, original art and atlas-to-ID provenance được ghi rõ; candidate recipes chưa phải khuyến nghị dinh dưỡng.
- Mức độ hoàn thành task: phần tài liệu/catalog chuẩn bị hoàn tất; runtime bị chặn bởi sign-off bắt buộc.
- Bằng chứng kiểm chứng: catalog counts/reference check PASS; new-doc whitespace check PASS; git diff --check PASS; integrity validator reported unrelated repository-wide findings above.
- Điểm tốn token/chưa tối ưu: đọc một phần template bị dài; lần sau dùng DD guide cùng các template cần thiết theo từng mục.
- Cách tối ưu cho phiên sau: sau sign-off, triển khai theo DD layer order; batch curate ảnh theo asset inventory và kiểm tra từng YouTube embed.
- Task-skill cần đọc lần sau: .codex/task-skills/coding.md
