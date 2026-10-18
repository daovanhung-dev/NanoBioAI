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

The board uses a 16 MB partition table matching the layout read from this device. Keep that layout when flashing to preserve existing NVS and data partitions.

## Phone-local AI profile

The `config.local-ai.json` profile points the firmware at the XiaoZhi server running in the phone app. Update its OTA URL if the phone's LAN address changes, keep the phone app server running on the same Wi-Fi, then build with:

```sh
python3 scripts/build.py ostb/ostb-xiaozhi-3st --config config.local-ai.json --name ostb-xiaozhi-3st
```

This profile always uses its configured OTA URL and leaves any saved URL and Wi-Fi credentials in NVS intact. Use the regular `config.json` profile for the project's default OTA service.
