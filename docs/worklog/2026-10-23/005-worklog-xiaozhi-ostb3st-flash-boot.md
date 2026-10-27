Commit de xuat: docs(worklog): ghi nhan build va boot XiaoZhi OSTB 3ST

# Worklog - Build và boot XiaoZhi trên OSTB 3ST

## Thời gian

- Ngày: 2026-10-23
- Bắt đầu: khoảng 13:17 Asia/Ho_Chi_Minh (thời điểm chính xác không được ghi riêng)
- Kết thúc: 14:14 Asia/Ho_Chi_Minh
- Timezone: Asia/Ho_Chi_Minh (UTC+07:00)

## Phạm vi

- Loại task: build, nạp firmware và nghiệm thu boot trên thiết bị thật.
- Module chính: `iot/xiaozhi-esp32`, profile `ostb/ostb-xiaozhi-3st` với `config.local-ai.json`.
- Yêu cầu: dùng ESP-IDF 6.1, nạp đầy đủ firmware và xác nhận khởi động qua serial.
- Giữ nguyên các thay đổi IoT/app đã có trong worktree; không sửa source firmware.

## Bằng chứng trước khi ghi

- `fuser -v /dev/ttyACM0` không phát hiện tiến trình đang giữ cổng trước các thao tác serial.
- Đọc trực tiếp nhận diện ESP32-S3 revision 0.2, PSRAM 8 MB và flash 16 MB; kết quả khớp hồ sơ OSTB 3ST.
- Partition table cũ trên thiết bị là `nvs` 24 KiB tại `0x9000`, `phy_init` 4 KiB tại `0xF000`, `factory` 1 MiB tại `0x10000`.
- Theo lựa chọn của người dùng, không sao lưu/dump toàn flash. Firmware demo và nội dung NVS cũ không có bản dump để khôi phục.

## Build và image

- Môi trường: ESP-IDF 6.1.0, esptool 5.6.0, target `esp32s3`.
- Lệnh build:
  `python3 scripts/build.py ostb/ostb-xiaozhi-3st --config config.local-ai.json --name ostb-xiaozhi-3st`
- Build thành công, firmware project version 2.5.3; ứng dụng `xiaozhi.bin` là 2,593,104 byte (`0x279150`), nhỏ hơn OTA slot 4,587,520 byte (`0x460000`), còn 43% dung lượng trống.
- Flash addresses lấy từ `build/flasher_args.json`: bootloader `0x0`, partition table `0x8000`, OTA data `0xD000`, app `0x20000`, assets `0x8E0000`.
- Bảng partition được build cho flash 16 MB: NVS 16 KiB, otadata 8 KiB, hai OTA slot 4,480 KiB, assets 5,760 KiB, LittleFS 1,504 KiB và `nvs_user` 32 KiB.

| Image | Kích thước | SHA-256 |
|---|---:|---|
| `build/bootloader/bootloader.bin` | 15,536 B | `1d0d06b8039ccb9714c4bd99f12ce7f4b226fbbbb1a95772a681b2bdde69fd8f` |
| `build/partition_table/partition-table.bin` | 3,072 B | `46f90f6fe9b0263729524d1f77917e16d102a103f5ef52e57f416b4cdfc4bf39` |
| `build/ota_data_initial.bin` | 8,192 B | `7d2c7ac4888bfd75cd5f56e8d61f69595121183afc81556c876732fd3782c62f` |
| `build/xiaozhi.bin` | 2,593,104 B | `0878e7260a3b662dd83f58e6ee74c023b66bdda6473ddf7436c60a9b6a8c0805` |
| `build/generated_assets.bin` | 1,262,757 B | `6aeecc3d1c21504592a884b85dda25152419e7d54acdb2b0b3f0f395a40abd04` |
| `build/merged-binary.bin` | 10,568,869 B | `a0b3add11ec90a75645451028810fbd704cee1e84a6a137c5199a5d0aaf2a37b` |

## Nạp và readback

