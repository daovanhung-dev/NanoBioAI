# Fixbug - Tạo lộ trình AI trên điện thoại

## Triệu chứng

- App Android `1.0.2+7` không hoàn tất lộ trình cá nhân 7 ngày.
- Lần chẩn đoán đầu không có `POST /api/v1/ai/generate`.
- Lần kiểm tra sau khi thêm chẩn đoán an toàn ghi nhận lỗi SQLite trước khi vào vòng gọi AI.

## Nguyên nhân được xác nhận

- Thiết bị trả `SqfliteDatabaseException`, SQLite result code `787`, tại lệnh ghi metadata trong `prepareStaging`.
- Bản ghi request cha được tạo ở thao tác trước, tách khỏi transaction ghi staging. Khi khóa ngoại không còn thấy bản ghi cha, staging không thể được ghi và app dừng trước request AI.
- Cảnh báo Android `CursorWindow` xuất hiện cùng khoảng thời gian nhưng stack trace lỗi không trỏ tới truy vấn danh mục; không dùng cảnh báo đó làm kết luận nguyên nhân.
- Sau khi sửa staging, log backend ghi nhận các request AI `200`, `413` và `429`. `429` xác nhận giới hạn theo user đang ở 6 request/phút không đủ cho luồng 7 ngày. `413` được giữ lại làm bằng chứng riêng; các request này không được tính là thành công.

## Thay đổi trong source

- Tạo/upsert request cha bên trong cùng transaction với `prepareStaging`, rồi mới ghi metadata staging.
- Thêm `X-Trace-Id` và log an toàn cho các endpoint AI: method, path, trace ID, thời lượng, status, business code, server trace ID hoặc loại lỗi mạng. Không log token, body, prompt, dữ liệu sức khỏe hay nội dung AI.
- Client dừng ngay khi gặp rate limit và trả lỗi `AIRateLimitedException`, không thử lần lượt các model rồi gửi thêm request dồn dập.
- Nâng mặc định `OLLAMA_TECHNICAL_REQUESTS_PER_MINUTE` trong source backend và `.env.example` từ 6 lên 30; test kiểm tra 30 request được nhận và request tiếp theo bị giới hạn.

## Kiểm chứng

- Focused Flutter suite: 127 test pass, gồm staging, tạo lộ trình, rate-limit client, trace header và onboarding.
- Backend rate-limit test: pass.
- `flutter analyze` trên 13 file Dart: không có issue.
- `ruff check` trên hai file backend: pass.
- `flutter build apk --debug`: pass.
- Trên điện thoại, sau thay đổi staging, progress đạt 11/77 sự kiện đã lưu; backend nhận request AI nhưng trả `429`, nên lộ trình 7 ngày chưa hoàn tất.

## Chưa xác nhận trên runtime

- Chưa đổi biến môi trường trên server đang chạy và chưa restart `nanobio-backend`. Kết nối SSH tự động từ máy phát triển trả `Permission denied (publickey,password)`; không có SSH identity khả dụng trong agent.
- APK mới đã build nhưng chưa cài lên điện thoại.
- Chưa xác nhận lộ trình đủ 77 sự kiện, đủ 7 ngày, cũng chưa thu được cặp trace ID/status từ app và server cho một lượt hoàn tất.

## Bước tiếp theo

1. Khôi phục một phiên SSH đã xác thực hoặc nạp SSH key được cấp vào agent.
2. Trên server, đặt `OLLAMA_TECHNICAL_REQUESTS_PER_MINUTE=30` và restart service hiện tại.
3. Cài APK bằng `adb install -r` để giữ dữ liệu ứng dụng, rồi tiếp tục request đang có staging.
4. Xác nhận progress 77/77, đủ 7 ngày đã lưu/hiển thị, status thành công có trace ID ở app/server và request tới Ollama.
