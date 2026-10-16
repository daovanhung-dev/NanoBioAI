Commit de xuat: docs(meal-catalog): ghi nhan nguon recipe open va gioi han AI

# Worklog - Nghiên cứu nguồn mở và ngân sách catalog AI

## Thời gian

- Ngày: 2026-10-16
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: research/docs trong goal mở rộng meal catalog.
- Module chính: M02 `PERSONAL_SCHEDULE_AI`, meal catalog và prompt catalog.
- Yêu cầu gốc: tìm nguồn recipe có quyền sử dụng truy nguyên được để hướng tới ít nhất 3.000 món; giữ toàn bộ danh mục khả dụng trong ngữ cảnh AI tạo lịch.

## Đã làm

- Kiểm tra lại Downloads và worktree; chưa có bundle/license mới, catalog runtime vẫn có 163 món.
- Tra cứu nguồn mở: Wikibooks có 3.797 trang namespace `Cookbook` trong danh mục recipe; category API ghi 836 trang có ảnh và 895 trang có đơn vị metric. Ghi rõ đây là số trang, chưa phải số recipe đã qua thẩm định, và ảnh có license theo từng file.
- Đọc chính sách Wikibooks: phần lớn text CC BY-SA 4.0/GFDL, bắt buộc attribution/ShareAlike; media có license riêng; FAQ không chấp nhận recipe AI chưa tự nấu và kiểm tra.
- Tra cứu RecipeDB: tài liệu dự án nêu CC BY-NC-SA 3.0; không chọn làm nguồn runtime khi chưa có quyền riêng phù hợp.
- Xác nhận FDC dùng CC0 1.0 cho dữ liệu thành phần; license này không được suy rộng sang recipe/ảnh khác.
- Đo lại candidate JSON: 3.000 cặp code/tên là 297.314 byte; thêm summary đầy đủ là 1.662.627 byte; theo ngân sách 1 MB summary được rút đồng đều còn tối đa 211 byte, vẫn giữ mọi code/tên. JSON đầy đủ 3.000 recipe là 15.035.627 byte, vượt request body 1.500.000 byte.
- Cập nhật hồ sơ nguồn và tài liệu AI để ghi chính xác phạm vi prompt: AI nhận toàn bộ chỉ mục, app hydrate chi tiết các món được chọn từ SQLite.

## File code/docs đã sửa

- `docs/meal_catalog/open_recipe_source_research_2026-10-16.md` - tạo - ghi quy mô, quyền và giới hạn của các nguồn đã khảo sát.
- `docs/meal_catalog/3000_recipe_dataset_intake.md` - thêm liên kết nghiên cứu nguồn.
- `docs/features/ai-generated-plan/005-feature-full-catalog-ai-context.md` - thêm phép đo UTF-8 trên candidate 3.000 dòng.
- `docs/worklog/2026-10-16/004-worklog-open-recipe-source-research.md` - tạo - lưu bằng chứng và bước tiếp theo.

## Tài liệu liên quan

- `docs/meal_catalog/3000_recipe_dataset_review_2026-10-16.md`
- `docs/meal_catalog/3000_recipe_dataset_intake.md`
- `docs/features/ai-generated-plan/005-feature-full-catalog-ai-context.md`
- [Wikibooks copyright policy](https://en.wikibooks.org/wiki/Wikibooks:Copyrights)
- [RecipeDB FAQ](https://cosylab.iiitd.edu.in/recipedb/FAQ)
- [USDA FoodData Central API guide](https://fdc.nal.usda.gov/api-guide/)

## Commands

- MediaWiki API `Category:Recipes` membership pagination: PASS - 3.845 members, including 3.797 `Cookbook` namespace pages; not treated as validated recipes.
- MediaWiki API `categoryinfo`: PASS - 836 image-tagged pages and 895 metric-tagged pages.
- Python JSON UTF-8 size calculation: PASS - measured compact code/name/summary and full candidate payload; no Gemini request sent.
- `git diff --check`: PASS - אין whitespace errors.
- `pwsh -NoProfile -File .codex/tools/update_worklog_learning.ps1`: PASS - cập nhật 19 tệp history/task-skill deterministic.
- `pwsh -NoProfile -File .codex/tools/validate_codex_integrity.ps1`: FAIL - thiếu `docs/audit/source_truth_manifest.json` và các stale path trong history/task-skill hiện có; không phát hiện lỗi từ tài liệu nguồn mới.
- Flutter/Dart tests: SKIPPED - docs/research only; no runtime implementation changed.

## Lỗi/Rủi ro

- Đã fix: none.
- Chưa fix: chưa có dataset/license áp dụng cho recipe trong candidate; chưa có nutrition row provenance hoặc thẩm định từng công thức; Wikibooks không được chọn vì thiếu nutrition/ảnh đầy đủ và có share-alike obligations.
- Cần kiểm tra tiếp: khi người dùng cung cấp bundle, xác minh recipe/image rights, provenance dinh dưỡng, ảnh và nội dung từng dòng trước khi tạo migration hoặc bật cho AI.

## Tỷ lệ hoàn thành

- Hoàn thành: source research và prompt-size evidence.
- Đang dở: mục tiêu 3.000 món trong runtime, hình ảnh theo món, nutrition evidence và khả năng chọn món đã duyệt.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - phân biệt số trang source với recipe đã kiểm định, và license nutrient với license recipe/media.
- Mức độ hoàn thành task: một bước research hoàn tất; mục tiêu catalog tổng thể chưa hoàn thành vì chưa có license bundle phù hợp.
- Bằng chứng kiểm chứng: MediaWiki API live counts, project source for prompt budget/request cap, local serialized-byte measurement, official license pages.
- Điểm tốn token/chưa tối ưu: query nhiều nguồn để loại dataset không phù hợp; có thể tiết kiệm bằng cách rà soát license trước khi tải corpus lớn.
- Cách tối ưu phiên sau: xử lý rights manifest và candidate JSON trực tiếp khi người dùng cung cấp bundle, rồi tính nutrition mapping và chuẩn hóa ảnh theo code.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
