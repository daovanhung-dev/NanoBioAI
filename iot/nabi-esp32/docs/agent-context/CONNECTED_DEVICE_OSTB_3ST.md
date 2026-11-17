# Hồ sơ ESP đang kết nối: OSTB 3ST

## Mục đích và phạm vi

Ảnh chụp thiết bị được cập nhật ngày **2026-11-14**, sau khi build và nạp app Nabi. Mọi task IoT/ESP32 phải đọc hồ sơ này trước khi chọn source hoặc chạy lệnh trên thiết bị. Chỉ áp dụng chân và giới hạn board khi target là OSTB 3ST; board khác phải dùng cấu hình riêng.

Hồ sơ tách dữ liệu thành ba mức bằng chứng:

- **Đọc từ thiết bị:** lấy bằng esptool qua USB Serial/JTAG hoặc log boot; mô tả trạng thái tại thời điểm kiểm tra.
- **Theo source/build:** lấy từ cấu hình board, hợp đồng dùng chung và artifact vừa build; không tự chứng minh hành vi kết nối với điện thoại.
- **Chưa xác minh:** cần thử nghiệm hoặc bằng chứng vật lý chưa có.

Trong lần kiểm tra này, chỉ đọc partition table và OTA metadata, không dump NVS, Wi-Fi credentials, token, khóa ghép đôi hay dữ liệu người dùng. Thao tác ghi chỉ nhắm app OTA0 tại `0x20000`; không ghi bootloader, partition table, OTA metadata, NVS, assets hay `nvs_user`. ACL serial được cấp tạm rồi gỡ sau khi xác minh boot.

## Đọc trực tiếp từ thiết bị

| Thuộc tính | Giá trị | Bằng chứng |
| --- | --- | --- |
| Chip | ESP32-S3, package QFN56, revision 0.2 | `esptool chip-id`, trước và sau ghi |
| CPU/tính năng | Dual Core + LP Core, tối đa 240 MHz; Wi-Fi và Bluetooth LE | `esptool chip-id` |
| Tinh thể | 40 MHz | `esptool chip-id` |
| PSRAM | 8 MB embedded PSRAM, cấu hình AP_3v3 | `esptool chip-id` và boot log |
| Giao tiếp USB | USB-Serial/JTAG | esptool và USB descriptor; cổng có thể đổi |
| Cổng tại lần kiểm tra | `/dev/ttyACM0`; ACL tạm đã gỡ, quyền trở lại `root:uucp` | Host ngày 2026-11-14 |
| Flash | 16 MB; manufacturer ID `0x68`, device ID `0x4018`; quad/4 data lines; 3.3 V | `esptool flash-id` |
| Secure Boot | Tắt | `esptool get-security-info`, đọc trước khi ghi ngày 2026-10-23; không thay đổi eFuse trong task này |
| Flash Encryption | Tắt; `SPI_BOOT_CRYPT_CNT=0` | `esptool get-security-info`, đọc trước khi ghi ngày 2026-10-23 |
| Firmware project | Nabi; preserved OTA compatibility SKU `ostb-xiaozhi-3st` | Serial boot sau khi ghi app |
| Firmware version/build | Nabi `2.5.3`, ESP-IDF `v6.1`, cấu hình lời chào `vi-VN` | Artifact cuối build ngày 2026-11-14 |
| App image vừa nạp | 3.178.000 byte (`0x307e10`), SHA-256 `476d9864b0575dc6c0bd84b4462a7c82ee2b6962daab19236cd0dc8f07efc554` | esptool ghi OTA0 và xác minh hash thành công |
| App slot đang chạy | `ota_0`, offset `0x20000` | OTA metadata trước khi nạp: sequence `1`, state `VALID`, CRC hợp lệ; hard reset và monitor nhận marker khởi tạo ứng dụng |
| NVS | Không dump hoặc ghi trực tiếp qua flash trong lần kiểm tra này | Chỉ ghi app OTA0; không có lệnh ghi/erase NVS |

### Partition table đang nạp

Đã đọc trực tiếp 4 KB tại `0x8000` ngày 2026-11-14. Bảng live khác partition CSV trong source/build. App Nabi vừa nạp vừa OTA0 live; firmware tìm assets theo label. Không ghi partition table để làm chúng khớp nhau.

