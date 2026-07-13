# NanoBio AI connection

## Cấu hình

Giữ khóa thật trong `.env` tại root dự án. Không thêm `.env` vào assets hoặc
commit lên Git. Các biến tối thiểu:

```env
SUPABASE_URL=https://...
SUPABASE_ANON_KEY=...
AUTH_EMAIL_REDIRECT_URL=nanobio://auth/callback
GEMINI_API_KEY=...
GEMINI_BASE_URL=https://generativelanguage.googleapis.com/v1beta
GEMINI_MODEL=gemini-3.5-flash
ONBOARDING_AI_DEV_CHECK_ENABLED=true
```

Lớp AI dùng Gemini REST `generateContent` và gửi khóa bằng header
`x-goog-api-key`; không dùng query string và không ghi khóa ra log.

## Kiểm tra trên Windows

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1 -ValidateOnly
powershell -ExecutionPolicy Bypass -File tools/test_gemini_connection.ps1
powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1
```

Trong VS Code, dùng các profile `NanoBio - App (Auth + AI)`,
`NanoBio - V2 App (Auth + AI)` hoặc `NanoBio - Admin (Auth + AI)`. CodeLens
Run/Debug tại từng entrypoint cũng dùng cùng profile qua `templateFor`. Mỗi lần
chạy, pre-launch task tạo `.dart_tool/nanobio_defines.json` từ `.env`; cả hai
file đều nằm ngoài Git và script không in giá trị bí mật.

Nếu runtime vẫn thiếu Gemini config, AI Chat ném typed failure và hiển thị
banner để người dùng biết dịch vụ chưa sẵn sàng. Trường hợp này không retry,
không trả fallback local và không commit quota.

## Build

```powershell
powershell -ExecutionPolicy Bypass -File tools/build_authenticated.ps1
```

Launcher terminal chuẩn là `tools/run_v2.ps1`. Khi cần chạy Flutter trực tiếp
để chẩn đoán, hãy tạo defines trước rồi dùng file tạm:

```powershell
powershell -ExecutionPolicy Bypass -File tools/prepare_dart_defines.ps1
flutter run -t lib/main.dart --dart-define-from-file=.dart_tool/nanobio_defines.json
```
