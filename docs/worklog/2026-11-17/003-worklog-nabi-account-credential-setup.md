Commit de xuat: feat(nabi-esp): require app login before local AP setup

# Worklog - Nabi ESP account credential setup without mobile data

## Thời gian

- Ngày: 2026-11-17
- Bắt đầu: Tiếp nối yêu cầu đổi luồng setup Nabi ESP đã được người dùng duyệt.
- Kết thúc: 23:40 Asia/Bangkok; backend release mới healthy, app/firmware builds pass; board chưa kết nối để nạp firmware.
- Timezone: Asia/Bangkok

## Phạm vi

- Loại task: coding, test, build, backend deployment và device readiness check.
- Module chính: `NABI_ESP_ASSISTANT`; app auth/SQLite vault, Android AP bridge, ESP cloud contract, backend IoT device auth.
- Yêu cầu: người dùng đăng nhập app trước; credential được giữ trong SQL/app theo plan, gửi và lưu trên ESP; cấu hình qua AP ESP không cần dữ liệu di động.
- Decisions: PostgreSQL giữ Argon2 hash; app lưu password ciphertext trong SQLite với key Android Keystore tới logout; ESP lưu account/password trong NVS theo lựa chọn người dùng; chuyển credential qua HTTP trên AP WPA2; cloud contract v4, voice protocol v3.

## Đã làm

- Thêm SQLite schema v37 và `NabiEspCredentialVault`; AES/GCM key nằm trong Android Keystore. Auth repository lưu sau sign-in/sign-up, cập nhật cache sau đổi password và xóa khi logout qua các đường đăng xuất của app.
- Đổi Android local provisioner và Flutter runtime: bỏ cellular binding, pairing-session creation và claim polling trong lúc setup. App chỉ gọi `/nabi/status` và `/nabi/provision` qua mạng ESP; nếu thiếu credential cache thì hướng dẫn login lại khi online.
- Cập nhật giao diện: đăng nhập trước khi nối AP; copy nói rõ không cần mobile data trong setup, thông tin app được mã hóa, ESP lưu account credential trong NVS. Giữ cổng Android debug pilot/release gate.
- Firmware AP contract v4 nhận Wi‑Fi/account credential, lưu `identifier_type`, `identifier`, `account_password` và `provision_pending` trong NVS. Sau khi ESP vào Wi‑Fi nhà, firmware gọi device-login qua HTTPS, lưu refresh token, giữ access token trong RAM và không fallback password login khi refresh lỗi.
- Backend thêm `POST /api/v1/iot/devices/credentials/login`: normalize phone/email/username, verify Argon2 password hash, rate limit theo account/IP, kiểm soát owner, reset consent khi rebind và kết thúc WebSocket lease khi reauth. PostgreSQL không nhận password thô; SQL chỉ giữ hash account/device token.
- Bump cloud contract lên v4, giữ voice protocol v3. Cập nhật DD, design, domain, checklist và test cục bộ cho payload AP mới.
- Deploy backend trong isolated release `/opt/nanobio/releases/nabi-web-20261117-01`; service active, local readiness 200 và public OpenAPI có route. Không đổi schema hoặc chạy migration.
- Kiểm tra cổng USB: ESP không xuất hiện trong `/dev/ttyACM*`, `/dev/ttyUSB*`, `/dev/serial/by-id` hoặc `lsusb`; vì vậy không đọc partition/OTA metadata và không ghi firmware. Điện thoại Android Xiaomi vẫn kết nối ADB; APK mới chưa được cài.
- Rà soát consistency sau implementation: sửa Kconfig help, board README, DD, Feature Hub, checklist và device snapshot để mô tả login trước AP, account credential provision local, không cần mobile data và phân biệt cloud contract v3 đang có trên board với v4 mới chỉ build.

## Bằng chứng kiểm chứng

