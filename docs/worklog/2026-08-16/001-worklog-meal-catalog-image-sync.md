Commit de xuat: fix(meal-plan): dong bo cong thuc va bundle anh mon an

# Worklog - Đồng bộ thực đơn và ảnh Meal Plan

## Thời gian

- Ngày: 2026-08-16
- Timezone: Asia/Saigon

## Phạm vi

- Loại task: coding + data validation
- Module chính: V1 Meal Plan / meal catalog / local meal assets
- Yêu cầu gốc: đồng bộ cách làm trong `docs/supabase/seed_data.sql` theo tài liệu `Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md`, bảo đảm mọi món có ảnh và hiển thị ảnh trong Meal Plan.

## Đã làm

- Đối chiếu source Markdown canonical với `docs/supabase/seed_data.sql` và tool `tools/sync_meal_catalog_sql.py`.
- Xác nhận contract nguồn hiện tại là 163 recipe entries / 64 chủ đề / 11 chương; SQL đã dùng `ingredients_json`, `cooking_steps_json`, `cooking_instructions`, `benefits` và source hash từ Markdown.
- Audit toàn bộ tên món theo canonical slug với tree `assets/images/meals/pdf_health_book` và `MealImageResolver`; không phát hiện món canonical cần ảnh web bổ sung.
- Xác định lỗi runtime chính: `pubspec.yaml` chưa khai báo trực tiếp thư mục ảnh lồng `assets/images/meals/pdf_health_book/`, nên Flutter không bundle các WebP này dù file tồn tại trong Git.
- Thêm asset entry chính xác vào `pubspec.yaml`.
- Thay test integrity cố định theo số lượng ảnh bằng test source-driven: đọc 163 recipe headings, resolve exact qua `MealImageResolver`, kiểm tra file WebP tồn tại và không rỗng, đồng thời kiểm tra pubspec bundling.
- Thêm `tools/validate_meal_sync.py` để kiểm tra read-only Markdown -> SQL canonical + recipe -> resolver -> WebP + pubspec trong một lệnh.
- Sửa trực tiếp `MealPhoto`: dùng `MealImageResolver.resolveAssetPath()` trước khi build `Image.asset`; món không có mapping verified fallback ngay, không cố tải asset sentinel giả.
- Giữ nguyên `meal_plan_page.dart` vì `main` đã render `MealPhoto` ở cả card và detail; không tạo migration/image column Supabase không cần thiết.

## File code/docs đã sửa

- `pubspec.yaml` - sửa - bundle trực tiếp thư mục WebP của Meal Plan.
- `lib/app_versions/v1/features/meal_plan/presentation/widgets/meal_photo.dart` - sửa - resolve ảnh verified trực tiếp và fallback không phát sinh asset lookup giả.
- `test/app_versions/v1/features/meal_plan/presentation/meal_plan_image_contract_test.dart` - sửa - khóa contract card/detail + resolver runtime.
- `test/app_versions/v1/features/meal_plan/presentation/utils/meal_image_asset_integrity_test.dart` - sửa - chuyển sang kiểm tra coverage theo source thay vì hard-code số file.
- `tools/validate_meal_sync.py` - tạo - validator read-only cho Markdown/SQL/image/pubspec.
- `docs/worklog/2026-08-16/001-worklog-meal-catalog-image-sync.md` - tạo - ghi nhận phiên.

## Tài liệu liên quan

- `docs/note/Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md`
- `docs/supabase/seed_data.sql`
- `docs/supabase/validate_meal_catalog.sql`
- `tools/sync_meal_catalog_sql.py`
- `lib/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver.dart`
- `lib/app_versions/v1/features/meal_plan/presentation/widgets/meal_photo.dart`
- `lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart`

## Commands

- GitHub connector audit source/tree/current runtime files: PASS.
- `python -m py_compile tools/validate_meal_sync.py`: PASS trên delivery tree.
- YAML parse `pubspec.yaml`: PASS trên delivery tree.
- `python tools/sync_meal_catalog_sql.py --check`: SKIPPED trong runtime này vì GitHub checkout không materialize được do DNS; static source audit cho thấy seed hiện được sinh bởi canonical sync tool.
- `flutter analyze` / `flutter test`: SKIPPED trong runtime này vì không có full checkout/Flutter SDK materialized; targeted tests được bàn giao để chạy trên checkout dự án.
- `.codex/tools/update_worklog_learning.ps1`: SKIPPED vì không có full checkout/PowerShell project context trong runtime artifact.

## Lỗi/Rủi ro

- Đã fix: ảnh món ăn tồn tại trong Git nhưng thư mục lồng chưa được Flutter bundle.
- Đã fix: test hard-code số WebP không chứng minh mọi món nguồn có ảnh.
- Không cần fix: không có món canonical thiếu ảnh sau audit, nên không tải ảnh ngoài web.
- Cần kiểm tra tiếp: chạy `python tools/validate_meal_sync.py`, targeted Flutter test/analyze và mở Meal Plan trên thiết bị sau khi chép các file vào checkout thật.

## Tỷ lệ hoàn thành

- Source/data/image audit: 100%.
- Source delivery: 100%, bao gồm code runtime trong `lib/`.
- Native Flutter verification trong runtime hiện tại: bị chặn bởi môi trường.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - fix đúng boundary asset bundle, không thêm ảnh web hoặc schema thừa.
- Mức độ hoàn thành task: source-ready; SQL canonical không cần rewrite khi nội dung đã đồng bộ.
- Bằng chứng kiểm chứng: GitHub source/tree audit + static validator + YAML/Python validation.
- Điểm tốn token/chưa tối ưu: GitHub clone bị DNS chặn nên phải audit qua connector theo vùng.
- Cách tối ưu phiên sau: chạy validator read-only trước; chỉ tìm ảnh ngoài nếu validator trả danh sách `missing_on_disk`.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`.
