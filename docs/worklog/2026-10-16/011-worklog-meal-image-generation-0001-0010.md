Commit de xuat: docs(worklog): ghi nhan lo anh mon Viet 0001-0010

# Worklog - Tạo và tích hợp ảnh món Việt 0001-0010

## Thời gian

- Ngày: 2026-10-16
- Bắt đầu: khoảng 13:40
- Kết thúc: 13:49
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: Tạo ảnh, tích hợp UI, kiểm tra và ghi nhận tiến độ.
- Module chính: `meal_plan` và catalog `nabi_3000_mon_viet_moi.json`.
- Yêu cầu gốc: Tạo ảnh riêng, photorealistic, đúng món cho catalog 3.000 món; hiển thị ảnh trong các luồng thực đơn và tiếp tục theo từng phiên.

## Đã làm

- Tạo 10 ảnh riêng cho mã `nabi_vn_0001` đến `nabi_vn_0010`; rà soát trực quan theo tên, mô tả và nguyên liệu, không thấy món phụ hoặc nguyên liệu ngoài công thức.
- Lưu ảnh theo `assets/images/meals/catalog_v1/<catalog_code>.png`; cập nhật đường dẫn, SHA-256, ghi chú rà soát và trạng thái `verified` trong manifest tiến độ.
- Bổ sung `MealImageResolver.resolveAssetPaths` để tra ảnh code-keyed theo danh sách asset; luồng chính đọc danh sách từ Flutter `AssetManifest`.
- Bổ sung `MealPhoto.catalogItem` và hiển thị ảnh thumbnail trong từng lựa chọn ở bộ chọn món thay thế. Thẻ món và trang chi tiết đã dùng `MealPhoto`.
- Tạo hướng dẫn quy trình và validator để đối chiếu catalog, trạng thái, đường dẫn, hash, tính duy nhất của ảnh, chữ ký PNG và khai báo asset.
- Tiến độ hiện tại: 10/3.000 verified; 2.990 not_started; không có ảnh chờ rà soát hoặc bị loại.

## File code/docs đã sửa

- `lib/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver.dart` - bổ sung tra ảnh theo mã món và helper thuần để kiểm tra chính xác đường dẫn.
- `lib/app_versions/v1/features/meal_plan/presentation/widgets/meal_photo.dart` - hỗ trợ ảnh cho catalog item và kích thước thumbnail.
- `lib/app_versions/v1/features/meal_plan/presentation/widgets/meal_replacement_picker.dart` - hiện ảnh theo từng mã món trong lựa chọn thay thế.
- `test/app_versions/v1/features/meal_plan/presentation/meal_plan_image_contract_test.dart` - kiểm tra ảnh ở thẻ, chi tiết và lựa chọn thay món.
- `test/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver_test.dart` - kiểm tra lookup theo mã món.
- `assets/images/meals/catalog_v1/nabi_vn_0001_...png` đến `nabi_vn_0010_...png` - 10 ảnh riêng đã rà soát.
- `docs/meal_catalog/image_generation_progress_v1.json` - trạng thái và dữ liệu kiểm chứng từng mã trong catalog.
- `docs/meal_catalog/IMAGE_GENERATION_GUIDE.md` - quy trình tiếp tục theo lô và phạm vi rà soát.
- `tools/validate_meal_image_generation_progress.py` - validator tiến độ và asset.

## Tài liệu liên quan

- `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md`, `.codex/history/LEARNED_SKILLS.md`
- `.codex/workflows/coding.md`, `.codex/task-skills/coding.md`, `.codex/DOCS_WORKFLOW.md`
- `.codex/design/README.md`, `.codex/design/master.md`, `.codex/design/file-matrix.md`, `.codex/design/groups/05_meal_nutrition.md`, `.codex/design/screens/v1-08-meal-plan.md`

## Commands

- `dart format ...` trên 5 file Dart đã sửa: PASS.
- `flutter test test/app_versions/v1/features/meal_plan/presentation/meal_plan_image_contract_test.dart test/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver_test.dart`: PASS, 6 tests.
- `dart analyze ...` trên 5 file Dart đã sửa: PASS, không có issue.
- `python3 tools/validate_meal_image_generation_progress.py`: PASS, 10 ảnh code-keyed duy nhất; 2.990 món chưa bắt đầu.
- `git diff --check`: PASS.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL do thiếu `docs/audit/source_truth_manifest.json` và các stale backticked path ở worklog/task-skill cũ, ngoài phạm vi thay đổi của phiên này.
- DTD discovery/connect và hot reload: SKIPPED, không có app Flutter đang kết nối; chưa có bằng chứng hiển thị trên thiết bị.

## Lỗi/Rủi ro

- Đã fix: Resolver mới ban đầu có lỗi cú pháp; bài test ban đầu cũng cần khởi tạo Flutter binding. Đã chuyển kiểm tra lookup sang helper thuần nhận danh sách asset và toàn bộ test mục tiêu sau đó PASS.
- Chưa fix: Mới có 10/3.000 ảnh. Ảnh được tạo bằng AI theo phong cách ảnh chụp; rà soát trực quan không chứng minh đây là ảnh chụp hiện trường hoặc xác nhận chuyên gia ẩm thực.
- Cần kiểm tra tiếp: Chạy app trên thiết bị hoặc app đang kết nối để xác nhận ảnh tải trong thẻ, chi tiết và bộ chọn thay món; xem xét dung lượng bundle khi số lượng asset tăng.

## Tỷ lệ hoàn thành

- Hoàn thành: 10 ảnh đã tạo, rà soát, lưu theo mã và liên kết vào luồng thực đơn.
- Đang dở: Còn 2.990 món; mục tiêu tổng thể chưa hoàn tất.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - 10 ảnh khác nhau, nguyên liệu nhận diện được, không có phong cách minh họa; bộ theo dõi và resolver kiểm tra được theo mã.
- Mức độ hoàn thành task: một lô đầu đã hoàn tất; mục tiêu 3.000 ảnh còn dang dở.
- Bằng chứng kiểm chứng: rà soát trực quan từng ảnh, 6 test mục tiêu PASS, `dart analyze` PASS, validator PASS, 10 hash ảnh khác nhau.
- Điểm tốn token/chưa tối ưu: các ảnh PNG khoảng 2.4–3.0 MB mỗi ảnh; cần theo dõi tổng dung lượng trước khi đưa toàn bộ catalog vào app bundle.
- Cách tối ưu cho phiên sau: đọc 5 món `not_started` tiếp theo từ manifest, lấy nguyên liệu từ catalog, tạo riêng từng ảnh, rà soát trước khi cập nhật trạng thái.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`.
