# OSTB Nabi 3ST

This target is for the ESP32-S3 OSTB Nabi 3ST board with a 240×296 NV3023 LCD mounted for landscape use (296×240 UI, USB connector on the right), a CST816-series touch controller, an ES7210 microphone ADC, and an ES8311 speaker codec.

## Hardware mapping

| Function | GPIO / setting |
| --- | --- |
| I2C SDA / SCL | 12 / 11 |
| I2S MCLK / BCLK / WS | 5 / 15 / 16 |
| I2S microphone data | 7 |
| I2S speaker data | 6 |
| Speaker amplifier enable | 4, active high |
| LCD SPI CLK / MOSI | 9 / 10 |
| LCD CS / DC / reset | 14 / 8 / 18 |
| LCD backlight | 13 |
| Touch controller | CST816, I2C address `0x15` |
| Volume down / up | 39 / 40 |
| Boot button | 0 |

The display uses a 50 ms low / 120 ms high hardware reset pulse to avoid marginal NV3023 resets, BGR pixel order, XY swapping, X/Y mirroring, and a 24-pixel horizontal address offset. The audio codec runs at 24 kHz with the microphone reference channel enabled.

## Build

```sh
python3 iot/nabi-esp32/scripts/build.py ostb/ostb-nabi-3st --language vi-VN
```

The Nabi source profile uses a custom 16 MB OTA partition table. A read-only
inspection of the connected ESP32-S3 on 2026-10-23 found a different live table:
`nvs` at `0x9000` (24 KB), `phy_init` at `0xF000` (4 KB), and a `factory` app at
`0x10000` (1 MB), with no OTA or assets partitions. Do not treat the source CSV
as the table currently on the device. Before flashing or updating this board,
verify the intended firmware and partition table together and preserve the
device's existing data.

## Phone-local AI profile

The `config.local-ai.json` profile uses the 16 MB OTA partition table and enables Nabi provisioning only for OSTB 3ST. The phone app obtains current SSID/password from Android `LocalOnlyHotspot` and sends them over BLE Protocomm Security 2. First pairing requires the one-time code displayed on the ESP; paired app/device keys are retained in Android Keystore/NVS so later app sessions can send fresh hotspot credentials.

The app and ESP values are generated from the workspace contract `iot/nabi_esp_contract.json`: protocol v3, TCP port `8386`, OTA path `/nabi/ota/`, WebSocket path `/nabi/v1/`, device-key header `X-Nabi-Device-Key`, and the BLE service/custom endpoint. The ESP obtains the phone address as the station DHCP gateway; it does not use a fixed hotspot IP. Firmware authenticates the OTA request with the paired device key, and the phone returns a session Bearer token for WebSocket. The profile compiles a non-routable fallback URL only; after Wi-Fi connects, firmware replaces its host with the live DHCP gateway. Manual Wi-Fi AP configuration remains available for recovery.

Protocomm BLE for this profile uses the ESP-IDF Bluedroid BLE 4.2 API. The profile disables the BLE 5.0 host API selection that omits the legacy advertising symbols used by Protocomm. Do not remove this board-profile setting without building the BLE provisioning variant.

Build with ESP-IDF 6.0.1 or newer:

```sh
python3 iot/nabi-esp32/scripts/build.py ostb/ostb-nabi-3st --config config.local-ai.json --language vi-VN
```

This profile preserves existing NVS while building. Before flashing, read the live partition table and verify OTA slot compatibility; flash only the application partition if the installed bootloader, partition table, assets, and firmware identity are compatible. The running firmware must include the Nabi BLE extension for automatic provisioning.

## NanoBio cloud voice profile

`config.cloud-ai.json` is a separate build profile for the main NanoBio Nabi
app. The ESP starts a WPA2 `Nabi-xxxx` setup AP and displays its temporary
8-digit password. The user first signs in to Nabi while the phone has Internet,
then connects to the ESP AP and submits home Wi-Fi credentials. The app sends
the cached account identifier/password and Wi-Fi credentials to
`http://192.168.4.1/nabi/provision` over the WPA2 local network; no mobile data
or Internet route is needed during this setup step. The app keeps the account
credential encrypted in SQLite with an Android Keystore key until logout.

The ESP stores Wi-Fi and account credentials in NVS, connects to the home
network, then logs in to `https://nanobio.s2w.click/api/v1/iot/devices/credentials/login`.
The backend verifies the existing Argon2 password hash and returns a
device-scoped access/refresh token pair. PostgreSQL stores only hashes of the
device tokens. The ESP keeps the refresh token in NVS, the access token in RAM,
and opens protocol-v3 WSS at `wss://nanobio.s2w.click/api/v1/iot/ws`. The app
can change per-device health-context consent, open sensitive context for five
minutes while the device is online, rename the device, or revoke it.

The account password, refresh token, and Wi-Fi password are stored in device
NVS. The current OSTB snapshot has flash encryption disabled, so physical
access can expose those values. Audio and transcript handling is owned by the
server speech worker; this profile does not use the phone-local Whisper/TTS
host. Build with:

```sh
python3 iot/nabi-esp32/scripts/build.py ostb/ostb-nabi-3st --config config.cloud-ai.json --language vi-VN
```

Keep `config.local-ai.json` for the separate phone-local flow. Before a
hardware write, read the live partition table and confirm the installed
bootloader/OTA slot and rollback path; do not write the partition table or NVS.
