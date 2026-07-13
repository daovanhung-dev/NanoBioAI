Commit de xuat: fix(ai): hien thi loi Gemini authentication key ro rang

# Fix lỗi Gemini Authentication Key sau onboarding

## Triệu chứng

- Hoàn tất onboarding nhưng lịch trình AI không được tạo.
- Ứng dụng chỉ hiển thị thông báo lỗi chung.

## Nguyên nhân xác nhận

- Preflight gọi được Gemini endpoint nhưng trả `401 UNAUTHENTICATED` với reason `ACCESS_TOKEN_TYPE_UNSUPPORTED`.
- Cấu hình local đang dùng credential dạng `AQ...`; credential này không được endpoint Gemini REST hiện tại chấp nhận như API key traffic.

## Cách sửa trong app

- Nhận diện lỗi HTTP 401/403 và trạng thái `UNAUTHENTICATED`/`PERMISSION_DENIED`.
- Hiển thị hướng dẫn an toàn để cập nhật Gemini API key hợp lệ thay vì thông báo thất bại chung.
- Sửa preflight để chạy hết danh sách model và báo mã HTTP thật.

## Giới hạn

- Không thể biến credential `AQ...` thành API key hợp lệ từ phía Flutter.
- Cần tạo/cấu hình credential Gemini được endpoint chấp nhận rồi rebuild app qua launcher.
