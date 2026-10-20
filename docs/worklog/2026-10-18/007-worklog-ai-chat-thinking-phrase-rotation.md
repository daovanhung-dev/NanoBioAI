Commit de xuat: docs(worklog): ghi nhan xoay vong cau suy nghi

# Worklog - Xoay vòng câu suy nghĩ cho Nabi Chat

## Thời gian

- Ngày: 2026-10-18
- Bắt đầu: khoảng 21:20
- Kết thúc: 21:34
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: tính năng giao diện và trạng thái AI Chat
- Module chính: M05 AI / AI Chat / SharedPreferences
- Yêu cầu gốc: thêm 100 câu suy nghĩ luân phiên, lưu vị trí trên thiết bị, retry dùng lại câu và ẩn câu sau token đầu tiên.

## Đã làm

- Thêm đúng 100 câu tiếng Việt theo thứ tự đã yêu cầu; test xác nhận số lượng và tính duy nhất.
- Lưu chỉ số kế tiếp trong SharedPreferences, xoay từ câu 100 về câu 1 và tiếp tục trong bộ nhớ phiên nếu đọc/ghi tùy chọn lỗi.
- Gắn câu đã chọn vào state của lượt chat; tin nhắn mới hợp lệ tăng chỉ số kể cả khi lỗi, retry tái sử dụng câu cũ, xóa lịch sử không reset chỉ số.
- Hiển thị câu cạnh vòng chờ tới token đầu tiên; bọc văn bản trong vùng co giãn để tránh tràn ở màn hình hẹp và cỡ chữ lớn.
- Bỏ hàng đợi Future tĩnh gây kẹt qua các lượt test; cursor được tăng đồng bộ trước khi chờ ghi tùy chọn.
- Thêm test danh sách, xoay vòng, lưu chỉ số, gọi đồng thời, lỗi/retry, xóa lịch sử và giao diện stream.
- Cập nhật tài liệu tính năng và worklog.

## File code/docs đã sửa

- `lib/app_versions/v1/features/ai_chat/presentation/ai_chat_thinking_phrases.dart` - thêm 100 câu theo thứ tự cố định.
- `lib/core/storage/localdb/app_prefs.dart` - đọc/ghi cursor cục bộ và xử lý fallback trong phiên.
- `lib/app_versions/v1/features/ai_chat/presentation/controllers/ai_chat_controller.dart` - gắn câu cho lượt mới và giữ câu khi retry.
- `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart` - hiện câu cạnh chỉ báo chờ tới token đầu.
- `test/app_versions/v1/features/ai_chat/ai_chat_thinking_phrase_test.dart` - thêm kiểm tra xoay vòng, trạng thái và bố cục.
- `test/app_versions/v1/features/ai_chat/ai_chat_screen_error_test.dart` - chờ kết thúc request async trước khi kiểm tra trạng thái lỗi.
- `docs/features/ai-chat/002-feature-ai-chat-thinking-phrase-rotation.md` - ghi nhận hành vi và giới hạn.
- `docs/worklog/2026-10-18/007-worklog-ai-chat-thinking-phrase-rotation.md` - ghi nhận phiên làm việc.

## Tài liệu liên quan

- `.codex/domains/ai-service.md`
- `.codex/design/screens/v1-15-ai-chat.md`
- `docs/features/ai-chat/001-feature-ai-chat-incremental-streaming.md`

## Commands

- `dart format <6 file Dart trong scope>`: PASS - không còn file cần format.
- `flutter test --no-pub test/app_versions/v1/features/ai_chat/ai_chat_screen_error_test.dart test/app_versions/v1/features/ai_chat/ai_chat_thinking_phrase_test.dart test/app_versions/v1/features/ai_chat/ai_chat_quota_test.dart`: PASS - 18 test.
- `flutter analyze --no-pub <6 file Dart trong scope>`: PASS - không có issue.
- Dart MCP hot reload trên `220333QPG`: FAIL - VM trả lỗi reload source sau khi thay đổi static state.
- Dart MCP hot restart trên `220333QPG`: PASS.
- Dart MCP runtime errors sau hot restart: PASS - không phát hiện lỗi runtime.
- Smoke chat thật trên thiết bị: SKIPPED - test không gọi AI thật hoặc dùng quota.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS - cập nhật 19 file history/task-skill được sinh tự động.
- `python3 .codex/tools/update_worklog_learning.py --check`: PASS - 19 file hợp lệ.

## Lỗi/Rủi ro

- Đã xử lý: thao tác ghi cursor dùng Future queue tĩnh khiến request chờ ở các lượt test liên tiếp; thay bằng khởi tạo cursor dùng chung và tăng chỉ số đồng bộ trước khi lưu.
- Chưa xác minh: thao tác chat thực tế trên thiết bị với model local; không tiêu quota AI trong phiên kiểm thử.
- Giới hạn: nếu SharedPreferences thực sự không truy cập được, bộ đếm chỉ giữ trong bộ nhớ của phiên ứng dụng.

## Tỷ lệ hoàn thành

- Hoàn thành: code, test mục tiêu, tài liệu, analyzer và hot restart.
- Đang dở: không còn việc triển khai bắt buộc; chưa có smoke chat thật trên thiết bị.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - chỉ dùng dữ liệu cục bộ, không đổi luồng AI hoặc quota.
- Mức độ hoàn thành task: hoàn tất phần đã duyệt; test UI xác nhận trạng thái chờ và kích thước hẹp.
- Bằng chứng kiểm chứng: 18 test pass, analyzer sạch, hot restart thành công, không có runtime error.
- Điểm tốn token/chưa tối ưu: lỗi test ban đầu chỉ lộ ra khi chạy nhiều widget test liên tiếp; cần giữ regression test theo cả suite.
- Cách tối ưu cho phiên sau: chạy test theo cụm ngay sau khi thêm storage async vào state chat.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
