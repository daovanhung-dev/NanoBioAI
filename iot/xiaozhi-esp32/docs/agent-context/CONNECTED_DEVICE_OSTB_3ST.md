# Hồ sơ ESP đang kết nối: OSTB 3ST

## Mục đích và phạm vi

Ảnh chụp thiết bị được cập nhật ngày **2026-10-23**, sau khi build và nạp app Nabi/ESP. Mọi task IoT/ESP32 phải đọc hồ sơ này trước khi chọn source hoặc chạy lệnh trên thiết bị. Chỉ áp dụng chân và giới hạn board khi target là OSTB 3ST; board khác phải dùng cấu hình riêng.

Hồ sơ tách dữ liệu thành ba mức bằng chứng:

- **Đọc từ thiết bị:** lấy bằng esptool qua USB Serial/JTAG hoặc log boot; mô tả trạng thái tại thời điểm kiểm tra.
- **Theo source/build:** lấy từ cấu hình board, hợp đồng dùng chung và artifact vừa build; không tự chứng minh hành vi kết nối với điện thoại.
- **Chưa xác minh:** cần thử nghiệm hoặc bằng chứng vật lý chưa có.

Trong phiên này, không đọc NVS, Wi-Fi credentials, token, khóa ghép đôi hay dữ liệu người dùng. Không lưu MAC/serial đầy đủ hoặc mã ghép đôi vào hồ sơ. Ghi flash chỉ nhắm app OTA0 tại `0x20000`; không ghi bootloader, partition table, OTA metadata, NVS, assets hay `nvs_user`.

## Đọc trực tiếp từ thiết bị

| Thuộc tính | Giá trị | Bằng chứng |
| --- | --- | --- |
| Chip | ESP32-S3, package QFN56, revision 0.2 | `esptool chip-id`, trước và sau ghi |
| CPU/tính năng | Dual Core + LP Core, tối đa 240 MHz; Wi-Fi và Bluetooth LE | `esptool chip-id` |
| Tinh thể | 40 MHz | `esptool chip-id` |
| PSRAM | 8 MB embedded PSRAM, cấu hình AP_3v3 | `esptool chip-id` và boot log |
| Giao tiếp USB | USB-Serial/JTAG | esptool và USB descriptor; cổng có thể đổi |
| Cổng tại lần kiểm tra | `/dev/ttyACM0` | Trạng thái host ngày 2026-10-23 |
| Flash | 16 MB; manufacturer ID `0x68`, device ID `0x4018`; quad/4 data lines; 3.3 V | `esptool flash-id` |
| Secure Boot | Tắt | `esptool get-security-info`, đọc trước khi ghi ngày 2026-10-23; không thay đổi eFuse trong task này |
| Flash Encryption | Tắt; `SPI_BOOT_CRYPT_CNT=0` | `esptool get-security-info`, đọc trước khi ghi ngày 2026-10-23 |
| Firmware project | `xiaozhi`, board SKU `ostb-xiaozhi-3st` | Serial boot sau khi ghi app |
| Firmware version/build | Version `2.5.3`, ESP-IDF `v6.1`; image auto-open WebSocket build ngày `2026-10-23` | App descriptor của firmware boot trước đó; artifact mới build và hash/readback đối chiếu |
| App image vừa nạp | 3,012,384 byte (`0x2DF720`), SHA-256 `4e012dccd32b4320c5c7da8f7cc28973c438a7855ea30481445db635f2013dfd` | Build artifact, esptool write verification và lần đọc lại app-range sau khi nạp |
| App slot đang chạy | `ota_0`, offset `0x20000` | OTA metadata sequence `1`, CRC hợp lệ; serial boot |
| NVS | Không dump hoặc thao tác trực tiếp qua flash; BLE provisioning đã lưu thông tin ghép đôi và Wi-Fi theo luồng firmware | Esptool chỉ ghi app `0x20000..0x2FFFFF`; kết quả provisioning trên thiết bị |

### Partition table đang nạp

Đã đọc trực tiếp 3 KB tại `0x8000` trước và sau khi ghi app. Bytes khớp partition table của build hiện tại.

| Tên | Loại/subtype | Offset | Kích thước |
| --- | --- | ---: | ---: |
| `nvs` | data / nvs | `0x9000` | `0x4000` (16 KB) |
| `otadata` | data / ota | `0xD000` | `0x2000` (8 KB) |
| `phy_init` | data / phy | `0xF000` | `0x1000` (4 KB) |
| `ota_0` | app / ota_0 | `0x20000` | `0x460000` (4,480 KB) |
| `ota_1` | app / ota_1 | `0x480000` | `0x460000` (4,480 KB) |
| `assets` | data / spiffs | `0x8E0000` | `0x5A0000` (5,760 KB) |
| `data` | data / littlefs | `0xE80000` | `0x178000` (1,504 KB) |
| `nvs_user` | data / nvs | `0xFF8000` | `0x8000` (32 KB) |

### Boot và kết nối đã kiểm tra

