Commit de xuat: fix(ai): luu tung ngay va fallback tu catalog SQLite

# Fixbug: giữ lịch đã tạo khi AI lỗi giữa chừng

## Hiện tượng

Yêu cầu tạo lịch 7 ngày gọi lần lượt 14 chunk, nhưng trước đây chỉ lưu `meal_plans` và `lifestyle_schedule_items` sau khi mọi chunk hoàn tất. Nếu chunk muộn lỗi hoặc hết lượt backend, người dùng không thấy các ngày đã hợp lệ.

## Sửa lỗi

- Dùng lựa chọn từ catalog SQLite để tạo gợi ý cục bộ khi provider, JSON hoặc giới hạn lượt AI thất bại.
- Lọc gợi ý cục bộ theo hồ sơ và metadata an toàn; nguồn lịch được ghi là `local_fallback` và không commit quota AI.
- Ghi mỗi ngày đã đủ bữa, vận động, và qua xác thực vào SQLite bằng một transaction. Lần tiếp tục giữ các ngày đã lưu và cập nhật phần tiếp theo.
- Ở chế độ nối, không xóa mục tùy chỉnh cùng ngày; ở chế độ thay, chỉ xóa dữ liệu ngày đang thay. Bước cuối xác nhận đúng ID/ngày do request tạo.

## Kiểm chứng

- Service/store/meal normalizer/exercise normalizer: 26 PASS; các test có tên fallback: 10 PASS; API theo ngày: 3 PASS; analyzer 10 file: sạch.
- SQLite in-memory đã xác nhận một ngày còn nguyên sau lỗi, request tiếp tục hoàn tất với ngày sau, nguồn fallback vẫn được lưu và các mục tùy chỉnh cùng ngày không bị xóa.
- Toàn bộ `ai_service_test.dart` vẫn có lỗi trong các case AI Chat log/API key và chunk/model retry ngoài nhóm fallback/API theo ngày.
- Không có app Flutter trong DTD và không chạy tạo lịch trên thiết bị; chưa xác minh Gemini, quota backend hoặc Supabase live.

## Ranh giới

Nếu không có đủ catalog đang hoạt động và phù hợp đã qua rà soát, không thể tạo fallback an toàn. Lỗi xác thực, quota, SQLite hoặc thiết bị cũng cần được xử lý riêng; fallback không bỏ qua các ràng buộc đó.
