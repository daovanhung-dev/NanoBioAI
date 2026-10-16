Commit de xuat: docs(meal-catalog): review incoming 3000 recipe candidate

# Worklog - Rà soát candidate catalog 3.000 món

## Thời gian

- Ngày: 2026-10-16
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: data intake review/documentation.
- Module chính: M02 `PERSONAL_SCHEDULE_AI`, meal catalog.
- Mục tiêu: kiểm tra gói candidate vừa có trong Downloads trước khi nhập dữ liệu hoặc thay đổi trạng thái runtime.

## Phát hiện

- Tìm thấy `NanoBio_3000_mon_anh_minh_hoa.zip` và bản `(1).zip` có cùng SHA-256; thư mục giải nén có 3.000 recipe và 3.000 ảnh WEBP.
- JSON có 3.000 code/tên món duy nhất; `source_sha256` tính lại khớp. ZIP toàn vẹn.
- Provenance mô tả ảnh minh họa tạo lập trình, không phải ảnh chụp. Không có rights CSV, license document hoặc evidence directory trong bundle.
- 3.000/3.000 recipe có `estimated_unverified`, `verified_nutrients=null`, không có FDC IDs/ngày chứng cứ; source URL dinh dưỡng chung không chứng minh phép tính theo hàng.
- 3.000/3.000 recipe đang inactive và không đủ điều kiện lập lịch. Có ví dụ bước nấu cần rà soát; không bật recipe.
- Script merge bên ngoài gói chọn 2.837 trong 3.000 recipe mở rộng để tạo tổng đúng 3.000 với 163 món gốc. Đây là lựa chọn ngầm có thể làm mất 163 dòng mở rộng.
- Không sửa dữ liệu JSON, ảnh, seeder, migration hoặc trạng thái duyệt.

## File đã sửa

- `docs/meal_catalog/3000_recipe_dataset_intake.md` - cập nhật trạng thái từ “chưa có bundle” sang “đã có candidate, chưa đạt cổng nhập”.
- `docs/meal_catalog/3000_recipe_dataset_review_2026-10-16.md` - ghi biên bản chi tiết, blockers và yêu cầu trước khi nhập.
- `docs/checklist/checklist_task_coding.md` và `docs/checklist/checklist_complete_DD.md` - cập nhật trạng thái M02 và bước tiếp theo.

## Xác minh

- `unzip -t`: PASS.
- Kiểm kê JSON/ảnh và kiểm tra hash `source_sha256`: PASS.
- Không chạy test; không có thay đổi runtime trong lần rà soát này.

## Trạng thái

- Candidate có đủ số lượng và ảnh minh họa để tiếp tục đánh giá.
- Chưa đạt quyền sử dụng recipe, chứng cứ dinh dưỡng và chất lượng công thức; không nhập vào app hoặc bật cho AI lập lịch.
- Cần license/provenance recipe và dữ liệu dinh dưỡng có thể truy nguyên trước migration v36.
