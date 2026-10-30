# PLAN — NanoBio IoT OSTB 3ST: SoftAP onboarding + Remote Ollama + Voice AI

- **Ngày:** 2026-10-28
- **Repository:** https://github.com/daovanhung-dev/NanoBioAI
- **Branch đọc:** `main` (GitHub connector; **không thực hiện thay đổi repository**)
- **Trạng thái:** Technical plan / chưa coding, chưa build, chưa flash
- **Phạm vi:** firmware `iot/xiaozhi-esp32/`, đặc biệt OSTB 3ST; có thể bổ sung server speech services riêng biệt trên Ubuntu. Không tích hợp qua `backend/` FastAPI.
- **Server hiện có (theo kết quả người dùng):** Public HTTPS `https://42.118.174.147/api/chat` (người dùng báo đã kết nối thành công), Nginx có Basic Auth user `esp32`, Ollama nội bộ `127.0.0.1:11434`, model `qwen3.5:2b-q4_K_M`.

> PHÂN BIỆT: Trạng thái server public do người dùng báo đã thành công; trong phiên này không đăng nhập vào server hoặc kiểm chứng chứng chỉ/IP trực tiếp. STT và TTS chưa có bằng chứng đã được triển khai. Không được đánh đồng Ollama Chat API với nhận dạng/phát tiếng nói.

## A. Mục tiêu và phạm vi nghiệm thu

### A1. Trải nghiệm sản phẩm
1. Bật ESP32-S3 lần đầu (hoặc khi chưa có Wi-Fi): firmware phát SoftAP có SSID theo mẫu `NanoBio-Setup-XXXX` và mật khẩu provisioning riêng từng thiết bị.
2. Điện thoại kết nối Wi-Fi của ESP; tự gợi ý captive portal nếu OS hỗ trợ, hoặc mở địa chỉ portal trên màn hình ESP (địa chỉ thật do WiFiManager cung cấp, không mặc định một IP chưa xác minh).
3. Người dùng chọn SSID Wi-Fi 2.4 GHz, nhập mật khẩu, gửi cấu hình qua giao diện portal; firmware xác nhận, lưu cấu hình qua API WiFiManager/SsidManager, kết nối STA, lấy DHCP.
4. ESP kiểm tra Internet/giờ hệ thống, xác minh TLS chứng chỉ IP và gọi `POST https://42.118.174.147/api/chat` với Basic Authentication; nhận và hiển thị trả lời tiếng Việt.
5. Trải nghiệm giọng nói phiên bản đầu: bấm/chạm để nói → microphone ghi audio → STT server → text → Ollama → text → TTS server → audio → ESP phát qua loa. Các dịch vụ speech cần triển khai riêng; **không gọi FastAPI backend ứng dụng NanoBio**.
6. Khi reboot có Wi-Fi hợp lệ, tự kết nối lại; không bật Setup AP ở mọi lần boot bình thường. Long-press nút cấu hình hoặc connect timeout đưa về AP để sửa Wi-Fi, không xóa dữ liệu khác.
7. Nếu mất Internet/server: trạng thái và thông báo rõ trên LCD, tự retry có backoff; không phát tán mật khẩu trong log.

### A2. Định nghĩa DONE
- P0: ESP SoftAP → điện thoại cấu hình → STA online → HTTPS 200 → JSON Ollama → LCD/serial hiển thị.
- P1: mic → STT tiếng Việt → Ollama → TTS tiếng Việt → loa ESP, 3 lượt đối thoại liên tiếp trên cùng thiết bị thật.
- P2: reconnect, security, reliability, OTA rollback, hiệu năng thực nghiệm, kiểm thử từ Wi-Fi khác mạng server.

## B. Context thực tế đã đọc từ repo

