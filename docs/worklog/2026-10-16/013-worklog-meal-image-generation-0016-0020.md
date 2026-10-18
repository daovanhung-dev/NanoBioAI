Commit de xuat: docs(worklog): ghi nhan lo anh mon Viet 0016-0020

# Worklog - Tạo ảnh món Việt 0016-0020

## Thời gian

- Ngày: 2026-10-16
- Bắt đầu: khoảng 13:56
- Kết thúc: 14:00
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: Tạo lô ảnh, rà soát trực quan, cập nhật tiến độ.
- Module chính: catalog `nabi_3000_mon_viet_moi.json`.
- Yêu cầu gốc: Tiếp tục tạo ảnh photorealistic riêng cho từng món chưa có ảnh, đối chiếu dữ liệu và lưu theo mã để các phiên sau không xử lý trùng.

## Đã làm

- Đọc tên, mô tả, nguyên liệu và trạng thái của mã `nabi_vn_0016` đến `nabi_vn_0020` trước khi tạo ảnh.
- Tạo và rà soát trực quan 5 ảnh: canh mồng tơi tôm đậu bắp; ba chỉ kho cải chua tiêu xanh; cá bống kho nấm rơm tiêu xanh; cá diêu hồng kho khế chua; gỏi đậu hũ xoài xanh cà rốt.
- Lưu ảnh riêng theo mã món; cập nhật đường dẫn, SHA-256, ghi chú rà soát và trạng thái `verified` trong manifest.
- Tiến độ hiện tại: 20/3.000 verified; 2.980 not_started; không có ảnh chờ rà soát hoặc bị loại.
- Cập nhật hướng dẫn để ghi nhận 20 món đầu đã qua quy trình.

## File code/docs đã sửa

- `assets/images/meals/catalog_v1/nabi_vn_0016_...png` đến `nabi_vn_0020_...png` - 5 ảnh mới, riêng theo từng mã món.
- `docs/meal_catalog/image_generation_progress_v1.json` - trạng thái, đường dẫn, hash và ghi chú kiểm định.
- `docs/meal_catalog/IMAGE_GENERATION_GUIDE.md` - số ảnh đã hoàn tất ở hai lô đầu.
- `docs/worklog/2026-10-16/013-worklog-meal-image-generation-0016-0020.md` - ghi nhận phiên.
- `.codex/history/*` và `.codex/task-skills/*` - cập nhật sinh tự động từ worklog.

## Tài liệu liên quan

- `docs/meal_catalog/IMAGE_GENERATION_GUIDE.md`
- `docs/meal_catalog/image_generation_progress_v1.json`
- `assets/data/nabi_3000_mon_viet_moi.json`

## Commands

- Đọc 5 record tiếp theo từ catalog và xác nhận trạng thái manifest là `not_started`: PASS.
- `python3 tools/validate_meal_image_generation_progress.py`: PASS, 20 ảnh code-keyed duy nhất; 2.980 món chưa bắt đầu.
- `python3 .codex/tools/update_worklog_learning.py --write`: PASS.
- `python3 .codex/tools/update_worklog_learning.py --check`: PASS.
- `git diff --check`: PASS.
- Test Flutter: SKIPPED, phiên này chỉ thêm ảnh và cập nhật tài liệu; không sửa mã runtime.

## Lỗi/Rủi ro

- Đã fix: Không có lỗi trong lô này.
- Chưa fix: Còn 2.980 món chưa có ảnh; ảnh được tạo bằng AI và rà soát trực quan, không phải ảnh chụp hiện trường hay chứng nhận chuyên gia ẩm thực. 20 PNG hiện chiếm khoảng 51 MB, tương đương khoảng 7,5 GB nếu mở rộng tuyến tính lên 3.000 món; cần giải quyết dung lượng/phân phối trước khi đóng gói toàn bộ vào app.
- Cần kiểm tra tiếp: Tiếp tục từ mã `nabi_vn_0021`; xác nhận hiển thị trên thiết bị vẫn chưa được chứng minh.

## Tỷ lệ hoàn thành

- Hoàn thành: 5 ảnh mới đã tạo, rà soát, lưu và ghi `verified`.
- Đang dở: Mục tiêu tổng thể còn 2.980 ảnh.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - từng ảnh thể hiện các nguyên liệu chính riêng của món; không có món thay thế hoặc phong cách minh họa.
- Mức độ hoàn thành task: hoàn thành lô 0016-0020; mục tiêu 3.000 ảnh còn dang dở.
- Bằng chứng kiểm chứng: rà soát trực quan, validator xác nhận đường dẫn/hash/tính duy nhất, manifest xác nhận số đếm.
- Điểm tốn token/chưa tối ưu: ảnh PNG trung bình khoảng 2,55 MB; ước tính tuyến tính 3.000 ảnh là khoảng 7,5 GB, chưa phù hợp để đưa nguyên trạng vào app bundle.
- Cách tối ưu cho phiên sau: đọc 5 record `not_started` kế tiếp từ manifest, viết prompt theo nguyên liệu, tạo và rà soát từng ảnh trước khi cập nhật trạng thái.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`.