- `flutter analyze --no-pub` trên 9 file Dart đã đổi: PASS, không issue.
- `flutter test --no-pub test/app_versions/v1/features/nabi_esp_assistant`: PASS, 5 tests; Android bridge test xác nhận payload account credential và không gọi cellular methods.
- `flutter build apk --debug --target-platform android-arm64 --no-pub`: PASS. Artifact `build/app/outputs/flutter-apk/app-debug.apk`, 559,082,014 bytes, SHA-256 `f93f143c7a59213cbc0efc2f5d6c358866893fe1044416658ad438c07089ae60`. APK hiện là debug pilot và chưa được cài lên điện thoại.
- `python3 iot/tools/generate_nabi_esp_cloud_contract.py --check`: PASS.
- Backend `uv run pytest -q tests/test_iot_api.py`: PASS, 9 tests; `uv run ruff check src/nanobio_backend/modules/iot tests/test_iot_api.py`: PASS; `uv run mypy src/nanobio_backend`: PASS, 106 files.
- ESP-IDF 6.1 build: PASS. `iot/nabi-esp32/build/nabi.bin`, 2,759,072 bytes, SHA-256 `d9f083822b8f3d90a70a484fecefbac894ea760c90683e970053eea93a844e7a`.
- Live backend release `nabi-web-20261117-01`: systemd active; `http://127.0.0.1:8000/health/ready` trả 200; route `/api/v1/iot/devices/credentials/login` có trong local và public OpenAPI.
- Chưa flash firmware trong lượt này. Board phải xuất hiện lại để đọc partition/OTA metadata và ghi app image duy nhất vào OTA slot phù hợp, giữ nguyên NVS, OTA metadata và partition table.

## Chưa nghiệm thu

- Chưa cài APK 559 MB lên điện thoại; chưa dùng app mới để thử cấu hình khi mobile data tắt. Yêu cầu cài đặt trước đây chỉ nêu rõ firmware ESP, nên APK mới được giữ ở dạng artifact để chờ chấp thuận cài lên điện thoại.
- Chưa nạp firmware contract v4 do board không có trên USB; chưa xác minh live partition/OTA metadata trong lượt này.
- Chưa chạy AP provision, ESP HTTPS login/refresh, WSS voice round trip, consent/revoke, reconnect hoặc mất Internet trên OSTB thật.
- NVS của OSTB 3ST chưa bật Flash Encryption; account password được giữ trong NVS theo yêu cầu và có thể khôi phục khi truy cập vật lý flash. Tech, QA, Privacy sign-off và release gate vẫn chờ.

## Lỗi và quyết định

- Backend response device-login ban đầu chứa datetime nội bộ làm JSON serialize fail; response đã loại `_at` metadata trước khi trả về, API tests pass.
- Rate limit được commit riêng trước password/device transaction để các lần login sai không bị rollback.
- Device-login từ cùng owner kết thúc session lease đang mở; rebind sau unbind xóa consent cũ. Account password login chỉ chạy khi vừa provision; refresh failure không tự đổi owner.
- Giữ debug-only gate vì DD chưa có Tech/QA/Privacy sign-off; source/APK có thể thử nội bộ, release vẫn khóa.
- ESP chưa được cài lại trong lượt này vì không có cổng serial. User đã cho phép app-only flash và không backup; trước lượt flash tiếp theo vẫn phải đọc live partition/OTA metadata và không dump NVS.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: source, contract, backend endpoint, app cache, local AP flow và current docs đã đồng nhất với quyết định người dùng; password được giữ hash trong PostgreSQL và ciphertext trong app.
- Mức độ hoàn thành task: source, tests, APK/firmware builds, backend deployment hoàn tất; app chưa cài, firmware chưa flash và phone-to-voice acceptance còn mở.
- Bằng chứng kiểm chứng: Flutter analyzer/5 tests/APK, backend 9 tests/Ruff/mypy, contract check, ESP-IDF image build/hash, server readiness/OpenAPI, `git diff --check`; USB probe cuối lượt không thấy ESP. Chưa có bằng chứng board hoặc app mới chạy E2E.
- Điểm tốn token/chưa tối ưu: Android debug APK gồm asset catalog lớn và vẫn khoảng 559 MB dù arm64-only; cần đánh giá asset packaging riêng nếu cài trên thiết bị bị thiếu dung lượng.
- Cách tối ưu cho phiên sau: cắm lại OSTB 3ST, đọc partition table/OTA metadata live, flash chỉ app image; sau đó cài APK debug hiện tại khi người dùng đồng ý, nối AP khi tắt dữ liệu di động và chạy login/voice/consent smoke.
- Task-skill: `.codex/task-skills/coding.md`
