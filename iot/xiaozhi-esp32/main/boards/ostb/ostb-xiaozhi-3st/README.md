# OSTB XiaoZhi 3ST

This target is for the ESP32-S3 OSTB XiaoZhi 3ST board with a 240×296 NV3023 LCD mounted for landscape use (296×240 UI, USB connector on the right), a CST816-series touch controller, an ES7210 microphone ADC, and an ES8311 speaker codec.

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
python3 scripts/build.py ostb-xiaozhi-3st --name ostb-xiaozhi-3st
```

The XiaoZhi source profile uses a custom 16 MB OTA partition table. A read-only
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
python3 scripts/build.py ostb/ostb-xiaozhi-3st --config config.local-ai.json --name ostb-xiaozhi-3st
```

This profile preserves existing NVS while building. Before flashing, read the live partition table and verify OTA slot compatibility; flash only the application partition if the installed bootloader, partition table, assets, and firmware identity are compatible. The running firmware must include the Nabi BLE extension for automatic provisioning.
