Commit de xuat: feat(nabi-esp): provision ESP OSTB qua hotspot Nabi

# Nabi - Siêu trợ lý AI kết nối ESP OSTB 3ST

## Trạng thái

PO intent đã được duyệt theo kế hoạch người dùng ngày 2026-10-23. Đợt này nối ứng dụng Nabi Android với profile firmware OSTB 3ST bằng một hợp đồng sinh từ `iot/nabi_esp_contract.json`. Tính năng vẫn ở trạng thái review-gated; Tech, QA và Privacy chưa sign-off. Build hoặc phép thử source không tự mở cổng phát hành.

## Trải nghiệm dự kiến

Người dùng chuẩn bị model GGUF, Whisper và voice Android TTS offline; bấm “Kết nối Nabi” để app khởi động LocalOnlyHotspot, foreground service và AI server. Android tự chọn SSID/mật khẩu. App dò ESP qua BLE, lần ghép đầu yêu cầu mã 8 chữ số đang hiển thị trên ESP, rồi gửi credential hotspot hiện tại qua Security 2. ESP kết nối Wi-Fi và gọi gateway DHCP trên `/nabi/ota/`. MVP phục vụ một ESP; Guest/Free dùng được nếu local AI sẵn sàng, theo quyết định quyền trước đó.

## Trạng thái hiện tại

- Tile chỉ xuất hiện Android, trong “Sắp ra mắt”; iOS không hiển thị. Nút kết nối giữ cổng review hiện hành.
- Android dùng LocalOnlyHotspot, service nền `connectedDevice`, HTTP OTA/WebSocket v3 trên cổng 8386, khóa thiết bị cho OTA và bearer token riêng cho WebSocket. Pipeline dùng local Whisper, model Nabi, TTS và Opus; audio/hội thoại giữ trong RAM.
- Android BLE provisioning dùng Espressif Provisioning Android Security 2; khóa ghép được mã hóa bằng Android Keystore. Ghép đôi lần đầu và cấp cấu hình Wi-Fi đã chạy trên điện thoại/ESP thật.
- Firmware profile OSTB 3ST có BLE Security 2, mã ghép đầu tiên hết hạn sau 2 phút, khóa pairing sau 5 mã sai tới lần khởi động kế tiếp, lưu khóa trong NVS, gửi Wi-Fi qua custom endpoint và tạo OTA URL bằng gateway DHCP. Manual config AP còn làm đường phục hồi.
- Firmware tích hợp được build/nạp vào OTA0; BLE provisioning, DHCP, `/nabi/ota/`, WebSocket v3 và ACK cho lệnh nghe/dừng đã được xác nhận. Firmware image đã đọc lại và khớp hash.
- Hội thoại giọng nói chưa nghiệm thu: lượt local Whisper/LLM quá 3 phút, chưa xác nhận TTS ra loa ESP. Cũng chưa thử phục hồi nhiều lần sau hotspot restart, màn hình khóa/Doze hoặc hội thoại khi ngắt Internet. Chi tiết ở [worklog tích hợp](../../worklog/2026-10-23/006-worklog-nabi-esp-ostb-auto-connect.md), [DD module](../../DD/nabi_esp_assistant/README.md) và [hồ sơ ESP](../../../iot/xiaozhi-esp32/docs/agent-context/CONNECTED_DEVICE_OSTB_3ST.md).

## Mở khóa triển khai

Đã build/cài Nabi Android, build/flash app partition tương thích đồng thời giữ NVS, và thử hotspot, BLE, OTA config cùng WebSocket v3/control trên điện thoại/ESP thật. Còn cần xác nhận hội thoại TTS/loa, hotspot restart, màn hình khóa/Doze và hành vi offline. Tech xác nhận giao thức, khóa và lifecycle; QA hoàn tất ma trận quyền/nền/kết nối; Privacy duyệt data flow, retention, logging và lưu khóa NVS. Không mở tính năng trong release trước khi đủ review và nghiệm thu.
