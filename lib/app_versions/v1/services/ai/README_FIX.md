# NanoBio AI Chat — runtime configuration

## Root cause

`.env` tại root dự án không tự được đóng gói vào APK. Khi ứng dụng được chạy
hoặc build mà không truyền Dart define, `AppEnv` không nhận được
`GEMINI_API_KEY` và AI Chat trả về trạng thái cấu hình chưa sẵn sàng.

## Chạy trên Windows

```powershell
powershell -ExecutionPolicy Bypass -File tools/test_gemini_connection.ps1
powershell -ExecutionPolicy Bypass -File tools/run_ai_chat.ps1
```

Chạy trên thiết bị cụ thể:

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_ai_chat.ps1 -DeviceId 220333QPG
```

Build APK:

```powershell
powershell -ExecutionPolicy Bypass -File tools/build_ai_chat_apk.ps1 -Mode debug
```

Các script đọc `.env`, tạo file tạm
`.dart_tool/nanobio_defines.json`, rồi truyền file này bằng
`--dart-define-from-file`. Giá trị bí mật không được in ra terminal và không
được đưa vào ZIP bàn giao.

## Gemini transport

- Endpoint: Gemini REST `models/{model}:generateContent`.
- Authentication: header `x-goog-api-key`.
- Model chính: `GEMINI_CHAT_MODEL`, fallback tương thích là `GEMINI_MODEL`.
- Fallback mặc định: `gemini-3.5-flash`, `gemini-3.1-flash-lite`.
- Chat history: tối đa 16 message đã xác nhận.
- Không thêm response vào context nếu request/quota commit thất bại.

Xem `docs/AI_CHAT_API_FIX.md` để biết ma trận lỗi và hướng dẫn chi tiết.
