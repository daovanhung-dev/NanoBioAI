# Overall — NABI_ESP_ASSISTANT / Nabi - Siêu trợ lý AI kết nối ESP

> Runtime update 2026-10-30: the app no longer uses a local GGUF model for
> generated replies. It sends the recognized Vietnamese transcript and bounded
> conversation history to the authenticated NanoBio backend over HTTPS.
> Whisper STT, Android TTS, audio transport, and ESP firmware remain local and
> unchanged. The user must sign in and have Internet access for AI replies.

## 0. Trạng thái tài liệu

| Trường | Giá trị |
|---|---|
| Mã module | `NABI_ESP_ASSISTANT` |
| DD decision | `Draft` — Tech, QA, Privacy review đang chờ |
| Implementation | `In Progress` — app Android và profile firmware có LocalOnlyHotspot, BLE Security 2, HTTP/WebSocket v3 và điều khiển nghe; build/device verification đang chạy |
| Verification | Server contract test và focused analyzer pass. App/firmware build, install/flash và physical connectivity/audio acceptance pending; không suy ra thiết bị chạy chỉ từ source |
| Nguồn yêu cầu | Kế hoạch người dùng được duyệt trong phiên 2026-10-23; chưa có BD riêng |
| Owner | PO NanoBio; Tech/QA/Privacy chưa ghi nhận |

## 1. Mục tiêu và giới hạn

Nabi tạo mạng LAN-only trên Android, phục vụ giao thức XiaoZhi từ điện thoại, dùng Whisper tiếng Việt local, câu trả lời từ NanoBio backend, và Android TTS offline. ESP OSTB 3ST ghi/đọc Opus và hiển thị; điện thoại xử lý STT → backend response → TTS.

Mục tiêu MVP là một ESP trên Android. Mỗi lượt thoại yêu cầu session đăng nhập và Internet vì transcript/lịch sử hội thoại được gửi tới backend AI. iOS không có tile hoạt động trong MVP. Không lưu audio/transcript/hội thoại xuống ổ đĩa.

### Không nằm trong MVP

- Hỗ trợ nhiều ESP, iOS, Internet routing qua hotspot hoặc remote access.
- OTA firmware qua ứng dụng; lần cài firmware/partition đầu yêu cầu USB.
- TLS đầu cuối trong MVP đã nêu; bảo vệ mạng dựa trên phạm vi hotspot riêng, Security 2 cho provisioning BLE và khóa thiết bị cho giao thức app.
- Tự cấp quyền hệ điều hành hoặc bỏ qua xác nhận người dùng.

## 2. Actor và quyền

| Actor | Quyền dự kiến | Giới hạn |
|---|---|---|
| Signed-in user | Dùng ESP khi Whisper, backend AI session và voice offline đã sẵn sàng | Cần Internet/session để nhận câu trả lời; vẫn tuân theo khả năng thiết bị |
| Nabi Android | Tạo LocalOnlyHotspot, server và provisioning BLE theo xác nhận hệ điều hành | Một thiết bị mỗi phiên; không ghi bí mật/log hội thoại |
| ESP OSTB 3ST đã nạp đúng firmware | Gửi Opus, nhận cấu hình phiên, nhận lệnh điều khiển nghe | Firmware demo hiện tại không hỗ trợ luồng này |

## 3. Luồng đề xuất

1. Người dùng đăng nhập, cài Whisper và chọn voice Android TTS ngoại tuyến. Lần tải Whisper cần Internet.
2. Người dùng mở Feature Hub trên Android và bấm “Kết nối Nabi”. App chuẩn bị Whisper/TTS, xin quyền hệ điều hành, mở LocalOnlyHotspot và foreground service. Release button vẫn khóa trong khi review chờ.
3. App tự dò ESP qua BLE. Lần ghép đầu, ESP hiển thị mã 8 chữ số dùng làm Proof of Possession trong Security 2; app gửi SSID/mật khẩu hotspot hiện tại cùng hợp đồng cấu hình qua custom endpoint. App mã hóa khóa thiết bị bằng Android Keystore, ESP lưu khóa trong NVS. Các lần sau khóa đã ghép xác thực BLE rồi app gửi credential hotspot mới.
4. Một nguồn `iot/nabi_esp_contract.json` sinh hằng Dart, Kotlin và ESP. Hợp đồng hiện dùng protocol v3, cổng `8386`, OTA `/nabi/ota/`, WebSocket `/nabi/v1/`, BLE UUID/endpoint và `X-Nabi-Device-Key`. ESP lấy gateway DHCP, gọi OTA bằng khóa thiết bị và nhận URL WebSocket cùng bearer token phiên; server chỉ giữ một socket.
5. ESP gửi Opus mono 16 kHz theo lượt nghe. Điện thoại giải mã và nhận dạng bằng Whisper, gửi transcript cùng tối đa 6 lượt lịch sử trong RAM tới backend AI, tổng hợp câu trả lời bằng Android TTS offline và trả Opus mono 24 kHz. Payload hội thoại không được ghi log hoặc lưu xuống ổ đĩa.
6. Trang điều khiển gửi `nabi.control` (`listen.start`, `listen.stop`); firmware chuyển yêu cầu vào event loop và trả `nabi.control_ack` có request id/trạng thái. Người dùng dừng server từ trang/notification; app đóng socket, server và hotspot.

