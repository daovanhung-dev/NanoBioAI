Commit đề xuất: fix(ai-chat): thêm retry và fallback cho AI chat

# Worklog - AI chat retry

## Thời gian
- Ngày: 2026-06-19
- Bắt đầu: Không xác định trong phiên Codex
- Kết thúc: 2026-06-19 12:36:37 +07:00
- Timezone: Asia/Saigon

## Phạm vi
- Loại task: fix
- Module chính: AI chat
- Yêu cầu gốc: Tạo retry cho AI chat, đảm bảo luôn trả về kết quả và ưu tiên model rẻ.

## Đã làm
- Cập nhật AI chat dùng danh sách model thay vì một model cố định.
- Đặt mặc định chat về `gemini-3.1-flash-lite`, fallback rẻ mặc định là `gemini-2.5-flash-lite`.
- Thêm retry/failover theo model, timeout từng attempt, cooldown model lỗi tạm thời và backoff ngắn.
- Khi thiếu API key hoặc toàn bộ attempt lỗi, service trả fallback local tiếng Việt thay vì crash.
- Giảm log dữ liệu nhạy cảm bằng cách ghi `messageLength`, model, attempt, source và reason thay vì raw message/raw response.
- Thêm test fake generator cho AI chat để không gọi Gemini thật.

## File code/docs đã sửa
- `lib/services/ai/ai_chat_service.dart` - sửa - thêm retry/failover/fallback và model candidates riêng cho chat.
- `test/services/ai/ai_service_test.dart` - sửa - thêm unit test cho AI chat retry/fallback/stream.
- `docs/worklog/2026-06-19/003-worklog-ai-chat-retry.md` - tạo - ghi nhận phiên sửa AI chat.

## Tài liệu liên quan
- Không phát sinh docs feature/fixbug/test/issue riêng.

## Commands
- `dart format lib\services\ai\ai_chat_service.dart test\services\ai\ai_service_test.dart`: FAIL - timeout sau 120-180 giây.
- `dart --version`: FAIL - timeout sau 30 giây, cho thấy Dart tool đang bị treo ngoài phạm vi code.
- `flutter test test\services\ai`: FAIL - timeout sau 240 giây, cùng nhóm lỗi môi trường Dart/Flutter đang treo.
- `Get-Process | Where-Object { $_.ProcessName -match 'dart|flutter' }`: PASS - phát hiện nhiều process Dart/Dart AOT còn chạy.
- `Stop-Process -Id 12980,16704,6312,20028,9728 -Force`: PASS - dừng các process phát sinh từ lệnh timeout trong phiên.
- `Stop-Process -Id 12668,11480 -Force`: PASS - dừng thêm process phát sinh từ lần thử lại.

## Lỗi/Rủi ro
- Đã fix: AI chat không còn phụ thuộc một model duy nhất và có fallback local khi AI/API không sẵn sàng.
- Chưa fix: Chưa xác nhận được bằng `flutter test` vì Dart/Flutter tool timeout ngay cả với `dart --version`.
- Cần kiểm tra tiếp: Chạy lại `dart format`, `flutter analyze`, `flutter test test/services/ai` sau khi xử lý các process Dart/Flutter cũ hoặc restart môi trường dev.
