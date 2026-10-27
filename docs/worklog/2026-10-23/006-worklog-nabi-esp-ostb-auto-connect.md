Commit de xuat: feat(iot): tích hợp kết nối Nabi tự động với OSTB 3ST

# Worklog - Nabi tự kết nối với ESP OSTB 3ST

## Thời gian

- Ngày: 2026-10-23
- Bắt đầu: phiên tiếp tục từ trạng thái build đang chạy; giờ bắt đầu không được lưu riêng.
- Kết thúc: sau 21:49 Asia/Ho_Chi_Minh; phút kết thúc chưa được ghi riêng.
- Timezone: Asia/Ho_Chi_Minh (UTC+07:00).

## Phạm vi

- Tích hợp hợp đồng dùng chung cho Nabi Android và firmware XiaoZhi OSTB 3ST.
- Build/cài app debug trên Xiaomi Android 11; build firmware ESP-IDF 6.1.
- Nạp duy nhất app image vào OTA0 sau khi xác minh chip, flash, bảng phân vùng và slot đang chạy.
- Không sửa `iot/xiaozhi-esp32/phone_app/`; các thay đổi sẵn có trong worktree được giữ nguyên.

## Hợp đồng và mã nguồn

- Canonical contract: `iot/nabi_esp_contract.json`; generator tạo Dart, Kotlin và C constants; protocol v3, port `8386`, OTA `/nabi/ota/`, WebSocket `/nabi/v1/`, SSID/password từ Android LocalOnlyHotspot, host lấy từ DHCP gateway.
- Android dùng `LocalOnlyHotspot`, foreground notification và BLE provisioning Security 2; khóa thiết bị lưu bằng Android Keystore. Lần ghép đầu dùng mã tạm trên ESP, các lần sau dùng khóa đã ghép.
- Firmware OSTB bắt đầu BLE provisioning, nhận hotspot credentials và đổi sang station; OTA gọi gateway động. Server yêu cầu device key cho OTA và token phiên cho WebSocket.
- Mã ghép đầu tiên hết hạn sau 2 phút; bộ đếm lỗi Security 2 khóa pairing sau 5 mã sai đến khi ESP khởi động lại. Cơ chế này đã build và nạp; không thử sai/hết hạn trên board đã ghép vì cần đổi trạng thái NVS hoặc chờ hết hạn.
- Có fallback AP cấu hình XiaoZhi. Các thay đổi chỉ áp dụng build profile OSTB 3ST.
- Feature Hub vẫn hiển thị “Sắp ra mắt” theo cổng Tech/QA/Privacy; không mở cho phát hành và không khẳng định đã nghiệm thu giao tiếp trên điện thoại thật.

## Build và kiểm tra ứng dụng Nabi

- `python3 iot/tools/generate_nabi_esp_contract.py --check`: PASS, output Dart/Android/ESP đồng bộ.
- `flutter analyze lib/app_versions/v1/features/nabi_esp_assistant test/features/nabi_esp_assistant`: PASS, không có diagnostic.
- `flutter test test/features/nabi_esp_assistant test/features/features_hub/features_hub_page_test.dart`: PASS (16 test; gồm server/contract/UI assistant và Feature Hub).
- `flutter build apk --debug`: PASS.
- APK `build/app/outputs/flutter-apk/app-debug.apk`: 808,006,004 byte; SHA-256 `049f0e9248abf3a7729132dd2a16a7e8a2ea70c859d3c8bec88d0f3ff928e6e5`.
- Cài bằng `adb install -r` lên thiết bị Android 11 model `220333QPG`, package `com.nanobioai.app`, version `1.0.2`/versionCode `7`: PASS. App mở vào MainActivity, không có crash trong logcat tại thời điểm kiểm tra.
- Flutter `attach` kết nối VM service và hot restart thành công.
- Trên app đã chuẩn bị model local, Whisper và voice offline; nút Kết nối mở hotspot/server và giao diện nhận trạng thái thiết bị. Feature Hub vẫn mang cổng “Sắp ra mắt” cho tới Tech/QA/Privacy review.
- Gradle cảnh báo các phiên bản Gradle 8.14.0, AGP 8.11.1 và Kotlin 2.2.20 sắp hết mức hỗ trợ trong bản Flutter tương lai; hiện không làm build lỗi.

