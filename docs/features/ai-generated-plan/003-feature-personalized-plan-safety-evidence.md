Commit de xuat: feat(ai): loc bang chung cho lich ca nhan

# Lọc dữ liệu và ràng buộc cho lịch cá nhân

## Mục tiêu

- Giữ SQLite làm nguồn danh mục món ăn và bài vận động trên thiết bị.
- Bổ sung bằng chứng dinh dưỡng có xuất xứ, bộ lọc ràng buộc tại thiết bị và giới hạn dữ liệu gửi cho AI.
- Dừng tạo lịch nếu thiếu ứng viên phù hợp hoặc đầu ra không được xác thực; chỉ lưu khi cả hai phần ăn uống và vận động hoàn tất.

## Luồng dữ liệu

1. Migration v30 thêm định lượng nguyên liệu, khẩu phần, trạng thái xác minh dị ứng/dinh dưỡng, dữ liệu an toàn vận động, cache bằng chứng thực phẩm và tùy chọn vận động cục bộ.
2. Danh mục 163 món tiếp tục được seed từ `assets/data/meal_catalog_v1.json`. Migration giữ nguyên mã, hash và metadata cũ; trường mới chưa có dữ kiện vẫn để `null` hoặc trạng thái chưa xác minh.
3. Ứng dụng lọc món theo bữa, dị ứng, tình trạng sức khỏe, mục tiêu và món cần tránh. Khi một ràng buộc chưa có dữ liệu đã rà soát, ứng viên bị loại. Bài vận động được lọc theo tình trạng sức khỏe, giới hạn cơ thể, dụng cụ, mục tiêu và trạng thái rà soát.
4. `nabi-food-evidence` chỉ nhận tên nguyên liệu, xác thực phiên người dùng, tìm bảng thành phần của Viện Dinh dưỡng Quốc gia trước rồi dùng USDA FoodData Central khi không có kết quả hoặc nguồn NIN tạm lỗi. Kết quả gồm mã thực phẩm, giá trị theo 100 g, nguồn, phiên bản và ngày truy xuất; dữ kiện được cache tại SQLite tối đa 180 ngày.
5. Prompt món ăn gửi tối đa 10 mã cho mỗi bữa. Mỗi bản ghi món và bằng chứng nguyên liệu chỉ xuất hiện một lần trong JSON; danh sách của từng bữa tham chiếu mã. Prompt vận động gửi tối đa 10 bài. AI chỉ trả mã và trường lịch.
6. Ứng dụng kiểm tra mã và cấu trúc đầu ra, nạp chi tiết món/bài từ SQLite, rồi ghi giao dịch kế hoạch sau khi cả phần ăn uống và vận động thành công.

## Quyền riêng tư và giới hạn sản phẩm

- Hồ sơ sức khỏe, tên, định danh, ghi chú tự do, thuốc và xét nghiệm không được đưa vào prompt hoặc tra cứu thực phẩm.
- Tra cứu phía máy chủ không nhận hồ sơ sức khỏe; phần thân yêu cầu chỉ chứa tên nguyên liệu. USDA key nằm trong secret `USDA_FDC_API_KEY` phía máy chủ.
- Kế hoạch là wellness chung. Ràng buộc bệnh/dị ứng chỉ được áp dụng từ dữ liệu đã rà soát; AI không quyết định an toàn y khoa và không tạo lịch điều trị.
- Dữ liệu hiện có chưa đồng nghĩa đã xác minh. Với dị ứng hoặc tình trạng bệnh, danh mục hiện có thể không còn món/bài đủ điều kiện; ứng dụng dừng thay vì suy đoán.
- Hướng dẫn vận động WHO được dùng làm tham chiếu wellness chung, không thay thế đánh giá riêng theo bệnh.

## Kiểm chứng và vận hành

- Migration kiểm tra bảo toàn 163 mã/hash và giữ giá trị chưa biết là `null`.
- Kiểm thử lọc xác nhận năm slot món, dữ liệu dị ứng/tình trạng chưa rà soát, giới hạn ứng viên, kích thước prompt, lỗi thiếu ứng viên và không ghi lịch một phần.
- Kiểm thử Edge Function xác nhận đầu vào chỉ gồm tên nguyên liệu, xác thực người gọi, ánh xạ đơn vị/nguồn và fallback sang USDA khi bảng NIN tạm lỗi.
- Chưa deploy `nabi-food-evidence`; vì vậy chưa xác minh secret USDA, RLS/auth trên môi trường Supabase, quota phía nhà cung cấp hoặc dữ liệu trả về trực tiếp từ các nguồn.

## Nguồn tham chiếu

- [USDA FoodData Central API Guide](https://fdc.nal.usda.gov/api-guide/)
- [Viện Dinh dưỡng Quốc gia](https://viendinhduong.vn/)
- [WHO Guidelines on Physical Activity and Sedentary Behaviour](https://www.who.int/publications/i/item/9789240015128)
