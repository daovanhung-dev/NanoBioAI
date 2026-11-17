# Function List — NABI_ESP_ASSISTANT

| ID | Chức năng | Layer / owner | Input → Output | Side effect / lỗi | Trạng thái |
|---|---|---|---|---|---|
| NABI-ESP-FN01 | Lưu account credential sau login | BackendAuthRepository → NabiEspCredentialVault → Android Keystore/SQLite | login success → ciphertext `{identifier_type, identifier, password}` theo user_id | SQLite ciphertext được xóa khi logout; server password vẫn Argon2 hash | Source/analyzer/build pass; UI login/vault integration test pending |
| NABI-ESP-FN02 | Provision Wi‑Fi và account qua AP | Flutter runtime → Android NabiEspLocalProvisioner → ESP local HTTP API | SSID/Wi‑Fi password + account identifier/password → device ID | WPA2 local; không cần mobile data; một lần provision mỗi phiên; ESP NVS lưu credentials | Source/build pass; phone-to-AP exchange pending |
| NABI-ESP-FN03 | Device login/refresh credential | NabiEspProvisioning::AuthenticateCloud | account credential hoặc refresh token → access + refresh + WSS | device-login qua HTTPS; ownership check; server chỉ hash device tokens; refresh không fallback password | Source/build/server route pass; login/refresh trên thiết bị pending |
| NABI-ESP-FN04 | Mở voice WebSocket | ESP WebsocketProtocol ↔ backend /iot/ws | audio/voice v3 → AI reply/audio | auth bearer + device ID; server revocation lease; không có app audio proxy | Server routes/worker health verified; device voice round trip pending |
| NABI-ESP-FN05 | Liệt kê và quản lý ESP | app service/page ↔ authenticated IoT API | owner session → status, name, consent | rename/unbind user-scoped; app không nhận device credential | Source có; focused Flutter analyze/test pass |
| NABI-ESP-FN06 | Cập nhật consent/unlock | app page → backend IoT API | consent hoặc confirm → context rule | default false; sensitive unlock yêu cầu active session và hết hạn sau 5 phút | Source có; backend tests pass; privacy/device integration pending |
| NABI-ESP-FN07 | Xử lý STT/TTS trên server | backend voice websocket → loopback speech worker | Opus → transcript/AI/audio | xử lý trong RAM; worker không public bind; không ghi payload ra ổ đĩa | Source/tests có; live worker health verified; voice round trip pending |
| NABI-ESP-FN08 | Build cloud firmware profile | config.cloud-ai.json + ESP-IDF | OSTB 3ST config → firmware image | profile độc lập local phone AI; chỉ flash app OTA slot sau khi đọc live partition | Build và OTA0 app-only flash pass; voice E2E pending |

## Reusable boundaries

- App auth dùng BackendApiClient; ESP lưu account credential trong NVS theo quyết định sản phẩm; flash encryption trên OSTB 3ST chưa bật.
- Server voice service nhận WSS từ ESP; app chỉ cấp quyền/cấu hình và quản lý thiết bị.
- iot/nabi_esp_contract.json giữ contract phone-local cũ; iot/nabi_esp_cloud_contract.json sinh cloud contract v4, device-login path và voice protocol v3.
- Chi tiết acceptance và review nằm trong Overall, mục 6.
