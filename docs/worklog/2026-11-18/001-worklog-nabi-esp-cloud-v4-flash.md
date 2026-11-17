Commit de xuat: docs(worklog): ghi nhan flash firmware nabi cloud v4

# Worklog - Build và nạp Nabi cloud v4 lên OSTB 3ST

## Thời gian

- Ngày: 2026-11-18
- Bắt đầu: Không ghi nhận trong nhật ký lệnh
- Kết thúc: 00:31 +07
- Timezone: Asia/Bangkok

## Phạm vi

- Loại task: Build firmware, kiểm tra server, nạp và xác minh boot trên thiết bị thật; cập nhật hồ sơ triển khai.
- Module chính: `NABI_ESP_ASSISTANT`, OSTB Nabi 3ST, backend IoT production.
- Yêu cầu gốc: Để ESP dùng dịch vụ AI trên server sau khi cấu hình qua app; người dùng yêu cầu build và cài firmware lên ESP đang cắm, không cần backup, đồng thời tự chạy APK sau.

## Đã làm

- Kiểm tra readiness server trả HTTP 200; `nanobio-backend`, PostgreSQL, Ollama và IoT speech worker đang chạy. Backend release hiện hành khớp các source IoT liên quan trong dự án, nên không cần cài môi trường hay deploy lại server trong lượt này.
- Build cloud contract v4 bằng ESP-IDF 6.1 cho profile `ostb/ostb-nabi-3st`, locale `vi-VN`.
- Đọc trực tiếp partition table và OTA metadata trước khi ghi. Slot `ota_0` nằm tại `0x20000`, kích thước `0x3F0000`; metadata có CRC hợp lệ và đang chọn OTA0.
- Ghi riêng app image `iot/nabi-esp32/build/nabi.bin` vào OTA0. Image 2.759.072 byte, SHA-256 `d9f083822b8f3d90a70a484fecefbac894ea760c90683e970053eea93a844e7a`; esptool báo hash dữ liệu đã xác minh.
- Hard reset và quan sát boot qua bộ lọc log: app bắt đầu, board/audio init hoàn tất, provisioning Wi-Fi cục bộ sẵn sàng và firmware vào chế độ cấu hình AP.
- Chỉ đọc partition table và OTA metadata; không backup/dump hoặc ghi NVS. Không ghi OTA metadata, partition table, bootloader, assets hay eFuse.
- Gỡ ACL serial tạm sau khi thao tác. Không cài APK theo yêu cầu; chưa chạy AP provisioning hoặc voice E2E.

## File code/docs đã sửa

- `docs/DD/nabi_esp_assistant/README.md` — cập nhật ngày và bằng chứng flash/boot.
- `docs/DD/nabi_esp_assistant/Overall.md` — đồng bộ trạng thái verification.
- `docs/DD/nabi_esp_assistant/List_Features.md` — ghi nhận OTA0 flash và acceptance còn chờ.
- `docs/DD/nabi_esp_assistant/history/CHANGELOG.md` — thêm dòng kết quả ngày 2026-11-18.
- `docs/features/nabi_esp_assistant/001-feature-nabi-esp-assistant.md` — cập nhật trạng thái và liên kết worklog.
- `iot/nabi-esp32/docs/agent-context/CONNECTED_DEVICE_OSTB_3ST.md` — cập nhật firmware, image, OTA và boot state đã đo trực tiếp.
- `docs/checklist/checklist_task_coding.md` — thêm follow-up build/flash và acceptance còn lại.
- `docs/checklist/checklist_complete_DD.md` — cập nhật bằng chứng device cho module Draft.
- `docs/worklog/2026-11-18/001-worklog-nabi-esp-cloud-v4-flash.md` — ghi nhật ký phiên.

## Tài liệu liên quan

- `iot/nabi-esp32/docs/agent-context/CONNECTED_DEVICE_OSTB_3ST.md`
- `docs/DD/nabi_esp_assistant/`
- `docs/checklist/checklist_task_coding.md`

## Commands

- `python3 iot/nabi-esp32/scripts/build.py ostb/ostb-nabi-3st --config config.cloud-ai.json --language vi-VN`: PASS — ESP-IDF 6.1; app image 2.759.072 byte.
- Đọc partition table và OTA metadata qua USB Serial/JTAG: PASS — chọn OTA0; không đọc NVS.
- Ghi app image qua esptool vào `0x20000`: PASS — số byte ghi khớp artifact và hash được xác minh.
- Boot monitor với bộ lọc an toàn: PASS — board/audio init và AP setup marker xuất hiện.
- Kiểm tra `/health/ready` server: PASS — HTTP 200.
- Kiểm tra trạng thái source IoT đang chạy trên server so với source dự án: PASS — khớp; không redeploy.
- Chạy APK / phone-to-AP / device-login / WSS voice acceptance: SKIPPED — người dùng sẽ tự chạy APK sau.
- Backup, dump NVS hoặc ghi partition/OTA metadata/bootloader/assets: SKIPPED — không thuộc thao tác được yêu cầu.

## Lỗi/Rủi ro

- Đã fix: firmware cloud v4 chưa có trên board sau phiên trước vì ESP chưa xuất hiện ở cổng USB; lượt này đã build, ghi riêng OTA0 và xác minh boot/AP.
- Chưa fix: chưa có app provisioning tới ESP, device-login thực tế, Wi-Fi nhà, voice round trip, token refresh/revoke, consent hoặc reconnect acceptance.
- Cần kiểm tra tiếp: người dùng chạy APK mới, đăng nhập khi điện thoại có Internet, nối AP để cấu hình; sau đó xác minh ESP kết nối Wi-Fi nhà và voice server. Giữ release gate đóng tới khi Tech/QA/Privacy review và nghiệm thu.

## Tỷ lệ hoàn thành

- Hoàn thành: build và nạp firmware; xác minh hash; xác minh boot/AP; kiểm tra readiness backend.
- Đang dở: tích hợp app-to-ESP và ESP-to-server E2E; APK do người dùng tự chạy.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt — app-only flash vào OTA0, có đối chiếu layout live trước khi ghi và bằng chứng hash/boot; không đụng vùng lưu dữ liệu.
- Mức độ hoàn thành task: hoàn tất build/nạp và readiness server; chưa hoàn tất E2E vì app chưa chạy theo yêu cầu.
- Bằng chứng kiểm chứng: build ESP-IDF 6.1; esptool hash verify; boot monitor; server readiness 200; server/source IoT đối chiếu khớp.
- Điểm tốn token/chưa tối ưu: một số ngữ cảnh lịch sử lặp giữa checklist và DD; worklog mới giữ phần cần cho lần tiếp tục.
- Cách tối ưu cho phiên sau: bắt đầu từ worklog này và device context; chỉ cần chạy acceptance qua APK, không build hoặc nạp lại nếu image/board không đổi.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