```mermaid
sequenceDiagram
    actor U as Người dùng
    participant A as Nabi Android
    participant E as ESP OSTB 3ST
    participant B as NanoBio backend
    U->>A: Kết nối Nabi
    A->>A: Chuẩn bị Whisper và voice offline
    A->>A: Xin quyền, mở LocalOnlyHotspot + foreground service
    U->>E: Bật ESP / nhập mã ghép lần đầu
    E->>A: BLE Security 2 + cấu hình Wi-Fi/custom endpoint
    E->>A: HTTP OTA qua gateway DHCP
    A-->>E: WebSocket URL, token phiên, protocol v3
    E->>A: WebSocket hello + Opus khi nghe
    A->>A: Whisper STT
    A->>B: Transcript + bounded history qua HTTPS
    B-->>A: Câu trả lời AI
    A->>A: Android TTS
    A-->>E: JSON trạng thái + Opus 24 kHz
    U->>A: Dừng phiên
    A-->>E: Đóng socket; giải phóng hotspot
```

## 4. Quy tắc bảo mật / dữ liệu

| ID | Quy tắc |
|---|---|
| NABI-ESP-BR01 | Không mở runtime trước Tech, QA và Privacy sign-off; PO intent đã có từ yêu cầu người dùng. |
| NABI-ESP-BR02 | Generated AI replies require an authenticated backend session; guests can keep the local ESP connection but cannot receive AI replies until signing in. |
| NABI-ESP-BR03 | Mỗi phiên tối đa một ESP và một kết nối WebSocket; từ chối kết nối thứ hai. |
| NABI-ESP-BR04 | Audio, transcript và hội thoại chỉ ở RAM; history tối đa 6 lượt; log chỉ trạng thái/loại lỗi, không có payload hoặc bí mật. |
| NABI-ESP-BR05 | OTA/WebSocket chỉ nhận thiết bị đã ghép; token phiên riêng; token, mật khẩu, mã ghép không xuất hiện trong UI log hoặc telemetry. |
| NABI-ESP-BR06 | BLE provisioning dùng Security 2; mã ghép đầu tiên hết hạn sau 2 phút. Khóa pairing được mã hóa bằng Android Keystore và lưu NVS phía ESP; không tuyên bố giới hạn số lần sai khi firmware chưa thực thi cơ chế này. |
| NABI-ESP-BR07 | LocalOnlyHotspot không có Internet; app không tự chuyển sang hotspot hệ thống nếu API không tạo được. |
| NABI-ESP-BR08 | Thiết bị đang nối có Flash Encryption tắt; khóa NVS có thể bị đọc khi truy cập vật lý flash. |
| NABI-ESP-BR09 | Do not claim AI replies work offline; Whisper and TTS are local, but generated replies require backend connectivity. |

## 5. Phụ thuộc và blocker

- Backend text response: `BackendVoiceChatTurnDatasource` and `BackendAiTextClient`.
- Local STT/TTS/audio: Flutter Whisper, Android voice capability, resample PCM and Opus.
- Native Android: LocalOnlyHotspot, BLE permissions/provisioning, foreground service `connectedDevice`, notification action.
- Firmware: Protocomm BLE + Security 2 + custom endpoint; dynamic OTA host from DHCP gateway; auth header; incoming control message/ack; display mã ghép; persistent paired key.
- Thiết bị: OSTB 3ST chạy XiaoZhi 2.5.3 / ESP-IDF 6.1, partition OTA 16 MiB. BLE Security 2 pairing, hotspot provisioning, DHCP, OTA config `/nabi/ota/`, WebSocket v3 và ACK listen controls đã qua thử thật; firmware app readback khớp. Backend voice round trip and TTS speaker output still need live acceptance. Xem [hồ sơ OSTB 3ST](../../../iot/xiaozhi-esp32/docs/agent-context/CONNECTED_DEVICE_OSTB_3ST.md) và [worklog tích hợp](../../worklog/2026-10-23/006-worklog-nabi-esp-ostb-auto-connect.md).

## 6. Review / acceptance gate

| Review | Trạng thái | Bằng chứng cần có |
|---|---|---|
| PO | Ý định được duyệt theo kế hoạch người dùng | Quyết định UX/quyền trong phiên 2026-10-23 |
| Tech | Chờ | Xác nhận API Android/FGS, BLE Security2, key lifecycle, protocol và firmware build |
| QA | Chờ | Test matrix quyền, background, hotspot lifecycle, one-device, reconnect và offline |
| Privacy | Chờ | Data flow/retention, audio/transcript boundary, logging, NVS/physical access và consent |
| Device | Một phần | BLE pairing, cấp hotspot, OTA config, WebSocket v3/control ACK đạt; cần voice round trip, reconnect/lifecycle nền và offline test |

Sau khi đủ review, cập nhật checklist, thiết kế, route/tile classification và bật feature flag. Không lấy build/test source làm thay thế acceptance trên Android/ESP thật.
