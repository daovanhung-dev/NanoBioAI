# Luồng AI local giữa Nabi Android và ESP OSTB 3ST

**Cập nhật:** 2026-10-23
**Phạm vi:** ứng dụng NanoBioAI chính (`lib/app_versions/v1/features/nabi_esp_assistant/`) và firmware `ostb/ostb-xiaozhi-3st`. `iot/xiaozhi-esp32/phone_app/` là ứng dụng riêng, không tham gia luồng này.

## 1. Kiến trúc

Điện thoại Android tạo mạng `LocalOnlyHotspot`, chạy HTTP/WebSocket server và giữ model local. ESP OSTB 3ST nhận Wi-Fi qua BLE Security 2, hỏi cấu hình WebSocket từ điện thoại rồi gửi audio Opus. Whisper, model GGUF và Android TTS chạy trên điện thoại; ESP thu/phát âm thanh và hiển thị trạng thái.

SSID, mật khẩu và IP hotspot do Android cấp. App không đặt SSID cố định, không dùng mật khẩu mẫu, và không giả định IP tĩnh. ESP tìm server bằng gateway được cấp trong DHCP.

## 2. Hợp đồng app-firmware

Nguồn chuẩn duy nhất là [`iot/nabi_esp_contract.json`](../../nabi_esp_contract.json). Chạy `python3 iot/tools/generate_nabi_esp_contract.py --check` để xác nhận các giá trị sinh trong Dart, Kotlin và C header còn đồng bộ.

| Giá trị | Hợp đồng |
|---|---|
| Phiên bản hợp đồng | `1` |
| Giao thức XiaoZhi | `3` |
| Cổng TCP | `8386` |
| HTTP cấu hình OTA | `/nabi/ota/` |
| WebSocket | `/nabi/v1/` |
| Xác thực OTA | Header `X-Nabi-Device-Key` |
| Xác thực WebSocket | `Authorization: Bearer <token-phiên>` |
| BLE | Prefix `NABI_`, Security 2, endpoint `nabi-config` |
| Host | Gateway IPv4 hiện hành do DHCP cấp cho ESP |

Giá trị trên là source contract. Chỉ build/đọc trực tiếp thiết bị mới xác nhận được firmware đang dùng hợp đồng đó.

## 3. Luồng kết nối

### 3.1 Bắt đầu từ Nabi

1. Người dùng tải/chọn model GGUF và Whisper, chọn voice Android TTS ngoại tuyến. Tải model lần đầu cần Internet.
2. Người dùng mở trang **Nabi - Siêu trợ lý AI** và bấm **Kết nối Nabi**. App kiểm tra AI sẵn sàng, xin quyền cần thiết, khởi chạy foreground service `connectedDevice`, rồi yêu cầu Android mở `LocalOnlyHotspot`.
3. Android trả SSID/mật khẩu hiện tại. App dò interface IPv4 mới của hotspot, bind server vào địa chỉ đó tại cổng `8386`, rồi báo **AI trên điện thoại sẵn sàng, đang chờ ESP**. Trạng thái này chưa có nghĩa ESP đã nối.
4. App bắt đầu scan BLE theo prefix và service UUID của hợp đồng. Nếu có nhiều địa chỉ host phù hợp mà không phân biệt được interface hotspot, UI yêu cầu chọn host trước khi báo sẵn sàng.

### 3.2 Ghép đôi BLE và chuyển Wi-Fi

