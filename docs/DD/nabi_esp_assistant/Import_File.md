# Import / File Map — NABI_ESP_ASSISTANT

Cập nhật 2026-11-17: luồng app chỉ lo provision/quản lý; hội thoại sau setup chạy giữa ESP và NanoBio server.

## App source trong NanoBio

| Path | Vai trò |
|---|---|
| lib/app_versions/v1/features/nabi_esp_assistant/presentation/pages/nabi_esp_assistant_page.dart | Hướng dẫn nối AP, nhập Wi‑Fi nhà; liệt kê thiết bị; quản lý consent, tên và hủy liên kết |
| lib/app_versions/v1/features/nabi_esp_assistant/data/services/nabi_esp_assistant_runtime.dart | Local AP setup with cached account credential, pending server status and app release gate |
| lib/core/storage/nabi_esp_credential_vault.dart | Encrypted SQLite credential vault using Android Keystore for AES key |
| lib/app_versions/v1/features/nabi_esp_assistant/data/services/nabi_esp_device_service.dart | API app đã đăng nhập: list, rename, consent, unlock, revoke; pairing-session endpoint còn lại chỉ phục vụ tương thích cũ |
| lib/app_versions/v1/features/nabi_esp_assistant/data/services/nabi_esp_cloud_contract.g.dart | Hằng số sinh từ cloud contract |
| lib/app_versions/v1/features/nabi_esp_assistant/data/services/nabi_esp_android_bridge.dart | MethodChannel cho AP detection, local provisioning và credential encryption |
| android/app/src/main/kotlin/com/nanobioai/app/nabi_esp/NabiEspLocalProvisioner.kt | Gửi provision request qua Wi‑Fi ESP; không cần bind cellular |
| android/app/src/main/kotlin/com/nanobioai/app/nabi_esp/NabiEspCredentialCrypto.kt | AES/GCM cipher qua Android Keystore |
| android/app/src/main/res/xml/nabi_network_security_config.xml | Cho phép HTTP cleartext chỉ tới AP local `192.168.4.1` |
| android/app/src/main/kotlin/com/nanobioai/app/nabi_esp/NabiEspCloudContract.kt | Hằng số AP/cloud sinh từ contract |
| iot/nabi_esp_cloud_contract.json và iot/tools/generate_nabi_esp_cloud_contract.py | Source of truth/generator riêng cho API/WSS cloud |

## Backend source

| Path | Vai trò |
|---|---|
| backend/src/nanobio_backend/modules/iot/router.py | REST endpoints device-login, legacy pairing, credential refresh, device, consent và WebSocket |
| backend/src/nanobio_backend/modules/iot/view.py | API orchestration, Argon2 credential check, ownership/auth behavior |
| backend/src/nanobio_backend/modules/iot/query.py | Persistence/query layer cho device, consent và session |
| backend/src/nanobio_backend/modules/iot/models.py | Pydantic request/response contracts |
| backend/src/nanobio_backend/modules/iot/voice.py | Voice WebSocket v3 và session lease |
| backend/src/nanobio_backend/services/iot_speech_worker.py | Local STT/TTS service |
| backend/systemd/nanobio-iot-speech-worker.service | Loopback systemd service; requires speech extra and installed model files |
| backend/src/nanobio_backend/db/models.py | SQLAlchemy IoT tables |
| backend/alembic/versions/0008_iot_devices.py | Deployed IoT schema revision, idempotent on the repo's dynamic initial schema |
| backend/alembic/versions/0009_merge_iot_web_push.py | Merge local Web Push and deployed IoT migration branches |
| backend/tests/test_iot_api.py | Pairing, consent, token rotation, revocation và voice contract tests |
| backend/.env.example | Non-secret IoT URL, loopback worker and model configuration template |

## Firmware source

| Path | Vai trò |
|---|---|
| iot/nabi-esp32/main/boards/ostb/ostb-nabi-3st/config.cloud-ai.json | Profile cloud riêng, giữ profile config.local-ai.json |
| iot/nabi-esp32/main/nabi_esp_cloud_contract.h | Hằng số sinh từ cloud contract |
| iot/nabi-esp32/main/nabi_esp_provisioning.* | AP status/provision routes, HTTPS device-login/refresh, NVS credential/token lifecycle |
| iot/nabi-esp32/main/protocols/websocket_protocol.cc | Authenticated direct ESP↔server WebSocket |
| iot/nabi-esp32/main/application.cc | Activation, reconnect và channel lifecycle |
| iot/nabi-esp32/main/ota.cc | Cấu hình OTA cũ chỉ dùng trong profile local; cloud pilot không chạy flow OTA này |

## Boundaries

- iot/nabi_esp_contract.json, iot/tools/generate_nabi_esp_contract.py, config.local-ai.json và iot/nabi-esp32/phone_app/ không đổi bởi cloud profile.
- Cấu hình Wi‑Fi và account credential đi qua HTTP trên AP WPA2; ESP lưu account credential trong NVS theo yêu cầu. PostgreSQL chỉ giữ Argon2 hash, app lưu password ciphertext trong SQLite tới khi logout.
- Foreground service/LocalOnlyHotspot source cũ còn trong native bridge nhưng không được runtime cloud hiện tại gọi.
- Source có mặt không chứng minh server đã được deploy/build hoặc device đã chạy. Xem acceptance gate trong Overall.
