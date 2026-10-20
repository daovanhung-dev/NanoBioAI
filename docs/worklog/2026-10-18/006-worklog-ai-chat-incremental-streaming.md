Commit de xuat: docs(worklog): ghi nhan streaming ai chat

# Worklog - Hiển thị câu trả lời AI theo luồng

## Thời gian

- Ngày: 2026-10-18
- Bắt đầu: trước 21:06; thời điểm chính xác không còn trong context khi tiếp tục phiên.
- Kết thúc: khoảng 21:08
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: cải tiến luồng hiển thị AI Chat
- Module chính: M05 AI / AI Chat / local runtime
- Yêu cầu gốc: hiển thị câu trả lời lần lượt trong lúc AI tạo, thay vì chờ toàn bộ nội dung.

## Đã làm

- Nối stream local qua repository và controller tới giao diện chat.
- Cập nhật một bubble Nabi ổn định khi các phần văn bản mới đến; ẩn chỉ báo suy nghĩ sau phần chữ đầu tiên.
- Cuộn theo nội dung mới khi người dùng vẫn ở cuối hội thoại; không kéo người dùng xuống khi họ đã cuộn lên đọc.
- Giữ làm sạch và kiểm tra nội dung tiếng Việt; nếu stream lỗi thì bỏ câu trả lời dở dang và giữ trạng thái lỗi/thử lại.
- Chặn fallback sang model khác sau khi đã phát một phần nội dung; giữ timeout stream ở thông báo lỗi timeout riêng.
- Tạo tài liệu tính năng cho luồng mới.

## File code/docs đã sửa

- `lib/app_versions/v1/services/ai/ai_chat_service.dart` - phát phần nội dung đã làm sạch trong lúc local runtime sinh câu trả lời.
- `lib/app_versions/v1/features/ai_chat/presentation/controllers/ai_chat_controller.dart` - nhận sự kiện stream và cập nhật bubble Nabi.
- `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart` - hiển thị nội dung tăng dần, giữ cuộn hội thoại và trạng thái chờ.
- `docs/features/ai-chat/001-feature-ai-chat-incremental-streaming.md` - mô tả luồng và giới hạn.

## Tài liệu liên quan

- `.codex/domains/ai-service.md`
- `.codex/design/screens/v1-15-ai-chat.md`

## Commands

- `dart format <3 file Dart trong scope>`: PASS - không còn file cần format sau vòng cuối.
- `flutter analyze --no-pub <3 file Dart trong scope>`: PASS - không có issue.
- Dart MCP hot reload trên app Flutter đang kết nối (`220333QPG`): PASS.
- Dart MCP runtime errors sau hot reload: PASS - không phát hiện lỗi runtime.
- Test tự động: SKIPPED - không được yêu cầu trong task này.
- Kiểm tra gửi câu hỏi thực tế qua giao diện: SKIPPED - chưa thực hiện smoke chat trên app.

## Lỗi/Rủi ro

- Đã xử lý: trước đây controller chờ `sendMessage` hoàn tất và service gom stream thành một chuỗi trước khi trả về.
- Chưa xác minh: hành vi hiển thị từng phần khi gửi câu hỏi thật trên thiết bị.
- Giới hạn: runtime có thể phát một sự kiện chứa nhiều token; giao diện hiển thị theo nhịp sự kiện từ model.

## Tỷ lệ hoàn thành

- Hoàn thành: nối luồng dữ liệu và giao diện; format, analyzer và hot reload đều đạt.
- Đang dở: smoke chat thật trên thiết bị chưa chạy.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - dùng luồng local sẵn có, giữ message identity, validation và xử lý lỗi.
- Mức độ hoàn thành task: hoàn tất phần triển khai; chưa có xác nhận thao tác chat thực tế.
- Bằng chứng kiểm chứng: analyzer sạch trên ba file trong scope, hot reload thành công, không có runtime error sau reload.
- Điểm tốn token/chưa tối ưu: worktree có nhiều thay đổi ngoài phạm vi nên chỉ kiểm tra file liên quan.
- Cách tối ưu cho phiên sau: xác nhận trên màn chat bằng một câu hỏi tổng hợp khi có phiên QA thiết bị.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