1. ESP được nạp firmware XiaoZhi có `CONFIG_NABI_ESP_ASSISTANT=y` và khởi động với OSTB 3ST. Lần ghép đầu, ESP tạo mã 8 chữ số dùng một lần, hiển thị mã trên màn hình và dùng mã làm Proof of Possession cho Security 2. Mã hết hạn sau 2 phút.
2. Người dùng nhập mã trên app. Espressif Provisioning Android và Protocomm trao đổi BLE Security 2 (SRP6a/AES-GCM). App không gửi mã hoặc mật khẩu vào log.
3. App gửi JSON qua custom endpoint BLE gồm phiên bản hợp đồng/giao thức, port/path và credential LocalOnlyHotspot hiện hành.
4. ESP kiểm tra toàn bộ hợp đồng, lưu khóa ghép ngẫu nhiên trong namespace `nabi_esp` của NVS, thay thông tin Wi-Fi trong `SsidManager` và kết nối như station. Khóa được trả về trong phiên BLE đã mã hóa; app lưu bằng Android Keystore.
5. Ở phiên sau, app xác thực bằng khóa ghép đã lưu rồi gửi lại SSID/mật khẩu hotspot mới. Như vậy việc Android tạo credential mới sau khi dừng hotspot không yêu cầu ghép lại.
6. Nếu BLE hoặc hotspot không hoạt động, người dùng vẫn có thể vào manual Wi-Fi configuration AP của firmware để phục hồi mạng. Luồng này không tự bypass xác nhận quyền Android.

### 3.3 ESP lấy cấu hình dịch vụ AI

Sau khi Wi-Fi station kết nối, ESP đọc IPv4 gateway từ `WIFI_STA_DEF` và tạo URL:

```text
http://<gateway-dhcp>:8386/nabi/ota/
```

`main/ota.cc` gửi URL này cùng header `X-Nabi-Device-Key`. Server so sánh khóa thiết bị theo thời gian hằng; khóa thiếu/sai nhận HTTP 401. Cấu hình OTA không hard-code địa chỉ điện thoại.

Khi hợp lệ, app trả cấu hình session, ví dụ:

```json
{
  "websocket": {
    "url": "ws://<gateway-dhcp>:8386/nabi/v1/",
    "token": "<token-phiên>",
    "version": 3
  }
}
```

`<token-phiên> tác` trong ví dụ chỉ là placeholder; token thực được sinh ngẫu nhiên mỗi lần server chạy, không lưu vào tài liệu. Firmware ghi URL/token/version vào NVS phần WebSocket. WebSocket yêu cầu đúng bearer token, chỉ nhận một ESP mỗi phiên và từ chối phiên thứ hai.

Profile dùng URL `0.0.0.0` làm fallback build không định tuyến; sau khi có Wi-Fi, firmware ưu tiên URL sinh động từ gateway DHCP. `CONFIG_OTA_URL_IGNORE_NVS=y` làm URL cũ trong NVS không ghim ESP vào hotspot trước. Không cần nhập **Custom OTA URL** cho luồng Nabi.

### 3.4 Hội thoại và lệnh nghe

1. ESP mở WebSocket v3 và gửi `hello`, khai báo Opus mono 16 kHz. Server trả `hello` và mô tả audio trả về mono 24 kHz.
2. Người dùng bấm bắt đầu nghe trong app. Nabi gửi:

   ```json
   {"type":"nabi.control","request_id":"abc123","action":"listen.start"}
   ```

   Firmware kiểm tra id/action, chuyển yêu cầu qua `Application` event loop và trả `nabi.control_ack` có cùng `request_id`.

3. ESP gửi frame Opus khi đang nghe. App gom tối đa 60 giây PCM trong RAM, chạy Whisper tiếng Việt, gọi local AI turn datasource và Android TTS, rồi gửi câu trả lời cùng các frame Opus 24 kHz về ESP.
4. Nút dừng nghe gửi `listen.stop`; ESP gửi hết lượt hiện tại và trở về chờ. Hội thoại theo lượt, không phải streaming STT/LLM/TTS đầu-cuối.
5. Transcript/audio không được lưu xuống ổ đĩa hoặc ghi log. Lịch sử giới hạn 6 lượt trong RAM của phiên app.

## 4. Vòng đời và khôi phục