### B1. Code/Docs chuẩn phải đọc (đã đối chiếu)
- `AGENTS.md`, `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md`, `.codex/domains/xiaozhi-esp32.md`, `.codex/workflows/coding.md`.
- `iot/xiaozhi-esp32/AGENTS.md`, `docs/agent-context/README.md`, `CONNECTED_DEVICE_OSTB_3ST.md`, `ARCHITECTURE.md`, `TASK_ROUTING.md`, `BOARDS_AND_BUILD.md`.
- `iot/xiaozhi-esp32/main/boards/common/wifi_board.cc`: `TryWifiConnect()` dùng `SsidManager`; khi chưa có SSID, đi vào `StartWifiConfigMode()`; khi build có `CONFIG_USE_HOTSPOT_WIFI_PROVISIONING` sẽ gọi `WifiManager::StartConfigAp()` và hiển thị URL `GetApWebUrl()`.
- `iot/xiaozhi-esp32/main/boards/ostb/ostb-xiaozhi-3st/ostb_xiaozhi_3st.cc`: driver màn hình/cảm ứng, các nút, audio codec; long-press boot vào Wi-Fi config.
- `iot/xiaozhi-esp32/main/audio/README.md`: audio input 16 kHz mono từ AudioEngine; Opus/audio queues hiện có; audio hardware/profile 24 kHz; cần đối chiếu resample và DMA.
- `iot/xiaozhi-esp32/main/nabi_esp_provisioning.cc`: BLE Security 2, pairing 8 số, local hotspot credentials, lưu NVS.
- `iot/nabi_esp_contract.json`: **chỉ** dành cho mode phone-local, contract v1, protocol v3, TCP 8386, `/nabi/ota/`, `/nabi/v1/`, BLE prefix `NABI_`.
- `iot/xiaozhi-esp32/main/ota.cc`: với mode phone-local lấy OTA host từ DHCP gateway và cấu hình WebSocket; code mới không được vô tình sử dụng cơ chế này khi chạy remote Ollama.
- `iot/xiaozhi-esp32/main/protocols/websocket_protocol.cc`, `docs/websocket.md`: XiaoZhi WS v1/v2/v3 khác hẳn giao thức Ollama REST `/api/chat`; **không thể** chỉ đổi WebSocket URL thành URL Ollama.
- `docs/DD/nabi_esp_assistant/README.md` bản v1.0-draft: hiện gắn với Android phone-local, voice round trip chưa nghiệm thu.

### B2. Hồ sơ thiết bị thực tế (2026-10-23)
- ESP32-S3 rev 0.2; Flash 16 MB; PSRAM 8 MB; firmware XiaoZhi 2.5.3, ESP-IDF 6.1; OTA0 `0x20000`.
- Partition đọc từ thiết bị: NVS `0x9000/0x4000`, otadata `0xD000/0x2000`, phy `0xF000/0x1000`, OTA0 `0x20000/0x460000`, OTA1 `0x480000/0x460000`, assets `0x8E0000/0x5A0000`, data `0xE80000/0x178000`, NVS-user `0xFF8000/0x8000`.
- ESP từng pair BLE thật với Android, nhận SSID/password và gateway, WebSocket control ACK; chưa xác minh TTS thoại E2E. `phone_app/` là dự án khác, **không thuộc Nabi integration**.
- Secure Boot/Flash Encryption đang tắt; NVS có khả năng bị trích xuất khi có quyền truy cập vật lý. Không claim secrets trên flash được bảo vệ tuyệt đối.
- Nguồn code là profile cho board OSTB, vẫn cần smoke test trên thiết bị thật; không suy luận LCD/mic/loa chạy tốt chỉ vì build pass.

### B3. Luật bắt buộc của repo
- ESP-IDF **6.0.1 trở lên, nên 6.1**; không build snapshot này bằng ESP-IDF 5.4.
- Chỉ một board factory `DECLARE_BOARD`, tránh sửa pin của board có sẵn.
- Board selection: `config.json/config.remote-ai.json` → `scripts/build.py` → Kconfig → CMake → board source, đúng 16MB partition layout.
- Giữ các thay đổi đang có và NVS; không tự chạy `erase_flash`, burn eFuse, ghi bootloader, ghi partition, flash app khi chưa xác nhận image/offset và backup.
- Không edit trực tiếp generated (`build/`, `managed_components/`, generated contracts, `sdkconfig` local).
- Thay đổi Application phải qua `SetDeviceState`/`Schedule`, không block audio/event loop, audio queue bounded.

## C. Thiết kế kiến trúc

### C1. MVP text-first, gọi Ollama không qua NanoBio backend
```
OSTB 3ST (STA Wi-Fi)
  ├── SoftAP onboarding + Captive Portal (chỉ setup/recovery)
  ├── TLS/HTTP Basic client + JSON parser + bounded chat history
  ├── LCD UI, button, event loop
  └── POST https://42.118.174.147/api/chat
          │ HTTPS public 443
          ▼
     FPT router → Nginx Basic Auth + rate limit
          ▼
     Ollama 127.0.0.1:11434 → Qwen3.5 2B
```
- Nginx tiếp tục chỉ expose `/api/chat`, chặn API quản trị Ollama.
- `stream:false`, `think:false` MVP. Giới hạn `num_ctx` + output + max JSON response + timeout. Truyền `messages` với system prompt tiếng Việt phù hợp NanoBio.
- Client duy trì lịch sử theo lượt trong RAM; giới hạn theo tổng byte/token ước lượng, giữ system message, drop các lượt cũ nhất. Không lưu nội dung hội thoại xuống NVS.

