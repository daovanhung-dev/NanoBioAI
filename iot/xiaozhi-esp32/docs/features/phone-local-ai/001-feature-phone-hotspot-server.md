Commit de xuat: feat(iot): provision OSTB 3ST qua hotspot Nabi

# Feature: Nabi Android làm máy chủ AI local cho ESP

## Trạng thái

- PO intent được duyệt theo kế hoạch tích hợp của người dùng ngày 2026-10-23.
- Main NanoBioAI Android app và profile firmware OSTB 3ST đang được nối bằng hợp đồng cấu hình chung.
- Tech, QA và Privacy review vẫn chờ; tính năng còn review-gated.
- Build, install, flash và kiểm thử trên thiết bị được ghi riêng trong worklog. Tài liệu này không coi source/build là bằng chứng kết nối thực.

## Mục tiêu

Điện thoại Android cấp mạng `LocalOnlyHotspot`, chạy local server và AI. ESP lấy Wi-Fi qua BLE Security 2, tự tìm host bằng gateway DHCP, nhận cấu hình WebSocket v3 rồi gửi/nhận audio Opus. Whisper, model GGUF và Android TTS chạy trong ứng dụng NanoBioAI chính. `iot/xiaozhi-esp32/phone_app/` là ứng dụng độc lập và không thuộc feature này.

## Hợp đồng app-firmware

Source chuẩn là [`iot/nabi_esp_contract.json`](../../../../nabi_esp_contract.json). Generator [`iot/tools/generate_nabi_esp_contract.py`](../../../../tools/generate_nabi_esp_contract.py) sinh định nghĩa Dart, Kotlin và ESP; `--check` xác minh đồng bộ.

| Cấu hình | Giá trị |
|---|---|
| Protocol | XiaoZhi v3 |
| Cổng | `8386` |
| HTTP OTA | `/nabi/ota/` |
| WebSocket | `/nabi/v1/` |
| Host | Gateway DHCP hiện tại; không hard-code SSID, mật khẩu hoặc IP |
| OTA auth | `X-Nabi-Device-Key` |
| WebSocket auth | Bearer token riêng mỗi phiên |
| BLE provisioning | Protocomm Security 2, mã ghép một lần 8 chữ số |

## Luồng sử dụng

1. Trước phiên đầu, người dùng chuẩn bị GGUF, Whisper và voice TTS offline. Tải model cần Internet; LocalOnlyHotspot không chia sẻ Internet cho ESP.
2. Người dùng bấm **Kết nối Nabi** trên Android. App kiểm tra AI, xin quyền cần thiết, khởi chạy foreground service và yêu cầu Android tạo LocalOnlyHotspot. SSID/mật khẩu do OS cấp.
3. App bind server vào interface hotspot thực tế trên port 8386 và báo **AI sẵn sàng, chờ ESP**. UI không nhầm trạng thái này với kết nối ESP.
4. Người dùng bật ESP OSTB 3ST. Lần đầu, nhập mã đang hiển thị trên ESP vào app; Security 2 bảo vệ thông tin Wi-Fi gửi qua BLE. App lưu khóa thiết bị bằng Android Keystore; ESP lưu khóa trong NVS.
5. Các lần sau, app tìm ESP và tái provisioning credential hotspot hiện tại bằng khóa đã ghép. ESP lấy gateway từ DHCP, gọi `/nabi/ota/`, nhận URL WebSocket/token phiên rồi giao tiếp XiaoZhi v3.
6. App xử lý Opus → Whisper → local model → Android TTS → Opus. Nút nghe gửi `nabi.control`; firmware xử lý qua event loop và trả `nabi.control_ack` có `request_id`.

Nếu Android không cấp hotspot hoặc BLE hỏng, UI hiển thị lỗi có thể thử lại; firmware còn manual Wi-Fi configuration AP làm đường phục hồi. Android có thể dừng hotspot; app cần đóng phiên và báo người dùng khởi động lại kết nối.

## Bảo mật và dữ liệu

- Không log SSID/mật khẩu, pairing key, session token, audio hoặc transcript. Audio/hội thoại chỉ ở RAM; lịch sử bị giới hạn trong runtime.
- BLE dùng Security 2. OTA xác thực khóa thiết bị; WebSocket xác thực token ngẫu nhiên theo phiên.
- HTTP/WebSocket LAN hiện plaintext; chỉ dùng hotspot riêng, không mở/forward port 8386 ra Internet.
- Thiết bị OSTB hiện có Flash Encryption tắt; khóa trong NVS có thể bị đọc khi truy cập vật lý flash.

## Nghiệm thu

| Hạng mục | Bằng chứng cần có |
|---|---|
| Contract | Dart/Kotlin/C sinh đồng bộ từ JSON |
| Android | LocalOnlyHotspot, host bind, foreground notification, permission denial và hotspot-stop handling trên điện thoại thật |
| BLE | Pairing đúng/sai/hết hạn; credential mới được cấp qua khóa cũ |
| ESP | OTA gateway DHCP, khóa sai trả 401, WebSocket protocol v3 và token sai bị từ chối |
| Conversation | `listen.start/stop` ack, tiếng Việt STT và TTS nghe được ở loa |
| Offline/background | Tắt Internet sau khi chuẩn bị model; thử khóa màn hình khi cắm sạc |

Build/source/test không xác nhận khả năng chạy nền, LCD, micro, loa hoặc hội thoại. Xem [luồng tích hợp chi tiết](../../phone-local-ai-flow_vi.md), [hồ sơ thiết bị](../../agent-context/CONNECTED_DEVICE_OSTB_3ST.md) và DD [Nabi - Siêu trợ lý AI](../../../../../docs/DD/nabi_esp_assistant/README.md).

## Source of truth

- Nabi app: `lib/app_versions/v1/features/nabi_esp_assistant/` ở repo NanoBioAI.
- Shared contract: [`iot/nabi_esp_contract.json`](../../../../nabi_esp_contract.json).
- OSTB provisioning: `main/nabi_esp_provisioning.*`.
- OTA host/auth: `main/ota.cc`.
- Listen control: `main/protocols/protocol.*` và `main/application.cc`.
- Firmware source không sửa `phone_app/` cho integration này.
