# NanoBio AI Chat — runtime configuration

## Root cause

`AIChatService` chỉ tạo Gemini REST client khi `AppEnv` resolve được
`GEMINI_API_KEY`. Nếu key bị thiếu, UI nhận
`AIConfigurationUnavailableException` và hiển thị:

> Nabi chưa sẵn sàng trò chuyện lúc này. Bạn thử lại sau một chút nhé.

`.env` tại root dự án không được đóng gói thành Flutter asset. Trước bản vá
này, Android native fallback chỉ điền `BuildConfig.GEMINI_API_KEY` cho build
`debug`; `profile`/`release` giữ chuỗi rỗng khi chạy/build trực tiếp mà không
truyền Dart define. Gradle cũng dùng `Properties.load`, trong khi các script
của dự án chấp nhận dotenv dạng `export KEY=value`, BOM và quoted values.
Những format đó có thể làm native fallback không tìm thấy key dù `.env` có
cấu hình.

## Sau bản vá

Android resolve private Gemini runtime config theo thứ tự:

1. Gradle property `GEMINI_API_KEY`.
2. Process environment `GEMINI_API_KEY`.
3. File local, untracked `.env` ở root repository.

Giá trị fallback được đưa vào `BuildConfig` cho mọi Android build type
(debug/profile/release). `AppEnv` vẫn ưu tiên `--dart-define`, vì vậy các
script canonical không đổi hành vi. `.env` không được thêm vào Flutter assets,
không được commit và giá trị key không được log.

## Chạy trên Windows

Khuyến nghị tiếp tục dùng script canonical:

```powershell
powershell -ExecutionPolicy Bypass -File tools/test_gemini_connection.ps1
powershell -ExecutionPolicy Bypass -File tools/run_ai_chat.ps1
```

Hoặc app runtime chuẩn:

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1
```

Build APK bằng script AI Chat:

```powershell
powershell -ExecutionPolicy Bypass -File tools/build_ai_chat_apk.ps1 -Mode debug
```

Sau bản vá, plain Android `flutter run`, `flutter run --profile`,
`flutter run --release` và `flutter build apk` cũng có native fallback nếu
Gradle/environment/local `.env` cung cấp `GEMINI_API_KEY`.

Sau khi thay đổi `.env`, cần **stop app và rebuild**, không chỉ hot reload,
vì `BuildConfig` được tạo ở build time.

## Gemini transport

- Endpoint: Gemini REST `models/{model}:generateContent`.
- Authentication: header `x-goog-api-key`.
- Model chính: `GEMINI_CHAT_MODEL`, fallback tương thích là `GEMINI_MODEL`.
- Chat history: tối đa 16 message đã xác nhận.
- Không thêm response vào context nếu request/quota commit thất bại.
- Automated tests dùng fake transport; không gọi Gemini thật.
