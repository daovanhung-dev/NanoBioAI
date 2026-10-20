Commit de xuat: feat(ai-chat): xoay vong cau suy nghi

# Xoay vòng câu suy nghĩ trong Nabi Chat

## Mục tiêu

Trong lúc Nabi chờ token đầu tiên từ model local, hiển thị một câu tiếng Việt thay đổi theo từng lượt gửi để người dùng biết yêu cầu đang được xử lý.

## Luồng hoạt động

- Danh sách 100 câu cố định nằm trong `AIChatThinkingPhrases`, theo đúng thứ tự đã duyệt; danh sách không có câu trùng nguyên văn.
- `AppPrefs` lưu chỉ số kế tiếp trong SharedPreferences bằng khóa `ai_chat_thinking_phrase_next_index`. Câu đầu tiên sau khi cài tính năng là câu 1; sau câu 100, lượt kế tiếp quay về câu 1.
- Mỗi tin nhắn mới không rỗng và được nhận xử lý sẽ tăng chỉ số, kể cả khi lượt AI thất bại. Lượt gửi rỗng hoặc đang có request/đặt chỗ câu thì bị bỏ qua và không tăng chỉ số.
- Thử lại lượt lỗi giữ câu đã gán cho lượt đó. Xóa lịch sử chat không đặt lại chỉ số.
- Khi không đọc hoặc ghi được SharedPreferences, bộ đếm tiếp tục trong bộ nhớ của phiên ứng dụng hiện tại.
- `AIChatScreen` hiển thị câu cạnh vòng chờ cho tới khi có nội dung đầu tiên từ model; phần chữ dùng vùng co giãn để hỗ trợ màn hình hẹp và cỡ chữ lớn.

## Phạm vi và giới hạn

- Câu được chọn cục bộ trên thiết bị; không đồng bộ tài khoản hoặc thiết bị.
- Không gọi AI để chọn câu và không thay đổi model, quota, nội dung lịch sử hay giao thức stream.
- Bộ đếm bắt đầu từ câu 1 khi tính năng được cài; không suy ngược các lượt chat cũ.

## Bằng chứng mã nguồn

- `lib/app_versions/v1/features/ai_chat/presentation/ai_chat_thinking_phrases.dart`
- `lib/core/storage/localdb/app_prefs.dart`
- `lib/app_versions/v1/features/ai_chat/presentation/controllers/ai_chat_controller.dart`
- `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart`
- `test/app_versions/v1/features/ai_chat/ai_chat_thinking_phrase_test.dart`