### C2. Voice version (có thêm dịch vụ giọng nói riêng)
```
 ESP mic → audio PCM 16k mono / WAV chunk ──HTTPS──► STT worker (Whisper.cpp)
     ◄────────────── transcript vi_VN ─────────────┘
 ESP ──HTTPS /api/chat──► Nginx/Ollama ──► response text
 ESP ──HTTPS───────────► TTS worker (Piper vi_VN) ──► WAV/PCM
 ESP → resample nếu cần → ES8311/I²S → loa
```
- Đây là mô hình **ESP gọi thẳng từng dịch vụ**, không đi qua FastAPI backend nghiệp vụ. Tuy nhiên STT và TTS vẫn cần tiến trình server có endpoint phù hợp. Ollama model Qwen 2B hiện có **không nhận audio hoặc sinh waveform** qua `/api/chat`.
- STT ứng viên: `whisper.cpp` `whisper-server` có HTTP endpoint `/inference` nhận WAV; cần thử tiếng Việt và CPU.
- TTS ứng viên: Piper với voice `vi_VN` (model có thực); Piper CLI không mặc định là HTTP API, phải lựa chọn một HTTP adapter/server riêng đã audit và giữ sau Nginx, hoặc chuyển sang giải pháp có HTTP API sẵn. Cần xác định cụ thể response audio và licensing của voice trước khi code ESP.
- Nginx cần 2 route riêng cho STT/TTS, auth/rate limit/body limit riêng: WAV 16 kHz 16-bit mono ~32KB/s, 5 giây ~160KB; `client_max_body_size 64k` hiện tại KHÔNG đủ, phải sửa **riêng cho đường STT**, không nới cho `/api/chat`.
- Phase đầu dùng push-to-talk, không cố làm thoại realtime full duplex; wake word/AEC/barge-in sau khi round trip đã ổn định.

### C3. Hai chế độ không phá tương thích
- `PHONE_LOCAL`: giữ contract `iot/nabi_esp_contract.json` (BLE Security2 → LocalOnlyHotspot → DHCP gateway 8386 → XiaoZhi WebSocket v3).
- `REMOTE_OLLAMA`: SoftAP/local webpage → Wi-Fi gia đình → public HTTPS → Chat REST; speech endpoints riêng ở phase tiếp.
- Chọn **build variant riêng** `config.remote-ai.json`, không sửa/đè `config.local-ai.json`, không xóa BLE provisioning hay logic OTA cũ. Nếu mã hiện có gắn `CONFIG_NABI_ESP_ASSISTANT` với mode phone-local, thiết kế Kconfig mới tách mode tường minh để không chạy cả 2 bootstrap song song.
- Tuyệt đối không để remote mode cố gọi `http://<DHCP gateway>:8386/nabi/ota/`; URL đó là logic cho điện thoại, không dùng để tìm Ollama public.

## D. State machine & network lifecycle

| State | Điều kiện vào | Hành động | Thành công / lỗi |
| --- | --- | --- | --- |
| BOOT | Nguồn/reset | NVS load, board init, chọn mode | Wifi scan/config |
| WIFI_SETUP | Chưa có SSID hoặc long press/setup retry | Start SoftAP + web UI + DNS captive portal nếu tương thích | credentials_received |
| WIFI_CONNECTING | Có SSID | Stop config AP (hoặc APSTA chuyển tiếp an toàn), STA join, DHCP | `IP_EVENT_STA_GOT_IP` hoặc timeout |
| INTERNET_CHECK | Đã có IP | NTP, DNS không cần nếu dùng IP, kiểm tra route/TLS | ONLINE hoặc NETWORK_ERROR |
| AI_READY | TLS/auth/API OK | Hiển thị Nano sẵn sàng, wake/PTT | LISTENING |
| LISTENING | PTT | Capture bounded PCM, optional VAD | TRANSCRIBING |
| TRANSCRIBING | Audio saved in RAM | POST speech STT | THINKING hoặc error |
| THINKING | Transcript có nội dung | POST Ollama /api/chat | SPEAKING hoặc error |
| SPEAKING | Text answer OK | POST TTS; playback | AI_READY |
| NETWORK_ERROR | Timeout/401/429/5xx/offline | thông báo, backoff, không mất Wi-Fi config | retry/setup |
| WIFI_RECONFIGURE | Long press | Kết thúc audio/session, vào SoftAP | WIFI_SETUP |

