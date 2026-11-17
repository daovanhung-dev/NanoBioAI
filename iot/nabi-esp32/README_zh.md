# Nabi ESP32 固件

这是用于 Nabi 兼容设备的 ESP-IDF 固件。OSTB 3ST 硬件、分区和刷写说明见
[OSTB 3ST 指南](main/boards/ostb/ostb-nabi-3st/README.md)。

## 构建 OSTB 3ST Nabi 配置

使用 ESP-IDF 6.1 或更高版本，并在 NanoBioAI 仓库根目录运行：

```sh
. "$IDF_PATH/export.sh"
python3 iot/nabi-esp32/scripts/build.py ostb/ostb-nabi-3st \
  --config config.local-ai.json --language vi-VN
```

此配置通过私人热点连接 Nabi 手机上的本地服务：OTA 路径为 `/nabi/ota/`，
音频 WebSocket 路径为 `/nabi/v1/`，端口为 `8386`。Android 配套应用位于
`phone_app/`。

其他开发板必须通过 `--ota-url` 或设备配置明确提供 OTA 地址；固件没有内置
远程 OTA 服务。许可和来源说明请查看 `LICENSE` 及组件 notices。

开发文档：[开发板构建与语言设置](docs/custom-board_zh.md)、
[WebSocket 协议](docs/websocket_zh.md)、[MQTT 与 UDP](docs/mqtt-udp_zh.md)、
[手机本地 AI 流程](docs/phone-local-ai-flow_vi.md)。
