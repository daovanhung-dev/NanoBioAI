Commit de xuat: fix(ui): sửa vòng đời hộp thoại liên hệ an toàn

# Bugfix — M31 thoát chỉnh sửa liên hệ an toàn

## Hiện tượng

Trên Android, sau khi mở chỉnh sửa liên hệ an toàn nhưng không lưu rồi quay lại,
màn hình có thể chuyển thành lỗi Flutter `_dependents.isEmpty`. Ảnh thiết bị chỉ
hiển thị assertion; stack trace cũ không có trong logcat.

## Điều tra và xử lý

- Form trước đây tạo các `TextEditingController` bên ngoài `showDialog`, sau đó
  giải phóng ngay khi Future của hộp thoại kết thúc. Vòng đời dữ liệu form vì thế
  phụ thuộc vào caller thay vì chính widget đang hiển thị các trường nhập.
- Chuyển form sang `StatefulWidget` riêng. Widget sở hữu controller và chỉ giải
  phóng chúng khi hộp thoại được dispose; chỉ nút **Lưu** mới trả bản nháp cho
  trang để gọi lưu. Hủy, Back và chạm ngoài đều không thay đổi liên hệ.
- Trong debug, tiếp tục ghi sự kiện lỗi đã được lọc và in stack trace cùng loại
  lỗi, không in nội dung exception hoặc context có thể chứa dữ liệu riêng tư.
- Giữ nguyên route hiện tại và trạng thái phiên giám sát bên dưới.

Stack trace tại thời điểm tái hiện ban đầu không được lưu nên chưa thể khẳng định
widget cụ thể gây assertion. Test hồi quy bao phủ việc đóng hộp thoại và route.

## Kiểm chứng

- Widget tests: Hủy, Back hệ thống, chạm ngoài, quay lại danh sách bằng mũi tên;
  xác nhận không có Flutter exception, liên hệ không đổi và trạng thái giám sát
  còn nguyên.
- Widget test lưu: bản nháp được gửi đến controller đúng một lần.
- Test logger: stack trace debug được giữ lại nhưng exception payload riêng tư
  không xuất hiện trong log.
- Build APK debug và cài bằng `adb install -r` trên Xiaomi 220333QPG / Android
  11. Sau khi mở lại app, ảnh màn hình là spinner khởi động; không thấy assertion
  hoặc `FATAL EXCEPTION`. Không thao tác được đến trang liên hệ trên thiết bị,
  nên nghiệm thu thủ công luồng sửa/quay lại còn chưa xác nhận.

Không đổi dữ liệu liên hệ, backend, schema hoặc API. Không dùng số QA của người
dùng trong test, log hay tài liệu.