**Ràng buộc:** transition qua Application event loop, callback mạng không được gọi HTTP block; network request chạy trong bounded worker task riêng; UI không gọi trực tiếp socket.

## E. Wire contracts

### E1. Ollama HTTP
- URL: `https://42.118.174.147/api/chat`, POST JSON, `Content-Type: application/json`.
- HTTPS xác minh chain + SAN IP bằng ESP x509 bundle/CA; **không** `skip_common_name_check`, **không** `-k` trong firmware. Cấp time NTP trước khi validate cert; nếu không Internet, báo lỗi chứ không fallback HTTP.
- `Authorization: Basic <base64(username:password)>` chỉ gửi qua HTTPS, mỗi thiết bị nên có username/password riêng; không ghi credential vào firmware source/Git, logs hoặc telemetry. Lưu trong NVS/secure provisioning theo khả năng thiết bị, thừa nhận flash encryption off.
- Body ví dụ (giá trị mục tiêu):
```json
{
  "model":"qwen3.5:2b-q4_K_M",
  "stream":false,
  "think":false,
  "keep_alive":"10m",
  "messages":[
    {"role":"system","content":"Bạn là Nano, trợ lý tiếng Việt của thiết bị NanoBio. Trả lời thân thiện, chính xác, ngắn gọn 1-2 câu, không tự bịa chuyên môn."},
    {"role":"user","content":"Chào Nano!"}
  ],
  "options":{"num_ctx":2048,"num_predict":160,"temperature":0.5}
}
```
- Parse `message.content`, `done`, `done_reason`, `total_duration` nếu có. Nếu `done_reason=length`, giảm yêu cầu câu trả lời/ngữ cảnh hoặc tăng vừa phải `num_predict` sau benchmark. Giới hạn response buffer, tối đa turn history và overflow handling.
- 401 unauthorized, 403 forbidden, 404 endpoint, 413 payload, 429 rate limited, 502/503 backend, 504 timeout, DNS/TCP/TLS failure đều có mã lỗi thiết bị riêng; dùng retry có backoff với 429/5xx/network, không retry loop cho 401.

### E2. Portal HTTP local (đề xuất, giữ lại WifiManager sẵn có)
- `GET /`: HTML setup gọn nhẹ, không cần JS CDN/cloud, mobile-responsive.
- `GET /api/wifi/scan`: SSID + RSSI + auth mode; không xuất ra mật khẩu.
- `POST /api/wifi/connect`: `{ "ssid":"...", "password":"..." }`, giới hạn body, sanitize/log redaction, trả trạng thái accepted (không khẳng định connected ngay).
- `GET /api/status`: trạng thái WIFI_CONNECTING/CONNECTED/ERROR và IP đã được cấp; không trả secrets.
- `POST /api/wifi/reset`: hành động được xác thực/physical confirmation, không được public trên STA interface.
- Đây là **contract dự kiến**; trước khi implement phải kiểm tra `WifiManager` / managed component có sẵn API/portal tương đương để **reuse, không duplicate HTTP server**.
- SSID dự kiến `NanoBio-Setup-XXXX`; không dùng mật khẩu AP mặc định chung như `12345678`, dùng secret mỗi thiết bị in trên màn hình hoặc tem/QR. Auto captive portal là best-effort; luôn có URL thủ công vì iOS/Android có thể không bật pop-up.

### E3. STT/TTS wire (sẽ final sau khi P0 pass)
- STT: `POST /speech/stt`, HTTPS, auth, audio `audio/wav`/multipart phù hợp `whisper-server`, có duration cap 5–10s, size cap tính từ sample rate. Nginx chỉ expose đúng route; `whisper.cpp` worker loopback.
- TTS: `POST /speech/tts`, `{text,voice,format}`, trả `audio/wav` hoặc PCM chunk (định nghĩa byte order, sample rate, channels). Backend speech adapter riêng, không phải business FastAPI; nếu muốn **tuyệt đối không thêm server ngoài Ollama**, voice round-trip chưa thể thực hiện với model/API hiện tại.
- ESP chuyển PCM/Opus đúng theo codec; tránh vừa dùng existing Opus sender vừa gửi WAV duplicate, tránh xung đột audio tasks.

## F. Kế hoạch coding thành từng PR/task

