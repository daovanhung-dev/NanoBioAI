Commit đề xuất: docs(issue): ghi nhận lỗi log raw prompt và raw response AI

# AI service log raw prompt, raw response và hồ sơ sức khỏe

## Tóm tắt
- AI service đang log prompt gốc, raw response, decoded JSON và `healthData` khi tạo meal/exercise plan hoặc check connection.
- Playbook AI yêu cầu log AI chỉ ghi summary an toàn, không log raw prompt/raw response dài.

## Mức độ ảnh hưởng
- Severity: high
- Ảnh hưởng user: prompt có thể chứa tên, mục tiêu, tình trạng sức khỏe, thói quen, mối quan tâm.
- Ảnh hưởng dev/build/test: log dài làm chậm debug/test, tăng I/O, khó đọc lỗi thật.

## Cách tái hiện
1. Chạy `flutter test`.
2. Quan sát log `AI_SERVICE` in `PROMPT_SENT`, `RAW_RESPONSE`, `DECODED_JSON`.
3. Test `meal generation logs trace, prompt, raw response, and AI source` còn khẳng định behavior này.

## Đã xác nhận
- `lib/services/ai/ai_service.dart:283-289` log `userId` và `healthData`.
- `lib/services/ai/ai_service.dart:325-331` log `MEAL_CHUNK_PROMPT_ORIGINAL`.
- `lib/services/ai/ai_service.dart:887-905` log prompt và raw response cho text generator.
- `lib/services/ai/ai_service.dart:920-926` log raw response từ Gemini.
- `lib/services/ai/ai_trace_logger.dart:114-148` chunk log payload dài theo 3500 ký tự.
- `test/services/ai/ai_service_test.dart:466-497` đang kỳ vọng log chứa raw response.

## Giả thuyết
- Trace logging được thêm để debug AI generation nhưng chưa được hạ xuống summary trước release.

## Workaround
- Tắt log ở build release bằng cấu hình ngoài code nếu có thể.

## Hướng fix đề xuất
- Chỉ log summary: traceId, method, model, count, source, error type, prompt length, response length.
- Không log raw prompt, raw response, `healthData`, userId thật.
- Cập nhật test để kỳ vọng log an toàn thay vì raw payload.

## Files/log liên quan
- `lib/services/ai/ai_service.dart`
- `lib/services/ai/ai_trace_logger.dart`
- `test/services/ai/ai_service_test.dart`

## Liên kết
- Worklog: ../../worklog/2026-06-19/007-worklog-release-1-0-bug-audit.md
