Commit de xuat: docs(worklog): ghi nhan lo anh mon Viet 0036-0040

# Worklog - Tạo ảnh món Việt 0036-0040

## Thời gian

- Ngày: 2026-10-16
- Bắt đầu: khoảng 14:19
- Kết thúc: 14:24
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: Tạo lô ảnh, rà soát trực quan, cập nhật tiến độ.
- Module chính: catalog `nabi_3000_mon_viet_moi.json`.
- Yêu cầu gốc: Tạo ảnh photorealistic riêng cho các món tiếp theo, đối chiếu công thức và lưu theo mã món.

## Đã làm

- Đọc tên, mô tả, nguyên liệu và trạng thái của mã `nabi_vn_0036` đến `nabi_vn_0040`.
- Tạo và rà soát 5 ảnh: mực nướng mật ong tỏi ớt chuông; bánh bèo nhân mực cà rốt; ghẹ hấp lá chanh sả cải thảo; cháo ức gà rau dền gạo lứt; cá rô phi kho nghệ cải chua.
- Lưu ảnh riêng theo mã món; cập nhật đường dẫn, SHA-256, ghi chú rà soát và trạng thái `verified` trong manifest.
- Tiến độ hiện tại: 40/3.000 verified; 2.960 not_started; không có ảnh chờ rà soát hoặc bị loại.
- Đo dung lượng hiện tại: 40 PNG chiếm khoảng 101 MB; tuyến tính lên 3.000 ảnh xấp xỉ 7,6 GB.

## File code/docs đã sửa

- `assets/images/meals/catalog_v1/nabi_vn_0036_...png` đến `nabi_vn_0040_...png` - 5 ảnh mới.
- `docs/meal_catalog/image_generation_progress_v1.json` - trạng thái, đường dẫn, hash và ghi chú kiểm định.
- `docs/meal_catalog/IMAGE_GENERATION_GUIDE.md` - số ảnh hiện có và ước tính dung lượng.
- `docs/worklog/2026-10-16/017-worklog-meal-image-generation-0036-0040.md` - ghi nhận phiên.
- `.codex/history/*` và `.codex/task-skills/*` - cập nhật sinh tự động từ worklog.

## Tài liệu liên quan

- `docs/meal_catalog/IMAGE_GENERATION_GUIDE.md`
- `docs/meal_catalog/image_generation_progress_v1.json`
- `assets/data/nabi_3000_mon_viet_moi.json`

## Commands

- Đọc 5 record tiếp theo từ catalog và xác nhận manifest là `not_started`: PASS.
- `python3 tools/validate_meal_image_generation_progress.py`: PASS, 40 ảnh code-keyed duy nhất; 2.960 món chưa bắt đầu.
- `du -sh assets/images/meals/catalog_v1`: PASS, 101 MB tại thời điểm kiểm tra.
- `python3 .codex/tools/update_worklog_learning.py --write`: PASS.
- `python3 .codex/tools/update_worklog_learning.py --check`: PASS.
- `git diff --check`: PASS.
- Test Flutter: SKIPPED, phiên này chỉ thêm ảnh và cập nhật tài liệu; không sửa mã runtime.

## Lỗi/Rủi ro

- Đã fix: Không có lỗi trong lô này.
- Chưa fix: Còn 2.960 món chưa có ảnh; ảnh được tạo bằng AI và rà soát trực quan, không phải ảnh chụp hiện trường hay xác nhận chuyên gia ẩm thực.
- Cần kiểm tra tiếp: Giải quyết dung lượng/phân phối trước khi đóng gói toàn catalog; tiếp tục từ mã `nabi_vn_0041`.

## Tỷ lệ hoàn thành

- Hoàn thành: 5 ảnh mới đã tạo, rà soát, lưu và ghi `verified`.
- Đang dở: Mục tiêu tổng thể còn 2.960 ảnh.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - năm món thể hiện nguyên liệu chính và cách chế biến nhận diện; mỗi file có hash riêng.
- Mức độ hoàn thành task: hoàn thành lô 0036-0040; mục tiêu 3.000 ảnh còn dang dở.
- Bằng chứng kiểm chứng: rà soát trực quan, validator xác nhận đường dẫn/hash/tính duy nhất và manifest xác nhận số đếm.
- Điểm tốn token/chưa tối ưu: 40 PNG đang chiếm 101 MB; giữ nguyên dung lượng trung bình thì 3.000 ảnh sẽ khoảng 7,6 GB.
- Cách tối ưu cho phiên sau: tiếp tục từ 0041, đồng thời xử lý chiến lược dung lượng/phân phối asset trước khi bundle toàn catalog.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`.