## Build firmware và thiết bị trước khi ghi

- Môi trường ESP-IDF 6.1.0, esptool 5.6.0, target `esp32s3`.
- Lệnh build:
  `python3 scripts/build.py ostb/ostb-xiaozhi-3st --config config.local-ai.json --name ostb-xiaozhi-3st`
- Build PASS sau thay đổi auto-open WebSocket và giới hạn sai mã ghép. App image `build/xiaozhi.bin`: 3,012,384 byte (`0x2DF720`), SHA-256 `4e012dccd32b4320c5c7da8f7cc28973c438a7855ea30481445db635f2013dfd`; OTA slot 4,587,520 byte (`0x460000`), còn khoảng 34% dung lượng.
- `build/flasher_args.json` chứa bootloader `0x0`, partition `0x8000`, OTA data `0xD000`, app `0x20000` và assets `0x8E0000`; chỉ artifact app ở `0x20000` được dùng cho lệnh ghi.
- `fuser -v /dev/ttyACM0` không thấy tiến trình giữ cổng trước từng thao tác serial.
- Đọc lại chip ngay trước flash: ESP32-S3 rev 0.2, PSRAM 8 MB, XTAL 40 MHz; flash 16 MB, ID `0x68/0x4018`, quad 3.3 V. Nhận dạng khớp thiết bị mục tiêu.
- Partition table `0x8000..0x8BFF` đọc từ thiết bị khớp byte với partition table của build: NVS 16 KB, otadata 8 KB, phy 4 KB, OTA0/OTA1 mỗi slot 4,480 KB, assets 5,760 KB, LittleFS 1,504 KB và nvs_user 32 KB.
- OTA metadata trước ghi: sequence `1`, CRC hợp lệ, slot đang chạy là OTA0. Không đọc NVS hay dump toàn flash; người dùng đã chấp thuận trước đó không tạo backup toàn flash.

## Nạp, readback và boot

- Ghi duy nhất bằng esptool:
  `python3 -m esptool --chip esp32s3 -p /dev/ttyACM0 -b 460800 write-flash --skip-flashed 0x20000 build/xiaozhi.bin`
- Esptool ghi 3,011,200 byte, vùng erase căn sector nằm trong OTA0 (`0x20000..0x2FFFFF`), rồi xác nhận hash khớp. Một lần thử trước dùng cờ `--verify` không được esptool 5.6.0 hỗ trợ; lệnh dừng trước khi kết nối cổng và không ghi dữ liệu. Lệnh chính thức bỏ cờ đó, dùng xác minh mặc định của esptool và readback độc lập.
- Đọc lại đúng 3,012,384 byte tại `0x20000` sau khi nạp: `cmp` PASS; SHA-256 readback `4e012dccd32b4320c5c7da8f7cc28973c438a7855ea30481445db635f2013dfd` khớp artifact.
- Partition table vẫn là bảng OTA đã đối chiếu với build; trước thao tác OTA0 đang active. Flash chỉ phủ app OTA0; NVS không bị đọc/ghi trực tiếp và không nằm trong phạm vi ghi.
- Serial boot trước sửa auto-open xác nhận project `xiaozhi`, app version `2.5.3`, ESP-IDF `v6.1`, revision `v0.2`, PSRAM 8 MB, board OSTB 3ST; LCD NV3023/LVGL, touch CST816S, audio ES8311/ES7210 và BLE provisioning khởi tạo. Image auto-open đã boot và WebSocket control ACK đã chạy. Image mới nhất (thêm khóa sau 5 mã sai) boot xác nhận Nabi BLE ready và Wi-Fi station; không thấy panic trong khoảng 50 giây monitor; hotspot đang tắt nên không thấy AP.
- Mã pairing hiển thị trong boot log không được ghi vào worklog hay profile. Chưa có ảnh/video để xác nhận hình LCD.

