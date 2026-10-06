Commit de xuat: fix(android): ask runtime permissions at app entry

# Fixbug — Yêu cầu quyền runtime khi mở Nabi trên Android

## Hiện tượng

- Trên Android, quyền `CALL_PHONE` chưa được yêu cầu khi người dùng mở Nabi.
- Người dùng chỉ gặp yêu cầu quyền trong luồng bắt đầu giám sát, nên không thấy
  hộp thoại quyền gọi ở thời điểm mong muốn.

## Nguyên nhân

- `BioAIApp` chưa theo dõi lifecycle và chưa có bước kiểm tra quyền tập trung ở
  app root. Quyền gọi, micro, camera và thông báo được xin rải rác theo tính năng.

## Sửa đổi

- Thêm bộ điều phối quyền runtime Android và chạy lúc app mở, cũng như khi app
  quay lại foreground. Yêu cầu tuần tự quyền gọi điện, micro, thông báo và máy
  ảnh còn thiếu; quyền đã cấp không bị hỏi lại.
- Gộp các lượt kiểm tra đang chạy để sự kiện resume do hộp thoại hệ thống không
  mở lặp yêu cầu quyền.
- Khi quyền bị từ chối vĩnh viễn, hiện hướng dẫn không chặn app với nút mở Cài
  đặt. Quyền báo thức chính xác vẫn theo luồng tính năng.
- Giữ nguyên luồng M31 `ACTION_CALL` khi được cấp quyền và mở trình gọi điền số
  sẵn nếu khởi tạo gọi trực tiếp không thực hiện được.

## Kiểm chứng

- Test bộ điều phối bao phủ quyền thiếu/đã cấp, từ chối thường/vĩnh viễn, nhiều
  lần gọi kiểm tra đồng thời và nền tảng không phải Android.
- Test app root bao phủ kiểm tra khi resume và hướng dẫn mở Cài đặt.
- Trên Xiaomi Android 11, bản APK debug được cài bằng `adb install -r`; khi mở
  app, Android hiện hộp thoại xin quyền gọi điện trước khi vào luồng giám sát.
- Sau hộp thoại, package manager báo `CALL_PHONE`, `CAMERA` và `RECORD_AUDIO` đã
  cấp; `MainActivity` đang ở foreground.
- Cuộc gọi trợ giúp không được lặp lại trong lượt này vì contact QA tạm đã được
  dọn ở lượt M31 trước.

## Giới hạn

- Hộp thoại quyền do Android điều khiển; quyền bị từ chối vĩnh viễn phải được
  bật trong Cài đặt.
- Việc mở trình gọi hoặc khởi tạo `ACTION_CALL` không chứng minh cuộc gọi đã
  kết nối.
