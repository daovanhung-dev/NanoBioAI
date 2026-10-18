# Quy trình tạo ảnh cho catalog 3.000 món

## Nguồn và nơi lưu

- Catalog nguồn: `assets/data/nabi_3000_mon_viet_moi.json`.
- Tiến độ từng món: `docs/meal_catalog/image_generation_progress_v1.json`.
- Ảnh đã kiểm duyệt: `assets/images/meals/catalog_v1/<code>.png`.
- Giữ nguyên JSON catalog nguồn và `source_sha256`; manifest ảnh lưu đường dẫn, mã món, hash file và trạng thái riêng.
- `MealImageResolver` tìm ảnh bằng mã catalog trước; `MealPhoto` hiển thị ảnh trên thẻ, trang chi tiết và lựa chọn thay món. `pubspec.yaml` khai báo riêng `assets/images/meals/catalog_v1/` để Flutter bundle đúng thư mục con này.
- Theo dõi dung lượng trước khi mở rộng: 55 PNG hiện có chiếm khoảng 138 MiB (144.344.526 byte); giữ nguyên mức trung bình này thì 3.000 ảnh sẽ khoảng 7,87 GB (7,33 GiB). Cần xử lý dung lượng/chiến lược phân phối trước khi đóng gói toàn catalog.

## Quy trình mỗi phiên

1. Đọc manifest và chọn 10 dòng `not_started` tiếp theo theo thứ tự nguồn. Mã và tên món đã có sẵn trong manifest; dùng danh sách này để chốt ánh xạ trước khi tạo, không tạo lại dòng `verified`.
2. Với mỗi món, dùng mô tả, nguyên liệu và bước nấu từ catalog để viết prompt riêng. Gửi 10 yêu cầu ảnh độc lập trong cùng một đợt để rút ngắn thời gian chờ; mỗi mã vẫn nhận một ảnh riêng. Nếu dữ liệu món mâu thuẫn đến mức không xác định được món cần thể hiện, bỏ món đó khỏi đợt và ghi nhận để rà soát.
3. Ảnh phải là food photography photorealistic của món đã nấu, đúng nguyên liệu và cách chế biến; không tranh vẽ, hoạt hình, CGI, render 3D, chữ hay watermark. Không thêm nguyên liệu, rau trang trí hoặc món phụ ngoài công thức.
4. Sau khi cả đợt hoàn tất, rà soát ảnh theo mã cùng một lượt: tên món, nguyên liệu nhận diện, cách nấu và độ chân thực. Ảnh chưa được rà soát lưu trạng thái `generated_needs_review`; chỉ chuyển sang `verified` sau khi đối chiếu đạt. Ảnh sai phải tạo lại và không tính là hoàn tất.
5. Gắn ảnh theo đúng mã món, cập nhật đường dẫn, SHA-256, ghi chú rà soát và số đếm manifest cho cả đợt; chạy `python3 tools/validate_meal_image_generation_progress.py`.
6. Khi cập nhật app hoặc đổi Dart, kiểm tra hiển thị trên luồng thực đơn liên quan. Việc manifest và file asset hợp lệ tự nó chưa chứng minh đã QA trên thiết bị.

Sau lô 0041-0045 ngày 2026-10-16: 45/3.000 ảnh `verified`, 2.955 món `not_started`; chưa có ảnh chờ rà soát hoặc bị loại. Đây là ảnh AI tạo theo phong cách photorealistic và được rà soát bằng mắt theo catalog, không phải ảnh chụp hiện trường hay xác nhận chuyên gia ẩm thực.

Sau lô 0046-0050 ngày 2026-10-16: 50/3.000 ảnh `verified`, 2.950 món `not_started`; chưa có ảnh chờ rà soát hoặc bị loại. Widget test tải và render 10 ảnh đầu mới nhất từ asset bundle; chưa QA trên thiết bị.

Sau lô 0051-0055 ngày 2026-10-16: 55/3.000 ảnh `verified`, 2.945 món `not_started`; chưa có ảnh chờ rà soát hoặc bị loại. Widget test tải và render 15 ảnh mã 0041-0055 từ asset bundle; chưa QA trên thiết bị.

Sau lô 0056-0065 ngày 2026-10-16: 65/3.000 ảnh `verified`, 2.935 món `not_started`; lô 10 ảnh được tạo bằng 10 yêu cầu riêng trong cùng một đợt, sau đó rà soát và gắn mã theo manifest; validator xác nhận đủ 65 ảnh duy nhất.

Sau lô 0066-0075 ngày 2026-10-16: 75/3.000 ảnh `verified`, 2.925 món `not_started`; widget test tải và hiển thị các ảnh mã 0041-0075 trong asset bundle, gồm 10 ảnh mới.

Sau lô 0076-0085 ngày 2026-10-16: 85/3.000 ảnh `verified`, 2.915 món `not_started`; widget test tải và hiển thị ảnh theo mã 0041-0085 trong asset bundle, gồm 10 ảnh mới.

Sau lô 0086-0095 ngày 2026-10-16: 95/3.000 ảnh `verified`, 2.905 món `not_started`; widget test tải và hiển thị ảnh theo mã 0041-0095 trong asset bundle, gồm 10 ảnh mới.

## Trạng thái

- `not_started`: chưa có ảnh cuối.
- `generated_needs_review`: đã lưu ảnh nhưng chưa được đối chiếu đạt yêu cầu.
- `verified`: ảnh đã qua rà soát trực quan theo tên, nguyên liệu và bước nấu; file và hash tồn tại.
- `rejected`: lần tạo không đạt; không được tính vào số ảnh hoàn thành.

Bốn lô đầu ngày 2026-10-16 gồm 40 món đầu catalog, dùng để hiệu chỉnh prompt và quy trình rà soát. Đây là ảnh được tạo bằng AI theo phong cách photorealistic; xác minh trong phiên này là rà soát trực quan theo dữ liệu catalog, không phải xác nhận chuyên gia ẩm thực hay ảnh chụp hiện trường.

Sau lô 0096-0105 ngày 2026-10-16: 105/3.000 ảnh `verified`, 2.895 món `not_started`; widget test tải và hiển thị ảnh theo mã 0041-0105 trong asset bundle. Một ảnh đầu tiên cho món thịt ếch bị loại do dễ nhầm với thịt gà và được tạo lại trước khi xác minh.