## Kiểm thử kết nối trên thiết bị thật

- App quét được ESP sau khi khởi tạo Espressif provisioning manager trên Android main Looper. Phát hiện thêm khác biệt thứ tự byte UUID BLE giữa chuỗi UUID chuẩn và cách ESP-IDF nhận UUID; generator đã đảo byte cho firmware, sau đó app nhận đúng dịch vụ.
- Ghép đôi lần đầu qua BLE Security 2 thành công. Cấu hình Wi-Fi LocalOnlyHotspot được gửi qua BLE bảo vệ; Android ghi nhận thiết bị tham gia hotspot. Không lưu mã ghép, credentials, token hoặc địa chỉ mạng động.
- Serial log trong lượt đó xác nhận ESP nhận DHCP, kết nối HTTP đến gateway trên cổng `8386`, gọi `/nabi/ota/`, nhận cấu hình và vào trạng thái idle. Đây là kiểm tra OTA cấu hình trên thiết bị, không tải firmware OTA.
- Firmware mới tự mở WebSocket sau OTA. Nabi nhận ACK cho `listen.start`; `listen.stop` được nhận và giao diện chuyển sang xử lý local AI. Hotspot/server đã dừng sau phiên thử; điện thoại vẫn ở Wi-Fi thường và Bluetooth đã tắt.
- Không hoàn tất câu trả lời âm thanh: Whisper/LLM local tiếp tục xử lý quá 3 phút trên điện thoại thử nghiệm; phiên bị dừng. Chưa chứng minh TTS phát ra loa ESP, chế độ màn hình khóa/Doze, ngắt Internet trong hội thoại hay phục hồi qua nhiều vòng tắt/bật hotspot.
- Chưa thử trực tiếp mã sai, mã hết hạn hoặc ngưỡng khóa trên thiết bị đã ghép, để giữ NVS và khóa hiện tại. Test này cần ESP sạch/thiết bị thứ hai hoặc quy trình QA có thể reset pairing được duyệt.

## Kết quả và giới hạn

- Đã build app và firmware, cài app trên điện thoại, nạp app-only vào ESP, xác minh readback; BLE pairing, hotspot provisioning, DHCP, OTA config, WebSocket v3 và ACK lệnh nghe/dừng đã chạy trên thiết bị thật.
- Chưa nghiệm thu hội thoại giọng nói đầu-cuối vì local AI xử lý quá lâu trên điện thoại thử nghiệm và chưa có phản hồi TTS xác nhận. Feature Hub tiếp tục giữ trạng thái review gate.
- NVS không bị nhắm bởi lệnh flash; firmware có lưu key/credentials qua luồng BLE provisioning, nhưng nội dung NVS không được dump hay đọc trực tiếp. Chưa so sánh bytes NVS trước/sau.
- Thông tin thực tế và source profile được cập nhật trong `iot/xiaozhi-esp32/docs/agent-context/CONNECTED_DEVICE_OSTB_3ST.md`.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: hợp đồng có nguồn chuẩn duy nhất; app và firmware build thành công; app image được kiểm tra fit, ghi đúng OTA0 và readback byte-for-byte; kết luận boot giữ đúng ranh giới bằng chứng.
- Mức độ hoàn thành: coding, build, cài app, flash app-only, BLE pairing, Wi-Fi, OTA config và WebSocket control đạt. Hội thoại STT/LLM/TTS chưa đạt nghiệm thu.
- Điểm còn thiếu: tối ưu/đo thời gian local inference trên điện thoại, xác nhận TTS/loa; thử ghép lại, hotspot restart, màn hình khóa, Doze và hội thoại sau khi tắt Internet; hoàn tất Tech/QA/Privacy review trước khi mở phát hành.
- Task-skill tiếp tục dùng: `.codex/task-skills/docs-context.md`, `.codex/task-skills/test.md`, `iot/xiaozhi-esp32/docs/agent-context/TASK_ROUTING.md`.
