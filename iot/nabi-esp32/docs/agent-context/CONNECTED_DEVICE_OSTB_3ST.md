# Hồ sơ thiết bị ESP: OSTB 3ST

## Mục đích và phạm vi

Lần đọc trực tiếp gần nhất được ghi ngày **2026-11-18**, sau khi build/nạp cloud contract v4 và kiểm tra boot/AP setup. App mới chưa chạy provisioning trên thiết bị; voice round trip chưa được nghiệm thu. Mọi task IoT/ESP32 phải đọc hồ sơ này trước khi chọn source hoặc chạy lệnh trên thiết bị. Chỉ áp dụng chân và giới hạn board khi target là OSTB 3ST; board khác phải dùng cấu hình riêng.

Hồ sơ tách dữ liệu thành ba mức bằng chứng:

- **Đọc từ thiết bị:** lấy bằng esptool qua USB Serial/JTAG hoặc log boot; mô tả trạng thái tại thời điểm kiểm tra.
- **Theo source/build:** lấy từ cấu hình board, hợp đồng dùng chung và artifact vừa build; không tự chứng minh hành vi kết nối với điện thoại.
- **Chưa xác minh:** cần thử nghiệm hoặc bằng chứng vật lý chưa có.

Trong lần ghi ngày 2026-11-18, chỉ đọc partition table và OTA metadata; không backup hoặc dump NVS, Wi-Fi credentials, token, khóa ghép đôi hay dữ liệu người dùng. Thao tác ghi chỉ nhắm app OTA0 tại `0x20000`; không ghi bootloader, partition table, OTA metadata, NVS, assets hay `nvs_user`. ACL serial tạm đã được gỡ sau khi hoàn tất thao tác thiết bị.

## Đọc trực tiếp từ thiết bị

| Thuộc tính | Giá trị | Bằng chứng |
| --- | --- | --- |
| Chip | ESP32-S3, package QFN56, revision 0.2 | `esptool chip-id`, trước và sau ghi |
| CPU/tính năng | Dual Core + LP Core, tối đa 240 MHz; Wi-Fi và Bluetooth LE | `esptool chip-id` |
| Tinh thể | 40 MHz | `esptool chip-id` |
| PSRAM | 8 MB embedded PSRAM, cấu hình AP_3v3 | `esptool chip-id` và boot log |
| Giao tiếp USB | USB-Serial/JTAG | esptool và USB descriptor; cổng có thể đổi |
| Cổng tại lần kiểm tra | `/dev/ttyACM0`; ACL tạm đã gỡ sau khi nạp | Host ngày 2026-11-18 |
| Flash | 16 MB; manufacturer ID `0x68`, device ID `0x4018`; quad/4 data lines; 3.3 V | `esptool flash-id` |
| Secure Boot | Tắt | `esptool get-security-info`, đọc trước khi ghi ngày 2026-10-23; không thay đổi eFuse trong task này |
| Flash Encryption | Tắt; `SPI_BOOT_CRYPT_CNT=0` | `esptool get-security-info`, đọc trước khi ghi ngày 2026-10-23 |
| Firmware project | Nabi; preserved OTA compatibility SKU `ostb-xiaozhi-3st` | Serial boot sau khi ghi app |
| Firmware version/build cuối đọc từ board | Nabi `2.5.3`, ESP-IDF `v6.1`, locale `vi-VN`, cloud contract v4 | Boot log ngày 2026-11-18 |
| App image hiện đã nạp | 2.759.072 byte (`0x2a19a0`), SHA-256 `d9f083822b8f3d90a70a484fecefbac894ea760c90683e970053eea93a844e7a` | esptool ghi OTA0 và xác minh hash thành công |
| App slot được chọn khi nạp | `ota_0`, offset `0x20000` | OTA metadata trước khi ghi: sequence `1`, CRC hợp lệ; metadata không bị ghi. Hard reset sau khi ghi. |
| NVS | Không dump hoặc ghi trực tiếp qua flash trong lượt này | Lệnh ghi chỉ nhắm app OTA0; không có lệnh ghi/erase NVS |

