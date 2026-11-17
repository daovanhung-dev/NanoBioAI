Commit de xuat: feat(nabi-esp): provision ESP OSTB qua server NanoBio

# Worklog - Nabi ESP cloud assistant

## Thời gian

- Ngày: 2026-11-17
- Bắt đầu: Tiếp nối context bàn giao; timestamp bắt đầu không còn trong context.
- Kết thúc: 20:31 Asia/Bangkok (cloud image đã được nạp và xác minh)
- Timezone: Asia/Bangkok

## Phạm vi

- Loại task: coding
- Module chính: NABI_ESP_ASSISTANT; backend IoT API/voice.
- Yêu cầu gốc: Sau khi cấu hình Wi‑Fi bằng app Nabi, ESP liên kết tài khoản an toàn và dùng dịch vụ AI giọng nói trên NanoBio server.

## Đã làm

- Thay luồng app assistant cục bộ bằng quy trình Android debug pilot: nhập Wi‑Fi, tạo pairing token ngắn hạn, BLE Security 2 và theo dõi ESP claim tài khoản.
- Thêm service app để liệt kê/đổi tên/thu hồi ESP và quản lý consent. Consent mặc định tắt; sensitive context cần xác nhận và server hết hạn sau 5 phút.
- Thêm/căn chỉnh IoT API, data models, migration, credential rotation, owner-scoped APIs, revocation và voice WebSocket/server speech worker.
- Thêm env template và loopback systemd unit cho speech worker; unit chưa được cài trên server.
- Thêm contract cloud sinh cho Dart/Kotlin/ESP và profile firmware cloud OSTB 3ST riêng. Giữ contract local-AI và config.local-ai.json.
- Thêm reauthentication trước khi ESP mở lại WebSocket khi socket đóng nhưng Wi‑Fi vẫn còn.
- Cập nhật DD, feature doc, checklist và changelog; giữ DD Draft và Tech/QA/Privacy gate đóng.
- Không thay đổi production server, không nạp firmware, không ghi partition/NVS/eFuse.

## File code/docs đã sửa

- Flutter/Kotlin Android: Nabi ESP runtime/page/API service/BLE contract/provisioning bridge và test app service.
- Backend: IoT router/models/view/query/voice/worker, config, migration, pyproject/lock, env example, systemd unit và IoT API tests.
- Firmware: cloud contract/generator, cloud profile, provisioning/authentication, websocket/application lifecycle, Kconfig/CMake, Wi‑Fi setup display, OTA guards, board README.
- Docs: Nabi ESP DD/feature/checklists/worklog và generated project learning index/task-skill nếu refresh thành công.

## Tài liệu liên quan

- DD: docs/DD/nabi_esp_assistant/
- Feature: docs/features/nabi_esp_assistant/001-feature-nabi-esp-assistant.md
- Connected device profile: iot/nabi-esp32/docs/agent-context/CONNECTED_DEVICE_OSTB_3ST.md
- Source plan: kế hoạch người dùng duyệt trong phiên 2026-11-17

## Commands

