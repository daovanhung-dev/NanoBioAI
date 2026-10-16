Commit de xuat: feat(meal-catalog): chuan bi tiep nhan bo du lieu 3000 mon

# Worklog - Chuẩn bị tiếp nhận catalog món 3.000 dòng

## Thời gian

- Ngày: 2026-10-16
- Bắt đầu: khoảng 08:51
- Kết thúc: 09:05
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding
- Module chính: M02 `PERSONAL_SCHEDULE_AI`, meal catalog/image assets.
- Yêu cầu gốc: Tiến tới catalog ít nhất 3.000 món có công thức, định lượng dinh dưỡng, ảnh và provenance/license.

## Đã làm

- Rà `assets/data/meal_catalog_v1.json`: hiện có 163 mã món duy nhất; 20 nhóm tên bị lặp; 163/163 có tên, mô tả, nguyên liệu và bước nấu; loại bữa đều `unclassified`; khẩu phần và sáu trường dinh dưỡng cơ bản trống; 0 dòng đủ điều kiện lập kế hoạch.
- Rà ảnh hiện có: 124 file ảnh khớp theo slug tên món cho cả 163 dòng. JSON không có cột ảnh, nên các món cùng tên dùng chung ảnh.
- Thêm intake note với cấu trúc gói catalog, bảng rights/provenance, quy ước ảnh theo mã và lệnh kiểm tra. Bộ dữ liệu gốc không bị sửa.
- Thêm `tools/validate_meal_catalog_bundle.py`: kiểm tra tối thiểu 3.000 dòng, giữ đủ mã hiện tại, code duy nhất/an toàn, schema/loại bữa, ingredient/steps/khẩu phần, nutrients số không âm, provenance recipe/ảnh/nutrition, file license và một ảnh code-keyed đúng chữ ký cho mỗi món.
- Nâng resolver ảnh để ưu tiên asset theo mã trong `assets/images/meals/catalog_v1/`, đọc Flutter asset manifest để chỉ dùng file thật có trong bundle, rồi fallback về ảnh tên món hiện có.
- Ghi nhận import sau khi được duyệt cần migration SQLite mới từ v35: seeder hiện và migration v35 còn kỳ vọng 163; không sửa lịch sử migration khi chưa có bộ dữ liệu để xác định chính sách merge.

## File code/docs đã sửa

- `tools/validate_meal_catalog_bundle.py` - thêm kiểm tra gói dữ liệu 3.000 món, rights, nutrition provenance và ảnh theo code.
- `docs/meal_catalog/3000_recipe_dataset_intake.md` - ghi nhận audit hiện trạng và hợp đồng tiếp nhận dữ liệu.
- `docs/checklist/checklist_complete_DD.md`, `docs/checklist/checklist_task_coding.md` - đồng bộ số liệu catalog, migration blocker và bước tiếp theo.
- `lib/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver.dart` - tìm ảnh đúng mã từ AssetManifest, giữ fallback ảnh catalog cũ.
- `lib/app_versions/v1/features/meal_plan/presentation/widgets/meal_photo.dart` - hiển thị asset code-keyed khi có, fallback qua ảnh tên món.
- `pubspec.yaml` - đăng ký thư mục asset ảnh cho catalog mới.
- `assets/images/meals/catalog_v1/.gitkeep` - giữ thư mục ảnh code-keyed trong source.

## Tài liệu liên quan

- `.codex/AGENTS.md`
- `.codex/PROJECT_MAP.md`
- `.codex/workflows/coding.md`
- `.codex/task-skills/coding.md`
- `.codex/domains/ai-service.md`
- `assets/data/meal_catalog_v1.json`
- `lib/core/storage/localdb/seeders/meal_catalog_seeder.dart`
- `lib/core/storage/localdb/migrations/migration_v35.dart`

## Commands

- `dart format` trên 4 file Dart liên quan: PASS, không còn thay đổi format.
- `flutter analyze` trên 4 file Dart liên quan: PASS, không có issue.
- Python `ast.parse` cho `tools/validate_meal_catalog_bundle.py`: PASS.
- `python3 tools/validate_meal_catalog_bundle.py --help`: PASS.
- `git diff --check`: PASS.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL do thiếu `docs/audit/source_truth_manifest.json` và các stale path trong `.codex/history/WORKLOG_2026-08-16_meal_nutrition_estimation.md`, `.codex/task-skills/nabi-character/SKILL.md`.
- `.codex/tools/update_worklog_learning.ps1`: PASS, cập nhật 19 file history/task-skill sinh tự động.
- `flutter test`: SKIPPED — phiên này không yêu cầu chạy test.
- Dart Tooling Daemon: không có app đang chạy để hot reload/restart.

## Lỗi/Rủi ro

- Đã fix: ảnh catalog mới có thể gắn chính xác theo mã; không cần mở rộng thủ công whitelist tên cho mỗi món mới.
- Chưa fix: chưa có file dữ liệu licensed, rights CSV, license evidence hoặc 2.837 món bổ sung. Không có bằng chứng để xét chính xác dinh dưỡng, license phân phối lại hay trạng thái an toàn.
- Cần kiểm tra tiếp: khi nhận gói, rà license/phạm vi sử dụng; chạy validator; cập nhật asset JSON và migration v36 theo cơ chế merge không xóa các trạng thái local; xác minh AI payload/token, import SQLite, ảnh và lịch tổng hợp.

## Tỷ lệ hoàn thành

- Hoàn thành: intake contract, validator và hỗ trợ asset ảnh theo code.
- Đang dở: mục tiêu 3.000 món; chờ dữ liệu licensed để nhập và xác minh.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt — phát hiện các điểm chặn ở dữ liệu, asset ảnh, seeder và migration trước khi nhập một bộ lớn.
- Mức độ hoàn thành task: một phần — hệ thống có thể tiếp nhận/kiểm tra gói theo quy ước; chưa có recipe rows mới.
- Bằng chứng kiểm chứng: targeted analyzer/format, Python syntax, CLI help. Không có test, ảnh người dùng, Gemini, SQLite migration hoặc device evidence.
- Điểm tốn token/chưa tối ưu: đã dùng đọc schema và truy vết đúng loader/seeder/image path; chưa cần đọc toàn bộ history hoặc chạy full suite.
- Cách tối ưu cho phiên sau: bắt đầu từ gói dữ liệu thực, kiểm license trước, rồi tạo migration trên đầy đủ source thay vì đoán mapping.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`.
