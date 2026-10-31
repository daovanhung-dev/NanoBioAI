# Views — NABI_ESP_ASSISTANT

## NABI_ESP_ASSISTANT-V01 — Feature Hub preview / Android

- Entry: Feature Hub → collapsed “Sắp ra mắt” group → “Nabi - Siêu trợ lý AI”.
- Platform: Android only. iOS does not render the tile.
- Access: guest có thể xem trang; thao tác kết nối yêu cầu đăng nhập để dùng backend AI. Đây không phải AI Voice page và không kế thừa membership gate của trang đó.
- Current rendering: connection control and review status. Release remains gated; debug build can exercise the local connection path.
- States: AI preparation, hotspot/server startup, scanning ESP, first pairing code entry, provisioning, waiting for ESP, connected/listening/processing/speaking, and safe errors. iOS has no active entry.
- Accessibility: semantic text states that the feature is not active and why; content scrolls on small screens/text scale.

## NABI_ESP_ASSISTANT-V02 — Connection control page

The page shows local speech-recognition readiness, hotspot/server state, ESP pairing/connection state, listening controls, retryable errors, reconnect and stop server. Generated replies require a signed-in NanoBio session and Internet. It must not display or log the stored device key. Every state uses text/icon plus color and exposes screen-reader labels.

| State | Required copy/action | Current status |
|---|---|---|
| Review pending | Release build keeps the connection entry gated | Implemented via current release gating |
| Whisper/voice missing | Explain speech-recognition or offline voice prerequisite and offer retry | Implemented in source; device readiness pending |
| Permission denied | Explain required Android permission and offer retry | Implemented in source; permission exercise pending |
| Pairing | Ask user to enter one-time code shown on ESP; never expose stored key | Implemented in source; BLE device test pending |
| Ready / connected | Show hotspot/server readiness separately from ESP connection | Implemented in source; device connection pending |
| Listening / replying | Show turn state; no transcript/audio persistence | Implemented in source; audio device test pending |
| Disconnected / error | Safe Vietnamese status and retry/reconnect action | Implemented in source; lifecycle device test pending |

## NABI_ESP_ASSISTANT-V03 — Notification

Persistent foreground notification shows session state and “Dừng Nabi”. Start originates from visible UI. Notification action asks Flutter to stop its server, then releases hotspot reservation and foreground service. Implemented in source; background/notification-device test pending.