- Firmware XiaoZhi version `2.5.3`, ESP-IDF `v6.1`; boot gần nhất xác nhận Nabi BLE provisioning sẵn sàng, Wi-Fi station chạy và không thấy panic trong khoảng 50 giây monitor. Hotspot điện thoại đã dừng nên station không thấy AP. App image mới nhất đã được đọc lại; bytes khớp hoàn toàn với build artifact. BLE provisioning đã lưu khóa ghép đôi và credentials theo API firmware; dữ liệu NVS không bị dump hoặc đọc trực tiếp.
- Nabi đã mở Android LocalOnlyHotspot và foreground service. BLE scan nhận thiết bị OSTB; ghép đôi Security 2 lần đầu và gửi cấu hình Wi-Fi thành công. ESP nhận DHCP address rồi gọi gateway tại cổng `8386`, đường dẫn `/nabi/ota/`; server trả cấu hình OTA/WS v3.
- Sau thay đổi auto-open, ESP thiết lập WebSocket khi nhận OTA. Nabi nhận ACK cho lệnh `listen.start`; `listen.stop` kết thúc lượt nghe và chuyển app sang trạng thái xử lý local AI.
- Chưa xác nhận đầu-cuối câu trả lời có tiếng nói: lượt Whisper/LLM trên điện thoại thử nghiệm vẫn xử lý sau hơn 3 phút và đã bị dừng. Vì vậy chưa nghiệm thu phản hồi TTS/âm thanh từ loa ESP.
- Lần đọc lại cuối cùng dùng esptool đã reset ESP. Hotspot/service đã dừng; điện thoại trở về Wi-Fi thường và Bluetooth tắt. Không ghi NVS, token, key, mã ghép đôi, SSID hoặc mật khẩu vào hồ sơ.
- Chưa có ảnh/video để xác nhận nội dung hiển thị LCD; boot/khởi tạo driver không phải bằng chứng hiển thị vật lý.

## Cấu hình OSTB 3ST trong source/build

Nguồn: [`README.md`](../../main/boards/ostb/ostb-xiaozhi-3st/README.md), [`config.h`](../../main/boards/ostb/ostb-xiaozhi-3st/config.h), [`config.json`](../../main/boards/ostb/ostb-xiaozhi-3st/config.json), [`config.local-ai.json`](../../main/boards/ostb/ostb-xiaozhi-3st/config.local-ai.json), [`partition CSV`](../../partitions/ostb-xiaozhi-3st-16m.csv), và [hợp đồng Nabi](../../../nabi_esp_contract.json).

Giá trị dưới đây mô tả source/build, không phải phép đọc từng chân hoặc ngoại vi trên bo mạch:

| Thành phần | Cấu hình source/build |
| --- | --- |
| Board/build identity | Manufacturer `ostb`, type/variant `ostb-xiaozhi-3st`, target `esp32s3` |
| Flash build options | 16 MB, DIO, 80 MHz |
| Partition source profile | OTA app `ota_0` tại `0x20000`, `ota_1` tại `0x480000`; `assets` tại `0x8E0000`; `data` tại `0xE80000`; `nvs_user` tại `0xFF8000` |
| LCD | NV3023, panel 240×296; giao diện landscape 296×240; SPI CLK/MOSI GPIO 9/10, CS/DC/reset GPIO 14/8/18, backlight GPIO 13; SPI 10 MHz; offset X/Y 24/0, swap XY và mirror X/Y bật; BGR |
| Touch | CST816-series, I2C address `0x15`; I2C port 1, SDA/SCL GPIO 12/11 |
| Audio | ES7210 microphone ADC và ES8311 speaker codec; 24 kHz input/output; I2S MCLK/BCLK/WS GPIO 5/15/16, mic DIN GPIO 7, speaker DOUT GPIO 6, amplifier enable GPIO 4 active-high |
| Nút | Boot GPIO 0; volume down/up GPIO 39/40 |
| Nabi transport contract | Protocol v3; TCP port `8386`; OTA path `/nabi/ota/`; WebSocket path `/nabi/v1/`; gateway lấy từ DHCP; BLE provisioning Security 2 |
| Pairing protection | Mã 8 chữ số hết hạn sau 2 phút; sau 5 lỗi xác thực Security 2, pairing bị khóa đến lần khởi động kế tiếp |
| Hotspot credentials | Android LocalOnlyHotspot cấp SSID/mật khẩu theo phiên; không cố định `NabiAI`/`12345678` |
| OTA source fallback | `CONFIG_OTA_URL=http://0.0.0.0:8386/nabi/ota/`, `CONFIG_OTA_URL_IGNORE_NVS=y`; lúc đã có gateway DHCP, firmware tạo URL `http://<gateway>:8386/nabi/ota/` |

## Giới hạn kết luận và việc còn lại

- App debug được build/cài trên Android 11; firmware được build với ESP-IDF 6.1 và chỉ ghi vào OTA0. Đã kiểm tra BLE pairing, cấp credentials hotspot, DHCP, HTTP OTA và WebSocket v3/control ACK trên thiết bị thật.
- Chưa nghiệm thu luồng trả lời giọng nói hoàn chỉnh, hồi phục sau nhiều chu kỳ tắt/bật hotspot, chế độ màn hình khóa/Doze hoặc hội thoại sau khi ngắt Internet. Hiệu năng local AI trên điện thoại thử chưa đạt phản hồi trong thời gian quan sát.
- Feature Hub vẫn giữ cổng Tech/QA/Privacy trước phát hành. Chưa có ảnh/video LCD. Không suy ra hình LCD từ log khởi tạo.
- Nếu board/firmware/partition hoặc host thay đổi, đọc lại thiết bị trước thao tác; giữ ranh giới giữa dữ liệu đo trực tiếp, source/build và chưa xác minh. Không ghi mật khẩu, token, khóa ghép đôi, transcript, audio, MAC đầy đủ hoặc serial vào agent context.
