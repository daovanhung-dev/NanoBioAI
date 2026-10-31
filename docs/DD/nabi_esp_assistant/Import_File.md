# Import / File Map — NABI_ESP_ASSISTANT

> Runtime update 2026-10-30: the GGUF text runtime has been removed. Voice
> recognition remains on-device; generated replies use authenticated backend
> AI and require Internet.

## App source in NanoBio

| Path | Current role |
|---|---|
| `lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart` | Android-only preview entry under “Sắp ra mắt”; not an active shortcut |
| `lib/app_versions/v1/features/nabi_esp_assistant/presentation/pages/nabi_esp_assistant_page.dart` | Control page with readiness, server, pairing, ESP and listening states |
| `lib/app_versions/v1/router/v1_route_paths.dart` | Preview route constant |
| `lib/app_versions/v1/router/v1_router.dart` | Preview route registration without the AI Voice paid/auth gate |
| `lib/app_versions/v1/features/ai_voice/data/datasources/voice_chat_turn_datasource.dart` | Shared sanitized backend text response |
| `android/app/src/main/AndroidManifest.xml` | Hotspot/Bluetooth permissions and connected-device service declaration |
| `android/app/src/main/kotlin/com/nanobioai/app/nabi_esp/` | LocalOnlyHotspot, foreground service, Espressif BLE Security 2 and secure pairing store |
| `iot/nabi_esp_contract.json` and `iot/tools/generate_nabi_esp_contract.py` | Canonical contract source and Dart/Kotlin/ESP generators |
| `iot/xiaozhi-esp32/main/nabi_esp_provisioning.*` | OSTB BLE Security 2, pairing display/key, Wi-Fi provisioning and DHCP gateway URL |
| `iot/xiaozhi-esp32/main/ota.cc` and `main/protocols/protocol.*`, `main/application.cc` | OTA device-key auth and listen control/ack handling |

## Runtime ownership

| Planned owner | Responsibility |
|---|---|
| `features/nabi_esp_assistant/domain/` | Pairing/session state, bounded message history, listen commands |
| `features/nabi_esp_assistant/data/` | Whisper adapter, PCM/Opus framing, TTS-to-WAV/resample, HTTP/WebSocket server, secure pairing store |
| `features/nabi_esp_assistant/providers/` | Riverpod lifecycle/readiness controller, no direct UI-to-native calls |
| `android/.../nabi_esp/` | LocalOnlyHotspot reservation, Espressif provisioning bridge, connected-device FGS and notification action |
| `iot/xiaozhi-esp32/main/` | OSTB provisioning Security2, pairing code display, gateway OTA/auth, WebSocket listen control/ack |

## Dependencies

- `flutter_whisper_ggml`, `opus_codec_dart`, and the native Opus loader used by the imported `phone_app`; verify Android ABI/build/license and lifecycle before adoption.
- Espressif Android provisioning library `com.github.espressif:esp-idf-provisioning-android:lib-2.4.4` for BLE Security 2 and custom endpoint; verify JitPack build and device behavior before release.
- Existing `flutter_secure_storage`, `crypto`, `flutter_tts`, `path_provider`, `http`, and selected `LocalAiTextClient` can cover some requirements.

`iot/xiaozhi-esp32/phone_app/` remains a separate app and is outside this integration. Do not copy its independent LLM/model manager or modify that tree for this feature.