### P0 — Audit, backup và baseline (không ghi thiết bị)
**Đọc:** `.codex/AGENTS.md`, IoT AGENTS, `CONNECTED_DEVICE_OSTB_3ST.md`, board config, NVS/partition.
- `git status --short`; ghi các thay đổi đang có, không override.
- Chạy `idf.py --version`; cần ESP-IDF 6.1; đối chiếu source được checkout, `build.py --list-boards`.
- Chụp log readonly hiện trạng: chip, flash, partition offset, app slot, startup, heap, PSRAM, Wi-Fi behavior. Không dump nguyên Flash/NVS chứa dữ liệu cá nhân nếu chưa cần.
- Xác minh backup app/partition đầy đủ và hash hiện hữu; nếu cần tạo backup phải có chấp thuận thao tác đọc flash (có thể reset/reboot).
- Xác nhận từ mạng ngoài public HTTPS `/api/chat` 200, 401 nếu thiếu auth, hạn mức Nginx và certificate chain/SAN IP. **Không dùng `curl -k`**.
**DoD:** baseline & rollback plan, issue list, chưa flash.

### P1 — SoftAP + portal onboarding (ưu tiên reuse)
**Owner:** `main/boards/common/wifi_board.cc`, WiFiManager/SsidManager component, board UI, `main/settings.*` nếu cần.
- Xem current Kconfig `CONFIG_USE_HOTSPOT_WIFI_PROVISIONING`; build profile mới phải bật đúng đường StartConfigAp, không chỉ BLE BLUFI.
- Đổi branding cấu hình AP sang NanoBio trong **profile remote / board scope**; tránh đổi mọi board XiaoZhi.
- Xác minh captive portal đang có; nếu chưa: thực hiện DNS captive portal + HTTP landing; cân nhắc DHCP Option 114, không redirect HTTPS.
- Portal chọn Wi-Fi, submit và poll trạng thái, validate đầu vào, lưu NVS qua manager. Không dừng AP trước khi phản hồi cho mobile; khi STA success, đóng AP sau khoảng grace ngắn.
- Force reconfigure: long-press boot (board đã hỗ trợ) + nút UI phù hợp; không factory-reset NVS nếu chỉ đổi SSID.
**DoD:** trên điện thoại kết nối AP, thấy portal, lưu Wi-Fi, ESP nhận IP, reboot tự reconnect, sai password → recover.

### P2 — Remote-AI variant và kết nối HTTPS /api/chat
**Owner:** `main/boards/ostb/ostb-xiaozhi-3st/config.remote-ai.json` (NEW), `main/Kconfig.projbuild`, `main/CMakeLists.txt`, `main/application.*`, new `main/nabi_remote_ai/`.
- Tạo Kconfig lựa chọn transport `PHONE_LOCAL` / `REMOTE_OLLAMA` riêng, build profile/OTA identity rõ ràng, không thay `config.local-ai.json`.
- Không gọi `Ota::GetLocalOtaUrl()` kiểu gateway trong remote mode; xử lý startup không phụ thuộc server trả `/nabi/ota/`.
- Client `RemoteAiClient` (esp_http_client hoặc existing HTTP abstraction) TLS + Basic, dynamic JSON cJSON, byte caps, bounded `messages`, system prompt, timeouts.
- Credentials và URL cấu hình qua ESP portal; hardcode URL mặc định có thể được, **không hardcode mật khẩu**. Nên expose `GET /api/status` local để thấy `server_online` mà không lộ auth.
- LCD thể hiện `Đang kết nối`, `Sẵn sàng`, `Đang suy nghĩ`, `AI trả lời`, `Lỗi Internet`, `Sai thông tin API`.
- Test trên host qua mock HTTP server và test thực bằng curl; sau đó smoke test thiết bị thật.
**DoD:** ESP đọc text từ `/api/chat`, hiển thị được câu tiếng Việt, 401/429/503 không crash.

### P3 — Microphone + xử lý utterance
**Owner:** `main/audio/`, `main/application.*`, board codec existing.
- Reuse ES7210 + AudioService/AFE; không viết lại I²S pin/codec. Push-to-talk bằng nút/touch để tạo lượt nghe.
- Định nghĩa capture 16kHz 16-bit mono PCM output từ AFE; WAV container nếu whisper server yêu cầu. 5s ~160kB; buffer bounded trong PSRAM, không alloc nhiều lần trên audio callback.
- End-point & VAD; nếu vắng tiếng hoặc file quá lớn, báo lỗi và không gửi.
- Ưu tiên bỏ ghi WAV xuống Flash: chỉ giữ RAM, timeout/abort cleanup đúng.
**DoD:** WAV test tách riêng phát lại/nhận dạng bằng PC, 10 lượt ghi liên tiếp không lỗi bộ nhớ.

