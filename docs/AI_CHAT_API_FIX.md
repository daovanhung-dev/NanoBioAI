# NanoBio — Fix kết nối AI Chat

## Nguyên nhân đã xác định

Màn hình AI Chat hiển thị thông báo “Nabi chưa sẵn sàng trò chuyện AI” khi
`AIChatService` không nhận được `GEMINI_API_KEY` ở runtime. File `.env` đặt tại
root dự án không tự xuất hiện trong APK; chạy `flutter run` hoặc build APK mà
không truyền Dart define sẽ làm cấu hình Gemini bị thiếu dù `.env` có dữ liệu.

## Cách chạy đúng trên Windows

Đặt `.env` tại root dự án, sau đó chạy:

```powershell
powershell -ExecutionPolicy Bypass -File tools/test_gemini_connection.ps1
powershell -ExecutionPolicy Bypass -File tools/run_ai_chat.ps1
```

Chạy trên thiết bị cụ thể:

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_ai_chat.ps1 -DeviceId 220333QPG
```

Script sẽ:

1. Đọc và chuẩn hóa `.env`, kể cả dòng có khoảng trắng quanh dấu `=`.
2. Kiểm tra `GEMINI_API_KEY` mà không in giá trị ra terminal.
3. Tạo `.dart_tool/nanobio_defines.json` ngoài source control.
4. Chạy Flutter với `--dart-define-from-file`.

## Build APK có cấu hình Gemini

```powershell
powershell -ExecutionPolicy Bypass -File tools/build_ai_chat_apk.ps1 -Mode debug
```

APK debug nằm tại đường dẫn build mặc định của Flutter. Không dùng trực tiếp:

```powershell
flutter build apk --debug
```

Lệnh trực tiếp phía trên không truyền API key vào runtime và sẽ tái hiện bug.

## Xử lý lỗi sau bản sửa

| Trạng thái | Thông báo ứng dụng |
|---|---|
| Thiếu cấu hình runtime | Nabi chưa sẵn sàng trò chuyện AI |
| API key bị từ chối | Khóa AI chưa hợp lệ |
| Mất mạng/TLS/timeout kết nối | Không thể kết nối với AI |
| Model không tồn tại hoặc bị thu hồi | Mô hình AI hiện chưa khả dụng |
| Quota/429/5xx | AI đang quá tải |
| Response rỗng hoặc không hợp lệ | Nabi chưa nhận được câu trả lời phù hợp |

Model chính lấy từ `GEMINI_CHAT_MODEL`, sau đó dùng `GEMINI_MODEL` để tương
thích cấu hình cũ. Fallback mặc định là `gemini-3.5-flash` và
`gemini-3.1-flash-lite`; model trùng lặp được loại bỏ.

## Bảo mật

- Không đóng gói `.env` thật trong ZIP bàn giao.
- Không thêm `.env` vào Flutter assets.
- Không hard-code API key trong Dart.
- Không log API key, raw prompt hoặc raw response.
- API key đã từng chia sẻ qua hội thoại nên cần thu hồi và tạo khóa mới trước
  khi phát hành cho người dùng thực.