- Foreground notification thể hiện server đang chờ hoặc có ESP và có hành động dừng. Dừng từ UI/notification đóng WebSocket listener, trả tài nguyên hotspot và dừng service.
- Nếu Android dừng LocalOnlyHotspot hoặc interface biến mất, ESP mất đường tới server. Người dùng khởi động lại kết nối trong Nabi; app lấy credential/gateway mới và provision lại ESP bằng khóa ghép đã lưu.
- Sau reboot ESP, credential được giữ trong Wi-Fi settings của firmware; khi gateway đổi, firmware tự dựng lại OTA URL từ DHCP khi gọi bootstrap.
- Nếu server dừng giữa phiên, bearer token cũ không còn dùng được. ESP cần lấy OTA configuration mới sau khi server chạy lại.
- Kết quả chạy nền tùy mẫu máy, Doze và chính sách pin. Cần thử khi màn hình khóa và điện thoại cắm sạc.

## 5. Bảo mật và giới hạn

- BLE provisioning dùng Security 2. Khóa ghép phía app được mã hóa bằng Android Keystore; firmware lưu khóa trong NVS. Thiết bị hiện có Flash Encryption tắt, vì vậy người truy cập trực tiếp flash có thể đọc NVS.
- HTTP/WebSocket trong phiên dùng plaintext; mã hóa BLE không thay TLS cho LAN. Chỉ dùng hotspot riêng, không thêm thiết bị lạ và không forward cổng `8386` ra Internet.
- Khóa pairing dùng như header OTA và bearer token giới hạn theo phiên cho WebSocket. Không ghi password, pairing key, session token, transcript hoặc audio vào log.
- LocalOnlyHotspot không cung cấp Internet cho ESP. AI hoạt động offline chỉ sau khi model, Whisper và voice offline đã sẵn sàng.
- ESP demo LCD hiện hữu không có giao thức provisioning này. Lần cài firmware XiaoZhi/partition tương thích đầu tiên cần USB; không flash partition table nếu bản đang nạp đã tương thích.
- Tính năng vẫn review-gated. Chưa hoàn tất Tech, QA, Privacy sign-off hoặc thử nghiệm hội thoại vật lý thì không mở phát hành.

## 6. Kiểm tra và nghiệm thu

| Bước | Tiêu chí |
|---|---|
| Contract | Generator `--check` pass; Dart/Kotlin/C dùng port/path/protocol/BLE values giống nhau |
| App setup | Model, Whisper, voice offline sẵn sàng; LocalOnlyHotspot/server chạy; UI ghi rõ đang chờ ESP |
| First pairing | Mã sai/hết hạn bị từ chối; mã đúng ghép Security 2, khóa lưu an toàn; không lộ secret trong log |
| Reconnect | Dừng/bật hotspot tạo credential mới; app provision lại bằng khóa cũ và ESP nhận gateway mới |
| OTA | URL gọi `/nabi/ota/`; khóa sai nhận 401; khóa đúng trả WebSocket URL, bearer token và version 3 |
| WebSocket | Token sai bị từ chối; một ESP hoạt động; token phiên cũ mất hiệu lực khi server dừng |
| Controls/audio | `listen.start/stop` có ack đúng id; câu tiếng Việt ngắn được Whisper nhận dạng và TTS nghe được qua loa ESP |
| Offline/background | Sau khi tải model/voice, tắt Internet nhưng giữ hotspot; thử app nền/màn hình khóa khi cắm sạc |

Build source, test loopback hoặc serial boot không chứng minh được BLE, hotspot, UI LCD, micro, loa hay hội thoại. Ghi riêng kết quả từng lớp.

## 7. Source of truth

- [Hợp đồng dùng chung](../../nabi_esp_contract.json)
- [Generator contract](../../tools/generate_nabi_esp_contract.py)
- [Nabi app feature](../../../lib/app_versions/v1/features/nabi_esp_assistant/)
- [Firmware provisioning](../main/nabi_esp_provisioning.cc)
- [OTA/auth firmware](../main/ota.cc)
- [Control/event loop](../main/application.cc)
- [Hồ sơ ESP OSTB 3ST](agent-context/CONNECTED_DEVICE_OSTB_3ST.md)