### P4 — Speech-to-text trên Ubuntu (service tách biệt)
**Server:** `whisper.cpp` `whisper-server` loopback; một Nginx path STT auth, rate limit và body cap riêng; benchmark CPU RAM cạnh Ollama.
- Kiểm chứng model tiếng Việt, response text, duration, HTTP timeout; xác định tên endpoint `/inference` của server được chọn.
- PTT audio từ ESP tới speech service; JSON text từ STT trả ESP, sau đó ESP gửi cho Ollama.
- Không để endpoint STT trả audio hay lỗi chứa PII; logs không ghi audio/raw transcript.
**DoD:** 10 câu tiếng Việt qua 2 mạng → transcript hợp lý; lỗi mạng/timeout không deadlock.

### P5 — TTS tiếng Việt và loa
**Server:** Piper `vi_VN` (đánh giá voice `vais1000`/`25hours_single`/`vivos`) + HTTP adapter **được xác định, kiểm tra license**; loopback + Nginx route protected.
- Chốt `audio/wav` mono PCM sample rate và output giới hạn, resample 16k/24k nếu cần; không tự động giả định codec TTS và codec DAC cùng sample rate.
- TTS reply audio được ESP tải trong chunks có flow-control và phát qua `AudioOutputTask`/codec. Không gửi toàn bộ file audio vào JSON.
- Giới hạn 1 lượt thoại; hỗ trợ stop playback khi user bấm dừng.
**DoD:** ESP nói lại giọng Việt nghe rõ ở loa, không vỡ tiếng, có thể lặp 5 lần.

### P6 — Dialogue, UI, reliability, security hardening
- Giữ 4–6 lượt chat RAM, giới hạn tổng byte/context; riêng system prompt bảo toàn.
- Nút/chạm: tap để nói, tap lại để kết thúc; long-press để cấu hình. Wake-word chỉ sau PTT ổn định.
- Wi-Fi lost → reconnect exponential backoff + jitter; server 401 → yêu cầu nhập lại API secret; 429 → cooldown; OTA cert renewal làm restart nginx → retry.
- NTP/RTC, CA bundle, hostname IP SAN, ngăn TLS downgrade; API username riêng per-device và chính sách revoke; giới hạn nhiệt/PSRAM/stack, watchdog.
- Không log tokens/password/SSID/audio/transcript; nếu thật sự cần structured metrics, chỉ log timings/errors.
- Đo P50/P95: wifi join, TLS handshake, STT, LLM, TTS, end-to-end. Kết quả server đã thấy 100 token ~11.24s là một mẫu, **không phải** latency bảo đảm.
**DoD:** soak 30 phút, 20 lượt nói, reboot/power loss, Wi-Fi change, 4G hotspot, 401, 429, 503, timeout, memory không xuống liên tục.

### P7 — Bàn giao, OTA, release QA
- Docs `docs/features/remote-ollama-voice/...` mới, cập nhật DD `nabi_esp_assistant` hoặc tạo DD mới cho chế độ server public; không tuyên bố phần phone-local đã hoàn thành.
- Backup/restore, OTA update/rollback, release identity, security configuration SOP. Không bật Secure Boot/flash encryption trên bo đang chạy nếu chưa có thiết kế migration và thiết bị test riêng.
- Chạy `python3 iot/tools/generate_nabi_esp_contract.py --check` nếu có chỉnh contract phone-local; remote contract cần source riêng rõ ràng.
- Chạy host tests, build profile mới, review binary partitions và image sizes; flashing OTA0/OTA1 chỉ khi đã đối chiếu slot đang chạy và có phép.
- Update worklogs & checklist theo `.codex/AGENTS.md`, `docs/checklist/checklist_complete_DD.md`, `docs/checklist/checklist_task_coding.md`.
**DoD:** ZIP source delta + plan + test report + CLI commands + rollback docs + ảnh/video thực nghiệm theo nhiệm vụ giao.

## G. File change matrix (dự kiến, không thay file khi chưa audit)

