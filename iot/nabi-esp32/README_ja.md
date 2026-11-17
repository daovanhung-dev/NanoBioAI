# Nabi ESP32 ファームウェア

Nabi 対応 ESP32 デバイス向けの ESP-IDF ファームウェアです。OSTB 3ST の
ハードウェア、パーティション、書き込み方法は
[OSTB 3ST ガイド](main/boards/ostb/ostb-nabi-3st/README.md)を参照してください。

## OSTB 3ST Nabi プロファイルをビルド

ESP-IDF 6.1 以降を使い、NanoBioAI リポジトリのルートで実行します。

```sh
. "$IDF_PATH/export.sh"
python3 iot/nabi-esp32/scripts/build.py ostb/ostb-nabi-3st \
  --config config.local-ai.json --language vi-VN
```

このプロファイルは、プライベートホットスポット上の Nabi Android アプリに
接続します。OTA パスは `/nabi/ota/`、音声 WebSocket パスは `/nabi/v1/`、
ポートは `8386` です。Android アプリは `phone_app/` にあります。

他のボードでは `--ota-url` またはデバイス設定で OTA URL を明示してください。
ファームウェアに外部 OTA サーバーの既定値はありません。ライセンスと出典は
`LICENSE` および各コンポーネントの notices を参照してください。

開発資料：[ボードのビルドと言語設定](docs/custom-board.md)、
[WebSocket プロトコル](docs/websocket.md)、[MQTT と UDP](docs/mqtt-udp.md)、
[スマートフォン内 AI の接続手順](docs/phone-local-ai-flow_vi.md)。
