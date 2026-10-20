Commit de xuat: feat(ai-chat): hien thi phan hoi theo luong

# Hiển thị câu trả lời AI theo luồng

## Mục tiêu

Hiển thị câu trả lời ngay khi AI local bắt đầu phát nội dung, để tin nhắn dài lên dần thay vì chờ toàn bộ câu trả lời hoàn tất.

## Luồng hoạt động

- `AIChatService` đọc các phần văn bản từ local runtime, làm sạch và chỉ phát phần mới khi nội dung hiển thị vẫn hợp lệ. Câu trả lời hoàn chỉnh tiếp tục được làm sạch và kiểm tra trước khi ghi vào lịch sử.
- `AIChatRepositoryImpl` chuyển từng phần thành sự kiện có nội dung tích lũy; sự kiện hoàn tất chỉ phát sau khi model kết thúc bình thường.
- `AIChatController` cập nhật cùng một tin nhắn Nabi qua từng sự kiện, giữ trạng thái đang tạo đến sự kiện hoàn tất.
- `AIChatScreen` bỏ chỉ báo suy nghĩ khi có chữ đầu tiên, giữ cuộn theo câu trả lời khi người dùng còn ở cuối danh sách, và không hiện thao tác báo cáo cho tin nhắn đang tạo.
- Nếu stream lỗi, phần trả lời chưa hoàn chỉnh bị gỡ khỏi màn hình và trạng thái thử lại/lỗi hiện có được giữ.

## Phạm vi và giới hạn

- Dùng stream local hiện có; không thêm API từ xa, không đổi giới hạn quota hoặc hợp đồng lưu lịch sử.
- Nội dung đến theo từng phần model phát ra. Một phần có thể chứa một hoặc nhiều từ tùy cách runtime gom token.
- Nếu stream lỗi sau khi đã hiện một phần câu trả lời, không nối tiếp bằng một model khác để tránh ghép hai câu trả lời khác nhau.

## Bằng chứng mã nguồn

- `lib/app_versions/v1/services/ai/ai_chat_service.dart`
- `lib/app_versions/v1/features/ai_chat/domain/repositories/ai_chat_repository_impl.dart`
- `lib/app_versions/v1/features/ai_chat/presentation/controllers/ai_chat_controller.dart`
- `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart`
