Commit de xuat: docs(worklog): ghi nhan lo anh mon Viet 0021-0025

# Worklog - Tạo ảnh món Việt 0021-0025

## Thời gian

- Ngày: 2026-10-16
- Bắt đầu: khoảng 14:01
- Kết thúc: 14:06
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: Tạo lô ảnh, rà soát trực quan, cập nhật tiến độ.
- Module chính: catalog `nabi_3000_mon_viet_moi.json`.
- Yêu cầu gốc: Tạo ảnh photorealistic riêng cho các món tiếp theo, khớp dữ liệu và lưu theo mã món.

## Đã làm

- Đọc tên, mô tả, nguyên liệu và trạng thái của mã `nabi_vn_0021` đến `nabi_vn_0025`.
- Tạo và rà soát trực quan 5 ảnh: mực lá hấp rau răm cải thảo; bánh xèo nhân bò bắp cải; mực ống xào dứa giá đỗ; bò lúc lắc; cháo nấm rơm khoai môn.
- Lưu ảnh riêng theo mã; cập nhật đường dẫn, SHA-256, ghi chú rà soát và trạng thái `verified` trong manifest.
- Tiến độ hiện tại: 25/3.000 verified; 2.975 not_started; không có ảnh chờ rà soát hoặc bị loại.
- Cập nhật hướng dẫn và ước tính dung lượng hiện tại: 25 PNG chiếm khoảng 63 MB; tuyến tính lên 3.000 ảnh tương đương khoảng 7,6 GB.

## File code/docs đã sửa

- `assets/images/meals/catalog_v1/nabi_vn_0021_...png` đến `nabi_vn_0025_...png` - 5 ảnh mới.
- `docs/meal_catalog/image_generation_progress_v1.json` - trạng thái, đường dẫn, hash và ghi chú kiểm định.
- `docs/meal_catalog/IMAGE_GENERATION_GUIDE.md` - số ảnh hiện có và rủi ro dung lượng.
- `docs/worklog/2026-10-16/014-worklog-meal-image-generation-0021-0025.md` - ghi nhận phiên.
- `.codex/history/*` và `.codex/task-skills/*` - cập nhật sinh tự động từ worklog.

## Tài liệu liên quan

- `docs/meal_catalog/IMAGE_GENERATION_GUIDE.md`
- `docs/meal_catalog/image_generation_progress_v1.json`
- `assets/data/nabi_3000_mon_viet_moi.json`

## Commands

- Đọc 5 record tiếp theo từ catalog và xác nhận trạng thái manifest là `not_started`: PASS.
- `python3 tools/validate_meal_image_generation_progress.py`: PASS, 25 ảnh code-keyed duy nhất; 2.975 món chưa bắt đầu.
- `du -sh assets/images/meals/catalog_v1`: PASS, 63 MB tại thời điểm kiểm tra.
- `python3 .codex/tools/update_worklog_learning.py --write`: PASS.
- `python3 .codex/tools/update_worklog_learning.py --check`: PASS.
- `git diff --check`: PASS.
- Test Flutter: SKIPPED, phiên này chỉ thêm ảnh và cập nhật tài liệu; không sửa mã runtime.

## Lỗi/Rủi ro

- Đã fix: Không có lỗi trong lô này.
- Chưa fix: Còn 2.975 món chưa có ảnh; ảnh được tạo bằng AI và rà soát trực quan, không phải ảnh chụp hiện trường hay chứng nhận chuyên gia ẩm thực.
- Cần kiểm tra tiếp: Giải quyết tối ưu dung lượng/phân phối trước khi đóng gói toàn catalog; tiếp tục từ mã `nabi_vn_0026`.

## Tỷ lệ hoàn thành

- Hoàn thành: 5 ảnh mới đã tạo, rà soát, lưu và ghi `verified`.
- Đang dở: Mục tiêu tổng thể còn 2.975 ảnh.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - từng ảnh phản ánh đúng nguyên liệu và cách chế biến tên món; không thấy món khác hoặc phong cách minh họa.
- Mức độ hoàn thành task: hoàn thành lô 0021-0025; mục tiêu 3.000 ảnh còn dang dở.
- Bằng chứng kiểm chứng: rà soát trực quan, validator xác nhận đường dẫn/hash/tính duy nhất và manifest xác nhận số đếm.
- Điểm tốn token/chưa tối ưu: PNG trung bình khoảng 2,5 MB; toàn bộ 3.000 ảnh không thể đóng gói nguyên trạng một cách hợp lý.
- Cách tối ưu cho phiên sau: tiếp tục từ 0026; đồng thời xác định phương án nén hoặc phân phối ảnh phù hợp trước khi thêm nhiều ảnh vào app bundle.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`.
