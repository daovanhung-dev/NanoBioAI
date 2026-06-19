Commit đề xuất: docs(issue): ghi nhận lỗi ai chat đọc dotenv khi chưa khởi tạo

# AI Chat crash khi dotenv chưa được khởi tạo

## Tóm tắt
- `AIChatService(apiKeyOverride: '')` vẫn đọc `dotenv.env['GEMINI_API_KEY']`.
- Nếu service được khởi tạo trong môi trường test, background isolate, hoặc entrypoint chưa `dotenv.load()`, app ném `NotInitializedError` thay vì dùng local fallback.

## Mức độ ảnh hưởng
- Severity: high
- Ảnh hưởng user: màn chat AI có thể crash hoặc không mở được trong luồng khởi tạo lệch chuẩn.
- Ảnh hưởng dev/build/test: `flutter test` fail trước release 1.0.

## Cách tái hiện
1. Chạy `flutter test`.
2. Test `AIChatService missing API key does not crash and returns local fallback` fail.
3. Log lỗi:
   - `NotInitializedError: DotEnv has not been initialized`
   - `package:nano_app/services/ai/ai_chat_service.dart:57:32`

## Đã xác nhận
- `lib/services/ai/ai_chat_service.dart:54-58` đọc `dotenv.env` dù constructor đã nhận `apiKeyOverride`.
- `test/services/ai/ai_service_test.dart:405-414` kỳ vọng missing key không crash và trả fallback.

## Giả thuyết
- Logic `apiKeyOverride: ''` bị `_cleanEnv` chuyển thành `null`, sau đó rơi tiếp sang nhánh đọc `dotenv.env`.

## Workaround
- Đảm bảo luôn gọi `dotenv.load()` trước khi tạo `AIChatService`, kể cả test/background entrypoint.

## Hướng fix đề xuất
- Phân biệt `apiKeyOverride` được truyền với không được truyền.
- Nếu override là chuỗi rỗng thì coi là missing key hợp lệ và không đọc `dotenv.env`.
- Thêm test cho constructor khi dotenv chưa init.

## Files/log liên quan
- `lib/services/ai/ai_chat_service.dart`
- `test/services/ai/ai_service_test.dart`

## Liên kết
- Worklog: ../../worklog/2026-06-19/007-worklog-release-1-0-bug-audit.md