- python3 iot/tools/generate_nabi_esp_contract.py --check: PASS.
- python3 iot/tools/generate_nabi_esp_cloud_contract.py --check: PASS.
- Parse iot/nabi-esp32/main/boards/ostb/ostb-nabi-3st/config.cloud-ai.json: PASS.
- backend .venv/bin/ruff check .: PASS.
- backend .venv/bin/ruff format --check .: PASS, 149 files formatted.
- backend .venv/bin/mypy src/nanobio_backend: PASS, 106 source files.
- backend .venv/bin/pytest -q: PASS; 2 tests skipped by suite.
- backend targeted tests/test_iot_api.py: PASS, 6 tests.
- flutter analyze on changed Nabi ESP Dart source/test: PASS, no issues.
- flutter test test/app_versions/v1/features/nabi_esp_assistant/nabi_esp_device_service_test.dart: PASS, 3 tests.
- flutter build apk --debug: PASS. Gradle/AGP/Kotlin and Android SDK metadata emit upgrade warnings only.
- uv run alembic heads/history: PASS, one head 0009_merge_iot_web_push merges local 0008_web_push and deployed 0008_iot_devices.
- Fresh SQLite Alembic upgrade to head: PASS, both IoT and Web Push tables exist.
- Simulated database at deployed revision 0008_iot_devices upgraded to merged head: PASS.
- systemd-analyze verify backend/systemd/nanobio-iot-speech-worker.service: NOT VALIDATED locally; the target install path /opt/nanobio/backend/.venv/bin/uvicorn is absent in this environment.
- ESP-IDF v6.1 Python environment: PASS; initialized with `install.sh esp32s3`.
- Cloud firmware build: PASS; `ostb/ostb-nabi-3st`, variant `ostb-xiaozhi-3st`, locale `vi-VN`, ESP32-S3. Output `iot/nabi-esp32/build/nabi.bin`, 3,128,576 bytes (`0x2fbd00`); binary checksum/ESP32-S3 image-info valid. Fits the connected board's documented OTA0 size `0x3f0000` with `0xf4300` bytes remaining.
- Live device checks: PASS; ESP32-S3 rev 0.2, 16 MB flash, 8 MB PSRAM. Partition table read from `0x8000` matches documented live layout; OTA sequence `1` and CRC are valid, selecting `ota_0`. No NVS read or dump.
- Firmware flash to the connected OSTB: PASS; wrote only `build/nabi.bin` at `0x20000` (erased/wrote `0x20000–0x31bfff`), esptool hash verification passed, then hard reset. No backup was created; bootloader, partition table, OTA metadata, NVS and assets were not written.
- Serial ACL cleanup: PENDING; user-granted `u:daovh:rw` ACL remains on `/dev/ttyACM0`; the agent shell has no passwordless sudo to remove it. Cleanup command: `sudo setfacl -x u:daovh /dev/ttyACM0`.
- OSTB cloud runtime/provisioning/voice/reconnect acceptance: NOT DONE; no post-flash monitor or service round trip was run.
- Production server changes: SKIPPED; no writes performed.
- clang-format --dry-run --Werror on changed firmware C++ files: PASS.
- python3 .codex/tools/update_worklog_learning.py --project-root . --write: PASS, refreshed 19 deterministic history/task-skill files; the PowerShell wrapper is unavailable.
- Targeted local Markdown-link validation for DD/feature/worklog: PASS.
- .codex/tools/validate_codex_integrity.ps1: SKIPPED because neither pwsh nor powershell is installed.
- git diff --check: PASS.

## Lỗi/Rủi ro

- Đã fix: ESP reconnect path now refreshes the per-device credential before opening a new WebSocket.
- Đã xử lý: ESP-IDF 6.1 cloud profile compiles after making the local/cloud Kconfig modes a mutually exclusive optional choice and aligning the Wi-Fi board UI declarations for cloud mode.
- Đã xác nhận: fresh live partition table and OTA sequence before writing; app-only flash fits OTA0 and esptool verified written hash.
- Chưa xác nhận: post-flash boot marker, BLE pairing, cloud claim, Wi-Fi credentials flow, WSS voice and token refresh on the physical device.
- Chưa fix: production deployment of any migration/source/config was intentionally not performed; both local and deployed Alembic paths were smoke-tested only against disposable SQLite.
- Can kiem tra tiep: Tech/QA/Privacy review; Android BLE Security 2 + OSTB Wi‑Fi claim; WSS voice round trip, token refresh/revocation, consent, network recovery and speaker audio.
- Security: board flash encryption is disabled in the connected-device snapshot; Wi‑Fi and refresh credentials stored in NVS remain exposed to physical flash access.

## Tỷ lệ hoàn thành

- Hoàn thành: local app/backend/firmware source, shared contract/profile, focused/full backend validation, focused Flutter validation, Android debug build, ESP-IDF cloud build and app-only firmware flash with hash verification.
- Đang dở: serial ACL cleanup, post-flash device acceptance and release reviews.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt — source/build thành công; app-only flash và hash verification đã hoàn tất.
- Mức độ hoàn thành task: firmware đã cài; xác nhận luồng runtime/cloud, sign-offs và production deployment còn mở.
- Bằng chứng kiểm chứng: backend full lint/format/mypy/tests; Flutter analyze/test; Android debug APK; cloud contract generation/profile JSON; ESP-IDF v6.1 build, image-info, live partition/OTA checks and esptool write verification.
- Điểm tốn token/chưa tối ưu: reviewed broad diffs before narrowing to the active cloud paths; several checks ran serially while waiting for Gradle.
- Cách tối ưu cho phiên sau: start with ESP-IDF 6.1 environment and confirmed board partition profile; run BLE, cloud claim, refresh and WSS tests on an isolated test account before review.
- Task-skill cần đọc lần sau: .codex/task-skills/coding.md

