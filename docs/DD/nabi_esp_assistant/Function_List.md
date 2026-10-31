# Function List — NABI_ESP_ASSISTANT

| ID | Chức năng | Layer / owner | Input → Output | Side effect / lỗi | Trạng thái |
|---|---|---|---|---|---|
| NABI_ESP_ASSISTANT-FN01 | Mở entry Android | Hub → GoRouter → page | tile → control page | iOS không hiện tile; release connection button remains locked pending review | Implemented; device navigation blocked by app auth startup |
| NABI_ESP_ASSISTANT-FN02 | Kiểm tra voice/backend readiness | `NabiEspVoicePipeline` | Whisper, backend session, voice → prepared pipeline | Missing Whisper/voice stops setup; Whisper download progress exposed; no transcript/audio logging | Implemented in source; not run on device |
| NABI_ESP_ASSISTANT-FN03 | Tạo hotspot và giữ service | Android MethodChannel + connectedDevice foreground service | start/stop → credentials and service state | Runtime permissions, API busy/unsupported, OS revocation; native service owns reservation | Implemented in source; phone API not exercised |
| NABI_ESP_ASSISTANT-FN04 | BLE scan/pair/provision | Espressif Android provisioning bridge + ESP Protocomm | device, PoP, SSID/password, shared config → paired state | Security 2; first code expires at 2 minutes; key in Android Keystore/NVS; no secret logging | Implemented in source; device exchange pending |
| NABI_ESP_ASSISTANT-FN05 | HTTP OTA/WebSocket session | `NabiEspServer` + `main/ota.cc` | OTA config/auth/socket → device state | Shared contract v3, port 8386 and `/nabi/*`; device-key OTA auth; random session bearer; reject invalid auth and second active socket | Implemented in source; focused contract test passes; device exchange pending |
| NABI_ESP_ASSISTANT-FN06 | STT → backend LLM → TTS | `NabiEspVoicePipeline` + backend AI turn datasource | Opus → transcript → backend answer → Opus | 6-turn RAM history, 60-second PCM bound, temporary TTS WAV deleted after read | Implemented in source; live backend/audio proof pending |
| NABI_ESP_ASSISTANT-FN07 | Send listen controls | page → `NabiEspServer` → `Application` | start/stop + request id → ack/state | Event-loop handoff; malformed ids/actions ignored; timeout handled | App and firmware handlers implemented; physical behavior pending |
| NABI_ESP_ASSISTANT-FN08 | Firmware provisioning/OTA/control | `iot/xiaozhi-esp32/main/` | BLE config, gateway, protocol messages | NVS pairing key, board display, audio/network tasks | Implemented in source; firmware build and device boot pending |

## Existing reusable source

- `BackendVoiceChatTurnDatasource.sendTurn()` applies Nabi’s safe prompt, sanitizer, timeout and authenticated backend client. It has a bounded message count and does not use local text inference.
- Whisper speech recognition and Android TTS remain device-side; the generated reply requires the NanoBio backend.
- `flutter_tts` is already installed for device speech but does not by itself prove an offline voice or expose Opus audio frames.

## Required tests after reviews

- Unit: pairing expiry/attempts, secret/token checks, bounded history, control state machine, audio framing/resampling, lifecycle cleanup.
- Widget/route: Android entry states, iOS hidden, missing AI setup, permission denied, disconnected, reconnecting and error states.
- Integration/device: LocalOnlyHotspot + FGS + background/screen lock + BLE Security2 + OSTB 3ST audio and offline network.
