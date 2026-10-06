Commit đề xuất: fix(m31): tách loading gọi chủ động khỏi dispatch tự động

# Fixbug — Nabi kẹt loading khi người dùng cần trợ giúp

## Hiện tượng

- Khi người dùng bấm “Tôi cần hỗ trợ”, overlay có thể tiếp tục hiển thị spinner
  “Nabi đang liên hệ người hỗ trợ…” thay vì chuyển sang giao diện cuộc gọi.
- Khi `phone_fallback_enabled` tắt, nhánh trợ giúp trả về trước khi mở cuộc gọi.
- Trạng thái `escalating` được dùng chung cho cả dispatch tự động và cuộc gọi
  chủ động; nhánh gọi chủ động không luôn kết thúc trạng thái đó sau handoff.

## Sửa đổi

- Thêm pha `manualHelp` riêng trong state machine. Pha này giữ cảnh báo có thể
  thao tác và không tự chuyển sang dispatch sau mốc 60 giây.
- Nút “Tôi cần hỗ trợ” gọi liên hệ an toàn đang hoạt động, đã bật quyền gọi và
  có số E.164 hợp lệ theo thứ tự ưu tiên, kể cả khi cờ gọi tự động đang tắt.
- Khi Android cho phép, dùng `CALL_PHONE`; nếu quyền bị từ chối hoặc khởi tạo
  trực tiếp thất bại, mở trình gọi có số điền sẵn. Không gọi dispatch máy chủ
  cho thao tác chủ động.
- Khi hệ điều hành nhận yêu cầu khởi tạo/mở cuộc gọi, đóng overlay loading và
  chỉ ghi nhận handoff, không tuyên bố cuộc gọi đã kết nối.
- Nếu thiếu liên hệ hoặc cả hai cách mở cuộc gọi thất bại, giữ cảnh báo, kết
  thúc loading và hiển thị nút thử lại/mở danh bạ. Kết quả gọi cũ bị ngắt giữa
  chừng được phục hồi thành trạng thái cần xử lý, không giữ spinner vô hạn.
- Giới hạn thời gian chờ acknowledgement, lưu event best-effort và khởi tạo
  native để chúng không thể giữ thao tác gọi chủ động ở trạng thái loading vô
  thời hạn.
- Cập nhật copy để phân biệt gọi tự động khi không phản hồi với thao tác gọi
  chủ động.

## Kiểm chứng

- Flutter controller, UI và state-machine tests: **27/27 PASS**.
- Deno dispatch/provider tests: **7/7 PASS**; luồng không phản hồi tiếp tục các
  kênh voice/SMS hiện có và lượt trợ giúp chủ động không đi qua server dispatch.
- `flutter analyze --no-pub` trên 8 file liên quan: **PASS**, không có issue.
- `flutter build apk --debug --no-pub`: **PASS**; APK cài bằng `adb install -r`
  lên Xiaomi 220333QPG Android 11, giữ dữ liệu ứng dụng.
- Ứng dụng process chạy foreground, logcat không có lỗi Flutter/fatal mới.
  Ảnh chụp fresh sau khi mở app hiển thị nền đen, nên chưa thao tác được nút và
  **chưa xác minh cuộc gọi thật trên máy**.
- Không thay đổi cấu hình QA/production, dữ liệu liên hệ hoặc backend.

## Giới hạn

- Khởi tạo `ACTION_CALL`/mở trình gọi không chứng minh người nhận đã bắt máy.
- Nghiệm thu tương tác trên thiết bị còn pending; hiện chưa có bằng chứng cuộc
  gọi thật của build này.
