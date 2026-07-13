Commit de xuat: fix(ai): khoi phuc ket noi Gemini cho toan bo tac vu AI

# Fix kết nối Gemini cho toàn bộ tác vụ AI

## Triệu chứng

- Ứng dụng có `GEMINI_API_KEY` trong `.env` nhưng các tác vụ AI vẫn báo không thể kết nối hoặc chuyển sang fallback cục bộ.
- Chạy/build theo cách thông thường chỉ nhận cấu hình Auth công khai; khóa Gemini không được truyền vào Dart runtime.
- Lớp AI còn phụ thuộc SDK `google_generative_ai` cũ, trong khi khóa hiện tại cần được gửi theo cơ chế header của Gemini REST.

## Nguyên nhân gốc

1. `.env` không nằm trong Flutter assets vì yêu cầu bảo mật, nhưng launcher/build trước đó chỉ bắt buộc ba biến Auth và không chặn trường hợp thiếu `GEMINI_API_KEY`.
2. `AIService` và `AIChatService` dùng SDK Gemini cũ; đường xác thực này không tương thích ổn định với loại khóa hiện có.
3. Không có công cụ preflight để kiểm tra key/model thật trước khi chạy ứng dụng, nên lỗi chỉ xuất hiện khi người dùng bấm tác vụ AI.

## Cách sửa

- Thêm `GeminiRestClient` dùng endpoint `models/{model}:generateContent`.
- Gửi khóa duy nhất trong header `x-goog-api-key`; không đưa khóa vào URL, log hoặc tài liệu.
- Dùng chung client mới cho:
  - kiểm tra AI trong onboarding;
  - tạo thực đơn;
  - tạo bài tập/lịch vận động;
  - AI Chat Nabi.
- Giữ nguyên retry, đổi model, cooldown, validate JSON/Vietnamese và local fallback.
- Giới hạn lịch sử chat ở 16 message để không tăng context vô hạn.
- Bắt buộc `GEMINI_API_KEY` trong `tools/run_v2.ps1` và `tools/build_authenticated.ps1`.
- Thêm VS Code launch profile truyền `.env` bằng `--dart-define-from-file`.
- Thêm `tools/test_gemini_connection.ps1` để kiểm tra key/model thật và tự thử model tiếp theo mà không in khóa.
- Loại bỏ dependency `google_generative_ai` đã không còn sử dụng.

## File chính

- `lib/app_versions/v1/services/ai/gemini_rest_client.dart`
- `lib/app_versions/v1/services/ai/ai_service.dart`
- `lib/app_versions/v1/services/ai/ai_chat_service.dart`
- `lib/app_versions/v1/services/ai/ai_exceptions.dart`
- `tools/run_v2.ps1`
- `tools/build_authenticated.ps1`
- `tools/test_gemini_connection.ps1`
- `.vscode/launch.json`

## Regression tests

- Client chấp nhận loại khóa hiện tại và gửi đúng header `x-goog-api-key`.
- Ghép nhiều text part trong response.
- Phân loại 429/5xx là transient và không lộ khóa trong exception.
- Onboarding connection check đi qua REST client chung.
- Chat gửi system instruction và giữ lịch sử hội thoại có giới hạn.
- Launcher/build contract bắt buộc Auth + AI config.

## Rủi ro còn lại

- Môi trường sửa code không có Flutter/Dart/PowerShell nên chưa chạy được analyzer, Flutter test hoặc APK build.
- Kết nối thật tới Gemini bị chặn ở bước DNS của sandbox; đã thêm preflight để chạy ngay trên máy Windows có mạng.
- Không claim production smoke hoàn tất cho tới khi chạy `tools/test_gemini_connection.ps1`, targeted Flutter tests và smoke trên thiết bị thật.
