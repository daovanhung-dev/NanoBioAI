# XiaoZhi Local AI (Android)

Ứng dụng Android chạy model ngôn ngữ GGUF trực tiếp trên điện thoại và cung cấp dịch vụ giọng nói local cho firmware XiaoZhi qua WebSocket. Trong lúc trò chuyện, nội dung âm thanh và prompt không được gửi tới AI server của dự án.

## Cài và chuẩn bị model

1. Mở tab **Model**.
2. Chọn **Nhập GGUF** để nhập model chat tương thích ChatML đã xuất ra bộ nhớ dùng chung của Android, hoặc chọn một model trong catalog:
   - [Qwen3 0.6B Q4_0](https://huggingface.co/ggml-org/Qwen3-0.6B-GGUF/blob/main/Qwen3-0.6B-Q4_0.gguf), khoảng 429 MiB.
   - [Qwen2.5 0.5B Instruct Q4_0](https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/blob/main/qwen2.5-0.5b-instruct-q4_0.gguf), khoảng 429 MiB.
   - [Qwen3 0.6B Q8_0](https://huggingface.co/ggml-org/Qwen3-0.6B-GGUF/blob/main/Qwen3-0.6B-Q8_0.gguf), khoảng 805 MiB và cần nhiều RAM hơn.
3. App kiểm tra SHA-256 trước khi nhận model tải xuống. Các model đã nhập/tải được giữ trong bộ nhớ app và có thể chọn lại ở danh sách **Model đã cài**.
4. Chọn **Tải và cài Whisper** để bật nhận dạng giọng nói tiếng Việt. Whisper tiny Q5 khoảng 31 MiB; lần tải đầu cần Internet. App tự nạp lại Whisper ở lần mở sau.
5. Tab **Cài đặt** cho phép chọn ngôn ngữ trả lời, ngữ cảnh, giọng TTS, tốc độ và cao độ.

Android cô lập vùng dữ liệu riêng của mỗi ứng dụng. App này không thể đọc thẳng model đang nằm trong thư mục riêng của một app AI khác. Nếu model đã có trong một app khác, hãy dùng app đó xuất/copy file `.gguf` tới Downloads rồi nhập qua trình chọn file Android. File GGUF nhập vào cần dùng chat template ChatML.

## Kết nối ESP

1. Điện thoại và ESP cần ở cùng mạng Wi-Fi; có thể bật hotspot trên điện thoại và cho ESP kết nối vào hotspot.
2. Để app cung cấp dịch vụ, model ngôn ngữ và Whisper phải đang nạp. Mở tab **ESP** rồi chọn **Khởi chạy server AI local**.
3. Sao chép **OTA URL** hiển thị trong app. Mở trang cấu hình Wi-Fi của ESP và nhập URL đó vào **Custom OTA URL**.
4. Lưu cấu hình và khởi động lại ESP. Firmware gọi OTA URL trên điện thoại để nhận địa chỉ WebSocket nội bộ.
5. Giữ app mở trên màn hình trong khi dùng. App giữ màn hình bật khi server đang chạy; bản này chưa đăng ký Android foreground service để duy trì khi app bị đưa lâu xuống nền.

OTA endpoint chỉ cấp cấu hình WebSocket; nhận dạng tiếng nói Whisper và suy luận LLM diễn ra trên điện thoại. Giọng đọc dùng Android TTS; để không phụ thuộc dịch vụ mạng, hãy cài/chọn voice ngoại tuyến trong Android. Model được tải xuống cần Internet lần đầu, sau đó inference có thể chạy offline; kết nối Wi-Fi LAN giữa điện thoại và ESP vẫn cần hoạt động.

Xem [mô tả chi tiết luồng AI local giữa điện thoại và ESP32](../docs/phone-local-ai-flow_vi.md) để biết trình tự OTA, WebSocket, audio, STT, LLM, TTS và cách kiểm tra MVP.

## Chạy từ source

```sh
cd phone_app
flutter pub get
flutter run
```

Tạo APK debug:

```sh
flutter build apk --debug
```
