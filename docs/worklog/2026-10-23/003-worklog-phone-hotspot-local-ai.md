Commit de xuat: feat(iot): noi ESP OSTB voi AI local qua hotspot dien thoai

# Worklog - Chạy XiaoZhi local AI qua hotspot điện thoại

## Thoi gian

- Ngay: 2026-10-23
- Bat dau: tiếp nối phiên IoT trước; thời điểm bắt đầu không được ghi riêng
- Ket thuc: 2026-10-23 13:27 Asia/Ho_Chi_Minh
- Timezone: Asia/Ho_Chi_Minh (UTC+07:00)

## Pham vi

- Loai task: triển khai app Android, profile firmware ESP và tài liệu nghiệm thu
- Module chinh: `iot/xiaozhi-esp32/phone_app/` và profile OSTB 3ST
- Yeu cau goc: chạy Whisper, GGUF và Android TTS trên điện thoại; ESP kết nối qua hotspot, lấy cấu hình WebSocket v3 và trao đổi audio theo lượt

## Da lam

- App chọn địa chỉ IPv4 nội bộ, yêu cầu chọn interface khi có nhiều candidate, bind server HTTP/WebSocket vào đúng địa chỉ và theo dõi khi địa chỉ biến mất.
- Thêm Android foreground service `connectedDevice`, notification có nút dừng, Flutter engine được cache qua lúc Activity detach và partial CPU wake lock trong phiên.
- Giới hạn một WebSocket ESP; từ chối Bearer token sai; `/health` trả trạng thái LLM, STT, TTS và voice offline. Server chỉ khởi chạy khi model, Whisper và voice TTS ngoại tuyến đều sẵn sàng.
- Profile OSTB local-AI ưu tiên `ota_url` trong NVS, bỏ IP cố định và dùng loopback làm fallback an toàn. Bảng 16 MB có `otadata`, hai OTA slot, assets, data và NVS.
- Tạo tài liệu feature và cập nhật hướng dẫn app/luồng, board README và `FILE_INDEX.md`.
- Không nạp firmware lên thiết bị. Build/đọc source không chứng minh nghiệm thu app hoặc phần cứng.

## File code/docs da sua

- `iot/xiaozhi-esp32/phone_app/lib/services/xiaozhi_server.dart` - bind/giám sát IPv4, readiness, offline TTS, health, auth và giới hạn WebSocket.
- `iot/xiaozhi-esp32/phone_app/lib/services/phone_server_lifecycle.dart` - cầu nối Flutter/native cho vòng đời service.
- `iot/xiaozhi-esp32/phone_app/android/app/src/main/kotlin/com/xiaozhi/xiaozhi_local_ai/MainActivity.kt` - khởi chạy/cache engine, permission notification và method channel.
- `iot/xiaozhi-esp32/phone_app/android/app/src/main/kotlin/com/xiaozhi/xiaozhi_local_ai/XiaoZhiServerService.kt` - foreground service, notification và wake lock.
- `iot/xiaozhi-esp32/phone_app/android/app/src/main/AndroidManifest.xml` - permission/service cho connected device.
- `iot/xiaozhi-esp32/phone_app/lib/main.dart`, `voice_service.dart` - UI chọn địa chỉ/trạng thái và voice TTS offline.
- `iot/xiaozhi-esp32/main/boards/ostb/ostb-xiaozhi-3st/config.local-ai.json`, `partitions/ostb-xiaozhi-3st-16m.csv`, board README - OTA NVS-first và profile flash 16 MB.
- `iot/xiaozhi-esp32/docs/phone-local-ai-flow_vi.md`, `phone_app/README.md`, `docs/features/phone-local-ai/001-feature-phone-hotspot-server.md` - luồng, vận hành, bảo mật và tiêu chí nghiệm thu.
- `iot/xiaozhi-esp32/docs/agent-context/FILE_INDEX.md` - làm mới inventory sau thay đổi.

## Tai lieu lien quan

- Hồ sơ phần cứng đã có trước phiên này: `iot/xiaozhi-esp32/docs/agent-context/CONNECTED_DEVICE_OSTB_3ST.md`.
- Quy định build/flash an toàn: skill `esp32-safe-flash` đã được đọc; cần full backup và xác nhận đúng target trước khi ghi flash.
- Android yêu cầu `ACCESS_LOCAL_NETWORK` khi app target SDK 37 trở lên. APK hiện target SDK 36 nên chưa xin quyền này; cần thêm manifest declaration và runtime request khi nâng target.

