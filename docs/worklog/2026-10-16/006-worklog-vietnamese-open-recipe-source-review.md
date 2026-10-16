Commit de xuat: docs(meal-catalog): danh gia bo recipe tieng Viet va nguon mo bo sung

# Worklog - Rà soát thêm nguồn công thức tiếng Việt và nguồn mở

## Thời gian

- Ngày: 2026-10-16
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: research/docs trong goal mở rộng meal catalog.
- Module chính: M02 `PERSONAL_SCHEDULE_AI`, meal catalog.
- Yêu cầu: tìm nguồn đủ quyền sử dụng để đạt tối thiểu 3.000 món có ảnh, công thức và dinh dưỡng theo form catalog.

## Đã làm

- Tìm thêm nguồn recipe tiếng Việt và các repository catalog toàn cầu.
- Rà `PTIT-KLTN/vietnamese_recipe_dataset`: README mô tả crawl từ Điện Máy Xanh và trích xuất công thức/khẩu phần; danh sách file công khai không có LICENSE. Không suy luận quyền của recipe từ quyền của crawler.
- Rà `xlabsinc/global-recipes`: README tự khai 420 recipe, 16 nhóm ẩm thực và 2 file Vietnamese; schema chưa có nutrition và README xếp ảnh/nutrition vào roadmap.
- Rà `global-recipe-db`: README tự khai 75.321 recipe nhưng DB không nằm trong repository; phần mềm MIT tách biệt dữ liệu, bảng nguồn có `Unknown / CC` và `Fair use`, đồng thời nguồn gốc giữ license riêng.
- Rà Palate Canonical 250: trang tải 250 món theo CC BY-NC 4.0 với nguyên liệu gram và macro/100 g, gồm nhóm Vietnamese. Trang yêu cầu liên hệ trước khi dùng thương mại; quyền/format của corpus đầy đủ chưa được cung cấp. Chỉ ghi là đầu mối cần xin mẫu và license.
- Kiểm tra lại Downloads theo tên tệp recipe/license/rights/catalog: chỉ có hai bản ZIP candidate minh họa cũ và script merge; chưa có bundle license mới.
- Không nhập nguồn vào runtime, không tạo checkout, không mua dữ liệu.

## File đã sửa

- `docs/meal_catalog/open_recipe_source_research_2026-10-16.md` - bổ sung bốn nguồn và lý do chưa đạt cổng license/số lượng/form.
- `docs/worklog/2026-10-16/006-worklog-vietnamese-open-recipe-source-review.md` - lưu tiến độ và căn cứ nguồn.

## Tài liệu liên quan

- [Vietnamese Recipe Dataset by PTIT-KLTN](https://github.com/PTIT-KLTN/vietnamese_recipe_dataset)
- [xlabsinc/global-recipes](https://github.com/xlabsinc/global-recipes)
- [global-recipe-db](https://github.com/drwjkirkpatrick-web/global-recipe-db)
- [Palate Canonical 250](https://palate.kitchen/data)
- `docs/meal_catalog/open_recipe_source_research_2026-10-16.md`

## Kiểm tra

- Web source review: PASS - đọc README/schema/license statements của từng nguồn; các số lượng và quyền được ghi là claim của nguồn khi chưa xác minh độc lập.
- Downloads inventory: PASS - chưa có bundle được người dùng cung cấp.
- `git diff --check`: PASS - không có whitespace errors.
- `pwsh -NoProfile -File .codex/tools/update_worklog_learning.ps1`: PASS - cập nhật 19 tệp history/task-skill deterministic.
- `pwsh -NoProfile -File .codex/tools/validate_codex_integrity.ps1`: FAIL - cùng vấn đề repository-wide đã có: thiếu `docs/audit/source_truth_manifest.json` và stale paths trong worklog/task-skill cũ; không chỉ ra lỗi ở hai tài liệu mới.
- Flutter/Dart tests: SKIPPED - chỉ cập nhật hồ sơ nghiên cứu.

## Lỗi/Rủi ro

- Chưa có nguồn được xác nhận đồng thời đủ 3.000 recipe, quyền thương mại/phân phối offline, ảnh được cấp quyền, nutrition theo khẩu phần và provenance theo từng dòng.
- Bundle người dùng dự kiến cung cấp vẫn là đầu vào cần thiết để bắt đầu nhập và đối chiếu theo validator.
- Form AI hiện gửi đầy đủ danh sách mã/tên và tóm tắt trong budget; chi tiết recipe được nạp từ SQLite sau khi model chọn mã. Không gửi nguyên văn full detail của 3.000 món trong một request.

## Tỷ lệ hoàn thành

- Hoàn thành: rà thêm 4 đầu mối mở và ghi rõ giới hạn quyền/quy mô/schema.
- Đang dở: nhận bundle license, xác minh từng nguồn/ảnh/nutrition, chuẩn hóa 3.000 recipe và tích hợp runtime.

## Tự đánh giá và bước tiếp theo

- Chất lượng đầu ra: giữ tách biệt quyền mã nguồn, quyền dữ liệu và điều khoản từng nguồn; không coi con số lớn hoặc nhãn MIT là license bao phủ mọi nội dung.
- Bằng chứng: trang README GitHub của các repository và trang dữ liệu/license Palate.
- Bước tiếp theo: khi bundle đến, kiểm tra quyền phân phối offline/sửa đổi/attribution, đối chiếu mã và recipe source, kiểm tra từng ảnh, cách tính khẩu phần, rồi chạy validator trước khi sửa seeder/migration.
- Task-skill lần sau: `.codex/task-skills/coding.md`.
