# Rà soát gói món ăn 3.000 dòng

## Cập nhật candidate JSON trong workspace — 2026-10-16

Phần bên dưới mô tả archive `NanoBio_3000_mon_anh_minh_hoa` trong Downloads. JSON hiện có trong workspace là file candidate khác: `assets/data/nabi_3000_mon_viet_moi.json`, 3.000 dòng/3.000 mã duy nhất, không trùng 163 mã hiện tại. Cả 3.000 dòng trong file này đặt `is_active=true` (không dùng cờ này làm bằng chứng duyệt), `is_plan_eligible=false`, `meal_type=unclassified`, `nutrition_status=estimated_unverified`, `constraint_metadata_status=awaiting_professional_review`, `metadata_status=ai_generated_needs_review`. Có 466 dòng thiếu `water_ml`, và JSON không chứa hồ sơ license hoặc evidence dinh dưỡng theo món. Theo chỉ thị trực tiếp ngày 2026-10-16, file được đóng gói vào app; chỉ mã/tên được gửi trong policy wellness riêng. File gốc không bị sửa và trạng thái review không được nâng.

Các thông tin ảnh, ZIP, hash archive và mã `nb_ext_*` bên dưới chỉ thuộc archive Downloads; ảnh không phải yêu cầu của cổng nhập catalog hiện tại.

## Cập nhật triển khai theo quyết định người dùng — 2026-10-16

- SQLite v36 và seeder cài mới chứa 3.163 mã duy nhất: giữ 163 món cũ, thêm 3.000 candidate. Upgrade v35 dùng insert-only và kiểm tra hash của các món cũ/candidate.
- Prompt wellness gửi code/name candidate; không gửi description, recipe, ingredient, hoặc số nutrition candidate. Normalizer/fallback chỉ nhận các mã có trong `eligibleCodesByType` do selector wellness tạo. Policy strict vẫn chặn candidate.
- Dị ứng hoặc thực phẩm cần tránh mà metadata chưa xác minh tiếp tục chặn candidate. Món được chọn hydrate recipe từ SQLite; số nutrition chưa xác minh bị loại khỏi snapshot và màn detail.
- Quyết định dùng dữ liệu không xác minh quyền phân phối hoặc chất lượng recipe/dinh dưỡng. Chưa có bằng chứng rights/license hoặc review chuyên môn.

## Kết luận về archive Downloads (không phải JSON workspace hiện tại)

Gói candidate đã được tìm thấy và kiểm tra cấu trúc, nhưng **chưa đủ điều kiện nhập vào catalog runtime hoặc dùng cho AI lập lịch**. Gói có đủ số lượng bản ghi và ảnh minh họa, nhưng chưa có hồ sơ quyền sử dụng cho từng recipe và toàn bộ dinh dưỡng đang ở trạng thái ước tính chưa xác minh.

## Gói đã rà soát

- Vị trí: `~/Downloads/NanoBio_3000_mon_anh_minh_hoa/` và hai ZIP cùng tên trong Downloads.
- SHA-256 hai bản ZIP: `fd326afebad379397176b90059c144ab84cfd188f093532216ae1700dd93ddc2` (giống nhau).
- Archive kiểm tra toàn vẹn; gồm 3.000 ảnh WEBP theo mã, 2 JSON và một script merge.
- JSON khai báo 3.000 recipe với 3.000 code và 3.000 tên chuẩn hóa duy nhất. `source_sha256` khớp hash tính lại trên danh sách recipes.
- Ảnh được khai báo là minh họa lập trình 448×448, không phải ảnh chụp món ăn. 3.000 file có tên theo code và byte khác nhau.

## Các cổng chưa đạt

1. **Quyền recipe chưa có hồ sơ:** archive không có rights CSV, license text hoặc hợp đồng/điều khoản. Provenance chỉ nói ảnh được tạo mới; recipe tự mô tả là “independently composed” và không lấy từ recipe đã thử nghiệm. Không thể suy ra license hoặc quyền phân phối từ trường license ảnh.
2. **Dinh dưỡng chưa xác minh:** 3.000/3.000 có `nutrition_status=estimated_unverified`, `verified_nutrients=null`, `nutrition_food_ids=[]`, `nutrition_evidence_date=null`. USDA chỉ được nêu như tham chiếu phương pháp, không có đối chiếu ingredient-to-food hoặc nguồn theo món.
3. **Recipe chưa qua rà soát:** bước nấu có tính mẫu lặp. Ví dụ món salad thịt lợn và rau xà lách (`nb_ext_3000`) yêu cầu làm chín xà lách và bún đã chín, cần sửa trước khi xem là công thức đã kiểm chứng.
4. **Chưa đủ điều kiện lập lịch:** tất cả bản ghi đặt `is_active=false` và `is_plan_eligible=false`; giữ cờ này là cần thiết cho đến khi hoàn thành kiểm định.
5. **Chính sách merge đi kèm làm rơi dữ liệu:** 3.000 món mở rộng cộng 163 món hiện tại là 3.163. `merge_meal_catalog_3000.py` chỉ lấy 2.837 dòng mở rộng để xuất đúng 3.000 tổng; cần quyết định giữ toàn bộ 3.163 hay chọn lọc có chủ đích trước khi nhập.

## Bước cần hoàn tất trước khi nhập

- Bổ sung điều khoản/license hoặc bằng chứng quyền sử dụng áp dụng cho recipe và asset, gồm quyền lưu offline, sửa đổi và phân phối trong ứng dụng.
- Cung cấp provenance dinh dưỡng có thể truy nguyên theo từng nguyên liệu, gồm food ID/phiên bản/ngày tra cứu và công thức quy đổi, hoặc thay bằng số liệu đã được chuyên gia xác nhận.
- Rà soát tính thực hành của định lượng và hướng dẫn nấu, kiểm tra dị ứng/giao thoa và đánh dấu rõ phạm vi người dùng phù hợp.
- Chốt chính sách merge; sau khi dữ liệu qua kiểm định mới tạo catalog hợp nhất, migration SQLite mới từ v35 và cập nhật seeder.
- Kiểm tra ngân sách request: ứng dụng truyền chỉ mục mã/tên/tóm tắt trong ngân sách và hydrate chi tiết từ SQLite sau khi AI chọn mã; không truyền toàn bộ 3.000 công thức đầy đủ trong một request.

Chưa thay đổi catalog JSON, SQLite, seeder hoặc trạng thái duyệt trong lần rà soát này.
