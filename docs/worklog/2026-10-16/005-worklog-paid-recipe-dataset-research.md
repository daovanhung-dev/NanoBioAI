Commit de xuat: docs(meal-catalog): danh gia nguon recipe co license thuong mai

# Worklog - Đánh giá nguồn recipe có license thương mại

## Thời gian

- Ngày: 2026-10-16
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: research/docs trong goal mở rộng meal catalog.
- Module chính: M02 `PERSONAL_SCHEDULE_AI`, meal catalog.
- Yêu cầu gốc: tìm nguồn công thức có quyền sử dụng, ảnh và nutrition để đưa catalog đến ít nhất 3.000 món.

## Đã làm

- Kiểm tra lại Downloads: chưa có dữ liệu hoặc license bundle mới; chỉ thấy candidate cũ `NanoBio_3000_mon_anh_minh_hoa`.
- Rà soát Pepesto recipe dataset và API terms. Nhà cung cấp công bố batch JSONL có recipe, nguyên liệu, bước nấu, calories/macros, dị ứng, ảnh 1024px và license vĩnh viễn để lưu/hiển thị trong app; thương mại và không cần attribution theo điều khoản hiện hành.
- Tính niêm yết cho 3.000 món: 3.000 × €0,90 = €2.700 nếu tiếng Anh; non-English cộng €0,30/món, tương đương €3.600 nếu có locale phù hợp. Danh sách ngôn ngữ của dataset hiện không có Vietnamese.
- Ghi rõ các điểm phải kiểm tra bằng sample trước batch lớn: nutrition có thể là toàn recipe hay mỗi serving; số portions được cung cấp dạng range; dataset sample không nêu fiber/water, source URL per recipe hoặc điều kiện sức khỏe; image là AI-generated; quality claims là từ vendor.
- Ghi nhận license proof có email người mua; không public hóa token. Không tạo checkout hoặc thanh toán.
- Rà soát Open Recipe Archive (54.843 recipe lịch sử theo README) và Epicurious scrape mirror; ghi lại vì sao không đạt form/ảnh/nutrition hoặc chưa đủ quyền phân phối.
- Cập nhật hồ sơ nguồn và hướng dẫn tiếp nhận để người dùng có thể chọn bundle riêng hoặc đưa batch vendor đã mua.

## File code/docs đã sửa

- `docs/meal_catalog/open_recipe_source_research_2026-10-16.md` - bổ sung Pepesto, Open Recipe Archive và Epicurious mirror cùng giới hạn rights/data.
- `docs/meal_catalog/3000_recipe_dataset_intake.md` - ghi nguồn thương mại, giá niêm yết và language limitation.
- `docs/worklog/2026-10-16/005-worklog-paid-recipe-dataset-research.md` - tạo - lưu evidence và bước tiếp theo.

## Tài liệu liên quan

- [Pepesto recipe dataset](https://www.pepesto.com/recipe-dataset/)
- [Pepesto dataset schema, locale, and pricing](https://www.pepesto.com/recipe-dataset-agent/)
- [Pepesto API terms](https://www.pepesto.com/api-terms/)
- [Open Recipe Archive](https://github.com/AdamBouhmad/open-recipe-archive)
- `docs/meal_catalog/3000_recipe_dataset_intake.md`

## Commands

- Downloads intake inventory: PASS - không có dataset/license mới.
- Web primary pages: PASS - đọc schema, pricing, license scope và locale từ vendor; không tạo checkout/payment.
- Cost calculation: PASS - 3.000 × €0,90 = €2.700; thêm €0,30/non-English khi locale được hỗ trợ.
- `git diff --check`: PASS - không có whitespace errors.
- `pwsh -NoProfile -File .codex/tools/update_worklog_learning.ps1`: PASS - cập nhật 19 tệp history/task-skill deterministic.
- `pwsh -NoProfile -File .codex/tools/validate_codex_integrity.ps1`: FAIL - thiếu `docs/audit/source_truth_manifest.json` và có stale path trong history/task-skill hiện hành; không chỉ ra lỗi từ report/intake mới.
- Flutter/Dart tests: SKIPPED - docs/research only.

## Lỗi/Rủi ro

- Đã fix: none.
- Chưa fix: chưa có bundle license đủ điều kiện; candidate cũ thiếu rights recipe và dinh dưỡng theo nguồn. Pepesto không liệt kê tiếng Việt và không có mẫu đã mua để xác nhận format/nutrition.
- Cần kiểm tra tiếp: khi người dùng gửi licensed data hoặc batch sample, rà soát license proof, nội dung, per-serving nutrition, ảnh và chuyển đổi schema trước migration.

## Tỷ lệ hoàn thành

- Hoàn thành: đánh giá nguồn thương mại khả dụng và chi phí niêm yết; mở rộng source shortlist.
- Đang dở: 3.000 dòng runtime chuẩn hóa, license proof thực tế, hình ảnh và nutrition QA.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - phân biệt claim vendor với kiểm chứng độc lập và tính ra mức chi phí trước khi xem xét mua.
- Mức độ hoàn thành task: source discovery đã tiến thêm một lựa chọn thực tế; chưa có dữ liệu để tích hợp.
- Bằng chứng kiểm chứng: vendor recipe dataset page, dataset agent page, API terms; inventory Downloads; calculation from published tier prices.
- Điểm tốn token/chưa tối ưu: trang catalog checkout bị timeout, nhưng agent documentation cung cấp locale/schema/pricing chính thức.
- Cách tối ưu phiên sau: khi có file JSONL mẫu, viết adapter theo đúng payload thật và giữ proof token ngoài public bundle.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
