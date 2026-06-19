Commit đề xuất: docs(issue): ghi nhận lỗi ai chat tăng token theo lịch sử

# AI Chat giữ lịch sử không giới hạn làm tăng token và độ trễ

## Tóm tắt
- `AIChatService` dùng `ChatSession` lâu dài cho mỗi model.
- Mỗi `sendMessage` gửi qua `session.sendMessage(...)`, nhưng service không giới hạn số lượt, không tóm tắt, không cắt lịch sử, và chỉ reset khi user gọi clear chat.

## Mức độ ảnh hưởng
- Severity: medium
- Ảnh hưởng user: chat dài có thể phản hồi chậm dần, dễ timeout, dễ đụng quota/context limit.
- Ảnh hưởng dev/build/test: khó tái hiện bằng unit test ngắn, nhưng là bug chi phí token và latency khi release.

## Cách tái hiện
1. Mở AI Chat.
2. Gửi nhiều tin nhắn trong cùng phiên.
3. Không bấm clear chat.
4. Session vẫn giữ lịch sử cũ khi gửi lượt tiếp theo.

## Đã xác nhận
- `lib/services/ai/ai_chat_service.dart:386` dùng `session.sendMessage(Content.text(message))`.
- `lib/services/ai/ai_chat_service.dart:404-405` dùng `sendMessageStream` trên cùng session.
- `lib/services/ai/ai_chat_service.dart:626-628` chỉ reset session khi gọi `resetChat`.
- Không thấy giới hạn số message, số token, hoặc cơ chế summarize history trong service.

## Giả thuyết
- Khi conversation dài, SDK sẽ gửi context lịch sử của `ChatSession`, làm input token tăng theo số lượt chat.

## Workaround
- Khuyến khích user bấm clear chat khi phiên chat dài.

## Hướng fix đề xuất
- Giới hạn lịch sử chat theo số lượt hoặc token ước lượng.
- Tạo cơ chế summarize hoặc reset mềm sau N lượt.
- Thêm telemetry/log summary cho message count và fallback khi history quá dài.

## Files/log liên quan
- `lib/services/ai/ai_chat_service.dart`

## Liên kết
- Worklog: ../../worklog/2026-06-19/007-worklog-release-1-0-bug-audit.md