| File | Hành động | Lý do |
| --- | --- | --- |
| `main/boards/common/wifi_board.cc` | reuse/điều chỉnh tối thiểu | SoftAP/state/recovery đã có |
| `main/boards/ostb/ostb-xiaozhi-3st/config.remote-ai.json` | NEW | build mode riêng, ESP-IDF6.1, 16MB |
| `main/boards/ostb/ostb-xiaozhi-3st/ostb_xiaozhi_3st.cc` | targeted | nút/touch/LCD chỉ nếu cần |
| `main/Kconfig.projbuild`, `main/CMakeLists.txt` | targeted | mode + sources |
| `main/nabi_remote_ai/remote_ai_client.{h,cc}` | NEW | Ollama HTTPS Basic/JSON |
| `main/nabi_remote_ai/remote_ai_settings.{h,cc}` | NEW | URL/secret/limits NVS, không hardcode |
| `main/nabi_remote_ai/remote_ai_voice.{h,cc}` | NEW later | HTTP STT/TTS và state |
| `main/application.*` | targeted | lifecycle state and scheduling |
| `main/audio/*` | targeted later | PCM utterance tap / streamed audio playback |
| `main/ota.cc` | targeted | không bootstrap phone gateway trong remote mode |
| `main/settings.*` | targeted | NVS key migration nếu cần |
| `iot/nabi_esp_contract.json` | KEEP | bảo toàn phone-local existing |
| `lib/app_versions/v1/features/nabi_esp_assistant/` | OPTIONAL P7 | optional Flutter setup/status; portal browser ở P1 không yêu cầu Flutter |
| `iot/xiaozhi-esp32/phone_app/` | DO NOT TOUCH | độc lập với NanoBio Flutter app |
| `docs/DD/nabi_esp_assistant/*` | UPDATE after product review | phân biệt phone local và public Ollama |

## H. Test matrix (test ID → điều kiện)

| ID | Bài test | Pass criteria |
| --- | --- | --- |
| NET-01 | Flash sạch Wi-Fi config (sandbox board/backup) | SoftAP NanoBio xuất hiện |
| NET-02 | Android/iOS vào AP | Truy cập captive portal hoặc URL tay |
| NET-03 | Sai password Wi-Fi | Thông báo, retry, AP recovery |
| NET-04 | SSID có dấu/ký tự đặc biệt | Parse/lưu đúng, không crash |
| NET-05 | Wi-Fi 5GHz-only | Thông báo không hỗ trợ 5GHz, không treo |
| NET-06 | Reboot | Tự nối STA không cần nhập lại |
| NET-07 | Long-press | Vào cấu hình mà không xóa pairing/data |
| SEC-01 | Chứng chỉ hợp lệ IP SAN | TLS handshake thành công |
| SEC-02 | Self-signed/wrong IP SAN/expired | Từ chối TLS |
| SEC-03 | Thiếu/sai Basic auth | 401, không retry vô hạn |
| SEC-04 | Nginx 429 | Backoff và UI cooldown |
| SEC-05 | Mất server/ngắt mạng | Không crash, tự reconnect |
| API-01 | Gửi user prompt unicode | Nhận `message.content` UTF-8 |
| API-02 | Antwort dài vượt buffer | Không tràn heap, hiển thị lỗi rõ |
| API-03 | 4–6 lượt đối thoại | Context được giới hạn và giữ đúng thứ tự role |
| API-04 | Nginx reject >limit | Không crash, không spam lại |
| AUD-01 | PTT microphone | WAV/PCM sạch, sample rate đúng |
| AUD-02 | STT tiếng Việt | nhận dạng được 10 câu kiểm thử |
| AUD-03 | TTS vi_VN | Loa phát nghe rõ, không vỡ tiếng |
| AUD-04 | User stop | Ngừng capture/playback đúng |
| SOAK-01 | 20 turn + 30min | Không reset, heap ổn định |
| FW-01 | Build profile + flash app only sau phép | Boot, NVS/OTA còn nguyên |
| REG-01 | Build phone-local variant | Hành vi cũ không bị phá |

## I. Security và vận hành (không bỏ qua)
1. Public Ollama phải đi qua Nginx HTTPS 443; tuyệt đối **không forward 11434/18080**.
2. Không mở `/api/pull`, `/api/delete`, model management endpoints; STT/TTS nếu cần chỉ mở URL có auth, body caps và concurrency cap.
3. Basic auth username/password không commit, không log, không nhúng cố định vào binary public; mỗi device một credential, quản lý vòng đời và revoke.
4. NVS chứa Wi-Fi/secret; vì Flash Encryption thiết bị đang tắt, tấn công vật lý có thể trích xuất. Dùng pairing/portal password riêng, hạn chế truy cập vật lý; đánh giá secure storage riêng trước production.
5. AP setup phải WPA2/WPA3 khả dụng, mã mạnh riêng, timeout; giới hạn request, chống CSRF/unauthorized actions và chỉ bind portal trên SoftAP interface.
6. Đừng dùng `curl -k` hoặc disable TLS validation để vượt lỗi HTTPS. Nếu chứng chỉ IP thay đổi/renew, firmware phải tin CA root thay vì pin leaf cert ngắn hạn.
7. Phần voice là dữ liệu nhạy cảm: không ghi âm/nhật ký hội thoại mặc định, có cơ chế xóa dữ liệu trong RAM; hiển thị thông báo đang thu âm.
8. Nginx rate limit hiện có thể thấp hơn mục tiêu 50 requests/phút: **phải đối chiếu config thực tế**; 10r/m/IP nếu tồn tại sẽ giới hạn cả ESP cùng NAT chung. Chỉ tăng sau khi benchmark CPU/ram STT/LLM/TTS.

