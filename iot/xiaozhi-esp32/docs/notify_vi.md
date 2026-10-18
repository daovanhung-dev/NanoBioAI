# Thông báo giọng nói không đồng bộ

Thông điệp `notify` cho phép máy chủ đám mây phát thông báo giọng nói một chiều khi thiết bị ở trạng thái rảnh. Thông điệp không mở kênh âm thanh hội thoại và không bao giờ bật đường gửi âm thanh từ micro lên máy chủ. Muốn bắt đầu hội thoại vẫn cần người dùng chủ động kích hoạt đánh thức.

## Định dạng thông điệp

Máy chủ đám mây gửi JSON sau qua kết nối điều khiển của giao thức hiện tại trên thiết bị. Với thiết bị MQTT, đây là topic điều khiển MQTT đang dùng:

```json
{
  "type": "notify",
  "audio_url": "https://cdn.example.com/audio/task-complete.ogg",
  "subtitles": [
    {
      "start_ms": 0,
      "text": "Your task is complete."
    },
    {
      "start_ms": 1800,
      "text": "The result has been saved."
    }
  ]
}
```

`audio_url` là bắt buộc. Chấp nhận cả URL bắt đầu bằng `http://` và `https://`. HTTP hữu ích khi phát triển trong mạng nội bộ; môi trường production có thể bắt buộc HTTPS khi tạo URL.

`subtitles` là tùy chọn. Mỗi mục chứa thời điểm bắt đầu theo mili giây của media và nội dung cần hiển thị. Thiết bị sắp xếp các mục theo `start_ms` và chỉ cập nhật màn hình khi quá trình phát chuyển sang mục phụ đề mới.

Thông điệp không có trường xác nhận, ID thông báo, trạng thái, loại thông báo hay thời hạn hết hiệu lực. Việc gửi là best effort và chỉ áp dụng cho thiết bị đang trực tuyến.

## Phản hồi âm thanh

`audio_url` phải trả về phản hồi thành công 2xx chứa một luồng đơn, mono, tệp Ogg Opus. Chấp nhận phản hồi dùng `Content-Length` hoặc truyền tải theo chunk. Thiết bị không theo redirect.

Tệp được đọc tăng dần. Thiết bị không cấp phát bộ nhớ dựa trên tổng độ dài phản hồi và không tải toàn bộ tệp xuống trước khi phát. Luồng thông báo dùng queue phản hồi HTTP có giới hạn sẵn có, buffer gói logic Ogg 2 KB, queue giải mã Opus dùng chung 20 gói và queue phát PCM hai frame hiện có. Queue giải mã tương ứng 1,2 giây ở thời lượng gói thông thường 60 ms của firmware. Các buffer này tạo backpressure cho TCP, đồng thời vẫn cho phép tính năng hoạt động trên thiết bị không có PSRAM.

Trên thiết bị dùng WakeNet của LiteAudioEngine độc lập, tài nguyên WakeNet được giải phóng trong khi phát thông báo và tạo lại khi thiết bị trở về `Idle`. Thiết bị dùng AFE giữ nguyên hành vi đánh thức cục bộ hiện tại.

Thời lượng gói Opus được đọc từ byte TOC của Opus thay vì truyền trong thông điệp MQTT. Chấp nhận các thời lượng gói nguyên từ 5 ms đến 120 ms mà decoder firmware hỗ trợ. Triển khai hiện tại từ chối luồng stereo, lỗi cấu trúc Ogg hoặc Opus, luồng không hoàn chỉnh, gói logic vượt kích thước cho phép và gói 2,5 ms.

## Hành vi thiết bị

Thiết bị chỉ chấp nhận `notify` khi đang ở trạng thái `Idle`. Sau đó, thiết bị thực hiện:

1. Chuyển sang trạng thái nội bộ `Notifying` và đưa bo sang chế độ hiệu năng.
2. Tắt xử lý giọng nói thông thường và đường gửi âm thanh từ micro.
3. Xóa nội dung phát trước đó rồi đưa âm thanh popup tích hợp sẵn vào hàng đợi.
4. Bắt đầu một HTTP GET trong tác vụ nền.
5. Tách các gói Ogg theo luồng và gửi trực tiếp vào queue giải mã Opus hiện có.
6. Hiển thị phụ đề theo vị trí media của các gói Opus đến tác vụ xuất âm thanh.
7. Chỉ trở lại `Idle` sau khi luồng HTTP kết thúc thành công và toàn bộ âm thanh đã xếp hàng được phát hết.

Popup được đưa vào queue trước khi tác vụ HTTP bắt đầu, vì vậy âm thanh từ xa không thể phát trước popup. Tuy nhiên, quá trình thiết lập kết nối HTTP vẫn diễn ra đồng thời với lúc popup thực sự đang phát.

Nếu toàn bộ queue phát hết sau khi âm thanh từ xa bắt đầu nhưng trước khi luồng HTTP kết thúc, thiết bị ghi log `Notification playback underrun #<count> at <position> ms`. Quá trình chuyển tiếp từ popup sang luồng từ xa và lúc kết thúc phát bình thường không được xem là underrun.

Thiết bị không mở kênh âm thanh UDP, không gửi `start-listening` và không tự động chuyển sang `Listening`. Thiết bị AFE có thể tiếp tục phát hiện từ đánh thức cục bộ trong lúc phát. Thiết bị không có khử vọng âm thanh phát sẽ giữ hành vi đánh thức hiện có ở chế độ speaking; các điều khiển đánh thức bằng phần cứng vẫn có thể hủy thông báo.

Thao tác đánh thức sẽ hủy tác vụ HTTP tạo luồng, xóa âm thanh thông báo đang xếp hàng và tiếp tục luồng đánh thức thông thường. Mất mạng, lỗi HTTP hoặc âm thanh không hợp lệ cũng hủy phát và đưa thiết bị về `Idle`. Thông báo thứ hai nhận được trong khi thiết bị đang bận sẽ bị bỏ qua.

## Chuyển tiếp qua xz-mqtt

`xz-mqtt` chuyển tiếp thông điệp bằng phương thức Redis RPC hiện có:

```json
{
  "method": "forward",
  "clientId": "device-client-id",
  "params": {
    "type": "notify",
    "audio_url": "https://cdn.example.com/audio/task-complete.ogg",
    "subtitles": [
      {
        "start_ms": 0,
        "text": "Your task is complete."
      }
    ]
  }
}
```

Kết quả RPC chứa giá trị boolean do thao tác gửi MQTT trả về:

```json
{
  "success": true
}
```

Kết quả này nghĩa là `xz-mqtt` đã ghi thông điệp publish vào kết nối thiết bị đang trực tuyến. Nó không xác nhận thiết bị đã nhận hoặc phát thông báo. `xz-mqtt` không tạo phiên UDP, không khởi chạy cầu nối chat, không proxy tệp Ogg và không lưu giữ thông báo cho thiết bị ngoại tuyến.

