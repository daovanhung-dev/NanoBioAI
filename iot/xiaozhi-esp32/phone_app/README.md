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
5. Tab **Cài đặt** cho phép chọn ngôn ngữ trả lời, ngữ cảnh, giọng TTS, tốc độ và cao độ. App ưu tiên chọn voice tiếng Việt offline; tab ESP báo riêng voice có thể chạy offline hay cần mạng.

Android cô lập vùng dữ liệu riêng của mỗi ứng dụng. App này không thể đọc thẳng model đang nằm trong thư mục riêng của một app AI khác. Nếu model đã có trong một app khác, hãy dùng app đó xuất/copy file `.gguf` tới Downloads rồi nhập qua trình chọn file Android. File GGUF nhập vào cần dùng chat template ChatML.

## Kết nối ESP

1. Bật hotspot trên điện thoại và kết nối ESP vào hotspot đó. Giữ hotspot riêng, có mật khẩu mạnh; không mở cổng `8765` ra Internet.
2. Nạp model GGUF, Whisper và chọn voice TTS ngoại tuyến. Server chỉ khởi chạy khi cả hai model và voice offline đã sẵn sàng. Mở tab **ESP**, chọn IPv4/interface hotspot rồi bấm **Khởi chạy server AI local**. Android yêu cầu quyền notification để hiện trạng thái và nút dừng.
3. Sao chép **OTA URL** hiển thị trong app. Mở trang cấu hình Wi-Fi của ESP, nhập URL vào **Custom OTA URL**, lưu rồi khởi động lại ESP.
4. Server chạy bằng Android foreground service loại `connectedDevice`; notification hiển thị trạng thái và có nút **Dừng server**. Có thể tắt màn hình/đưa app xuống nền. Phiên thử nghiệm nên giữ điện thoại cắm sạc; Doze và chính sách riêng của hãng vẫn có thể trì hoãn mạng cục bộ.
5. Nếu IP hotspot đổi, app báo trạng thái mới. Chọn URL mới trong app, cập nhật **Custom OTA URL** trên ESP rồi khởi động lại ESP để lấy cấu hình WebSocket mới.

OTA endpoint chỉ cấp cấu hình WebSocket; nhận dạng tiếng nói Whisper và suy luận LLM diễn ra trên điện thoại. Giọng đọc dùng Android TTS; app kiểm tra thuộc tính `network_required` và từ chối khởi chạy nếu voice đang chọn cần mạng. Model được tải xuống cần Internet lần đầu, sau đó inference có thể chạy offline; kết nối Wi-Fi LAN giữa điện thoại và ESP vẫn cần hoạt động.

Server bind đúng IPv4 đã chọn thay vì mở trên mọi interface. Nếu có nhiều interface IPv4 riêng, app yêu cầu chọn một địa chỉ. Server phục vụ một ESP trong mỗi phiên. HTTP và WebSocket hiện không mã hóa TLS; chỉ dùng hotspot riêng và không kết nối thiết bị lạ.

APK hiện target SDK 36 nên chưa xin quyền LAN riêng. Trước khi nâng target lên SDK 37, cần khai báo và xin quyền runtime `ACCESS_LOCAL_NETWORK` trước khi mở listener LAN.

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
