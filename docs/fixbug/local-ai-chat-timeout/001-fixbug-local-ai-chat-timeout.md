Commit de xuat: fix(ai-chat): tang timeout suy luan local

# Fix local AI chat timeout

## Triệu chứng

Trên Android 11 với Qwen3 1.7B, chat có thể hiện tin nhắn người dùng nhưng không có câu trả lời. Service chat đặt giới hạn 20 giây cho toàn bộ lần sinh; model chưa kịp phát token đầu tiên đã bị đổi thành lỗi chung “Nabi đang bận”.

## Thay đổi

- Đặt giới hạn mặc định giữa các token của chat local thành 120 giây; `Stream.timeout` khởi động lại bộ đếm khi có token mới. Đường generator được inject trong test vẫn chịu giới hạn toàn lần gọi.
- Thêm `AILocalInferenceTimeoutException` và copy tiếng Việt riêng, có thể thử lại. Timeout không bị phân loại thành quá tải và không đưa model vào cooldown.
- Giữ phân loại riêng cho lỗi model không sẵn sàng và lỗi runtime/quá tải.
- Log chỉ giữ model, trạng thái đã chuẩn hóa, loại lỗi và thời gian xử lý. App logger chỉ ghi kiểu lỗi; không ghi prompt hay câu trả lời.
- Repository chỉ commit quota và thêm lịch sử sau khi inference hoàn tất thành công.
- Bổ sung kiểm tra thời điểm token đầu sau 20 giây, timeout, lỗi model/runtime, thông báo có thể thử lại, quota và trạng thái lịch sử. Smoke test Android dùng câu hỏi số học tổng hợp và repository không có quota gateway.

## Kiểm chứng

- Focused Flutter tests: PASS, 23 tests qua service, quota và màn chat.
- Targeted `flutter analyze`: PASS, không có issue.
- Android 11 / Qwen3 1.7B: smoke test đã nhận câu trả lời ở lần chạy đầu, nhưng runner báo lỗi sau khi test hoàn tất do timer UI còn chạy sau khi dispose provider. Đã thêm thời gian dọn timer vào smoke test. Lần chạy lại không đến inference vì runner gỡ ứng dụng sau lần lỗi và lựa chọn model đã mất; cần chạy lại trên thiết bị sau khi model được cài/chọn lại.

## Phạm vi

Không đổi kiến trúc AI local, quota, hoặc thêm Gemini fallback. Không ghi nội dung câu hỏi/câu trả lời vào log. Model không được tải lại trong phiên này.