### Partition table đang nạp

Đã đọc trực tiếp 4 KB tại `0x8000` ngày 2026-11-18 trước khi ghi firmware. Bảng live khác partition CSV trong source/build. Cloud app Nabi được ghi riêng vào OTA0 live; firmware tìm assets theo label. Không ghi partition table để làm chúng khớp nhau.

| Tên | Loại/subtype | Offset | Kích thước |
| --- | --- | ---: | ---: |
| `nvs` | data / nvs | `0x9000` | `0x4000` (16 KB) |
| `otadata` | data / ota | `0xD000` | `0x2000` (8 KB) |
| `phy_init` | data / phy | `0xF000` | `0x1000` (4 KB) |
| `ota_0` | app / ota_0 | `0x20000` | `0x3F0000` (4,032 KB) |
| `ota_1` | app / ota_1 | `0x410000` | `0x3F0000` (4,032 KB) |
| `assets` | data / spiffs | `0x800000` | `0x800000` (8,192 KB) |

### Boot và kết nối đã kiểm tra

- Cloud image contract v4 boot qua `After board/audio init`; firmware ghi nhận sẵn sàng cho local Wi-Fi provisioning và hiển thị trạng thái cấu hình AP.
- Chưa dùng APK mới để gọi `/nabi/status`/`/nabi/provision`, đăng nhập thiết bị, xác nhận Wi-Fi nhà hoặc chạy voice round trip. Boot/AP log không chứng minh các bước đó; người dùng sẽ chạy APK sau.
- Đã đọc OTA metadata ngay trước khi ghi: sequence `1`, CRC hợp lệ, chọn OTA0. Chỉ app image tại `0x20000` được ghi; NVS và OTA metadata không bị ghi.
- Lịch sử E2E ngày 2026-10-23: Nabi mở Android LocalOnlyHotspot và foreground service; BLE Security 2 provisioning, DHCP, HTTP OTA config và WebSocket v3/control ACK đã được thử với firmware trước đó. Không lặp lại các bước E2E này sau lần build ngày 2026-11-14.
- Lịch sử xử lý thoại ngày 2026-10-23: lượt Whisper/LLM trên điện thoại thử nghiệm vượt thời gian chờ; phản hồi TTS/âm thanh đầu-cuối chưa được nghiệm thu.
- ACL `u:daovh:rw` đã gỡ sau khi thao tác hoàn tất. Không ghi token, key, mã ghép đôi, SSID hoặc mật khẩu vào hồ sơ.
- Chưa có ảnh/video để xác nhận nội dung hiển thị LCD; boot/khởi tạo driver không phải bằng chứng hiển thị vật lý.

## Cấu hình OSTB 3ST trong source/build

Nguồn: [`README.md`](../../main/boards/ostb/ostb-nabi-3st/README.md), [`config.h`](../../main/boards/ostb/ostb-nabi-3st/config.h), [`config.json`](../../main/boards/ostb/ostb-nabi-3st/config.json), [`config.local-ai.json`](../../main/boards/ostb/ostb-nabi-3st/config.local-ai.json), [`partition CSV`](../../partitions/ostb-nabi-3st-16m.csv), và [hợp đồng Nabi](../../../nabi_esp_contract.json).

Giá trị dưới đây mô tả source/build, không phải phép đọc từng chân hoặc ngoại vi trên bo mạch:

| Thành phần | Cấu hình source/build |
| --- | --- |
| Board/build identity | Display label `OSTB Nabi 3ST`; manufacturer `ostb`; preserved type/variant ID `ostb-xiaozhi-3st`; target `esp32s3` |
| Flash build options | 16 MB, DIO, 80 MHz |
| Partition source profile | CSV source: OTA app `ota_0` tại `0x20000`, `ota_1` tại `0x480000`; `assets` tại `0x8E0000`; `data` tại `0xE80000`; `nvs_user` tại `0xFF8000`. Bảng live hiện tại khác các offset/kích thước này. |
| LCD | NV3023, panel 240×296; giao diện landscape 296×240; SPI CLK/MOSI GPIO 9/10, CS/DC/reset GPIO 14/8/18, backlight GPIO 13; SPI 10 MHz; offset X/Y 24/0, swap XY và mirror X/Y bật; BGR |
| Touch | CST816-series, I2C address `0x15`; I2C port 1, SDA/SCL GPIO 12/11 |
| Audio | ES7210 microphone ADC và ES8311 speaker codec; 24 kHz input/output; I2S MCLK/BCLK/WS GPIO 5/15/16, mic DIN GPIO 7, speaker DOUT GPIO 6, amplifier enable GPIO 4 active-high |
| Nút | Boot GPIO 0; volume down/up GPIO 39/40 |
| Cloud assistant transport | Cloud contract v4; voice protocol v3; device-login qua `https://nanobio.s2w.click/api/v1/iot/devices/credentials/login`; WSS `/api/v1/iot/ws`; cấu hình tại WPA2 AP `192.168.4.1`, không cần mobile data |
| Cloud AP protection | AP WPA2 `Nabi-xxxx`; mật khẩu tạm 8 chữ số trên màn hình; mỗi phiên nhận một lần provision rồi chuyển sang station |
| Cloud contract v4 artifact | `iot/nabi-esp32/build/nabi.bin`, 2.759.072 byte, SHA-256 `d9f083822b8f3d90a70a484fecefbac894ea760c90683e970053eea93a844e7a` | ESP-IDF 6.1 build, OTA0 flash/hash verification và boot/AP mode pass |
| Local phone-AI profile | Contract v3; TCP port `8386`; OTA `/nabi/ota/`; WebSocket `/nabi/v1/`; provisioning BLE Security 2 |
| Phone-local hotspot | Android LocalOnlyHotspot cấp SSID/mật khẩu theo phiên; không cố định `NabiAI`/`12345678` |
| OTA source fallback | `CONFIG_OTA_URL=http://0.0.0.0:8386/nabi/ota/`, `CONFIG_OTA_URL_IGNORE_NVS=y`; lúc đã có gateway DHCP, firmware tạo URL `http://<gateway>:8386/nabi/ota/` |

## Giới hạn kết luận và việc còn lại

- Firmware cloud contract v4 đã được ghi riêng vào OTA0 live, xác minh hash và boot tới board/audio initialization; log xác nhận firmware sẵn sàng cho cấu hình AP. Không backup hoặc ghi NVS/OTA metadata/partition table.
- Chưa nghiệm thu luồng trả lời giọng nói hoàn chỉnh, hồi phục sau nhiều chu kỳ tắt/bật hotspot, chế độ màn hình khóa/Doze hoặc hội thoại sau khi ngắt Internet. Hiệu năng local AI trên điện thoại thử chưa đạt phản hồi trong thời gian quan sát.
- Feature Hub vẫn giữ cổng Tech/QA/Privacy trước phát hành. Chưa có ảnh/video LCD. Không suy ra hình LCD từ log khởi tạo.
- Cloud contract v4 đã được ghi và esptool xác minh byte/hash; board/audio init và AP config mode đã thấy trong boot log. Chưa nghiệm thu v4 AP provisioning qua app, device-login/refresh/revoke, WSS voice, consent hoặc TTS. Nếu board/firmware/partition hoặc host thay đổi, đọc lại thiết bị trước thao tác; giữ ranh giới giữa dữ liệu đo trực tiếp, source/build và chưa xác minh. Không ghi mật khẩu, token, khóa ghép đôi, transcript, audio, MAC đầy đủ hoặc serial vào agent context.