| Tên | Loại/subtype | Offset | Kích thước |
| --- | --- | ---: | ---: |
| `nvs` | data / nvs | `0x9000` | `0x4000` (16 KB) |
| `otadata` | data / ota | `0xD000` | `0x2000` (8 KB) |
| `phy_init` | data / phy | `0xF000` | `0x1000` (4 KB) |
| `ota_0` | app / ota_0 | `0x20000` | `0x3F0000` (4,032 KB) |
| `ota_1` | app / ota_1 | `0x410000` | `0x3F0000` (4,032 KB) |
| `assets` | data / spiffs | `0x800000` | `0x800000` (8,192 KB) |

### Boot và kết nối đã kiểm tra

- Firmware Nabi `2.5.3` boot từ OTA0 sau khi esptool xác minh hash và hard reset. IDF monitor ghi nhận `Project name: nabi`, `After board/audio init`, rồi bắt đầu quét Wi-Fi; không thấy marker crash trong khoảng 21 giây quan sát. Đây là bằng chứng app khởi tạo board/audio, không xác nhận trực quan LCD hoặc toàn bộ luồng mạng.
- Trong lượt quan sát này station không tìm thấy AP đã lưu và tiếp tục quét; chưa xác minh HTTP/captive portal bằng trình duyệt tại `192.168.4.1`.
- Lần đọc OTA metadata trước khi ghi cho thấy sequence `1`, CRC hợp lệ, chọn OTA0. Không ghi hoặc đổi OTA metadata khi triển khai.
- Lịch sử E2E ngày 2026-10-23: Nabi mở Android LocalOnlyHotspot và foreground service; BLE Security 2 provisioning, DHCP, HTTP OTA config và WebSocket v3/control ACK đã được thử với firmware trước đó. Không lặp lại các bước E2E này sau lần build ngày 2026-11-14.
- Lịch sử xử lý thoại ngày 2026-10-23: lượt Whisper/LLM trên điện thoại thử nghiệm vượt thời gian chờ; phản hồi TTS/âm thanh đầu-cuối chưa được nghiệm thu.
- ACL của user `daovh` trên `/dev/ttyACM0` đã được gỡ; host trở về quyền `root:uucp`. Không ghi token, key, mã ghép đôi, SSID hoặc mật khẩu vào hồ sơ.
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
| Nabi transport contract | Protocol v3; TCP port `8386`; OTA path `/nabi/ota/`; WebSocket path `/nabi/v1/`; gateway lấy từ DHCP; BLE provisioning Security 2 |
| Pairing protection | Mã 8 chữ số hết hạn sau 2 phút; sau 5 lỗi xác thực Security 2, pairing bị khóa đến lần khởi động kế tiếp |
| Hotspot credentials | Android LocalOnlyHotspot cấp SSID/mật khẩu theo phiên; không cố định `NabiAI`/`12345678` |
| OTA source fallback | `CONFIG_OTA_URL=http://0.0.0.0:8386/nabi/ota/`, `CONFIG_OTA_URL_IGNORE_NVS=y`; lúc đã có gateway DHCP, firmware tạo URL `http://<gateway>:8386/nabi/ota/` |

## Giới hạn kết luận và việc còn lại

- Firmware Nabi cuối được build với ESP-IDF 6.1, ghi riêng vào OTA0 live và boot tới board/audio initialization. BLE pairing, hotspot, DHCP, HTTP OTA và WebSocket v3/control ACK là kết quả E2E của firmware trước đó, chưa chạy lại sau lần cập nhật cuối.
- Chưa nghiệm thu luồng trả lời giọng nói hoàn chỉnh, hồi phục sau nhiều chu kỳ tắt/bật hotspot, chế độ màn hình khóa/Doze hoặc hội thoại sau khi ngắt Internet. Hiệu năng local AI trên điện thoại thử chưa đạt phản hồi trong thời gian quan sát.
- Feature Hub vẫn giữ cổng Tech/QA/Privacy trước phát hành. Chưa có ảnh/video LCD. Không suy ra hình LCD từ log khởi tạo.
- Nếu board/firmware/partition hoặc host thay đổi, đọc lại thiết bị trước thao tác; giữ ranh giới giữa dữ liệu đo trực tiếp, source/build và chưa xác minh. Không ghi mật khẩu, token, khóa ghép đôi, transcript, audio, MAC đầy đủ hoặc serial vào agent context.