## J. Lệnh kiểm tra an toàn trước coding

```bash
# Machine Debian, chỉ đọc
cd /path/to/NanoBioAI
git status --short
cat iot/nabi_esp_contract.json
cd iot/xiaozhi-esp32
source /path/to/esp-idf-v6.1/export.sh
idf.py --version
python3 scripts/build.py --list-boards
# Chưa flash/erase.

# Ubuntu server, chỉ đọc (không in secret)
sudo ss -lntp | grep -E ':(443|11434|18080)\b'
sudo nginx -t
curl --max-time 5 http://127.0.0.1:11434/api/tags
sudo /snap/bin/certbot certificates  # nếu dùng snap certbot
```

### Remote API contract smoke-test, từ mạng khác
```bash
curl -u esp32 --max-time 120 \
  https://42.118.174.147/api/chat \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen3.5:2b-q4_K_M","stream":false,"think":false,"messages":[{"role":"user","content":"Xin chào Nano!"}],"options":{"num_predict":160}}'
```

## K. Quy trình giao Codex

```text
Task: Triển khai P0 + P1 + P2 của PLAN NanoBio Remote Ollama cho OSTB 3ST.
Repo: daovanhung-dev/NanoBioAI.
Đầu tiên đọc root AGENTS.md -> .codex/AGENTS.md -> PROJECT_MAP -> coding workflow -> xiaozhi domain -> iot/xiaozhi-esp32/AGENTS.md -> CONNECTED_DEVICE_OSTB_3ST.md -> kiến trúc/tuyến nhiệm vụ -> source ownership.
Không viết lại Wi-Fi manager/audio codec; tận dụng SoftAP StartConfigAp có sẵn.
Giữ phone-local mode, existing NVS và partition 16MB; thêm mode remote Ollama với variant riêng.
Không dùng FastAPI NanoBio; gọi HTTPS POST /api/chat qua public IP 42.118.174.147 và Nginx Basic Auth, validate cert; không hardcode secret.
Đầu tiên làm text-only E2E, chưa triển khai audio. Không tự flash, erase, burn eFuse hay thay đổi server production.
Kiểm tra git diff, build/test host, tạo báo cáo QA và hướng dẫn flash an toàn; liệt kê test nào chưa xác nhận trên board thật.
```

## L. Nguồn đối chiếu kỹ thuật
- GitHub repository: https://github.com/daovanhung-dev/NanoBioAI
- Board context: https://github.com/daovanhung-dev/NanoBioAI/blob/main/iot/xiaozhi-esp32/docs/agent-context/CONNECTED_DEVICE_OSTB_3ST.md
- Wi-Fi board source: https://github.com/daovanhung-dev/NanoBioAI/blob/main/iot/xiaozhi-esp32/main/boards/common/wifi_board.cc
- Espressif Captive Portal: https://github.com/espressif/esp-idf/blob/master/examples/protocols/http_server/captive_portal/README.md
- ESP HTTP client TLS/Auth: https://github.com/espressif/esp-idf/blob/master/docs/en/api-reference/protocols/esp_http_client.rst
- Ollama API: https://github.com/ollama/ollama/blob/main/docs/api.md
- Whisper server: https://github.com/ggml-org/whisper.cpp/blob/master/examples/server/README.md
- Piper Vietnamese voices: https://github.com/rhasspy/piper/blob/master/VOICES.md

## M. Open decisions / blockers
- Public HTTPS 42.118.174.147 đã user xác nhận hoạt động; vẫn cần smoke-test từ ESP trên Wi-Fi khác, certificate SAN và cert renewal.
- Chưa kiểm tra runtime current `CONFIG_USE_HOTSPOT_WIFI_PROVISIONING` trong binary thật; xác minh variant trước khi dựa vào SoftAP.
- Chưa xác minh Nginx public Basic auth per-device policy và rate limit thực tế.
- Chưa có STT/TTS server; cần chọn, benchmark, dựng routes trước P4-P5.
- Không chắc thời gian CPU để STT/LLM/TTS cùng chạy đáp ứng trải nghiệm giọng nói; benchmark trước khi cam kết SLA.
- Chế độ backup/restore đã đầy đủ hay chưa phải xác minh lại trên thiết bị; không flash trong giai đoạn plan.