- Xóa riêng NVS mới `0x9000–0xCFFF` (16 KiB). Đọc lại ngay sau xóa xác nhận toàn vùng là `0xFF`.
- Ghi đủ bootloader, partition table, otadata, app và assets bằng esptool theo đúng địa chỉ từ build. Esptool báo hash ghi xác minh thành công cho từng image.
- `verify-flash` xác nhận bootloader, partition table, app và assets khớp image. Bảng partition đọc lại từ `0x8000` được parse thành công và xác nhận đủ hai OTA slot cùng các vùng assets/data.
- `ota_data_initial.bin` được build với toàn byte `0xFF` và đã được esptool xác minh khi ghi. Sau reset đầu tiên, readback cho thấy 12 byte metadata đã đổi sang các record OTA có sequence/CRC; vì vậy verify byte-for-byte so với seed ban đầu không còn đạt sau khi thiết bị khởi động. Đây là dữ liệu trạng thái OTA được cập nhật trong quá trình chọn slot/khởi động; log boot xác nhận ứng dụng từ `ota_0` đã chạy. Không ghi đè lại metadata sau boot.

## Boot serial

- Chạy `idf.py -p /dev/ttyACM0 monitor` ở 115200 baud; dừng monitor bình thường bằng Ctrl+].
- ROM báo `SPI_FAST_FLASH_BOOT`; app báo project `xiaozhi`, version 2.5.3, ESP-IDF v6.1, chip revision v0.2.
- Log xác nhận 8 MB PSRAM được nhận và đưa vào heap; board SKU `ostb-xiaozhi-3st` khởi tạo.
- Driver LCD NV3023 tạo thành công; LVGL, backlight, touch CST816S và codec ES8311/ES7210 khởi tạo. Wi-Fi đi vào chế độ cấu hình AP, DNS và web server cấu hình chạy tại `192.168.4.1` do NVS Wi-Fi sạch.
- Theo dõi khoảng 12 giây sau khi vào cấu hình: không thấy panic hoặc reset loop.
- Log khởi tạo LCD/backlight không chứng minh ảnh đang hiển thị đúng bằng mắt; cần ảnh/video mới để nghiệm thu hình ảnh vật lý.
- Chưa kiểm tra BLE provisioning, kết nối app Nabi, hội thoại AI hoặc âm thanh đầu-cuối. Trang Nabi hiện vẫn là preview theo release gate.

## Lệnh và kết quả

- ESP-IDF export 6.1 và lệnh build canonical ở trên: PASS.
- `python3 .../gen_esp32part.py build/partition_table/partition-table.bin`: PASS; bảng build hợp lệ.
- Kiểm tra app size so với OTA slot: PASS.
- Esptool `write-flash` cho 5 image: PASS; từng vùng được verify trong lúc ghi.
- `verify-flash`: bootloader, partition table, app, assets PASS; OTA seed được cập nhật sau reset đầu tiên như ghi chú trên.
- Readback/parse bảng phân vùng trên chip: PASS.
- Serial boot và khởi tạo board: PASS, không panic/reset loop trong thời gian quan sát.

## Rủi ro và giới hạn

- NVS cũ đã bị xóa theo kế hoạch và không có full-flash backup theo lựa chọn người dùng.
- Wi-Fi chưa cấu hình; firmware đang phát AP cấu hình riêng của XiaoZhi.
- Chỉ nghiệm thu build, flash, readback và boot firmware. Không nghiệm thu hình ảnh LCD bằng camera hay luồng Nabi trên điện thoại.
- Build có thông báo Kconfig/deprecation từ một số dependency; không làm build thất bại.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: firmware mới đã boot trên đúng board; bằng chứng từ build, flash readback, partition table và serial được ghi riêng theo từng lớp.
- Mức độ hoàn thành yêu cầu: hoàn tất build, nạp đủ image, reset và xác nhận boot. Nghiệm thu trực quan LCD và kết nối điện thoại nằm ngoài yêu cầu boot này.
- Điểm chưa tối ưu: `verify-flash` cho OTA seed chạy sau reset nên thấy trạng thái OTA đã thay đổi; với các lần nạp tiếp theo, xác minh OTA seed ngay sau ghi hoặc ghi rõ thời điểm bootloader/app cập nhật trạng thái.
- Cách tối ưu phiên sau: sau khi cổng serial được giải phóng, chụp ảnh LCD để kiểm tra UI và cấu hình lại Wi-Fi/OTA theo quy trình người dùng.
- Task-skill nên đọc lần sau: `.codex/task-skills/test.md` và `iot/xiaozhi-esp32/docs/agent-context/TASK_ROUTING.md`.
