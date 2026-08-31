Commit de xuat: fix(food-scan): khac phuc gate va payload anh

# Fixbug - Không dùng được chức năng phân tích món ăn

## Triệu chứng

Food Scan có thể bị dừng trước khi gọi AI hoặc bị Edge Function từ chối request,
khiến UI chỉ hiển thị thông báo phân tích thất bại.

## Root cause đã xác nhận

1. App gate kiểm tra `EffectiveAccess.isPlus`, trong khi Edge Function và product
   contract cho phép cả `plus` và `family_plus`. FamilyPlus bị đưa thẳng về màn
   hình nâng cấp và không bao giờ tới request AI.
2. `FoodScanImageService` chỉ giới hạn ảnh nguồn ở 5 MB và resize tối đa 1536px,
   nhưng không giới hạn kích thước JPEG cuối cùng. Ảnh chi tiết có thể vượt
   `food-scan-analyze` limit sau khi base64, nhận HTTP 413 rồi bị map thành lỗi
   chung ở app.

## Đã sửa

- Đổi Food Scan gate sang `hasPaidAccess`, đồng bộ với server Plus/FamilyPlus.
- Chuẩn hóa ảnh thành JPEG không EXIF/GPS và nén lặp quality/kích thước để file
  cuối không vượt 900.000 byte; ngân sách này nằm dưới giới hạn base64/request
  của Edge Function.
- Thêm dependency injection cho thư mục đích/thời gian để regression test không
  phụ thuộc path provider mặc định.
- Cập nhật copy lỗi/UI để nói rõ Plus hoặc FamilyPlus.
- Thêm regression test cho paid-access gate và ảnh JPEG đã chuẩn hóa.

## Triển khai

`food-scan-analyze` đã deploy lại vào project `rnwohifdnylqfofkydfl`, version 3,
trạng thái `ACTIVE`, `verify_jwt=true`.

## Giới hạn kiểm chứng

Đã xác minh auth boundary remote bằng request không auth và anon token. Chưa chạy
được success path remote bằng tài khoản Plus/FamilyPlus vì workspace không có
access token người dùng hợp lệ; không tạo user/membership giả trên production.
Flutter test/analyze chưa chạy được vì máy hiện không có Flutter/Dart SDK.
