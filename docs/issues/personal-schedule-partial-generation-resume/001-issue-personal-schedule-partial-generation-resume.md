Commit de xuat: docs(issue): ghi nhan loi khong tiep tuc duoc lich tao dang do

# Lịch mới đã lưu một phần không thể tiếp tục ngay

## Tóm tắt

- Severity: medium
- Lệnh tạo lịch ghi từng ngày đã hoàn tất vào các bảng lịch chính để hỗ trợ tiếp tục request.
- Nếu request lỗi sau khi lưu từ hai ngày trở lên, chính các ngày còn dang dở làm tăng horizon hiện tại. Lần thử lại bị chặn trước khi service tìm request thất bại để tiếp tục.

## Kỳ vọng và thực tế

- Kỳ vọng: request `generating` hoặc `failed` có dữ liệu staging được tiếp tục với cùng ngày bắt đầu, không phụ thuộc các ngày đã lưu một phần.
- Thực tế: `generateNextPlan` đọc horizon và ném `PersonalScheduleStillActiveException` khi còn từ hai ngày, trước khi gọi `findIncompleteRequestId`. Vì dữ liệu của request một phần nằm trong các bảng được dùng để tính horizon, lần thử lại có thể bị chặn nhiều ngày.

## Cách tái hiện theo source

1. Tài khoản thành viên bắt đầu tạo lịch 7 ngày khi lịch cũ còn 0 hoặc 1 ngày.
2. Cho quá trình lưu thành công ít nhất hai ngày rồi làm một bước sau đó thất bại.
3. Gọi tạo lại ngay: horizon đã bao gồm những ngày mới lưu và service từ chối trước bước tìm request `failed`.
4. Sau khi mở lại trang, nút tạo cũng bị khóa khi horizon còn ít nhất hai ngày.

## Bằng chứng

- `lib/app_versions/v1/services/ai/generated_plan_service.dart:238-245` chặn theo horizon.
- `lib/app_versions/v1/services/ai/generated_plan_service.dart:251-270` tìm request chưa hoàn tất sau guard horizon và khôi phục ngày bắt đầu từ request cũ.
- `lib/app_versions/v1/services/ai/generated_plan_service.dart:899-913` lưu từng ngày vào request store trước khi toàn bộ kế hoạch kết thúc.
- `lib/app_versions/v1/services/ai/generated_plan_request_store.dart:235-264` cho thấy `generating` và `failed` là trạng thái có thể tìm để tiếp tục.
- `lib/app_versions/v1/services/ai/generated_plan_request_store.dart:475-515` ghi ngày vào `meal_plans` và `lifestyle_schedule_items` trong transaction.
- `lib/app_versions/v1/features/lifestyle_schedule/presentation/widgets/schedule_regeneration_card.dart:20-25` chỉ bật nút khi `remainingDays < 2`.

Đây là kết luận từ luồng source; phiên rà soát này không chạy test hoặc tái hiện trên thiết bị.

## Ảnh hưởng

Người dùng có thể thấy lịch mới chỉ có một phần, không thể tiếp tục hoặc thay thế ngay phần còn thiếu, và phải đợi đến khi horizon lại còn dưới hai ngày. Cùng phiên, nút có thể vẫn trông khả dụng do giá trị horizon cũ, nhưng service đọc lại dữ liệu và trả lỗi “lịch vẫn còn ngày”.

## Hướng sửa đề xuất

- Tìm và tiếp tục request dở dang trước guard tạo request mới; vẫn kiểm tra chồng lấn với lịch hiện có.
- Hoặc lưu dữ liệu dở dang trong staging riêng và chỉ đưa vào lịch chính khi toàn bộ 7 ngày được xác nhận.
- Khi lỗi, đồng bộ lại horizon và các provider lịch; hiển thị rõ thao tác tiếp tục hoặc trạng thái một phần.

