Commit de xuat: fix(m31): huong dan khoi phuc khi chua xac minh lien he

# Fix bug — Khôi phục hỗ trợ khi chưa có liên hệ xác minh

## Hiện tượng và nguyên nhân

- Alert hiển thị `verified_contact_required` vì danh sách không có contact đã
  xác minh. “Thử gửi lại” gọi lại cùng luồng dispatch nên không thể khắc phục
  điều kiện này.
- Mã dispatch exception trước đó chỉ được chuyển thành chuỗi giao diện, làm
  widget không phân biệt được lỗi cấu hình liên hệ với lỗi mạng/provider.
- Nút gọi thủ công chỉ xuất hiện khi contact đã xác minh, contact cho phép gọi
  và runtime flag `phone_fallback_enabled` bật. Staging lần gần nhất được đọc
  chỉ có cờ này tắt.

## Sửa

- Controller giữ lỗi dispatch có kiểu; khi thiếu contact xác minh, cảnh báo mở
  danh bạ để người dùng xác minh thay vì hiển thị nút retry vô ích.
- Sau khi tải lại và thấy contact đã xác minh, cảnh báo vẫn mở và cho phép người
  dùng chủ động thử dispatch lại.
- Thẻ trạng thái cho phép giám sát cục bộ nhưng cảnh báo khi không có contact xác
  minh; khi cờ gọi tắt, giao diện nói rõ gọi trực tiếp đang tạm dừng.
- Giữ contact verified-only và server kill switch. Không đổi schema/RPC/flag,
  không ghi dữ liệu QA, không gửi OTP, mở dialer hay thực hiện cuộc gọi.

## Kiểm chứng

- M31 focused Flutter tests: 40/40 PASS, gồm controller recovery, alert/status UI,
  repository, access gate, state machine, Android call contract, SQLite v26 và
  Supabase contract.
- Targeted Flutter analyzer trên controller, page, widgets và tests: 0 issue.
- `flutter build apk --debug --no-pub`: PASS; APK được build cục bộ, chưa cài lên
  thiết bị.
- Thiết bị Android/UI acceptance chưa chạy; shell input vẫn bị chặn bởi
  `INJECT_EVENTS`. Cờ staging/production giữ nguyên.
