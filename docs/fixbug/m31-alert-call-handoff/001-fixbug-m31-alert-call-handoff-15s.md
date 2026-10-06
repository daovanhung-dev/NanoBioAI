Commit de xuat: fix(m31): tat chuong sau khi ban giao goi va cho 15 giay

# Fixbug — Chuông M31 sau bàn giao cuộc gọi và thời hạn phản hồi

> Cập nhật 2026-10-06: timeout 15 giây bàn giao cuộc gọi cục bộ cho liên hệ đã
> lưu, không phụ thuộc cờ runtime phía server. Kết quả kiểm chứng gốc phía dưới
> là lịch sử của lần sửa handoff trước; bằng chứng hiện tại nằm trong worklog
> M31 mới nhất.

## Hiện tượng / yêu cầu

- Sau khi người dùng chọn **Tôi cần hỗ trợ**, cảnh báo âm thanh và notification
  không được giữ lại khi hệ điều hành đã nhận yêu cầu mở cuộc gọi.
- Lỗi mở `ACTION_CALL`, trình gọi `ACTION_DIAL` hoặc `tel:` phải để cảnh báo
  tiếp tục hoạt động để người dùng thử lại.
- Thời hạn không phản hồi trước escalation voice/SMS còn 60 giây và có nhắc ở
  giây 30; yêu cầu mới đổi thành 15 giây và bỏ nhắc trung gian.

## Sửa đổi

- Đồng bộ bộ đếm Flutter và timer native Android/iOS về 15 giây; bỏ pha và sự
  kiện nhắc lại ở giây 30. Phản hồi rõ ràng vẫn hủy timer.
- Android chỉ dừng tone, hủy notification cảnh báo và timer sau khi
  `ACTION_CALL` hoặc `ACTION_DIAL` được `startActivity` chấp nhận.
- iOS chỉ xóa cảnh báo sau callback `tel:` thành công. Lỗi bàn giao không xóa
  notification hoặc âm báo hiện có.
- Giữ phiên giám sát và event hiện tại sau handoff; state chỉ ghi nhận yêu cầu
  gọi được khởi tạo/bàn giao, không xác nhận đã kết nối hoặc có người bắt máy.
- Thao tác **Tôi cần hỗ trợ** và timeout 15 giây đều dùng contact ưu tiên cao
  nhất đủ điều kiện, không gọi server dispatch và không phụ thuộc
  `phone_fallback_enabled`.
- Cập nhật BD M31 v1.3, DD hiện hành, changelog, checklist và worklog.

## Cập nhật hợp đồng timeout 15 giây — 2026-10-06

- Timeout native và trạng thái snapshot `escalating` dùng chung luồng gọi local
  qua gateway; chọn liên hệ đang hoạt động có quyền nhận cuộc gọi theo ưu tiên.
- Tự gọi khi không phản hồi sau 15 giây nếu có liên hệ đã lưu đang hoạt động và
  đồng ý nhận cuộc gọi. Android ưu tiên `ACTION_CALL` khi có quyền, nếu không
  thì mở trình gọi; iOS bàn giao `tel:`. Thiếu liên hệ hoặc lỗi handoff giữ
  cảnh báo và hướng dẫn thao tác thủ công.
- Thành công bàn giao chỉ ghi nhận hệ điều hành nhận yêu cầu, giữ phiên giám sát
  và tắt chuông/thông báo. Event ID cùng trạng thái local ngăn timeout hoặc
  snapshot lặp gọi lần hai; trạng thái `starting` sau khôi phục không tự retry.
- Timeout không gọi Edge dispatch, không tạo retry backend, không thêm API,
  enum `escalation_status` hay thay đổi schema. Retry cũ no-response được đánh
  dấu dừng tại máy.
- Test hiện tại: controller 23/23 và UI/native contract 16/16 PASS; analyze
  đang được chạy lại sau khi dọn import. Không thực hiện cuộc gọi thật; iOS
  physical-device acceptance chưa có.

## Điều chỉnh sau ảnh kiểm thử — 2026-10-06

- Ảnh thiết bị cho thấy runtime flag mặc định tắt đang chặn luồng timeout.
- Bỏ flag khỏi chọn liên hệ, cấu hình timer native và copy giao diện; liên hệ
  ưu tiên có consent vẫn được gửi cho bộ đếm local.
- Không thay đổi schema/API hoặc cấu hình server. Controller regression test
  xác nhận timeout gọi local dù fake runtime flag là `false`.

## Kiểm chứng

- State-machine, controller, UI và native-contract Flutter suite: **47/47 PASS**.
- Flutter analyzer trên 10 file Dart liên quan: **PASS**, 0 issue.
- `flutter build apk --debug --no-pub`: **PASS**.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk`: **PASS**, thiết
  bị `220333QPG`, Android 11; dữ liệu ứng dụng được giữ lại.
- Ảnh mới sau khi mở activity còn nền đen. Không thấy `FATAL EXCEPTION`,
  `E/flutter`, `FlutterError` hay `PlatformException` mới trong logcat đã lọc.
  Không thể thao tác vào màn M31 để xác nhận trạng thái chuông/dialer bằng tay.
- Không bấm nút Gọi, không phát sinh cuộc gọi, không thay đổi liên hệ hoặc
  cấu hình QA/production trong lượt này.
- iOS được rà source và contract; không có Xcode/iPhone để build hoặc nghiệm
  thu thiết bị trong môi trường này.

## Giới hạn

- Android/iOS nhận yêu cầu mở giao diện điện thoại không bảo đảm cuộc gọi kết
  nối. Quyền, SIM, mạng, nhà mạng và người nhận vẫn quyết định kết quả.
- Nghiệm thu tương tác trên Xiaomi còn pending do app hiển thị nền đen sau cài
  bản debug; cần đưa app vào màn M31 rồi xác nhận chuông tắt khi giao diện gọi
  xuất hiện, không bấm Call.
