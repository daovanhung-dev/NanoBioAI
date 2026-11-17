Commit de xuat: feat(nabi-esp): provision ESP OSTB qua AP va NanoBio server

# Worklog - Nabi ESP AP provisioning và nạp firmware

## Thời gian

- Ngày: 2026-11-17
- Bắt đầu: Tiếp nối phiên triển khai cloud assistant và chờ người dùng cắm lại OSTB 3ST.
- Kết thúc: 21:58 Asia/Bangkok; firmware app-only đã nạp và log boot/AP đã được kiểm tra.
- Timezone: Asia/Bangkok

## Phạm vi

- Loại task: coding
- Module chính: NABI_ESP_ASSISTANT; Android provisioning bridge, OSTB 3ST firmware và server integration.
- Yêu cầu: ESP phát AP; app Nabi thiết lập Wi‑Fi từ mục Tiện ích; app dùng kết nối di động để tạo phiên ghép; ESP lưu thông tin Wi‑Fi và credential thiết bị rồi dùng dịch vụ voice AI trên server.
- Phạm vi phần cứng: OSTB Nabi 3ST đang kết nối. Người dùng đã yêu cầu build và cài firmware trực tiếp, không backup.

## Đã làm

- Hoàn thiện luồng AP setup: ESP mở AP WPA2 `Nabi-xxxx`, hiển thị mã dùng một lần; app dùng mạng di động cho API tài khoản và mạng ESP cho API local `192.168.4.1`.
- Android local provisioner tạm bind request local vào Wi‑Fi ESP trong khi giữ API backend qua cellular; account password không được gửi đến ESP. ESP nhận Wi‑Fi và pairing token dùng một lần, sau đó claim credential thiết bị với server.
- Sửa lỗi khởi động phát hiện trên board: thiết bị chưa pair luôn mở setup AP, kể cả NVS còn SSID cũ. Khi pairing được lưu, firmware mới chuyển sang kết nối Wi‑Fi nhà.
- Sửa tương thích build ESP-IDF 6.1: include cấp phát động, tạo local HTTP response trước khi xếp Wi‑Fi task và gửi status HTTP bằng chuỗi tương thích với phiên bản IDF.
- Native bridge trả lỗi local network/I/O về Flutter bằng thông báo tiếng Việt an toàn, tránh làm UI chờ vô hạn khi ESP không phản hồi.
- Sửa guard asset/display setup để cloud profile biên dịch và dùng chung màn hình cấu hình Wi‑Fi.
- Xác minh production server đã có IoT routes/schema và speech worker; không cần thay đổi hay deploy server. Không ghi production server.
- Cắm lại board sau khi USB biến mất; đọc lại live partition table và OTA metadata trước lượt nạp cuối. Nạp duy nhất `nabi.bin` vào OTA0 offset `0x20000`, không backup và không ghi NVS/OTA metadata/partition table/bootloader/assets.
- Sau khi esptool xác minh hash, xem boot log: board/audio init hoàn tất; unpaired device mở AP/config mode và hướng dẫn nối `Nabi-xxxx`/nhập mã.
- Gỡ ACL serial tạm `u:daovh:rw` sau thao tác; xác nhận entry đã biến mất.
- Đồng bộ DD, feature, checklist, hồ sơ OSTB và project context để nêu đúng bằng chứng và các bước E2E còn mở.

## Bằng chứng kiểm chứng

