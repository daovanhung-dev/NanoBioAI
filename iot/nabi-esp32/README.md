# Nabi ESP32 Firmware

This ESP-IDF firmware powers Nabi-compatible ESP32 devices. The OSTB 3ST target
is maintained and validated in the NanoBioAI workspace. See the board guide at
[`main/boards/ostb/ostb-nabi-3st/README.md`](main/boards/ostb/ostb-nabi-3st/README.md)
for hardware, partition, and flash constraints.

## Build the OSTB 3ST Nabi profile

Use ESP-IDF 6.1 or newer and build from the NanoBioAI repository root:

```sh
. "$IDF_PATH/export.sh"
python3 iot/nabi-esp32/scripts/build.py ostb/ostb-nabi-3st \
  --config config.local-ai.json --language vi-VN
```

The profile uses the Nabi phone-local service on the private hotspot. Its OTA
endpoint is `/nabi/ota/`, and its authenticated audio channel is `/nabi/v1/` on
port `8386`. The Android companion app is in `phone_app/`.

Other board builds must receive an explicit Nabi OTA URL through `--ota-url`
or a device configuration. There is no built-in remote OTA service. For
example:

```sh
python3 iot/nabi-esp32/scripts/build.py <board> --ota-url https://your-host/ota/
```

## Development

- [Board build and language options](docs/custom-board.md)
- [WebSocket protocol](docs/websocket.md)
- [MQTT and UDP protocol](docs/mqtt-udp.md)
- [Phone-local AI flow](docs/phone-local-ai-flow_vi.md)
- [Firmware release process](docs/releasing.md)

Use the project `LICENSE` and component notices for licensing and source
attribution.