## Commands

- `dart format ...` và `flutter analyze`: PASS; analyzer báo `No issues found!`.
- `flutter build apk --debug --target-platform android-arm64`: PASS; APK `phone_app/build/app/outputs/flutter-apk/app-debug.apk`, 180,498,671 bytes, SHA-256 `b4d9166f0a080466eaef198058bd752309b34706e71533c19d295f93fd4ff51b`.
- `python scripts/build.py ostb/ostb-xiaozhi-3st --config config.local-ai.json --name ostb-xiaozhi-3st` với ESP-IDF 6.1: PASS; app image 2,593,104 bytes, nhỏ hơn OTA slot 4,587,520 bytes.
- ESP-IDF partition parser: PASS; table có `otadata` 8 KiB, `ota_0`/`ota_1` mỗi slot 4,480 KiB, `assets` 5,760 KiB, `data` 1,504 KiB và `nvs_user` 32 KiB.
- `build/merged-binary.bin`: 10,568,869 bytes, SHA-256 `a0b3add11ec90a75645451028810fbd704cee1e84a6a137c5199a5d0aaf2a37b`.
- `aapt dump badging/xmltree`: PASS; package `com.xiaozhi.xiaozhi_local_ai`, target SDK 36, service type `connectedDevice`, notification và foreground-service permissions hiện diện.
- `adb devices -l`: không có điện thoại Android được kết nối.
- Kiểm tra profile JSON, `FILE_INDEX` path inventory và tìm IP cũ/`CONFIG_OTA_URL_IGNORE_NVS=y`: PASS.
- `git diff --check`: PASS.
- `pwsh -NoLogo -NoProfile -File .codex/tools/update_worklog_learning.ps1`: PASS; cập nhật 19 file history/task-skill xác định.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL do thiếu file docs/audit/source_truth_manifest.json và các path stale trong worklog/task-skill NanoBio lịch sử; không chỉ ra lỗi từ file IoT mới trong phiên này.
- Không chạy test tự động hoặc kiểm tra thoại thực; người dùng chưa yêu cầu thêm bộ test và chưa có thiết bị Android.

## Loi/Rui ro

- Da fix: cấu hình compile-time cố định `192.168.11.145` và `CONFIG_OTA_URL_IGNORE_NVS=y` đã được bỏ khỏi profile local-AI.
- Chua fix: ESP gắn USB hiện vẫn chạy demo LCD ESP-IDF 5.4, partition `factory` 1 MB; chưa có firmware XiaoZhi chạy trên thiết bị.
- Can kiem tra tiep: cài app trên đúng điện thoại; kiểm tra model/Whisper/TTS, `/health`, notification, nền/tắt màn hình khi sạc, WebSocket v3, hội thoại tiếng Việt, token sai, offline và đổi địa chỉ hotspot.
- HTTP/WebSocket hiện không mã hóa TLS. Chỉ dùng hotspot riêng, không cho thiết bị lạ vào mạng và không mở cổng ra Internet.
- Build phát một số cảnh báo Kconfig/deprecation từ ESP-IDF và dependency upstream, nhưng kết thúc thành công.

## Ty le hoan thanh

- Hoan thanh: source app/profile, tài liệu và build artifacts.
- Dang do: nghiệm thu runtime trên điện thoại/ESP và nạp profile mới.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - đã build cả APK và firmware; phạm vi bằng chứng runtime được tách rõ.
- Muc do hoan thanh task: implementation hoàn thành; nghiệm thu phần cứng chưa làm do thiếu điện thoại và xác nhận target/backup trước flash.
- Bang chung kiem chung: `flutter analyze`, APK debug, build ESP-IDF 6.1, partition parser, manifest metadata và source checks.
- Diem ton token/chua toi uu: build ESP-IDF lần đầu biên dịch nhiều dependency nên mất thời gian.
- Cach toi uu cho phien sau: giữ ESP-IDF source/toolchain đã cài ngoài repo và tái sử dụng build cache; trước flash kiểm tra cổng/target và xác nhận full backup.
- Task-skill can doc lan sau: `.codex/task-skills/docs-context.md` và skill `esp32-safe-flash`.