- `python3 iot/tools/generate_nabi_esp_cloud_contract.py --check`: PASS.
- `flutter analyze --no-pub lib/app_versions/v1/features/nabi_esp_assistant`: PASS, không có issue.
- `flutter test --no-pub test/app_versions/v1/features/nabi_esp_assistant`: PASS, 5 tests.
- `flutter build apk --debug --no-pub`: PASS; artifact `build/app/outputs/flutter-apk/app-debug.apk`.
- Build APK chạy lại sau thay đổi xử lý lỗi I/O trên Android bridge: PASS; Gradle chỉ cảnh báo các phiên bản toolchain sắp hết hỗ trợ.
- `flutter analyze --no-pub` toàn repo: FAIL do lỗi ngoài feature này: thiếu `package:nano_app/core/ai_local/local_ai_runtime_service.dart`, `LocalAiRuntimeService` chưa định nghĩa trong integration test và một async-gap info có sẵn.
- ESP-IDF v6.1: `python3 scripts/build.py ostb/ostb-nabi-3st --config config.cloud-ai.json --language vi-VN`: PASS. Output `iot/nabi-esp32/build/nabi.bin`, 2.757.936 byte (`0x2a1530`), SHA-256 `dab50a16aca99c5424386a9766eb12b1ccb2f94d5ca9bbc8382610ab01d7bc13`.
- Artifact nhỏ hơn OTA0 live (`0x3F0000`). Trước lượt ghi cuối, partition map live được xác nhận: OTA0 `0x20000`, OTA1 `0x410000`, NVS `0x9000`, OTA metadata sequence `1` với CRC hợp lệ.
- Esptool ghi đúng `0x20000` rồi báo `Hash of data verified`; hard reset và boot log xác nhận board/audio init, `Nabi cloud device is not paired; opening local setup AP`, `Starting config AP`, `WiFi config mode entered`.
- Server read-only: backend và speech worker active; OpenAPI có device/claim/refresh/pairing routes; bảng IoT tồn tại; Alembic head `0010_web_push`; health worker trả HTTP 200; endpoint devices không auth trả 401. Không thay đổi production.
- ACL cleanup: `getfacl /dev/ttyACM0` không còn entry `user:daovh`.
- `python3 iot/tools/generate_nabi_esp_cloud_contract.py --check` sau cập nhật docs: PASS.
- `git diff --check` sau khi hoàn tất worklog/context refresh: PASS.
- `clang-format --dry-run --Werror` trên 3 file C++ đã đổi: báo 7 vị trí formatting trong `nabi_esp_provisioning.cc`; build ESP-IDF vẫn pass. Không format lại sau khi flash cuối để giữ source/image đã kiểm tra nhất quán về thời điểm; đây là style-only và chưa ảnh hưởng compile/runtime.
- `.codex/tools/validate_codex_integrity.ps1`: không chạy được vì môi trường không có `pwsh` hoặc `powershell`.

## Chưa nghiệm thu

- Chưa dùng điện thoại để nối AP, gọi `/nabi/status`/`/nabi/provision`, kiểm tra route cellular/local, claim pairing token, lưu Wi‑Fi hoặc xác nhận app hiển thị thiết bị.
- Chưa kiểm tra voice WebSocket đầu-cuối, STT/AI/TTS qua loa, token refresh/revoke, consent, reconnect hay mất Internet trên board.
- Tech, QA và Privacy sign-off còn chờ; Android feature tiếp tục bị khóa cho release.
- Không khẳng định firmware đã đăng nhập server chỉ từ boot/AP log. Boot log hiện chứng minh thiết bị vào đúng bước cấu hình.

## Lỗi và quyết định

- Lần flash đầu sau khi board được cắm lại cho thấy SSID cũ trong NVS khiến firmware bỏ qua AP dù thiết bị chưa pair. Đã sửa nhánh startup, build lại và nạp bản cuối; log boot bản cuối chứng minh AP được mở.
- Các macro enum HTTP 409/503 không có trong HTTP server header của ESP-IDF 6.1; đổi sang `httpd_resp_set_status` với status text tương ứng.
- Production backend đã có routes, schema và worker phù hợp nên không triển khai lại hoặc chạy migration trên server.
- Full repo Flutter analyze còn lỗi độc lập trong local-AI integration test; focused Nabi ESP analyze/tests và Android build đều pass.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt — AP-first startup được kiểm tra trên board thật sau khi build lại; ranh giới giữa boot evidence và E2E chưa xác minh được ghi rõ.
- Mức độ hoàn thành task: source, build APK/firmware, app-only flash và boot AP đã hoàn tất; phone provisioning, claim và voice E2E còn mở.
- Bằng chứng kiểm chứng: focused Flutter analyze/5 tests, debug APK, contract check, ESP-IDF build/hash, live partition/OTA read, esptool hash verify, boot log, server route/schema/worker health và ACL cleanup.
- Điểm tốn token/chưa tối ưu: USB board biến mất giữa lượt; lần boot đầu làm lộ điều kiện startup bị bỏ sót, cần build/nạp thêm một lượt. Đã reread OTA state trước bản cuối.
- Cách tối ưu cho phiên sau: ghép một Android phone test với board, theo dõi `/nabi/status` → `/nabi/provision` → claim và voice round trip; chụp trạng thái app/AP/log đã lọc payload nhạy cảm.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
