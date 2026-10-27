# Danh mục file dự án

> Snapshot tạo ngày 2026-10-23. Danh mục gồm mọi đường dẫn Git-tracked, các file first-party untracked đang có trong worktree và chính tài liệu context này.

- Đường dẫn được liệt kê: **1779** (1772 tracked, 7 first-party untracked; có 0 tracked path hiện không tồn tại trong worktree).
- Mỗi dòng mô tả vai trò của file theo nội dung hoặc cách project tham chiếu; asset nhị phân được liệt kê riêng theo định dạng và kích thước byte, với vai trò dựa trên tên, locale hoặc source sử dụng.
- Không liệt kê từng file trong .git/, build/, managed_components/ và ignored local sdkconfig*; đây là Git metadata, output build, dependency đã resolve hoặc config sinh tại máy.
- Với path tracked đang thiếu, kích thước lấy từ Git blob ở HEAD; không khôi phục file đang thiếu.

## Tổng quan theo vùng

### Nabi / ESP phone-local AI entry points

Read the mandatory [connected-device snapshot](CONNECTED_DEVICE_OSTB_3ST.md), then use these implementation owners:

| Path | Owner |
| --- | --- |
| `docs/features/phone-local-ai/001-feature-phone-hotspot-server.md` | Current phone-to-OSTB integration flow and acceptance boundary |
| `../../nabi_esp_contract.json` | Canonical protocol/port/path/BLE contract source |
| `../../tools/generate_nabi_esp_contract.py` | Generates Dart, Kotlin, and ESP constants; supports `--check` |
| `main/nabi_esp_contract.h` | Generated ESP constants |
| `main/nabi_esp_provisioning.h` / `main/nabi_esp_provisioning.cc` | OSTB BLE Security 2, one-time code, pairing key, Wi-Fi configuration, DHCP gateway lookup |
| `main/ota.cc` | Dynamic OTA URL and paired-device HTTP header |
| `main/protocols/protocol.h` / `.cc`, `main/application.cc` | Nabi listen command acknowledgement and event-loop dispatch |
| `lib/app_versions/v1/features/nabi_esp_assistant/` | Main Nabi app UI, runtime, local server and voice pipeline (repo root) |
| `android/app/src/main/kotlin/com/nanobioai/app/nabi_esp/` | Main Nabi app Android hotspot, BLE and foreground service (repo root) |

`iot/xiaozhi-esp32/phone_app/` is a separate app. It is outside this Nabi integration and must not be treated as its app-side implementation.

| Vùng | File |
| --- | ---: |
| `.clang-format` | 1 |
| `.dockerignore` | 1 |
| `.github/` | 10 |
| `.gitignore` | 1 |
| `AGENTS.md` | 1 |
| `CMakeLists.txt` | 1 |
| `LICENSE` | 1 |
| `README.md` | 1 |
| `README_ja.md` | 1 |
| `README_zh.md` | 1 |
| `docker/` | 5 |
| `docs/` | 40 |
| `main/` | 1619 |
| `partitions/` | 14 |
| `phone_app/` | 33 |
| `scripts/` | 38 |
| `sdkconfig.defaults` | 1 |
| `sdkconfig.defaults.esp32` | 1 |
| `sdkconfig.defaults.esp32c3` | 1 |
| `sdkconfig.defaults.esp32c5` | 1 |
| `sdkconfig.defaults.esp32c6` | 1 |
| `sdkconfig.defaults.esp32p4` | 1 |
| `sdkconfig.defaults.esp32s3` | 1 |
| `sdkconfig.defaults.esp32s31` | 1 |

## Danh mục đầy đủ

| Đường dẫn | Định dạng | Kích thước byte | Trạng thái worktree | Vai trò |
| --- | --- | ---: | --- | --- |
| `.clang-format` | `no extension` | 3337 | tracked | Quy tắc định dạng C/C++ của repository. |
| `.dockerignore` | `no extension` | 176 | tracked | Các đường dẫn bỏ qua khi build Docker. |
| `.github/ISSUE_TEMPLATE/01_build_flash_bug.yml` | `yml` | 2679 | tracked | GitHub issue template for collecting a specific report/request type. |
| `.github/ISSUE_TEMPLATE/02_runtime_bug.yml` | `yml` | 2912 | tracked | GitHub issue template for collecting a specific report/request type. |
| `.github/ISSUE_TEMPLATE/03_feature_request.yml` | `yml` | 1571 | tracked | GitHub issue template for collecting a specific report/request type. |
| `.github/ISSUE_TEMPLATE/04_board_support_request.yml` | `yml` | 2171 | tracked | GitHub issue template for collecting a specific report/request type. |
| `.github/ISSUE_TEMPLATE/05_technical_question.yml` | `yml` | 1613 | tracked | GitHub issue template for collecting a specific report/request type. |
| `.github/ISSUE_TEMPLATE/config.yml` | `yml` | 551 | tracked | GitHub issue template for collecting a specific report/request type. |
| `.github/SUPPORT.md` | `md` | 2849 | tracked | Cấu hình hỗ trợ hoặc tự động hóa GitHub. Main section: Account and Device Support. |
| `.github/workflows/build.yml` | `yml` | 3664 | tracked | CI chọn variants theo changed files, host tooling checks và build matrix. |
| `.github/workflows/release.yml` | `yml` | 4215 | tracked | Workflow build và publish firmware release matrix. |
| `.github/workflows/test-mcp.yml` | `yml` | 890 | tracked | Workflow kiểm tra MCP liên quan. |
| `.gitignore` | `no extension` | 239 | tracked | Các file/đường dẫn Git bỏ qua. |
| `AGENTS.md` | `md` | 6019 | tracked | Quy tắc agent: phạm vi, kiến trúc, an toàn thay đổi, build và xác minh. Main section: AGENTS.md. |
| `CMakeLists.txt` | `txt` | 494 | tracked | Khởi tạo project ESP-IDF và phiên bản firmware. |
| `LICENSE` | `no extension` | 1140 | tracked | Điều khoản cấp phép MIT. |
| `README.md` | `md` | 10335 | tracked | Tổng quan sản phẩm, SDK được hỗ trợ, tính năng, board, cách phát triển và tài liệu. Main section: An MCP-based Chatbot. |
| `README_ja.md` | `md` | 11885 | tracked | Bản tiếng Nhật của tổng quan dự án. Main section: MCP ベースのチャットボット. |
| `README_zh.md` | `md` | 9939 | tracked | Bản tiếng Trung của tổng quan dự án. Main section: An MCP-based Chatbot. |
| `docker/firmware-builder/Dockerfile` | `no extension` | 1187 | tracked | Container image environment for reproducible firmware builds. |
| `docker/firmware-builder/README.md` | `md` | 3304 | tracked | Instructions for the Docker firmware builder. Main section: Firmware builder container. |
| `docker/firmware-builder/entrypoint.sh` | `sh` | 350 | tracked | Container startup wrapper for firmware builder. |
| `docker/firmware-builder/firmware_builder.py` | `py` | 15839 | tracked | Docker build orchestration implementation. Entry points/types: `utc_now`, `env`, `upload_config`, `parser`, `validate`, `run_and_log`, `command_output`, `project_version`. |
| `docker/firmware-builder/test_firmware_builder.py` | `py` | 13685 | tracked | Tests for Docker firmware-builder orchestration. Entry points/types: `FirmwareBuilderTest`. |
| `docs/agent-context/ARCHITECTURE.md` | `md` | 6402 | tracked | Sơ đồ ownership và luồng khởi động/runtime của firmware. Main section: Kiến trúc và luồng runtime. |
| `docs/agent-context/BOARDS_AND_BUILD.md` | `md` | 3993 | tracked | Chuỗi chọn board/variant, partition, assets và build. Main section: Board, variant và build. |
| `docs/agent-context/CONNECTED_DEVICE_OSTB_3ST.md` | `md` | 8690 | first-party untracked | Snapshot ESP sau khi build/nạp OTA0, xác minh BLE/Wi-Fi/OTA config/WebSocket và tách bằng chứng thiết bị khỏi source/build. Main section: Hồ sơ ESP đang kết nối: OSTB 3ST. |
| `docs/agent-context/README.md` | `md` | 4969 | tracked | Điểm vào bộ context, quy trình nạp context và thứ tự nguồn sự thật. Main section: XiaoZhi ESP32 Agent Context. |
| `docs/agent-context/TASK_ROUTING.md` | `md` | 4113 | tracked | Bản đồ task tới owner, tài liệu, ranh giới và kiểm chứng. Main section: Định tuyến task. |
| `docs/audio-codec-input-audit.md` | `md` | 23313 | tracked | Documentation: AudioCodec 输入通道审计; see this file for its authoritative topic and details. Main section: 本轮调整. |
| `docs/audio-codec-input-audit_vi.md` | `md` | 26673 | tracked | Documentation: Kiểm toán kênh đầu vào AudioCodec; see this file for its authoritative topic and details. Main section: Điều chỉnh trong đợt này. |
| `docs/blufi.md` | `md` | 2817 | tracked | Documentation: BluFi Provisioning (with `esp-wifi-connect`); see this file for its authoritative topic and details. Main section: Prerequisites. |
| `docs/blufi_vi.md` | `md` | 3452 | tracked | Documentation: Cấu hình BluFi (tích hợp `esp-wifi-connect`); see this file for its authoritative topic and details. Main section: Điều kiện tiên quyết. |
| `docs/blufi_zh.md` | `md` | 2492 | tracked | Documentation: BluFi 配网（集成 esp-wifi-connect）; see this file for its authoritative topic and details. Main section: 前置条件. |
| `docs/code_style.md` | `md` | 3496 | tracked | Documentation: Code Style Guide; see this file for its authoritative topic and details. Main section: Formatting Tool. |
| `docs/code_style_vi.md` | `md` | 4324 | tracked | Documentation: Hướng dẫn phong cách mã nguồn; see this file for its authoritative topic and details. Main section: Công cụ định dạng. |
| `docs/code_style_zh.md` | `md` | 3433 | tracked | Documentation: 代码风格指南; see this file for its authoritative topic and details. Main section: 代码格式化工具. |
| `docs/custom-board.md` | `md` | 19384 | tracked | Documentation: Custom Board Guide; see this file for its authoritative topic and details. Main section: Important. |
| `docs/custom-board_vi.md` | `md` | 21663 | tracked | Documentation: Hướng dẫn tạo bo mạch tùy chỉnh; see this file for its authoritative topic and details. Main section: Quan trọng. |
| `docs/custom-board_zh.md` | `md` | 16331 | tracked | Documentation: 自定义开发板指南; see this file for its authoritative topic and details. Main section: 重要提示. |
| `docs/features/phone-local-ai/001-feature-phone-hotspot-server.md` | `md` | 5188 | first-party untracked | Thiết kế Nabi Android LocalOnlyHotspot, BLE Security 2, cổng 8386, dynamic gateway OTA/WebSocket v3 và review gate. |
| `docs/glyph-push.md` | `md` | 7452 | tracked | Documentation: Dynamic Text Glyph Push Extension; see this file for its authoritative topic and details. Main section: 1. Capability advertisement. |
| `docs/glyph-push_vi.md` | `md` | 9568 | tracked | Documentation: Phần mở rộng đẩy glyph văn bản động; see this file for its authoritative topic and details. Main section: 1. Quảng bá khả năng. |
| `docs/glyph-push_zh.md` | `md` | 6657 | tracked | Documentation: 动态文字 Glyph Push 扩展; see this file for its authoritative topic and details. Main section: 1. 能力声明. |
| `docs/mcp-based-graph.jpg` | `jpg` | 97848 | tracked | Ảnh minh họa trong tài liệu `mcp-based-graph`. |
| `docs/mcp-based-graph_vi.jpg` | `jpg` | 50331 | tracked | Ảnh minh họa trong tài liệu `mcp-based-graph_vi`. |
| `docs/mcp-protocol.md` | `md` | 8846 | tracked | Documentation: MCP (Model Context Protocol) Interaction Flow; see this file for its authoritative topic and details. Main section: Message Format. |
| `docs/mcp-protocol_vi.md` | `md` | 10174 | tracked | Documentation: Luồng tương tác MCP (Model Context Protocol); see this file for its authoritative topic and details. Main section: Định dạng thông điệp. |
| `docs/mcp-protocol_zh.md` | `md` | 9705 | tracked | Documentation: MCP (Model Context Protocol) 交互流程; see this file for its authoritative topic and details. Main section: 协议格式. |
| `docs/mcp-usage.md` | `md` | 6593 | tracked | Documentation: MCP IoT Control Usage; see this file for its authoritative topic and details. Main section: Introduction. |
| `docs/mcp-usage_vi.md` | `md` | 7624 | tracked | Documentation: Cách dùng MCP để điều khiển IoT; see this file for its authoritative topic and details. Main section: Giới thiệu. |
| `docs/mcp-usage_zh.md` | `md` | 3717 | tracked | Documentation: MCP 协议物联网控制用法说明; see this file for its authoritative topic and details. Main section: 简介. |
| `docs/mqtt-udp.md` | `md` | 10024 | tracked | Documentation: MQTT + UDP Hybrid Communication Protocol; see this file for its authoritative topic and details. Main section: 1. Overview. |
| `docs/mqtt-udp_vi.md` | `md` | 11670 | tracked | Documentation: Giao thức truyền thông kết hợp MQTT + UDP; see this file for its authoritative topic and details. Main section: 1. Tổng quan. |
| `docs/mqtt-udp_zh.md` | `md` | 9306 | tracked | Documentation: MQTT + UDP 混合通信协议文档; see this file for its authoritative topic and details. Main section: 1. 协议概览. |
| `docs/notify.md` | `md` | 5155 | tracked | Documentation: Asynchronous Voice Notifications; see this file for its authoritative topic and details. Main section: Message format. |
| `docs/notify_vi.md` | `md` | 6374 | tracked | Documentation: Thông báo giọng nói không đồng bộ; see this file for its authoritative topic and details. Main section: Định dạng thông điệp. |
| `docs/phone-local-ai-flow_vi.md` | `md` | 10177 | tracked | Luồng OTA/WebSocket/audio/STT/LLM/TTS, BLE Security 2 và server Nabi qua LocalOnlyHotspot. |
| `docs/releasing.md` | `md` | 2770 | tracked | Documentation: Publishing firmware releases; see this file for its authoritative topic and details. Main section: Running the workflow. |
| `docs/releasing_vi.md` | `md` | 3479 | tracked | Documentation: Phát hành firmware; see this file for its authoritative topic and details. Main section: Chạy workflow. |
| `docs/websocket.md` | `md` | 18247 | tracked | Documentation: WebSocket Communication Protocol; see this file for its authoritative topic and details. Main section: 1. Overall Flow. |
| `docs/websocket_vi.md` | `md` | 20751 | tracked | Documentation: Giao thức truyền thông WebSocket; see this file for its authoritative topic and details. Main section: 1. Luồng tổng quát. |
| `docs/websocket_zh.md` | `md` | 18021 | tracked | Documentation: 1. 总体流程概览; see this file for its authoritative topic and details. Main section: 2. 通用请求头. |
| `main/CMakeLists.txt` | `txt` | 68825 | tracked | Main ESP-IDF component composition: common/selected-board sources, fonts, emojis, locale and asset generation. |
| `main/Kconfig.projbuild` | `projbuild` | 45624 | tracked | Project Kconfig: target-gated board choice, languages, audio/AEC, display/assets and feature options. |
| `main/application.cc` | `cc` | 55598 | tracked | Điều phối lifecycle, event loop, state, protocol, audio, assets, MCP, OTA và notify. Key types/methods: `digit_sound`, `Application::SetDeviceState`, `Application::Initialize`, `Application::Run`, `Application::HandleNetworkConnectedEvent`, `Application::HandleNetworkDisconnectedEvent`, `Application::HandleActivationDoneEvent`, `Application::ActivationTask`. |
| `main/application.h` | `h` | 6876 | tracked | API và state nội bộ của Application; events và scheduling. Key types/methods: `AecMode`, `Application`, `TaskPriorityReset`. |
| `main/assets.cc` | `cc` | 26067 | tracked | Load/checksum/mmap assets, models, themes và font capability. Key types/methods: `mmap_assets_table`, `Assets::FindPartition`, `Assets::Apply`, `Assets::InitializePartition`, `Assets::UnApplyPartition`, `Assets::UseBuiltInTextFontCapability`, `Assets::DisableTextFontGlyphPush`, `Assets::GetAssetData`. |
| `main/assets.h` | `h` | 3245 | tracked | API asset partition, font capability và asset strategies. Key types/methods: `Asset`, `TextFontCapability`, `Assets`, `AssetStrategy`, `LvglStrategy`, `EmoteStrategy`. |
| `main/assets/common/exclamation.ogg` | `ogg` | 1663 | tracked | Hiệu ứng âm thanh dùng chung `exclamation` được nhúng vào firmware. |
| `main/assets/common/low_battery.ogg` | `ogg` | 2269 | tracked | Hiệu ứng âm thanh dùng chung `low_battery` được nhúng vào firmware. |
| `main/assets/common/popup.ogg` | `ogg` | 1148 | tracked | Hiệu ứng âm thanh dùng chung `popup` được nhúng vào firmware. |
| `main/assets/common/success.ogg` | `ogg` | 2012 | tracked | Hiệu ứng âm thanh dùng chung `success` được nhúng vào firmware. |
| `main/assets/common/vibration.ogg` | `ogg` | 1574 | tracked | Hiệu ứng âm thanh dùng chung `vibration` được nhúng vào firmware. |
| `main/assets/locales/ar-SA/0.ogg` | `ogg` | 1940 | tracked | Audio prompt `0` cho locale `ar-SA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ar-SA/1.ogg` | `ogg` | 1658 | tracked | Audio prompt `1` cho locale `ar-SA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ar-SA/2.ogg` | `ogg` | 1938 | tracked | Audio prompt `2` cho locale `ar-SA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ar-SA/3.ogg` | `ogg` | 1861 | tracked | Audio prompt `3` cho locale `ar-SA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ar-SA/4.ogg` | `ogg` | 1949 | tracked | Audio prompt `4` cho locale `ar-SA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ar-SA/5.ogg` | `ogg` | 1755 | tracked | Audio prompt `5` cho locale `ar-SA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ar-SA/6.ogg` | `ogg` | 1825 | tracked | Audio prompt `6` cho locale `ar-SA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ar-SA/7.ogg` | `ogg` | 1721 | tracked | Audio prompt `7` cho locale `ar-SA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ar-SA/8.ogg` | `ogg` | 1977 | tracked | Audio prompt `8` cho locale `ar-SA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ar-SA/9.ogg` | `ogg` | 2063 | tracked | Audio prompt `9` cho locale `ar-SA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ar-SA/activation.ogg` | `ogg` | 13539 | tracked | Audio prompt `activation` cho locale `ar-SA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ar-SA/err_pin.ogg` | `ogg` | 4416 | tracked | Audio prompt `err_pin` cho locale `ar-SA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ar-SA/err_reg.ogg` | `ogg` | 9211 | tracked | Audio prompt `err_reg` cho locale `ar-SA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ar-SA/language.json` | `json` | 3283 | tracked | Dữ liệu ngôn ngữ `ar-SA` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/ar-SA/upgrade.ogg` | `ogg` | 4104 | tracked | Audio prompt `upgrade` cho locale `ar-SA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ar-SA/welcome.ogg` | `ogg` | 2971 | tracked | Audio prompt `welcome` cho locale `ar-SA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ar-SA/wificonfig.ogg` | `ogg` | 5461 | tracked | Audio prompt `wificonfig` cho locale `ar-SA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/bg-BG/0.ogg` | `ogg` | 2369 | tracked | Audio prompt `0` cho locale `bg-BG`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/bg-BG/1.ogg` | `ogg` | 1867 | tracked | Audio prompt `1` cho locale `bg-BG`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/bg-BG/2.ogg` | `ogg` | 2356 | tracked | Audio prompt `2` cho locale `bg-BG`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/bg-BG/3.ogg` | `ogg` | 2245 | tracked | Audio prompt `3` cho locale `bg-BG`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/bg-BG/4.ogg` | `ogg` | 2611 | tracked | Audio prompt `4` cho locale `bg-BG`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/bg-BG/5.ogg` | `ogg` | 2015 | tracked | Audio prompt `5` cho locale `bg-BG`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/bg-BG/6.ogg` | `ogg` | 2231 | tracked | Audio prompt `6` cho locale `bg-BG`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/bg-BG/7.ogg` | `ogg` | 2276 | tracked | Audio prompt `7` cho locale `bg-BG`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/bg-BG/8.ogg` | `ogg` | 2133 | tracked | Audio prompt `8` cho locale `bg-BG`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/bg-BG/9.ogg` | `ogg` | 1770 | tracked | Audio prompt `9` cho locale `bg-BG`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/bg-BG/activation.ogg` | `ogg` | 14501 | tracked | Audio prompt `activation` cho locale `bg-BG`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/bg-BG/err_pin.ogg` | `ogg` | 4716 | tracked | Audio prompt `err_pin` cho locale `bg-BG`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/bg-BG/err_reg.ogg` | `ogg` | 10755 | tracked | Audio prompt `err_reg` cho locale `bg-BG`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/bg-BG/language.json` | `json` | 3822 | tracked | Dữ liệu ngôn ngữ `bg-BG` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/bg-BG/upgrade.ogg` | `ogg` | 6374 | tracked | Audio prompt `upgrade` cho locale `bg-BG`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/bg-BG/welcome.ogg` | `ogg` | 3502 | tracked | Audio prompt `welcome` cho locale `bg-BG`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/bg-BG/wificonfig.ogg` | `ogg` | 7569 | tracked | Audio prompt `wificonfig` cho locale `bg-BG`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ca-ES/0.ogg` | `ogg` | 1790 | tracked | Audio prompt `0` cho locale `ca-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ca-ES/1.ogg` | `ogg` | 2616 | tracked | Audio prompt `1` cho locale `ca-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ca-ES/2.ogg` | `ogg` | 1737 | tracked | Audio prompt `2` cho locale `ca-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ca-ES/3.ogg` | `ogg` | 2088 | tracked | Audio prompt `3` cho locale `ca-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ca-ES/4.ogg` | `ogg` | 1897 | tracked | Audio prompt `4` cho locale `ca-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ca-ES/5.ogg` | `ogg` | 1733 | tracked | Audio prompt `5` cho locale `ca-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ca-ES/6.ogg` | `ogg` | 1923 | tracked | Audio prompt `6` cho locale `ca-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ca-ES/7.ogg` | `ogg` | 1674 | tracked | Audio prompt `7` cho locale `ca-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ca-ES/8.ogg` | `ogg` | 1892 | tracked | Audio prompt `8` cho locale `ca-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ca-ES/9.ogg` | `ogg` | 1986 | tracked | Audio prompt `9` cho locale `ca-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ca-ES/activation.ogg` | `ogg` | 11679 | tracked | Audio prompt `activation` cho locale `ca-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ca-ES/err_pin.ogg` | `ogg` | 5439 | tracked | Audio prompt `err_pin` cho locale `ca-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ca-ES/err_reg.ogg` | `ogg` | 8509 | tracked | Audio prompt `err_reg` cho locale `ca-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ca-ES/language.json` | `json` | 2856 | tracked | Dữ liệu ngôn ngữ `ca-ES` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/ca-ES/upgrade.ogg` | `ogg` | 3717 | tracked | Audio prompt `upgrade` cho locale `ca-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ca-ES/welcome.ogg` | `ogg` | 2876 | tracked | Audio prompt `welcome` cho locale `ca-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ca-ES/wificonfig.ogg` | `ogg` | 5347 | tracked | Audio prompt `wificonfig` cho locale `ca-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/cs-CZ/0.ogg` | `ogg` | 1781 | tracked | Audio prompt `0` cho locale `cs-CZ`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/cs-CZ/1.ogg` | `ogg` | 2000 | tracked | Audio prompt `1` cho locale `cs-CZ`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/cs-CZ/2.ogg` | `ogg` | 1788 | tracked | Audio prompt `2` cho locale `cs-CZ`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/cs-CZ/3.ogg` | `ogg` | 1531 | tracked | Audio prompt `3` cho locale `cs-CZ`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/cs-CZ/4.ogg` | `ogg` | 1880 | tracked | Audio prompt `4` cho locale `cs-CZ`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/cs-CZ/5.ogg` | `ogg` | 1857 | tracked | Audio prompt `5` cho locale `cs-CZ`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/cs-CZ/6.ogg` | `ogg` | 1871 | tracked | Audio prompt `6` cho locale `cs-CZ`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/cs-CZ/7.ogg` | `ogg` | 2052 | tracked | Audio prompt `7` cho locale `cs-CZ`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/cs-CZ/8.ogg` | `ogg` | 2057 | tracked | Audio prompt `8` cho locale `cs-CZ`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/cs-CZ/9.ogg` | `ogg` | 1876 | tracked | Audio prompt `9` cho locale `cs-CZ`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/cs-CZ/activation.ogg` | `ogg` | 9954 | tracked | Audio prompt `activation` cho locale `cs-CZ`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/cs-CZ/err_pin.ogg` | `ogg` | 4045 | tracked | Audio prompt `err_pin` cho locale `cs-CZ`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/cs-CZ/err_reg.ogg` | `ogg` | 7830 | tracked | Audio prompt `err_reg` cho locale `cs-CZ`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/cs-CZ/language.json` | `json` | 2799 | tracked | Dữ liệu ngôn ngữ `cs-CZ` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/cs-CZ/upgrade.ogg` | `ogg` | 4499 | tracked | Audio prompt `upgrade` cho locale `cs-CZ`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/cs-CZ/welcome.ogg` | `ogg` | 2672 | tracked | Audio prompt `welcome` cho locale `cs-CZ`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/cs-CZ/wificonfig.ogg` | `ogg` | 5169 | tracked | Audio prompt `wificonfig` cho locale `cs-CZ`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/da-DK/0.ogg` | `ogg` | 1986 | tracked | Audio prompt `0` cho locale `da-DK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/da-DK/1.ogg` | `ogg` | 1916 | tracked | Audio prompt `1` cho locale `da-DK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/da-DK/2.ogg` | `ogg` | 2185 | tracked | Audio prompt `2` cho locale `da-DK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/da-DK/3.ogg` | `ogg` | 2178 | tracked | Audio prompt `3` cho locale `da-DK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/da-DK/4.ogg` | `ogg` | 2143 | tracked | Audio prompt `4` cho locale `da-DK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/da-DK/5.ogg` | `ogg` | 1974 | tracked | Audio prompt `5` cho locale `da-DK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/da-DK/6.ogg` | `ogg` | 1874 | tracked | Audio prompt `6` cho locale `da-DK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/da-DK/7.ogg` | `ogg` | 2125 | tracked | Audio prompt `7` cho locale `da-DK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/da-DK/8.ogg` | `ogg` | 1519 | tracked | Audio prompt `8` cho locale `da-DK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/da-DK/9.ogg` | `ogg` | 1790 | tracked | Audio prompt `9` cho locale `da-DK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/da-DK/activation.ogg` | `ogg` | 11373 | tracked | Audio prompt `activation` cho locale `da-DK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/da-DK/err_pin.ogg` | `ogg` | 3600 | tracked | Audio prompt `err_pin` cho locale `da-DK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/da-DK/err_reg.ogg` | `ogg` | 9516 | tracked | Audio prompt `err_reg` cho locale `da-DK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/da-DK/language.json` | `json` | 2736 | tracked | Dữ liệu ngôn ngữ `da-DK` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/da-DK/upgrade.ogg` | `ogg` | 3074 | tracked | Audio prompt `upgrade` cho locale `da-DK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/da-DK/welcome.ogg` | `ogg` | 2849 | tracked | Audio prompt `welcome` cho locale `da-DK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/da-DK/wificonfig.ogg` | `ogg` | 5526 | tracked | Audio prompt `wificonfig` cho locale `da-DK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/de-DE/0.ogg` | `ogg` | 1829 | tracked | Audio prompt `0` cho locale `de-DE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/de-DE/1.ogg` | `ogg` | 1801 | tracked | Audio prompt `1` cho locale `de-DE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/de-DE/2.ogg` | `ogg` | 2010 | tracked | Audio prompt `2` cho locale `de-DE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/de-DE/3.ogg` | `ogg` | 1756 | tracked | Audio prompt `3` cho locale `de-DE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/de-DE/4.ogg` | `ogg` | 1868 | tracked | Audio prompt `4` cho locale `de-DE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/de-DE/5.ogg` | `ogg` | 1979 | tracked | Audio prompt `5` cho locale `de-DE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/de-DE/6.ogg` | `ogg` | 1943 | tracked | Audio prompt `6` cho locale `de-DE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/de-DE/7.ogg` | `ogg` | 2139 | tracked | Audio prompt `7` cho locale `de-DE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/de-DE/8.ogg` | `ogg` | 1751 | tracked | Audio prompt `8` cho locale `de-DE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/de-DE/9.ogg` | `ogg` | 1835 | tracked | Audio prompt `9` cho locale `de-DE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/de-DE/activation.ogg` | `ogg` | 14512 | tracked | Audio prompt `activation` cho locale `de-DE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/de-DE/err_pin.ogg` | `ogg` | 4396 | tracked | Audio prompt `err_pin` cho locale `de-DE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/de-DE/err_reg.ogg` | `ogg` | 11221 | tracked | Audio prompt `err_reg` cho locale `de-DE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/de-DE/language.json` | `json` | 2840 | tracked | Dữ liệu ngôn ngữ `de-DE` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/de-DE/upgrade.ogg` | `ogg` | 4370 | tracked | Audio prompt `upgrade` cho locale `de-DE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/de-DE/welcome.ogg` | `ogg` | 2814 | tracked | Audio prompt `welcome` cho locale `de-DE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/de-DE/wificonfig.ogg` | `ogg` | 6587 | tracked | Audio prompt `wificonfig` cho locale `de-DE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/el-GR/0.ogg` | `ogg` | 2138 | tracked | Audio prompt `0` cho locale `el-GR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/el-GR/1.ogg` | `ogg` | 1744 | tracked | Audio prompt `1` cho locale `el-GR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/el-GR/2.ogg` | `ogg` | 2003 | tracked | Audio prompt `2` cho locale `el-GR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/el-GR/3.ogg` | `ogg` | 1767 | tracked | Audio prompt `3` cho locale `el-GR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/el-GR/4.ogg` | `ogg` | 2010 | tracked | Audio prompt `4` cho locale `el-GR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/el-GR/5.ogg` | `ogg` | 1882 | tracked | Audio prompt `5` cho locale `el-GR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/el-GR/6.ogg` | `ogg` | 1717 | tracked | Audio prompt `6` cho locale `el-GR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/el-GR/7.ogg` | `ogg` | 1795 | tracked | Audio prompt `7` cho locale `el-GR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/el-GR/8.ogg` | `ogg` | 1788 | tracked | Audio prompt `8` cho locale `el-GR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/el-GR/9.ogg` | `ogg` | 1561 | tracked | Audio prompt `9` cho locale `el-GR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/el-GR/activation.ogg` | `ogg` | 14003 | tracked | Audio prompt `activation` cho locale `el-GR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/el-GR/err_pin.ogg` | `ogg` | 4867 | tracked | Audio prompt `err_pin` cho locale `el-GR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/el-GR/err_reg.ogg` | `ogg` | 9306 | tracked | Audio prompt `err_reg` cho locale `el-GR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/el-GR/language.json` | `json` | 3691 | tracked | Dữ liệu ngôn ngữ `el-GR` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/el-GR/upgrade.ogg` | `ogg` | 4139 | tracked | Audio prompt `upgrade` cho locale `el-GR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/el-GR/welcome.ogg` | `ogg` | 2936 | tracked | Audio prompt `welcome` cho locale `el-GR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/el-GR/wificonfig.ogg` | `ogg` | 6031 | tracked | Audio prompt `wificonfig` cho locale `el-GR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/en-US/0.ogg` | `ogg` | 1924 | tracked | Audio prompt `0` cho locale `en-US`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/en-US/1.ogg` | `ogg` | 1569 | tracked | Audio prompt `1` cho locale `en-US`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/en-US/2.ogg` | `ogg` | 1532 | tracked | Audio prompt `2` cho locale `en-US`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/en-US/3.ogg` | `ogg` | 1445 | tracked | Audio prompt `3` cho locale `en-US`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/en-US/4.ogg` | `ogg` | 1944 | tracked | Audio prompt `4` cho locale `en-US`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/en-US/5.ogg` | `ogg` | 1586 | tracked | Audio prompt `5` cho locale `en-US`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/en-US/6.ogg` | `ogg` | 1764 | tracked | Audio prompt `6` cho locale `en-US`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/en-US/7.ogg` | `ogg` | 2110 | tracked | Audio prompt `7` cho locale `en-US`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/en-US/8.ogg` | `ogg` | 1571 | tracked | Audio prompt `8` cho locale `en-US`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/en-US/9.ogg` | `ogg` | 1653 | tracked | Audio prompt `9` cho locale `en-US`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/en-US/activation.ogg` | `ogg` | 8855 | tracked | Audio prompt `activation` cho locale `en-US`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/en-US/err_pin.ogg` | `ogg` | 3805 | tracked | Audio prompt `err_pin` cho locale `en-US`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/en-US/err_reg.ogg` | `ogg` | 7780 | tracked | Audio prompt `err_reg` cho locale `en-US`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/en-US/language.json` | `json` | 2606 | tracked | Dữ liệu ngôn ngữ `en-US` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/en-US/upgrade.ogg` | `ogg` | 3112 | tracked | Audio prompt `upgrade` cho locale `en-US`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/en-US/welcome.ogg` | `ogg` | 2765 | tracked | Audio prompt `welcome` cho locale `en-US`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/en-US/wificonfig.ogg` | `ogg` | 4634 | tracked | Audio prompt `wificonfig` cho locale `en-US`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/es-ES/0.ogg` | `ogg` | 1841 | tracked | Audio prompt `0` cho locale `es-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/es-ES/1.ogg` | `ogg` | 1519 | tracked | Audio prompt `1` cho locale `es-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/es-ES/2.ogg` | `ogg` | 1880 | tracked | Audio prompt `2` cho locale `es-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/es-ES/3.ogg` | `ogg` | 1747 | tracked | Audio prompt `3` cho locale `es-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/es-ES/4.ogg` | `ogg` | 1871 | tracked | Audio prompt `4` cho locale `es-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/es-ES/5.ogg` | `ogg` | 2111 | tracked | Audio prompt `5` cho locale `es-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/es-ES/6.ogg` | `ogg` | 1960 | tracked | Audio prompt `6` cho locale `es-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/es-ES/7.ogg` | `ogg` | 2157 | tracked | Audio prompt `7` cho locale `es-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/es-ES/8.ogg` | `ogg` | 1863 | tracked | Audio prompt `8` cho locale `es-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/es-ES/9.ogg` | `ogg` | 2020 | tracked | Audio prompt `9` cho locale `es-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/es-ES/activation.ogg` | `ogg` | 14758 | tracked | Audio prompt `activation` cho locale `es-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/es-ES/err_pin.ogg` | `ogg` | 5458 | tracked | Audio prompt `err_pin` cho locale `es-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/es-ES/err_reg.ogg` | `ogg` | 10160 | tracked | Audio prompt `err_reg` cho locale `es-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/es-ES/language.json` | `json` | 2835 | tracked | Dữ liệu ngôn ngữ `es-ES` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/es-ES/upgrade.ogg` | `ogg` | 3947 | tracked | Audio prompt `upgrade` cho locale `es-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/es-ES/welcome.ogg` | `ogg` | 2909 | tracked | Audio prompt `welcome` cho locale `es-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/es-ES/wificonfig.ogg` | `ogg` | 6979 | tracked | Audio prompt `wificonfig` cho locale `es-ES`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fa-IR/0.ogg` | `ogg` | 1975 | tracked | Audio prompt `0` cho locale `fa-IR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fa-IR/1.ogg` | `ogg` | 2234 | tracked | Audio prompt `1` cho locale `fa-IR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fa-IR/2.ogg` | `ogg` | 1626 | tracked | Audio prompt `2` cho locale `fa-IR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fa-IR/3.ogg` | `ogg` | 1792 | tracked | Audio prompt `3` cho locale `fa-IR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fa-IR/4.ogg` | `ogg` | 2043 | tracked | Audio prompt `4` cho locale `fa-IR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fa-IR/5.ogg` | `ogg` | 3109 | tracked | Audio prompt `5` cho locale `fa-IR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fa-IR/6.ogg` | `ogg` | 1909 | tracked | Audio prompt `6` cho locale `fa-IR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fa-IR/7.ogg` | `ogg` | 2461 | tracked | Audio prompt `7` cho locale `fa-IR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fa-IR/8.ogg` | `ogg` | 2679 | tracked | Audio prompt `8` cho locale `fa-IR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fa-IR/9.ogg` | `ogg` | 2393 | tracked | Audio prompt `9` cho locale `fa-IR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fa-IR/activation.ogg` | `ogg` | 12991 | tracked | Audio prompt `activation` cho locale `fa-IR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fa-IR/err_pin.ogg` | `ogg` | 4750 | tracked | Audio prompt `err_pin` cho locale `fa-IR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fa-IR/err_reg.ogg` | `ogg` | 11655 | tracked | Audio prompt `err_reg` cho locale `fa-IR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fa-IR/language.json` | `json` | 3379 | tracked | Dữ liệu ngôn ngữ `fa-IR` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/fa-IR/upgrade.ogg` | `ogg` | 3495 | tracked | Audio prompt `upgrade` cho locale `fa-IR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fa-IR/welcome.ogg` | `ogg` | 3309 | tracked | Audio prompt `welcome` cho locale `fa-IR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fa-IR/wificonfig.ogg` | `ogg` | 4700 | tracked | Audio prompt `wificonfig` cho locale `fa-IR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fi-FI/0.ogg` | `ogg` | 2108 | tracked | Audio prompt `0` cho locale `fi-FI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fi-FI/1.ogg` | `ogg` | 2169 | tracked | Audio prompt `1` cho locale `fi-FI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fi-FI/2.ogg` | `ogg` | 2158 | tracked | Audio prompt `2` cho locale `fi-FI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fi-FI/3.ogg` | `ogg` | 2159 | tracked | Audio prompt `3` cho locale `fi-FI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fi-FI/4.ogg` | `ogg` | 2233 | tracked | Audio prompt `4` cho locale `fi-FI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fi-FI/5.ogg` | `ogg` | 2147 | tracked | Audio prompt `5` cho locale `fi-FI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fi-FI/6.ogg` | `ogg` | 2133 | tracked | Audio prompt `6` cho locale `fi-FI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fi-FI/7.ogg` | `ogg` | 2468 | tracked | Audio prompt `7` cho locale `fi-FI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fi-FI/8.ogg` | `ogg` | 2240 | tracked | Audio prompt `8` cho locale `fi-FI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fi-FI/9.ogg` | `ogg` | 2328 | tracked | Audio prompt `9` cho locale `fi-FI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fi-FI/activation.ogg` | `ogg` | 10121 | tracked | Audio prompt `activation` cho locale `fi-FI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fi-FI/err_pin.ogg` | `ogg` | 3567 | tracked | Audio prompt `err_pin` cho locale `fi-FI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fi-FI/err_reg.ogg` | `ogg` | 8709 | tracked | Audio prompt `err_reg` cho locale `fi-FI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fi-FI/language.json` | `json` | 2848 | tracked | Dữ liệu ngôn ngữ `fi-FI` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/fi-FI/upgrade.ogg` | `ogg` | 4239 | tracked | Audio prompt `upgrade` cho locale `fi-FI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fi-FI/welcome.ogg` | `ogg` | 2828 | tracked | Audio prompt `welcome` cho locale `fi-FI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fi-FI/wificonfig.ogg` | `ogg` | 5423 | tracked | Audio prompt `wificonfig` cho locale `fi-FI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fil-PH/0.ogg` | `ogg` | 1571 | tracked | Audio prompt `0` cho locale `fil-PH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fil-PH/1.ogg` | `ogg` | 1537 | tracked | Audio prompt `1` cho locale `fil-PH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fil-PH/2.ogg` | `ogg` | 1628 | tracked | Audio prompt `2` cho locale `fil-PH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fil-PH/3.ogg` | `ogg` | 1514 | tracked | Audio prompt `3` cho locale `fil-PH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fil-PH/4.ogg` | `ogg` | 1395 | tracked | Audio prompt `4` cho locale `fil-PH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fil-PH/5.ogg` | `ogg` | 1497 | tracked | Audio prompt `5` cho locale `fil-PH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fil-PH/6.ogg` | `ogg` | 1480 | tracked | Audio prompt `6` cho locale `fil-PH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fil-PH/7.ogg` | `ogg` | 1527 | tracked | Audio prompt `7` cho locale `fil-PH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fil-PH/8.ogg` | `ogg` | 1647 | tracked | Audio prompt `8` cho locale `fil-PH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fil-PH/9.ogg` | `ogg` | 1604 | tracked | Audio prompt `9` cho locale `fil-PH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fil-PH/activation.ogg` | `ogg` | 12289 | tracked | Audio prompt `activation` cho locale `fil-PH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fil-PH/err_pin.ogg` | `ogg` | 4032 | tracked | Audio prompt `err_pin` cho locale `fil-PH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fil-PH/err_reg.ogg` | `ogg` | 7125 | tracked | Audio prompt `err_reg` cho locale `fil-PH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fil-PH/language.json` | `json` | 2859 | tracked | Dữ liệu ngôn ngữ `fil-PH` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/fil-PH/upgrade.ogg` | `ogg` | 3478 | tracked | Audio prompt `upgrade` cho locale `fil-PH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fil-PH/welcome.ogg` | `ogg` | 3754 | tracked | Audio prompt `welcome` cho locale `fil-PH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fil-PH/wificonfig.ogg` | `ogg` | 6006 | tracked | Audio prompt `wificonfig` cho locale `fil-PH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fr-FR/0.ogg` | `ogg` | 2291 | tracked | Audio prompt `0` cho locale `fr-FR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fr-FR/1.ogg` | `ogg` | 2472 | tracked | Audio prompt `1` cho locale `fr-FR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fr-FR/2.ogg` | `ogg` | 2555 | tracked | Audio prompt `2` cho locale `fr-FR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fr-FR/3.ogg` | `ogg` | 2243 | tracked | Audio prompt `3` cho locale `fr-FR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fr-FR/4.ogg` | `ogg` | 2326 | tracked | Audio prompt `4` cho locale `fr-FR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fr-FR/5.ogg` | `ogg` | 2558 | tracked | Audio prompt `5` cho locale `fr-FR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fr-FR/6.ogg` | `ogg` | 2377 | tracked | Audio prompt `6` cho locale `fr-FR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fr-FR/7.ogg` | `ogg` | 2321 | tracked | Audio prompt `7` cho locale `fr-FR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fr-FR/8.ogg` | `ogg` | 2362 | tracked | Audio prompt `8` cho locale `fr-FR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fr-FR/9.ogg` | `ogg` | 2100 | tracked | Audio prompt `9` cho locale `fr-FR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fr-FR/activation.ogg` | `ogg` | 17207 | tracked | Audio prompt `activation` cho locale `fr-FR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fr-FR/err_pin.ogg` | `ogg` | 6043 | tracked | Audio prompt `err_pin` cho locale `fr-FR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fr-FR/err_reg.ogg` | `ogg` | 9869 | tracked | Audio prompt `err_reg` cho locale `fr-FR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fr-FR/language.json` | `json` | 2953 | tracked | Dữ liệu ngôn ngữ `fr-FR` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/fr-FR/upgrade.ogg` | `ogg` | 3757 | tracked | Audio prompt `upgrade` cho locale `fr-FR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fr-FR/welcome.ogg` | `ogg` | 2927 | tracked | Audio prompt `welcome` cho locale `fr-FR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/fr-FR/wificonfig.ogg` | `ogg` | 5157 | tracked | Audio prompt `wificonfig` cho locale `fr-FR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/he-IL/0.ogg` | `ogg` | 1753 | tracked | Audio prompt `0` cho locale `he-IL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/he-IL/1.ogg` | `ogg` | 1921 | tracked | Audio prompt `1` cho locale `he-IL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/he-IL/2.ogg` | `ogg` | 2000 | tracked | Audio prompt `2` cho locale `he-IL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/he-IL/3.ogg` | `ogg` | 1970 | tracked | Audio prompt `3` cho locale `he-IL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/he-IL/4.ogg` | `ogg` | 2095 | tracked | Audio prompt `4` cho locale `he-IL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/he-IL/5.ogg` | `ogg` | 2220 | tracked | Audio prompt `5` cho locale `he-IL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/he-IL/6.ogg` | `ogg` | 3459 | tracked | Audio prompt `6` cho locale `he-IL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/he-IL/7.ogg` | `ogg` | 2222 | tracked | Audio prompt `7` cho locale `he-IL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/he-IL/8.ogg` | `ogg` | 3889 | tracked | Audio prompt `8` cho locale `he-IL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/he-IL/9.ogg` | `ogg` | 3396 | tracked | Audio prompt `9` cho locale `he-IL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/he-IL/activation.ogg` | `ogg` | 8528 | tracked | Audio prompt `activation` cho locale `he-IL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/he-IL/err_pin.ogg` | `ogg` | 5032 | tracked | Audio prompt `err_pin` cho locale `he-IL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/he-IL/err_reg.ogg` | `ogg` | 7378 | tracked | Audio prompt `err_reg` cho locale `he-IL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/he-IL/language.json` | `json` | 2951 | tracked | Dữ liệu ngôn ngữ `he-IL` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/he-IL/upgrade.ogg` | `ogg` | 3648 | tracked | Audio prompt `upgrade` cho locale `he-IL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/he-IL/welcome.ogg` | `ogg` | 3037 | tracked | Audio prompt `welcome` cho locale `he-IL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/he-IL/wificonfig.ogg` | `ogg` | 4292 | tracked | Audio prompt `wificonfig` cho locale `he-IL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hi-IN/0.ogg` | `ogg` | 2313 | tracked | Audio prompt `0` cho locale `hi-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hi-IN/1.ogg` | `ogg` | 1490 | tracked | Audio prompt `1` cho locale `hi-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hi-IN/2.ogg` | `ogg` | 1609 | tracked | Audio prompt `2` cho locale `hi-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hi-IN/3.ogg` | `ogg` | 1530 | tracked | Audio prompt `3` cho locale `hi-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hi-IN/4.ogg` | `ogg` | 1530 | tracked | Audio prompt `4` cho locale `hi-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hi-IN/5.ogg` | `ogg` | 1837 | tracked | Audio prompt `5` cho locale `hi-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hi-IN/6.ogg` | `ogg` | 1503 | tracked | Audio prompt `6` cho locale `hi-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hi-IN/7.ogg` | `ogg` | 1803 | tracked | Audio prompt `7` cho locale `hi-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hi-IN/8.ogg` | `ogg` | 1590 | tracked | Audio prompt `8` cho locale `hi-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hi-IN/9.ogg` | `ogg` | 1550 | tracked | Audio prompt `9` cho locale `hi-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hi-IN/activation.ogg` | `ogg` | 10626 | tracked | Audio prompt `activation` cho locale `hi-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hi-IN/err_pin.ogg` | `ogg` | 2949 | tracked | Audio prompt `err_pin` cho locale `hi-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hi-IN/err_reg.ogg` | `ogg` | 7548 | tracked | Audio prompt `err_reg` cho locale `hi-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hi-IN/language.json` | `json` | 4411 | tracked | Dữ liệu ngôn ngữ `hi-IN` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/hi-IN/upgrade.ogg` | `ogg` | 3315 | tracked | Audio prompt `upgrade` cho locale `hi-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hi-IN/welcome.ogg` | `ogg` | 2582 | tracked | Audio prompt `welcome` cho locale `hi-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hi-IN/wificonfig.ogg` | `ogg` | 4698 | tracked | Audio prompt `wificonfig` cho locale `hi-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hr-HR/0.ogg` | `ogg` | 2514 | tracked | Audio prompt `0` cho locale `hr-HR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hr-HR/1.ogg` | `ogg` | 2662 | tracked | Audio prompt `1` cho locale `hr-HR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hr-HR/2.ogg` | `ogg` | 2174 | tracked | Audio prompt `2` cho locale `hr-HR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hr-HR/3.ogg` | `ogg` | 3902 | tracked | Audio prompt `3` cho locale `hr-HR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hr-HR/4.ogg` | `ogg` | 1876 | tracked | Audio prompt `4` cho locale `hr-HR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hr-HR/5.ogg` | `ogg` | 1996 | tracked | Audio prompt `5` cho locale `hr-HR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hr-HR/6.ogg` | `ogg` | 2249 | tracked | Audio prompt `6` cho locale `hr-HR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hr-HR/7.ogg` | `ogg` | 2586 | tracked | Audio prompt `7` cho locale `hr-HR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hr-HR/8.ogg` | `ogg` | 2509 | tracked | Audio prompt `8` cho locale `hr-HR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hr-HR/9.ogg` | `ogg` | 2187 | tracked | Audio prompt `9` cho locale `hr-HR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hr-HR/activation.ogg` | `ogg` | 14451 | tracked | Audio prompt `activation` cho locale `hr-HR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hr-HR/err_pin.ogg` | `ogg` | 7108 | tracked | Audio prompt `err_pin` cho locale `hr-HR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hr-HR/err_reg.ogg` | `ogg` | 13477 | tracked | Audio prompt `err_reg` cho locale `hr-HR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hr-HR/language.json` | `json` | 2822 | tracked | Dữ liệu ngôn ngữ `hr-HR` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/hr-HR/upgrade.ogg` | `ogg` | 4241 | tracked | Audio prompt `upgrade` cho locale `hr-HR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hr-HR/welcome.ogg` | `ogg` | 5092 | tracked | Audio prompt `welcome` cho locale `hr-HR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hr-HR/wificonfig.ogg` | `ogg` | 6223 | tracked | Audio prompt `wificonfig` cho locale `hr-HR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hu-HU/0.ogg` | `ogg` | 1582 | tracked | Audio prompt `0` cho locale `hu-HU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hu-HU/1.ogg` | `ogg` | 1963 | tracked | Audio prompt `1` cho locale `hu-HU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hu-HU/2.ogg` | `ogg` | 2418 | tracked | Audio prompt `2` cho locale `hu-HU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hu-HU/3.ogg` | `ogg` | 1966 | tracked | Audio prompt `3` cho locale `hu-HU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hu-HU/4.ogg` | `ogg` | 2161 | tracked | Audio prompt `4` cho locale `hu-HU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hu-HU/5.ogg` | `ogg` | 2173 | tracked | Audio prompt `5` cho locale `hu-HU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hu-HU/6.ogg` | `ogg` | 2251 | tracked | Audio prompt `6` cho locale `hu-HU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hu-HU/7.ogg` | `ogg` | 1531 | tracked | Audio prompt `7` cho locale `hu-HU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hu-HU/8.ogg` | `ogg` | 2119 | tracked | Audio prompt `8` cho locale `hu-HU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hu-HU/9.ogg` | `ogg` | 2049 | tracked | Audio prompt `9` cho locale `hu-HU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hu-HU/activation.ogg` | `ogg` | 15641 | tracked | Audio prompt `activation` cho locale `hu-HU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hu-HU/err_pin.ogg` | `ogg` | 6545 | tracked | Audio prompt `err_pin` cho locale `hu-HU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hu-HU/err_reg.ogg` | `ogg` | 10408 | tracked | Audio prompt `err_reg` cho locale `hu-HU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hu-HU/language.json` | `json` | 2952 | tracked | Dữ liệu ngôn ngữ `hu-HU` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/hu-HU/upgrade.ogg` | `ogg` | 3811 | tracked | Audio prompt `upgrade` cho locale `hu-HU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hu-HU/welcome.ogg` | `ogg` | 3060 | tracked | Audio prompt `welcome` cho locale `hu-HU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/hu-HU/wificonfig.ogg` | `ogg` | 5701 | tracked | Audio prompt `wificonfig` cho locale `hu-HU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/id-ID/0.ogg` | `ogg` | 2025 | tracked | Audio prompt `0` cho locale `id-ID`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/id-ID/1.ogg` | `ogg` | 2633 | tracked | Audio prompt `1` cho locale `id-ID`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/id-ID/2.ogg` | `ogg` | 2273 | tracked | Audio prompt `2` cho locale `id-ID`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/id-ID/3.ogg` | `ogg` | 2252 | tracked | Audio prompt `3` cho locale `id-ID`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/id-ID/4.ogg` | `ogg` | 1806 | tracked | Audio prompt `4` cho locale `id-ID`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/id-ID/5.ogg` | `ogg` | 2342 | tracked | Audio prompt `5` cho locale `id-ID`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/id-ID/6.ogg` | `ogg` | 2178 | tracked | Audio prompt `6` cho locale `id-ID`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/id-ID/7.ogg` | `ogg` | 2101 | tracked | Audio prompt `7` cho locale `id-ID`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/id-ID/8.ogg` | `ogg` | 2409 | tracked | Audio prompt `8` cho locale `id-ID`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/id-ID/9.ogg` | `ogg` | 2484 | tracked | Audio prompt `9` cho locale `id-ID`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/id-ID/activation.ogg` | `ogg` | 17124 | tracked | Audio prompt `activation` cho locale `id-ID`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/id-ID/err_pin.ogg` | `ogg` | 5087 | tracked | Audio prompt `err_pin` cho locale `id-ID`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/id-ID/err_reg.ogg` | `ogg` | 7716 | tracked | Audio prompt `err_reg` cho locale `id-ID`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/id-ID/language.json` | `json` | 2684 | tracked | Dữ liệu ngôn ngữ `id-ID` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/id-ID/upgrade.ogg` | `ogg` | 3823 | tracked | Audio prompt `upgrade` cho locale `id-ID`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/id-ID/welcome.ogg` | `ogg` | 2537 | tracked | Audio prompt `welcome` cho locale `id-ID`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/id-ID/wificonfig.ogg` | `ogg` | 8706 | tracked | Audio prompt `wificonfig` cho locale `id-ID`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/it-IT/0.ogg` | `ogg` | 1877 | tracked | Audio prompt `0` cho locale `it-IT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/it-IT/1.ogg` | `ogg` | 1423 | tracked | Audio prompt `1` cho locale `it-IT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/it-IT/2.ogg` | `ogg` | 1436 | tracked | Audio prompt `2` cho locale `it-IT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/it-IT/3.ogg` | `ogg` | 1302 | tracked | Audio prompt `3` cho locale `it-IT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/it-IT/4.ogg` | `ogg` | 1404 | tracked | Audio prompt `4` cho locale `it-IT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/it-IT/5.ogg` | `ogg` | 1607 | tracked | Audio prompt `5` cho locale `it-IT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/it-IT/6.ogg` | `ogg` | 1457 | tracked | Audio prompt `6` cho locale `it-IT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/it-IT/7.ogg` | `ogg` | 1632 | tracked | Audio prompt `7` cho locale `it-IT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/it-IT/8.ogg` | `ogg` | 1494 | tracked | Audio prompt `8` cho locale `it-IT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/it-IT/9.ogg` | `ogg` | 1888 | tracked | Audio prompt `9` cho locale `it-IT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/it-IT/activation.ogg` | `ogg` | 12274 | tracked | Audio prompt `activation` cho locale `it-IT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/it-IT/err_pin.ogg` | `ogg` | 3023 | tracked | Audio prompt `err_pin` cho locale `it-IT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/it-IT/err_reg.ogg` | `ogg` | 8416 | tracked | Audio prompt `err_reg` cho locale `it-IT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/it-IT/language.json` | `json` | 2803 | tracked | Dữ liệu ngôn ngữ `it-IT` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/it-IT/upgrade.ogg` | `ogg` | 4059 | tracked | Audio prompt `upgrade` cho locale `it-IT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/it-IT/welcome.ogg` | `ogg` | 3063 | tracked | Audio prompt `welcome` cho locale `it-IT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/it-IT/wificonfig.ogg` | `ogg` | 5995 | tracked | Audio prompt `wificonfig` cho locale `it-IT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ja-JP/0.ogg` | `ogg` | 1499 | tracked | Audio prompt `0` cho locale `ja-JP`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ja-JP/1.ogg` | `ogg` | 1459 | tracked | Audio prompt `1` cho locale `ja-JP`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ja-JP/2.ogg` | `ogg` | 1203 | tracked | Audio prompt `2` cho locale `ja-JP`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ja-JP/3.ogg` | `ogg` | 1312 | tracked | Audio prompt `3` cho locale `ja-JP`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ja-JP/4.ogg` | `ogg` | 1372 | tracked | Audio prompt `4` cho locale `ja-JP`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ja-JP/5.ogg` | `ogg` | 1085 | tracked | Audio prompt `5` cho locale `ja-JP`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ja-JP/6.ogg` | `ogg` | 1482 | tracked | Audio prompt `6` cho locale `ja-JP`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ja-JP/7.ogg` | `ogg` | 1503 | tracked | Audio prompt `7` cho locale `ja-JP`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ja-JP/8.ogg` | `ogg` | 1663 | tracked | Audio prompt `8` cho locale `ja-JP`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ja-JP/9.ogg` | `ogg` | 1565 | tracked | Audio prompt `9` cho locale `ja-JP`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ja-JP/activation.ogg` | `ogg` | 12162 | tracked | Audio prompt `activation` cho locale `ja-JP`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ja-JP/err_pin.ogg` | `ogg` | 4547 | tracked | Audio prompt `err_pin` cho locale `ja-JP`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ja-JP/err_reg.ogg` | `ogg` | 10168 | tracked | Audio prompt `err_reg` cho locale `ja-JP`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ja-JP/language.json` | `json` | 3308 | tracked | Dữ liệu ngôn ngữ `ja-JP` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/ja-JP/upgrade.ogg` | `ogg` | 4754 | tracked | Audio prompt `upgrade` cho locale `ja-JP`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ja-JP/welcome.ogg` | `ogg` | 3403 | tracked | Audio prompt `welcome` cho locale `ja-JP`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ja-JP/wificonfig.ogg` | `ogg` | 6770 | tracked | Audio prompt `wificonfig` cho locale `ja-JP`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ko-KR/0.ogg` | `ogg` | 1696 | tracked | Audio prompt `0` cho locale `ko-KR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ko-KR/1.ogg` | `ogg` | 1687 | tracked | Audio prompt `1` cho locale `ko-KR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ko-KR/2.ogg` | `ogg` | 1475 | tracked | Audio prompt `2` cho locale `ko-KR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ko-KR/3.ogg` | `ogg` | 1588 | tracked | Audio prompt `3` cho locale `ko-KR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ko-KR/4.ogg` | `ogg` | 1426 | tracked | Audio prompt `4` cho locale `ko-KR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ko-KR/5.ogg` | `ogg` | 1490 | tracked | Audio prompt `5` cho locale `ko-KR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ko-KR/6.ogg` | `ogg` | 1516 | tracked | Audio prompt `6` cho locale `ko-KR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ko-KR/7.ogg` | `ogg` | 1734 | tracked | Audio prompt `7` cho locale `ko-KR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ko-KR/8.ogg` | `ogg` | 1454 | tracked | Audio prompt `8` cho locale `ko-KR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ko-KR/9.ogg` | `ogg` | 2430 | tracked | Audio prompt `9` cho locale `ko-KR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ko-KR/activation.ogg` | `ogg` | 11193 | tracked | Audio prompt `activation` cho locale `ko-KR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ko-KR/err_pin.ogg` | `ogg` | 4725 | tracked | Audio prompt `err_pin` cho locale `ko-KR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ko-KR/err_reg.ogg` | `ogg` | 10954 | tracked | Audio prompt `err_reg` cho locale `ko-KR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ko-KR/language.json` | `json` | 2871 | tracked | Dữ liệu ngôn ngữ `ko-KR` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/ko-KR/upgrade.ogg` | `ogg` | 5335 | tracked | Audio prompt `upgrade` cho locale `ko-KR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ko-KR/welcome.ogg` | `ogg` | 4566 | tracked | Audio prompt `welcome` cho locale `ko-KR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ko-KR/wificonfig.ogg` | `ogg` | 6474 | tracked | Audio prompt `wificonfig` cho locale `ko-KR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/mr-IN/0.ogg` | `ogg` | 14637 | tracked | Audio prompt `0` cho locale `mr-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/mr-IN/1.ogg` | `ogg` | 15271 | tracked | Audio prompt `1` cho locale `mr-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/mr-IN/2.ogg` | `ogg` | 14297 | tracked | Audio prompt `2` cho locale `mr-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/mr-IN/3.ogg` | `ogg` | 14099 | tracked | Audio prompt `3` cho locale `mr-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/mr-IN/4.ogg` | `ogg` | 14561 | tracked | Audio prompt `4` cho locale `mr-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/mr-IN/5.ogg` | `ogg` | 14540 | tracked | Audio prompt `5` cho locale `mr-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/mr-IN/6.ogg` | `ogg` | 14128 | tracked | Audio prompt `6` cho locale `mr-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/mr-IN/7.ogg` | `ogg` | 14317 | tracked | Audio prompt `7` cho locale `mr-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/mr-IN/8.ogg` | `ogg` | 14707 | tracked | Audio prompt `8` cho locale `mr-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/mr-IN/9.ogg` | `ogg` | 13983 | tracked | Audio prompt `9` cho locale `mr-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/mr-IN/activation.ogg` | `ogg` | 53176 | tracked | Audio prompt `activation` cho locale `mr-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/mr-IN/err_pin.ogg` | `ogg` | 19921 | tracked | Audio prompt `err_pin` cho locale `mr-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/mr-IN/err_reg.ogg` | `ogg` | 54375 | tracked | Audio prompt `err_reg` cho locale `mr-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/mr-IN/language.json` | `json` | 4383 | tracked | Dữ liệu ngôn ngữ `mr-IN` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/mr-IN/upgrade.ogg` | `ogg` | 36391 | tracked | Audio prompt `upgrade` cho locale `mr-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/mr-IN/welcome.ogg` | `ogg` | 21895 | tracked | Audio prompt `welcome` cho locale `mr-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/mr-IN/wificonfig.ogg` | `ogg` | 58140 | tracked | Audio prompt `wificonfig` cho locale `mr-IN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ms-MY/0.ogg` | `ogg` | 2176 | tracked | Audio prompt `0` cho locale `ms-MY`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ms-MY/1.ogg` | `ogg` | 1639 | tracked | Audio prompt `1` cho locale `ms-MY`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ms-MY/2.ogg` | `ogg` | 2159 | tracked | Audio prompt `2` cho locale `ms-MY`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ms-MY/3.ogg` | `ogg` | 1571 | tracked | Audio prompt `3` cho locale `ms-MY`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ms-MY/4.ogg` | `ogg` | 1680 | tracked | Audio prompt `4` cho locale `ms-MY`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ms-MY/5.ogg` | `ogg` | 1565 | tracked | Audio prompt `5` cho locale `ms-MY`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ms-MY/6.ogg` | `ogg` | 1661 | tracked | Audio prompt `6` cho locale `ms-MY`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ms-MY/7.ogg` | `ogg` | 1486 | tracked | Audio prompt `7` cho locale `ms-MY`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ms-MY/8.ogg` | `ogg` | 2181 | tracked | Audio prompt `8` cho locale `ms-MY`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ms-MY/9.ogg` | `ogg` | 2479 | tracked | Audio prompt `9` cho locale `ms-MY`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ms-MY/activation.ogg` | `ogg` | 12883 | tracked | Audio prompt `activation` cho locale `ms-MY`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ms-MY/err_pin.ogg` | `ogg` | 4105 | tracked | Audio prompt `err_pin` cho locale `ms-MY`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ms-MY/err_reg.ogg` | `ogg` | 10706 | tracked | Audio prompt `err_reg` cho locale `ms-MY`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ms-MY/language.json` | `json` | 2690 | tracked | Dữ liệu ngôn ngữ `ms-MY` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/ms-MY/upgrade.ogg` | `ogg` | 4065 | tracked | Audio prompt `upgrade` cho locale `ms-MY`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ms-MY/welcome.ogg` | `ogg` | 5732 | tracked | Audio prompt `welcome` cho locale `ms-MY`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ms-MY/wificonfig.ogg` | `ogg` | 5042 | tracked | Audio prompt `wificonfig` cho locale `ms-MY`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nb-NO/0.ogg` | `ogg` | 1541 | tracked | Audio prompt `0` cho locale `nb-NO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nb-NO/1.ogg` | `ogg` | 1448 | tracked | Audio prompt `1` cho locale `nb-NO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nb-NO/2.ogg` | `ogg` | 2024 | tracked | Audio prompt `2` cho locale `nb-NO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nb-NO/3.ogg` | `ogg` | 1767 | tracked | Audio prompt `3` cho locale `nb-NO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nb-NO/4.ogg` | `ogg` | 1898 | tracked | Audio prompt `4` cho locale `nb-NO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nb-NO/5.ogg` | `ogg` | 1778 | tracked | Audio prompt `5` cho locale `nb-NO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nb-NO/6.ogg` | `ogg` | 1997 | tracked | Audio prompt `6` cho locale `nb-NO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nb-NO/7.ogg` | `ogg` | 1647 | tracked | Audio prompt `7` cho locale `nb-NO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nb-NO/8.ogg` | `ogg` | 1507 | tracked | Audio prompt `8` cho locale `nb-NO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nb-NO/9.ogg` | `ogg` | 1782 | tracked | Audio prompt `9` cho locale `nb-NO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nb-NO/activation.ogg` | `ogg` | 12110 | tracked | Audio prompt `activation` cho locale `nb-NO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nb-NO/err_pin.ogg` | `ogg` | 4175 | tracked | Audio prompt `err_pin` cho locale `nb-NO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nb-NO/err_reg.ogg` | `ogg` | 8992 | tracked | Audio prompt `err_reg` cho locale `nb-NO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nb-NO/language.json` | `json` | 2692 | tracked | Dữ liệu ngôn ngữ `nb-NO` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/nb-NO/upgrade.ogg` | `ogg` | 3155 | tracked | Audio prompt `upgrade` cho locale `nb-NO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nb-NO/welcome.ogg` | `ogg` | 2512 | tracked | Audio prompt `welcome` cho locale `nb-NO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nb-NO/wificonfig.ogg` | `ogg` | 6131 | tracked | Audio prompt `wificonfig` cho locale `nb-NO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nl-NL/0.ogg` | `ogg` | 1859 | tracked | Audio prompt `0` cho locale `nl-NL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nl-NL/1.ogg` | `ogg` | 1553 | tracked | Audio prompt `1` cho locale `nl-NL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nl-NL/2.ogg` | `ogg` | 1712 | tracked | Audio prompt `2` cho locale `nl-NL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nl-NL/3.ogg` | `ogg` | 1547 | tracked | Audio prompt `3` cho locale `nl-NL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nl-NL/4.ogg` | `ogg` | 1885 | tracked | Audio prompt `4` cho locale `nl-NL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nl-NL/5.ogg` | `ogg` | 2010 | tracked | Audio prompt `5` cho locale `nl-NL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nl-NL/6.ogg` | `ogg` | 1872 | tracked | Audio prompt `6` cho locale `nl-NL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nl-NL/7.ogg` | `ogg` | 1981 | tracked | Audio prompt `7` cho locale `nl-NL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nl-NL/8.ogg` | `ogg` | 1787 | tracked | Audio prompt `8` cho locale `nl-NL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nl-NL/9.ogg` | `ogg` | 2154 | tracked | Audio prompt `9` cho locale `nl-NL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nl-NL/activation.ogg` | `ogg` | 13132 | tracked | Audio prompt `activation` cho locale `nl-NL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nl-NL/err_pin.ogg` | `ogg` | 3190 | tracked | Audio prompt `err_pin` cho locale `nl-NL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nl-NL/err_reg.ogg` | `ogg` | 10114 | tracked | Audio prompt `err_reg` cho locale `nl-NL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nl-NL/language.json` | `json` | 2731 | tracked | Dữ liệu ngôn ngữ `nl-NL` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/nl-NL/upgrade.ogg` | `ogg` | 3529 | tracked | Audio prompt `upgrade` cho locale `nl-NL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nl-NL/welcome.ogg` | `ogg` | 2917 | tracked | Audio prompt `welcome` cho locale `nl-NL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/nl-NL/wificonfig.ogg` | `ogg` | 5759 | tracked | Audio prompt `wificonfig` cho locale `nl-NL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pl-PL/0.ogg` | `ogg` | 2138 | tracked | Audio prompt `0` cho locale `pl-PL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pl-PL/1.ogg` | `ogg` | 2152 | tracked | Audio prompt `1` cho locale `pl-PL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pl-PL/2.ogg` | `ogg` | 1762 | tracked | Audio prompt `2` cho locale `pl-PL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pl-PL/3.ogg` | `ogg` | 1821 | tracked | Audio prompt `3` cho locale `pl-PL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pl-PL/4.ogg` | `ogg` | 1883 | tracked | Audio prompt `4` cho locale `pl-PL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pl-PL/5.ogg` | `ogg` | 2067 | tracked | Audio prompt `5` cho locale `pl-PL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pl-PL/6.ogg` | `ogg` | 2430 | tracked | Audio prompt `6` cho locale `pl-PL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pl-PL/7.ogg` | `ogg` | 2142 | tracked | Audio prompt `7` cho locale `pl-PL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pl-PL/8.ogg` | `ogg` | 1963 | tracked | Audio prompt `8` cho locale `pl-PL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pl-PL/9.ogg` | `ogg` | 2386 | tracked | Audio prompt `9` cho locale `pl-PL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pl-PL/activation.ogg` | `ogg` | 10689 | tracked | Audio prompt `activation` cho locale `pl-PL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pl-PL/err_pin.ogg` | `ogg` | 4294 | tracked | Audio prompt `err_pin` cho locale `pl-PL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pl-PL/err_reg.ogg` | `ogg` | 7341 | tracked | Audio prompt `err_reg` cho locale `pl-PL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pl-PL/language.json` | `json` | 2940 | tracked | Dữ liệu ngôn ngữ `pl-PL` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/pl-PL/upgrade.ogg` | `ogg` | 3937 | tracked | Audio prompt `upgrade` cho locale `pl-PL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pl-PL/welcome.ogg` | `ogg` | 3562 | tracked | Audio prompt `welcome` cho locale `pl-PL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pl-PL/wificonfig.ogg` | `ogg` | 4551 | tracked | Audio prompt `wificonfig` cho locale `pl-PL`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-BR/0.ogg` | `ogg` | 1977 | tracked | Audio prompt `0` cho locale `pt-BR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-BR/1.ogg` | `ogg` | 1496 | tracked | Audio prompt `1` cho locale `pt-BR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-BR/2.ogg` | `ogg` | 1876 | tracked | Audio prompt `2` cho locale `pt-BR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-BR/3.ogg` | `ogg` | 2119 | tracked | Audio prompt `3` cho locale `pt-BR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-BR/4.ogg` | `ogg` | 1843 | tracked | Audio prompt `4` cho locale `pt-BR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-BR/5.ogg` | `ogg` | 2197 | tracked | Audio prompt `5` cho locale `pt-BR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-BR/6.ogg` | `ogg` | 1886 | tracked | Audio prompt `6` cho locale `pt-BR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-BR/7.ogg` | `ogg` | 2094 | tracked | Audio prompt `7` cho locale `pt-BR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-BR/8.ogg` | `ogg` | 1973 | tracked | Audio prompt `8` cho locale `pt-BR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-BR/9.ogg` | `ogg` | 1809 | tracked | Audio prompt `9` cho locale `pt-BR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-BR/activation.ogg` | `ogg` | 14660 | tracked | Audio prompt `activation` cho locale `pt-BR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-BR/err_pin.ogg` | `ogg` | 3457 | tracked | Audio prompt `err_pin` cho locale `pt-BR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-BR/err_reg.ogg` | `ogg` | 8363 | tracked | Audio prompt `err_reg` cho locale `pt-BR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-BR/language.json` | `json` | 2790 | tracked | Dữ liệu ngôn ngữ `pt-BR` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/pt-BR/upgrade.ogg` | `ogg` | 4051 | tracked | Audio prompt `upgrade` cho locale `pt-BR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-BR/welcome.ogg` | `ogg` | 3053 | tracked | Audio prompt `welcome` cho locale `pt-BR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-BR/wificonfig.ogg` | `ogg` | 5471 | tracked | Audio prompt `wificonfig` cho locale `pt-BR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-PT/0.ogg` | `ogg` | 1977 | tracked | Audio prompt `0` cho locale `pt-PT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-PT/1.ogg` | `ogg` | 1496 | tracked | Audio prompt `1` cho locale `pt-PT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-PT/2.ogg` | `ogg` | 1876 | tracked | Audio prompt `2` cho locale `pt-PT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-PT/3.ogg` | `ogg` | 2119 | tracked | Audio prompt `3` cho locale `pt-PT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-PT/4.ogg` | `ogg` | 1843 | tracked | Audio prompt `4` cho locale `pt-PT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-PT/5.ogg` | `ogg` | 2197 | tracked | Audio prompt `5` cho locale `pt-PT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-PT/6.ogg` | `ogg` | 1886 | tracked | Audio prompt `6` cho locale `pt-PT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-PT/7.ogg` | `ogg` | 2094 | tracked | Audio prompt `7` cho locale `pt-PT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-PT/8.ogg` | `ogg` | 1973 | tracked | Audio prompt `8` cho locale `pt-PT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-PT/9.ogg` | `ogg` | 1809 | tracked | Audio prompt `9` cho locale `pt-PT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-PT/activation.ogg` | `ogg` | 14660 | tracked | Audio prompt `activation` cho locale `pt-PT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-PT/err_pin.ogg` | `ogg` | 3457 | tracked | Audio prompt `err_pin` cho locale `pt-PT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-PT/err_reg.ogg` | `ogg` | 8363 | tracked | Audio prompt `err_reg` cho locale `pt-PT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-PT/language.json` | `json` | 2815 | tracked | Dữ liệu ngôn ngữ `pt-PT` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/pt-PT/upgrade.ogg` | `ogg` | 4051 | tracked | Audio prompt `upgrade` cho locale `pt-PT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-PT/welcome.ogg` | `ogg` | 3053 | tracked | Audio prompt `welcome` cho locale `pt-PT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/pt-PT/wificonfig.ogg` | `ogg` | 5471 | tracked | Audio prompt `wificonfig` cho locale `pt-PT`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ro-RO/0.ogg` | `ogg` | 1958 | tracked | Audio prompt `0` cho locale `ro-RO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ro-RO/1.ogg` | `ogg` | 1870 | tracked | Audio prompt `1` cho locale `ro-RO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ro-RO/2.ogg` | `ogg` | 1839 | tracked | Audio prompt `2` cho locale `ro-RO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ro-RO/3.ogg` | `ogg` | 1566 | tracked | Audio prompt `3` cho locale `ro-RO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ro-RO/4.ogg` | `ogg` | 2149 | tracked | Audio prompt `4` cho locale `ro-RO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ro-RO/5.ogg` | `ogg` | 1766 | tracked | Audio prompt `5` cho locale `ro-RO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ro-RO/6.ogg` | `ogg` | 1947 | tracked | Audio prompt `6` cho locale `ro-RO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ro-RO/7.ogg` | `ogg` | 2318 | tracked | Audio prompt `7` cho locale `ro-RO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ro-RO/8.ogg` | `ogg` | 2000 | tracked | Audio prompt `8` cho locale `ro-RO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ro-RO/9.ogg` | `ogg` | 2279 | tracked | Audio prompt `9` cho locale `ro-RO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ro-RO/activation.ogg` | `ogg` | 15258 | tracked | Audio prompt `activation` cho locale `ro-RO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ro-RO/err_pin.ogg` | `ogg` | 5609 | tracked | Audio prompt `err_pin` cho locale `ro-RO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ro-RO/err_reg.ogg` | `ogg` | 9224 | tracked | Audio prompt `err_reg` cho locale `ro-RO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ro-RO/language.json` | `json` | 2916 | tracked | Dữ liệu ngôn ngữ `ro-RO` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/ro-RO/upgrade.ogg` | `ogg` | 4479 | tracked | Audio prompt `upgrade` cho locale `ro-RO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ro-RO/welcome.ogg` | `ogg` | 2592 | tracked | Audio prompt `welcome` cho locale `ro-RO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ro-RO/wificonfig.ogg` | `ogg` | 5552 | tracked | Audio prompt `wificonfig` cho locale `ro-RO`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ru-RU/0.ogg` | `ogg` | 1661 | tracked | Audio prompt `0` cho locale `ru-RU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ru-RU/1.ogg` | `ogg` | 1847 | tracked | Audio prompt `1` cho locale `ru-RU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ru-RU/2.ogg` | `ogg` | 1215 | tracked | Audio prompt `2` cho locale `ru-RU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ru-RU/3.ogg` | `ogg` | 854 | tracked | Audio prompt `3` cho locale `ru-RU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ru-RU/4.ogg` | `ogg` | 2328 | tracked | Audio prompt `4` cho locale `ru-RU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ru-RU/5.ogg` | `ogg` | 2106 | tracked | Audio prompt `5` cho locale `ru-RU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ru-RU/6.ogg` | `ogg` | 1091 | tracked | Audio prompt `6` cho locale `ru-RU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ru-RU/7.ogg` | `ogg` | 1103 | tracked | Audio prompt `7` cho locale `ru-RU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ru-RU/8.ogg` | `ogg` | 2557 | tracked | Audio prompt `8` cho locale `ru-RU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ru-RU/9.ogg` | `ogg` | 1986 | tracked | Audio prompt `9` cho locale `ru-RU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ru-RU/activation.ogg` | `ogg` | 12285 | tracked | Audio prompt `activation` cho locale `ru-RU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ru-RU/err_pin.ogg` | `ogg` | 5773 | tracked | Audio prompt `err_pin` cho locale `ru-RU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ru-RU/err_reg.ogg` | `ogg` | 9221 | tracked | Audio prompt `err_reg` cho locale `ru-RU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ru-RU/language.json` | `json` | 3618 | tracked | Dữ liệu ngôn ngữ `ru-RU` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/ru-RU/upgrade.ogg` | `ogg` | 3396 | tracked | Audio prompt `upgrade` cho locale `ru-RU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ru-RU/welcome.ogg` | `ogg` | 2327 | tracked | Audio prompt `welcome` cho locale `ru-RU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/ru-RU/wificonfig.ogg` | `ogg` | 7563 | tracked | Audio prompt `wificonfig` cho locale `ru-RU`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sk-SK/0.ogg` | `ogg` | 1503 | tracked | Audio prompt `0` cho locale `sk-SK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sk-SK/1.ogg` | `ogg` | 1558 | tracked | Audio prompt `1` cho locale `sk-SK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sk-SK/2.ogg` | `ogg` | 1286 | tracked | Audio prompt `2` cho locale `sk-SK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sk-SK/3.ogg` | `ogg` | 1267 | tracked | Audio prompt `3` cho locale `sk-SK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sk-SK/4.ogg` | `ogg` | 1613 | tracked | Audio prompt `4` cho locale `sk-SK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sk-SK/5.ogg` | `ogg` | 1240 | tracked | Audio prompt `5` cho locale `sk-SK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sk-SK/6.ogg` | `ogg` | 1723 | tracked | Audio prompt `6` cho locale `sk-SK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sk-SK/7.ogg` | `ogg` | 1646 | tracked | Audio prompt `7` cho locale `sk-SK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sk-SK/8.ogg` | `ogg` | 1455 | tracked | Audio prompt `8` cho locale `sk-SK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sk-SK/9.ogg` | `ogg` | 1533 | tracked | Audio prompt `9` cho locale `sk-SK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sk-SK/activation.ogg` | `ogg` | 9297 | tracked | Audio prompt `activation` cho locale `sk-SK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sk-SK/err_pin.ogg` | `ogg` | 2554 | tracked | Audio prompt `err_pin` cho locale `sk-SK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sk-SK/err_reg.ogg` | `ogg` | 7410 | tracked | Audio prompt `err_reg` cho locale `sk-SK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sk-SK/language.json` | `json` | 2785 | tracked | Dữ liệu ngôn ngữ `sk-SK` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/sk-SK/upgrade.ogg` | `ogg` | 3182 | tracked | Audio prompt `upgrade` cho locale `sk-SK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sk-SK/welcome.ogg` | `ogg` | 2198 | tracked | Audio prompt `welcome` cho locale `sk-SK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sk-SK/wificonfig.ogg` | `ogg` | 4439 | tracked | Audio prompt `wificonfig` cho locale `sk-SK`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sl-SI/0.ogg` | `ogg` | 1907 | tracked | Audio prompt `0` cho locale `sl-SI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sl-SI/1.ogg` | `ogg` | 1324 | tracked | Audio prompt `1` cho locale `sl-SI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sl-SI/2.ogg` | `ogg` | 1552 | tracked | Audio prompt `2` cho locale `sl-SI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sl-SI/3.ogg` | `ogg` | 1385 | tracked | Audio prompt `3` cho locale `sl-SI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sl-SI/4.ogg` | `ogg` | 1638 | tracked | Audio prompt `4` cho locale `sl-SI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sl-SI/5.ogg` | `ogg` | 1308 | tracked | Audio prompt `5` cho locale `sl-SI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sl-SI/6.ogg` | `ogg` | 1913 | tracked | Audio prompt `6` cho locale `sl-SI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sl-SI/7.ogg` | `ogg` | 1623 | tracked | Audio prompt `7` cho locale `sl-SI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sl-SI/8.ogg` | `ogg` | 1652 | tracked | Audio prompt `8` cho locale `sl-SI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sl-SI/9.ogg` | `ogg` | 1522 | tracked | Audio prompt `9` cho locale `sl-SI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sl-SI/activation.ogg` | `ogg` | 14764 | tracked | Audio prompt `activation` cho locale `sl-SI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sl-SI/err_pin.ogg` | `ogg` | 5445 | tracked | Audio prompt `err_pin` cho locale `sl-SI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sl-SI/err_reg.ogg` | `ogg` | 9313 | tracked | Audio prompt `err_reg` cho locale `sl-SI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sl-SI/language.json` | `json` | 2763 | tracked | Dữ liệu ngôn ngữ `sl-SI` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/sl-SI/upgrade.ogg` | `ogg` | 3282 | tracked | Audio prompt `upgrade` cho locale `sl-SI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sl-SI/welcome.ogg` | `ogg` | 3786 | tracked | Audio prompt `welcome` cho locale `sl-SI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sl-SI/wificonfig.ogg` | `ogg` | 7214 | tracked | Audio prompt `wificonfig` cho locale `sl-SI`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sr-RS/language.json` | `json` | 3622 | tracked | Dữ liệu ngôn ngữ `sr-RS` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/sv-SE/0.ogg` | `ogg` | 2303 | tracked | Audio prompt `0` cho locale `sv-SE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sv-SE/1.ogg` | `ogg` | 2228 | tracked | Audio prompt `1` cho locale `sv-SE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sv-SE/2.ogg` | `ogg` | 1995 | tracked | Audio prompt `2` cho locale `sv-SE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sv-SE/3.ogg` | `ogg` | 2018 | tracked | Audio prompt `3` cho locale `sv-SE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sv-SE/4.ogg` | `ogg` | 2010 | tracked | Audio prompt `4` cho locale `sv-SE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sv-SE/5.ogg` | `ogg` | 1938 | tracked | Audio prompt `5` cho locale `sv-SE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sv-SE/6.ogg` | `ogg` | 1900 | tracked | Audio prompt `6` cho locale `sv-SE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sv-SE/7.ogg` | `ogg` | 1894 | tracked | Audio prompt `7` cho locale `sv-SE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sv-SE/8.ogg` | `ogg` | 2028 | tracked | Audio prompt `8` cho locale `sv-SE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sv-SE/9.ogg` | `ogg` | 2597 | tracked | Audio prompt `9` cho locale `sv-SE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sv-SE/activation.ogg` | `ogg` | 14059 | tracked | Audio prompt `activation` cho locale `sv-SE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sv-SE/err_pin.ogg` | `ogg` | 5779 | tracked | Audio prompt `err_pin` cho locale `sv-SE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sv-SE/err_reg.ogg` | `ogg` | 8675 | tracked | Audio prompt `err_reg` cho locale `sv-SE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sv-SE/language.json` | `json` | 2697 | tracked | Dữ liệu ngôn ngữ `sv-SE` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/sv-SE/upgrade.ogg` | `ogg` | 4643 | tracked | Audio prompt `upgrade` cho locale `sv-SE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sv-SE/welcome.ogg` | `ogg` | 2490 | tracked | Audio prompt `welcome` cho locale `sv-SE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/sv-SE/wificonfig.ogg` | `ogg` | 6484 | tracked | Audio prompt `wificonfig` cho locale `sv-SE`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/th-TH/0.ogg` | `ogg` | 2279 | tracked | Audio prompt `0` cho locale `th-TH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/th-TH/1.ogg` | `ogg` | 2055 | tracked | Audio prompt `1` cho locale `th-TH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/th-TH/2.ogg` | `ogg` | 2086 | tracked | Audio prompt `2` cho locale `th-TH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/th-TH/3.ogg` | `ogg` | 2251 | tracked | Audio prompt `3` cho locale `th-TH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/th-TH/4.ogg` | `ogg` | 1919 | tracked | Audio prompt `4` cho locale `th-TH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/th-TH/5.ogg` | `ogg` | 1961 | tracked | Audio prompt `5` cho locale `th-TH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/th-TH/6.ogg` | `ogg` | 1889 | tracked | Audio prompt `6` cho locale `th-TH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/th-TH/7.ogg` | `ogg` | 1590 | tracked | Audio prompt `7` cho locale `th-TH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/th-TH/8.ogg` | `ogg` | 1560 | tracked | Audio prompt `8` cho locale `th-TH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/th-TH/9.ogg` | `ogg` | 1646 | tracked | Audio prompt `9` cho locale `th-TH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/th-TH/activation.ogg` | `ogg` | 9627 | tracked | Audio prompt `activation` cho locale `th-TH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/th-TH/err_pin.ogg` | `ogg` | 3382 | tracked | Audio prompt `err_pin` cho locale `th-TH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/th-TH/err_reg.ogg` | `ogg` | 9745 | tracked | Audio prompt `err_reg` cho locale `th-TH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/th-TH/language.json` | `json` | 4383 | tracked | Dữ liệu ngôn ngữ `th-TH` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/th-TH/upgrade.ogg` | `ogg` | 3404 | tracked | Audio prompt `upgrade` cho locale `th-TH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/th-TH/welcome.ogg` | `ogg` | 3788 | tracked | Audio prompt `welcome` cho locale `th-TH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/th-TH/wificonfig.ogg` | `ogg` | 5596 | tracked | Audio prompt `wificonfig` cho locale `th-TH`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/tr-TR/0.ogg` | `ogg` | 1972 | tracked | Audio prompt `0` cho locale `tr-TR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/tr-TR/1.ogg` | `ogg` | 1983 | tracked | Audio prompt `1` cho locale `tr-TR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/tr-TR/2.ogg` | `ogg` | 1699 | tracked | Audio prompt `2` cho locale `tr-TR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/tr-TR/3.ogg` | `ogg` | 1767 | tracked | Audio prompt `3` cho locale `tr-TR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/tr-TR/4.ogg` | `ogg` | 1972 | tracked | Audio prompt `4` cho locale `tr-TR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/tr-TR/5.ogg` | `ogg` | 1868 | tracked | Audio prompt `5` cho locale `tr-TR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/tr-TR/6.ogg` | `ogg` | 2014 | tracked | Audio prompt `6` cho locale `tr-TR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/tr-TR/7.ogg` | `ogg` | 1818 | tracked | Audio prompt `7` cho locale `tr-TR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/tr-TR/8.ogg` | `ogg` | 2196 | tracked | Audio prompt `8` cho locale `tr-TR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/tr-TR/9.ogg` | `ogg` | 2002 | tracked | Audio prompt `9` cho locale `tr-TR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/tr-TR/activation.ogg` | `ogg` | 10808 | tracked | Audio prompt `activation` cho locale `tr-TR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/tr-TR/err_pin.ogg` | `ogg` | 4456 | tracked | Audio prompt `err_pin` cho locale `tr-TR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/tr-TR/err_reg.ogg` | `ogg` | 9495 | tracked | Audio prompt `err_reg` cho locale `tr-TR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/tr-TR/language.json` | `json` | 2747 | tracked | Dữ liệu ngôn ngữ `tr-TR` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/tr-TR/upgrade.ogg` | `ogg` | 4021 | tracked | Audio prompt `upgrade` cho locale `tr-TR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/tr-TR/welcome.ogg` | `ogg` | 3010 | tracked | Audio prompt `welcome` cho locale `tr-TR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/tr-TR/wificonfig.ogg` | `ogg` | 5432 | tracked | Audio prompt `wificonfig` cho locale `tr-TR`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/uk-UA/0.ogg` | `ogg` | 2003 | tracked | Audio prompt `0` cho locale `uk-UA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/uk-UA/1.ogg` | `ogg` | 1902 | tracked | Audio prompt `1` cho locale `uk-UA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/uk-UA/2.ogg` | `ogg` | 2026 | tracked | Audio prompt `2` cho locale `uk-UA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/uk-UA/3.ogg` | `ogg` | 1765 | tracked | Audio prompt `3` cho locale `uk-UA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/uk-UA/4.ogg` | `ogg` | 2327 | tracked | Audio prompt `4` cho locale `uk-UA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/uk-UA/5.ogg` | `ogg` | 1989 | tracked | Audio prompt `5` cho locale `uk-UA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/uk-UA/6.ogg` | `ogg` | 1975 | tracked | Audio prompt `6` cho locale `uk-UA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/uk-UA/7.ogg` | `ogg` | 1678 | tracked | Audio prompt `7` cho locale `uk-UA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/uk-UA/8.ogg` | `ogg` | 2279 | tracked | Audio prompt `8` cho locale `uk-UA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/uk-UA/9.ogg` | `ogg` | 2146 | tracked | Audio prompt `9` cho locale `uk-UA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/uk-UA/activation.ogg` | `ogg` | 14195 | tracked | Audio prompt `activation` cho locale `uk-UA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/uk-UA/err_pin.ogg` | `ogg` | 4537 | tracked | Audio prompt `err_pin` cho locale `uk-UA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/uk-UA/err_reg.ogg` | `ogg` | 9545 | tracked | Audio prompt `err_reg` cho locale `uk-UA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/uk-UA/language.json` | `json` | 3772 | tracked | Dữ liệu ngôn ngữ `uk-UA` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/uk-UA/upgrade.ogg` | `ogg` | 3642 | tracked | Audio prompt `upgrade` cho locale `uk-UA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/uk-UA/welcome.ogg` | `ogg` | 2803 | tracked | Audio prompt `welcome` cho locale `uk-UA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/uk-UA/wificonfig.ogg` | `ogg` | 5981 | tracked | Audio prompt `wificonfig` cho locale `uk-UA`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/vi-VN/0.ogg` | `ogg` | 1446 | tracked | Audio prompt `0` cho locale `vi-VN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/vi-VN/1.ogg` | `ogg` | 1635 | tracked | Audio prompt `1` cho locale `vi-VN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/vi-VN/2.ogg` | `ogg` | 1857 | tracked | Audio prompt `2` cho locale `vi-VN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/vi-VN/3.ogg` | `ogg` | 1656 | tracked | Audio prompt `3` cho locale `vi-VN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/vi-VN/4.ogg` | `ogg` | 1649 | tracked | Audio prompt `4` cho locale `vi-VN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/vi-VN/5.ogg` | `ogg` | 1443 | tracked | Audio prompt `5` cho locale `vi-VN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/vi-VN/6.ogg` | `ogg` | 1786 | tracked | Audio prompt `6` cho locale `vi-VN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/vi-VN/7.ogg` | `ogg` | 1967 | tracked | Audio prompt `7` cho locale `vi-VN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/vi-VN/8.ogg` | `ogg` | 1494 | tracked | Audio prompt `8` cho locale `vi-VN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/vi-VN/9.ogg` | `ogg` | 1733 | tracked | Audio prompt `9` cho locale `vi-VN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/vi-VN/activation.ogg` | `ogg` | 9747 | tracked | Audio prompt `activation` cho locale `vi-VN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/vi-VN/err_pin.ogg` | `ogg` | 3806 | tracked | Audio prompt `err_pin` cho locale `vi-VN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/vi-VN/err_reg.ogg` | `ogg` | 8213 | tracked | Audio prompt `err_reg` cho locale `vi-VN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/vi-VN/language.json` | `json` | 2989 | tracked | Dữ liệu ngôn ngữ `vi-VN` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/vi-VN/upgrade.ogg` | `ogg` | 4162 | tracked | Audio prompt `upgrade` cho locale `vi-VN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/vi-VN/welcome.ogg` | `ogg` | 2929 | tracked | Audio prompt `welcome` cho locale `vi-VN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/vi-VN/wificonfig.ogg` | `ogg` | 5203 | tracked | Audio prompt `wificonfig` cho locale `vi-VN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-CN/0.ogg` | `ogg` | 1438 | tracked | Audio prompt `0` cho locale `zh-CN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-CN/1.ogg` | `ogg` | 1485 | tracked | Audio prompt `1` cho locale `zh-CN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-CN/2.ogg` | `ogg` | 1250 | tracked | Audio prompt `2` cho locale `zh-CN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-CN/3.ogg` | `ogg` | 1503 | tracked | Audio prompt `3` cho locale `zh-CN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-CN/4.ogg` | `ogg` | 1634 | tracked | Audio prompt `4` cho locale `zh-CN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-CN/5.ogg` | `ogg` | 1512 | tracked | Audio prompt `5` cho locale `zh-CN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-CN/6.ogg` | `ogg` | 1496 | tracked | Audio prompt `6` cho locale `zh-CN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-CN/7.ogg` | `ogg` | 1652 | tracked | Audio prompt `7` cho locale `zh-CN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-CN/8.ogg` | `ogg` | 1473 | tracked | Audio prompt `8` cho locale `zh-CN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-CN/9.ogg` | `ogg` | 1421 | tracked | Audio prompt `9` cho locale `zh-CN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-CN/activation.ogg` | `ogg` | 8402 | tracked | Audio prompt `activation` cho locale `zh-CN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-CN/err_pin.ogg` | `ogg` | 3538 | tracked | Audio prompt `err_pin` cho locale `zh-CN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-CN/err_reg.ogg` | `ogg` | 6747 | tracked | Audio prompt `err_reg` cho locale `zh-CN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-CN/language.json` | `json` | 2506 | tracked | Dữ liệu ngôn ngữ `zh-CN` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/zh-CN/upgrade.ogg` | `ogg` | 2847 | tracked | Audio prompt `upgrade` cho locale `zh-CN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-CN/welcome.ogg` | `ogg` | 3493 | tracked | Audio prompt `welcome` cho locale `zh-CN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-CN/wificonfig.ogg` | `ogg` | 3155 | tracked | Audio prompt `wificonfig` cho locale `zh-CN`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-TW/0.ogg` | `ogg` | 1438 | tracked | Audio prompt `0` cho locale `zh-TW`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-TW/1.ogg` | `ogg` | 1485 | tracked | Audio prompt `1` cho locale `zh-TW`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-TW/2.ogg` | `ogg` | 1250 | tracked | Audio prompt `2` cho locale `zh-TW`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-TW/3.ogg` | `ogg` | 1503 | tracked | Audio prompt `3` cho locale `zh-TW`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-TW/4.ogg` | `ogg` | 1634 | tracked | Audio prompt `4` cho locale `zh-TW`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-TW/5.ogg` | `ogg` | 1512 | tracked | Audio prompt `5` cho locale `zh-TW`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-TW/6.ogg` | `ogg` | 1496 | tracked | Audio prompt `6` cho locale `zh-TW`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-TW/7.ogg` | `ogg` | 1652 | tracked | Audio prompt `7` cho locale `zh-TW`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-TW/8.ogg` | `ogg` | 1473 | tracked | Audio prompt `8` cho locale `zh-TW`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-TW/9.ogg` | `ogg` | 1421 | tracked | Audio prompt `9` cho locale `zh-TW`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-TW/activation.ogg` | `ogg` | 8402 | tracked | Audio prompt `activation` cho locale `zh-TW`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-TW/err_pin.ogg` | `ogg` | 3538 | tracked | Audio prompt `err_pin` cho locale `zh-TW`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-TW/err_reg.ogg` | `ogg` | 6747 | tracked | Audio prompt `err_reg` cho locale `zh-TW`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-TW/language.json` | `json` | 2507 | tracked | Dữ liệu ngôn ngữ `zh-TW` (JSON keys: language, strings); source cho localized strings/voice assets. |
| `main/assets/locales/zh-TW/upgrade.ogg` | `ogg` | 2847 | tracked | Audio prompt `upgrade` cho locale `zh-TW`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-TW/welcome.ogg` | `ogg` | 3493 | tracked | Audio prompt `welcome` cho locale `zh-TW`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/assets/locales/zh-TW/wificonfig.ogg` | `ogg` | 3155 | tracked | Audio prompt `wificonfig` cho locale `zh-TW`; build chọn locale hiện hành và fallback về en-US khi thiếu. |
| `main/audio/README.md` | `md` | 5426 | tracked | Thiết kế pipeline audio và các ràng buộc audio subsystem. Main section: Audio Service Architecture. |
| `main/audio/audio_codec.cc` | `cc` | 1638 | tracked | Hành vi I2S/audio codec dùng chung. Key types/methods: `AudioCodec::OutputData`, `AudioCodec::InputData`, `AudioCodec::Start`, `AudioCodec::SetOutputVolume`, `AudioCodec::SetInputGain`, `AudioCodec::EnableInput`, `AudioCodec::EnableOutput`. |
| `main/audio/audio_codec.h` | `h` | 2340 | tracked | Interface AudioCodec cho thu/phát âm thanh. Key types/methods: `AudioCodec`. |
| `main/audio/audio_debugger.cc` | `cc` | 2656 | tracked | Công cụ debug/ghi nhận thống kê audio. Key types/methods: `AudioDebugger::Feed`. |
| `main/audio/audio_debugger.h` | `h` | 349 | tracked | Interface và cấu trúc dữ liệu debug audio. Key types/methods: `AudioDebugger`, `sockaddr_in`. |
| `main/audio/audio_engine.h` | `h` | 1361 | tracked | Interface engine cho xử lý audio, wake word, VAD và AEC. Key types/methods: `AudioEngine`. |
| `main/audio/audio_service.cc` | `cc` | 35164 | tracked | Tasks capture/output/codec, queues, encode/decode và wake/audio control. Key types/methods: `AudioService::Initialize`, `AudioService::Start`, `AudioService::Stop`, `AudioService::ReadAudioData`, `AudioService::AudioInputTask`, `AudioService::AudioOutputTask`, `AudioService::OpusCodecTask`, `AudioService::SetDecodeSampleRate`. |
| `main/audio/audio_service.h` | `h` | 8895 | tracked | Interface AudioService, task/queue types và callbacks. Key types/methods: `AudioServiceCallbacks`, `AudioTaskType`, `AudioTask`, `DebugStatistics`, `AudioService`. |
| `main/audio/codecs/box_audio_codec.cc` | `cc` | 9110 | tracked | Codec backend `box_audio_codec`: kết nối audio service với codec/I2S hoặc no/dummy audio path. Key types/methods: `BoxAudioCodec::CreateDuplexChannels`, `BoxAudioCodec::SetOutputVolume`, `BoxAudioCodec::EnableInput`, `BoxAudioCodec::EnableOutput`, `BoxAudioCodec::Read`, `BoxAudioCodec::Write`. |
| `main/audio/codecs/box_audio_codec.h` | `h` | 1660 | tracked | Codec backend `box_audio_codec`: kết nối audio service với codec/I2S hoặc no/dummy audio path. Key types/methods: `BoxAudioCodec`. |
| `main/audio/codecs/dummy_audio_codec.cc` | `cc` | 475 | tracked | Codec backend `dummy_audio_codec`: kết nối audio service với codec/I2S hoặc no/dummy audio path. Key types/methods: `DummyAudioCodec::Read`, `DummyAudioCodec::Write`. |
| `main/audio/codecs/dummy_audio_codec.h` | `h` | 406 | tracked | Codec backend `dummy_audio_codec`: kết nối audio service với codec/I2S hoặc no/dummy audio path. Key types/methods: `DummyAudioCodec`. |
| `main/audio/codecs/es8311_audio_codec.cc` | `cc` | 7128 | tracked | Codec backend `es8311_audio_codec`: kết nối audio service với codec/I2S hoặc no/dummy audio path. Key types/methods: `Es8311AudioCodec::ResetCodec`, `Es8311AudioCodec::UpdateDeviceState`, `Es8311AudioCodec::CreateDuplexChannels`, `Es8311AudioCodec::SetOutputVolume`, `Es8311AudioCodec::EnableInput`, `Es8311AudioCodec::EnableOutput`, `Es8311AudioCodec::Read`, `Es8311AudioCodec::Write`. |
| `main/audio/codecs/es8311_audio_codec.h` | `h` | 1464 | tracked | Codec backend `es8311_audio_codec`: kết nối audio service với codec/I2S hoặc no/dummy audio path. Key types/methods: `Es8311AudioCodec`. |
| `main/audio/codecs/es8374_audio_codec.cc` | `cc` | 6581 | tracked | Codec backend `es8374_audio_codec`: kết nối audio service với codec/I2S hoặc no/dummy audio path. Key types/methods: `Es8374AudioCodec::CreateDuplexChannels`, `Es8374AudioCodec::SetOutputVolume`, `Es8374AudioCodec::EnableInput`, `Es8374AudioCodec::EnableOutput`, `Es8374AudioCodec::Read`, `Es8374AudioCodec::Write`. |
| `main/audio/codecs/es8374_audio_codec.h` | `h` | 1409 | tracked | Codec backend `es8374_audio_codec`: kết nối audio service với codec/I2S hoặc no/dummy audio path. Key types/methods: `Es8374AudioCodec`. |
| `main/audio/codecs/es8388_audio_codec.cc` | `cc` | 7978 | tracked | Codec backend `es8388_audio_codec`: kết nối audio service với codec/I2S hoặc no/dummy audio path. Key types/methods: `Es8388AudioCodec::CreateDuplexChannels`, `Es8388AudioCodec::SetOutputVolume`, `Es8388AudioCodec::EnableInput`, `Es8388AudioCodec::EnableOutput`, `Es8388AudioCodec::Read`, `Es8388AudioCodec::Write`. |
| `main/audio/codecs/es8388_audio_codec.h` | `h` | 1433 | tracked | Codec backend `es8388_audio_codec`: kết nối audio service với codec/I2S hoặc no/dummy audio path. Key types/methods: `Es8388AudioCodec`. |
| `main/audio/codecs/es8389_audio_codec.cc` | `cc` | 8330 | tracked | Codec backend `es8389_audio_codec`: kết nối audio service với codec/I2S hoặc no/dummy audio path. Key types/methods: `Es8389AudioCodec::CreateDuplexChannels`, `Es8389AudioCodec::SetOutputVolume`, `Es8389AudioCodec::EnableInput`, `Es8389AudioCodec::EnableOutput`, `Es8389AudioCodec::Read`, `Es8389AudioCodec::Write`. |
| `main/audio/codecs/es8389_audio_codec.h` | `h` | 1498 | tracked | Codec backend `es8389_audio_codec`: kết nối audio service với codec/I2S hoặc no/dummy audio path. Key types/methods: `Es8389AudioCodec`. |
| `main/audio/codecs/no_audio_codec.cc` | `cc` | 13438 | tracked | Codec backend `no_audio_codec`: kết nối audio service với codec/I2S hoặc no/dummy audio path. Key types/methods: `NoAudioCodec::Write`, `NoAudioCodec::Read`, `NoAudioCodec::EnableInput`, `NoAudioCodec::EnableOutput`, `NoAudioCodecSimplexPdm::Read`. |
| `main/audio/codecs/no_audio_codec.h` | `h` | 1743 | tracked | Codec backend `no_audio_codec`: kết nối audio service với codec/I2S hoặc no/dummy audio path. Key types/methods: `NoAudioCodec`, `NoAudioCodecDuplex`, `NoAudioCodecSimplex`, `NoAudioCodecSimplexPdm`. |
| `main/audio/demuxer/ogg_demuxer.cc` | `cc` | 16381 | tracked | Đọc trang/packet Ogg cho luồng Opus. Key types/methods: `OggDemuxer::Reset`, `OggDemuxer::GetOpusPacketDurationMs`, `OggDemuxer::Finish`, `OggDemuxer::Process`. |
| `main/audio/demuxer/ogg_demuxer.h` | `h` | 2174 | tracked | Interface và trạng thái Ogg demuxer. Key types/methods: `OggDemuxer`, `ParseState`, `Opus_t`, `context_t`. |
| `main/audio/engines/afe_audio_engine.cc` | `cc` | 24547 | tracked | Triển khai AudioEngine cho pipeline, xử lý giọng nói, VAD/wake/AEC. Key types/methods: `AfeAudioEngine::Initialize`, `AfeAudioEngine::Feed`, `AfeAudioEngine::EnableWakeWordDetection`, `AfeAudioEngine::EnableVoiceProcessing`, `AfeAudioEngine::EnableDeviceAec`, `AfeAudioEngine::HasWakeWord`, `AfeAudioEngine::GetWakeWords`, `AfeAudioEngine::IsWakeWordDetectionEnabled`. |
| `main/audio/engines/afe_audio_engine.h` | `h` | 4294 | tracked | Triển khai AudioEngine cho pipeline, xử lý giọng nói, VAD/wake/AEC. Key types/methods: `CustomWakeWord`, `AfeAudioEngine`, `WakeDetector`. |
| `main/audio/engines/lite_audio_engine.cc` | `cc` | 5842 | tracked | Triển khai AudioEngine cho pipeline, xử lý giọng nói, VAD/wake/AEC. Key types/methods: `LiteAudioEngine::Initialize`, `LiteAudioEngine::Feed`, `LiteAudioEngine::EnableWakeWordDetection`, `LiteAudioEngine::EnableVoiceProcessing`, `LiteAudioEngine::EnableDeviceAec`, `LiteAudioEngine::HasWakeWord`, `LiteAudioEngine::GetWakeWords`, `LiteAudioEngine::IsWakeWordDetectionEnabled`. |
| `main/audio/engines/lite_audio_engine.h` | `h` | 2356 | tracked | Triển khai AudioEngine cho pipeline, xử lý giọng nói, VAD/wake/AEC. Key types/methods: `EspWakeWord`, `LiteAudioEngine`. |
| `main/audio/fixed_queue.h` | `h` | 1764 | tracked | Queue dung lượng cố định dùng trong đường audio. Key types/methods: `FixedQueue`. |
| `main/audio/wake_word.h` | `h` | 806 | tracked | Interface wake-word detector. Key types/methods: `WakeWord`. |
| `main/audio/wake_words/custom_wake_word.cc` | `cc` | 12505 | tracked | Wake-word model/detection hoặc cache audio đầu vào cho wake flow. Key types/methods: `CustomWakeWord::ParseWakenetModelConfig`, `CustomWakeWord::Initialize`, `CustomWakeWord::OnWakeWordDetected`, `CustomWakeWord::GetWakeWords`, `CustomWakeWord::Start`, `CustomWakeWord::Stop`, `CustomWakeWord::Feed`, `CustomWakeWord::FeedMono`. |
| `main/audio/wake_words/custom_wake_word.h` | `h` | 2312 | tracked | Wake-word model/detection hoặc cache audio đầu vào cho wake flow. Key types/methods: `CustomWakeWord`, `Command`. |
| `main/audio/wake_words/esp_wake_word.cc` | `cc` | 4087 | tracked | Wake-word model/detection hoặc cache audio đầu vào cho wake flow. Key types/methods: `EspWakeWord::Initialize`, `EspWakeWord::OnWakeWordDetected`, `EspWakeWord::Start`, `EspWakeWord::Stop`, `EspWakeWord::Feed`, `EspWakeWord::GetFeedSize`, `EspWakeWord::GetWakeWords`, `EspWakeWord::EncodeWakeWordData`. |
| `main/audio/wake_words/esp_wake_word.h` | `h` | 1331 | tracked | Wake-word model/detection hoặc cache audio đầu vào cho wake flow. Key types/methods: `EspWakeWord`. |
| `main/audio/wake_words/wake_word_audio_cache.cc` | `cc` | 2832 | tracked | Wake-word model/detection hoặc cache audio đầu vào cho wake flow. Key types/methods: `WakeWordAudioCache::Initialize`, `WakeWordAudioCache::Store`, `WakeWordAudioCache::Read`, `WakeWordAudioCache::Size`, `WakeWordAudioCache::Clear`. |
| `main/audio/wake_words/wake_word_audio_cache.h` | `h` | 725 | tracked | Wake-word model/detection hoặc cache audio đầu vào cho wake flow. Key types/methods: `WakeWordAudioCache`. |
| `main/boards/alientek/atk-dnesp32s3-box/atk_dnesp32s3_box.cc` | `cc` | 9848 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `atk_dnesp32s3_box.cc` trong `main/boards/alientek/atk-dnesp32s3-box`. Key types/methods: `ATK_NoAudioCodecDuplex`, `XL9555_IN`, `atk_dnesp32s3_box`. |
| `main/boards/alientek/atk-dnesp32s3-box/config.h` | `h` | 1196 | tracked | Pin map và compile-time hardware options cho board `main/boards/alientek/atk-dnesp32s3-box`. |
| `main/boards/alientek/atk-dnesp32s3-box/config.json` | `json` | 277 | tracked | Board/release config: target `esp32s3`, type `atk-dnesp32s3-box`, variants: atk-dnesp32s3-box. |
| `main/boards/alientek/atk-dnesp32s3-box0/atk_dnesp32s3_box0.cc` | `cc` | 15233 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `atk_dnesp32s3_box0.cc` trong `main/boards/alientek/atk-dnesp32s3-box0`. Key types/methods: `atk_dnesp32s3_box0`. |
| `main/boards/alientek/atk-dnesp32s3-box0/config.h` | `h` | 1832 | tracked | Pin map và compile-time hardware options cho board `main/boards/alientek/atk-dnesp32s3-box0`. Key types/methods: `XiaozhiStatus`, `LcdStatus`, `WakeStatus`, `PowerSupply`, `PowerSleep`. |
| `main/boards/alientek/atk-dnesp32s3-box0/config.json` | `json` | 214 | tracked | Board/release config: target `esp32s3`, type `atk-dnesp32s3-box0`, variants: atk-dnesp32s3-box0. |
| `main/boards/alientek/atk-dnesp32s3-box0/power_manager.h` | `h` | 6075 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/alientek/atk-dnesp32s3-box0`. Key types/methods: `PowerManager`. |
| `main/boards/alientek/atk-dnesp32s3-box2-4g/atk_dnesp32s3_box2.cc` | `cc` | 19211 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `atk_dnesp32s3_box2.cc` trong `main/boards/alientek/atk-dnesp32s3-box2-4g`. Key types/methods: `atk_dnesp32s3_box2_4g`. |
| `main/boards/alientek/atk-dnesp32s3-box2-4g/config.h` | `h` | 2251 | tracked | Pin map và compile-time hardware options cho board `main/boards/alientek/atk-dnesp32s3-box2-4g`. Key types/methods: `PowerSupply`. |
| `main/boards/alientek/atk-dnesp32s3-box2-4g/config.json` | `json` | 220 | tracked | Board/release config: target `esp32s3`, type `atk-dnesp32s3-box2-4g`, variants: atk-dnesp32s3-box2-4g. |
| `main/boards/alientek/atk-dnesp32s3-box2-4g/power_manager.h` | `h` | 6467 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/alientek/atk-dnesp32s3-box2-4g`. Key types/methods: `PowerManager`. |
| `main/boards/alientek/atk-dnesp32s3-box2-wifi/atk_dnesp32s3_box2.cc` | `cc` | 18146 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `atk_dnesp32s3_box2.cc` trong `main/boards/alientek/atk-dnesp32s3-box2-wifi`. Key types/methods: `atk_dnesp32s3_box2_wifi`. |
| `main/boards/alientek/atk-dnesp32s3-box2-wifi/config.h` | `h` | 2037 | tracked | Pin map và compile-time hardware options cho board `main/boards/alientek/atk-dnesp32s3-box2-wifi`. Key types/methods: `PowerSupply`. |
| `main/boards/alientek/atk-dnesp32s3-box2-wifi/config.json` | `json` | 224 | tracked | Board/release config: target `esp32s3`, type `atk-dnesp32s3-box2-wifi`, variants: atk-dnesp32s3-box2-wifi. |
| `main/boards/alientek/atk-dnesp32s3-box2-wifi/power_manager.h` | `h` | 6467 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/alientek/atk-dnesp32s3-box2-wifi`. Key types/methods: `PowerManager`. |
| `main/boards/alientek/atk-dnesp32s3-box3/atk_dnesp32s3_box3.cc` | `cc` | 18158 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `atk_dnesp32s3_box3.cc` trong `main/boards/alientek/atk-dnesp32s3-box3`. Key types/methods: `atk_dnesp32s3_box3`. |
| `main/boards/alientek/atk-dnesp32s3-box3/config.h` | `h` | 2849 | tracked | Pin map và compile-time hardware options cho board `main/boards/alientek/atk-dnesp32s3-box3`. Key types/methods: `PowerSupply`. |
| `main/boards/alientek/atk-dnesp32s3-box3/config.json` | `json` | 453 | tracked | Board/release config: target `esp32s3`, type `atk-dnesp32s3-box3`, variants: atk-dnesp32s3-box3. |
| `main/boards/alientek/atk-dnesp32s3-box3/power_manager.h` | `h` | 6485 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/alientek/atk-dnesp32s3-box3`. Key types/methods: `PowerManager`. |
| `main/boards/alientek/atk-dnesp32s3/atk_dnesp32s3.cc` | `cc` | 7080 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `atk_dnesp32s3.cc` trong `main/boards/alientek/atk-dnesp32s3`. Key types/methods: `XL9555`, `atk_dnesp32s3`. |
| `main/boards/alientek/atk-dnesp32s3/config.h` | `h` | 1716 | tracked | Pin map và compile-time hardware options cho board `main/boards/alientek/atk-dnesp32s3`. |
| `main/boards/alientek/atk-dnesp32s3/config.json` | `json` | 400 | tracked | Board/release config: target `esp32s3`, type `atk-dnesp32s3`, variants: atk-dnesp32s3. |
| `main/boards/alientek/atk-dnesp32s3m-4g/atk_dnesp32s3m.cc` | `cc` | 7571 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `atk_dnesp32s3m.cc` trong `main/boards/alientek/atk-dnesp32s3m-4g`. Key types/methods: `atk_dnesp32s3m_4g`. |
| `main/boards/alientek/atk-dnesp32s3m-4g/config.h` | `h` | 1318 | tracked | Pin map và compile-time hardware options cho board `main/boards/alientek/atk-dnesp32s3m-4g`. |
| `main/boards/alientek/atk-dnesp32s3m-4g/config.json` | `json` | 111 | tracked | Board/release config: target `esp32s3`, type `atk-dnesp32s3m-4g`, variants: chưa khai báo builds. |
| `main/boards/alientek/atk-dnesp32s3m-wifi/atk_dnesp32s3m.cc` | `cc` | 7883 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `atk_dnesp32s3m.cc` trong `main/boards/alientek/atk-dnesp32s3m-wifi`. Key types/methods: `atk_dnesp32s3m_wifi`. |
| `main/boards/alientek/atk-dnesp32s3m-wifi/config.h` | `h` | 1312 | tracked | Pin map và compile-time hardware options cho board `main/boards/alientek/atk-dnesp32s3m-wifi`. |
| `main/boards/alientek/atk-dnesp32s3m-wifi/config.json` | `json` | 113 | tracked | Board/release config: target `esp32s3`, type `atk-dnesp32s3m-wifi`, variants: chưa khai báo builds. |
| `main/boards/bread-compact-esp32-lcd/config.h` | `h` | 7965 | tracked | Pin map và compile-time hardware options cho board `main/boards/bread-compact-esp32-lcd`. |
| `main/boards/bread-compact-esp32-lcd/config.json` | `json` | 254 | tracked | Board/release config: target `esp32`, type `bread-compact-esp32-lcd`, variants: bread-compact-esp32-lcd. |
| `main/boards/bread-compact-esp32-lcd/esp32_bread_board_lcd.cc` | `cc` | 7197 | tracked | Driver hoặc UI/display resource riêng của board `esp32_bread_board_lcd.cc` trong `main/boards/bread-compact-esp32-lcd`. Key types/methods: `CompactWifiBoardLCD`. |
| `main/boards/bread-compact-esp32/README.md` | `md` | 279 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/bread-compact-esp32`. Main section: 编译配置命令. |
| `main/boards/bread-compact-esp32/config.h` | `h` | 1434 | tracked | Pin map và compile-time hardware options cho board `main/boards/bread-compact-esp32`. |
| `main/boards/bread-compact-esp32/config.json` | `json` | 407 | tracked | Board/release config: target `esp32`, type `bread-compact-esp32`, variants: bread-compact-esp32, bread-compact-esp32-128x32. |
| `main/boards/bread-compact-esp32/esp32_bread_board.cc` | `cc` | 5401 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32_bread_board.cc` trong `main/boards/bread-compact-esp32`. Key types/methods: `CompactWifiBoard`. |
| `main/boards/bread-compact-ml307/compact_ml307_board.cc` | `cc` | 6519 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `compact_ml307_board.cc` trong `main/boards/bread-compact-ml307`. Key types/methods: `CompactMl307Board`. |
| `main/boards/bread-compact-ml307/config.h` | `h` | 1426 | tracked | Pin map và compile-time hardware options cho board `main/boards/bread-compact-ml307`. |
| `main/boards/bread-compact-ml307/config.json` | `json` | 409 | tracked | Board/release config: target `esp32s3`, type `bread-compact-ml307`, variants: bread-compact-ml307, bread-compact-ml307-128x64. |
| `main/boards/bread-compact-nt26/compact_nt26_board.cc` | `cc` | 6390 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `compact_nt26_board.cc` trong `main/boards/bread-compact-nt26`. Key types/methods: `CompactNt26Board`. |
| `main/boards/bread-compact-nt26/config.h` | `h` | 1577 | tracked | Pin map và compile-time hardware options cho board `main/boards/bread-compact-nt26`. |
| `main/boards/bread-compact-nt26/config.json` | `json` | 241 | tracked | Board/release config: target `esp32s3`, type `bread-compact-nt26`, variants: bread-compact-nt26. |
| `main/boards/bread-compact-wifi-lcd/compact_wifi_board_lcd.cc` | `cc` | 6373 | tracked | Driver hoặc UI/display resource riêng của board `compact_wifi_board_lcd.cc` trong `main/boards/bread-compact-wifi-lcd`. Key types/methods: `CompactWifiBoardLCD`. |
| `main/boards/bread-compact-wifi-lcd/config.h` | `h` | 8290 | tracked | Pin map và compile-time hardware options cho board `main/boards/bread-compact-wifi-lcd`. |
| `main/boards/bread-compact-wifi-lcd/config.json` | `json` | 249 | tracked | Board/release config: target `esp32s3`, type `bread-compact-wifi-lcd`, variants: bread-compact-wifi-lcd. |
| `main/boards/bread-compact-wifi-s3cam/README.md` | `md` | 572 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/bread-compact-wifi-s3cam`. Main section: 编译配置命令. |
| `main/boards/bread-compact-wifi-s3cam/compact_wifi_board_s3cam.cc` | `cc` | 7488 | tracked | Tích hợp mạng riêng của board `compact_wifi_board_s3cam.cc` trong `main/boards/bread-compact-wifi-s3cam`. Key types/methods: `CompactWifiBoardS3Cam`. |
| `main/boards/bread-compact-wifi-s3cam/config.h` | `h` | 8895 | tracked | Pin map và compile-time hardware options cho board `main/boards/bread-compact-wifi-s3cam`. |
| `main/boards/bread-compact-wifi-s3cam/config.json` | `json` | 378 | tracked | Board/release config: target `esp32s3`, type `bread-compact-wifi-s3cam`, variants: bread-compact-wifi-s3cam. |
| `main/boards/bread-compact-wifi/compact_wifi_board.cc` | `cc` | 6175 | tracked | Tích hợp mạng riêng của board `compact_wifi_board.cc` trong `main/boards/bread-compact-wifi`. Key types/methods: `CompactWifiBoard`. |
| `main/boards/bread-compact-wifi/config.h` | `h` | 1433 | tracked | Pin map và compile-time hardware options cho board `main/boards/bread-compact-wifi`. |
| `main/boards/bread-compact-wifi/config.json` | `json` | 406 | tracked | Board/release config: target `esp32s3`, type `bread-compact-wifi`, variants: bread-compact-wifi, bread-compact-wifi-128x64. |
| `main/boards/chd/chd-esp32s3-box/README.md` | `md` | 2358 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/chd/chd-esp32s3-box`. Main section: 简介. |
| `main/boards/chd/chd-esp32s3-box/chd_esp32s3_box_board.cc` | `cc` | 35840 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `chd_esp32s3_box_board.cc` trong `main/boards/chd/chd-esp32s3-box`. Key types/methods: `CustomLcdDisplay`, `ChdEsp32s3BoxBoard`. |
| `main/boards/chd/chd-esp32s3-box/config.h` | `h` | 5284 | tracked | Pin map và compile-time hardware options cho board `main/boards/chd/chd-esp32s3-box`. |
| `main/boards/chd/chd-esp32s3-box/config.json` | `json` | 464 | tracked | Board/release config: target `esp32s3`, type `chd-esp32s3-box`, variants: chd-esp32s3-box, chd-esp32s3-box-lcd35. |
| `main/boards/chd/chd-esp32s3-box/power_manager.h` | `h` | 6186 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/chd/chd-esp32s3-box`. Key types/methods: `PowerManager`. |
| `main/boards/chd/chd-esp32s3-eye/README.md` | `md` | 916 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/chd/chd-esp32s3-eye`. Main section: 简介. |
| `main/boards/chd/chd-esp32s3-eye/chd_esp32s3_eye_board.cc` | `cc` | 9680 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `chd_esp32s3_eye_board.cc` trong `main/boards/chd/chd-esp32s3-eye`. Key types/methods: `ChdEsp32s3EyeBoard`. |
| `main/boards/chd/chd-esp32s3-eye/config.h` | `h` | 2573 | tracked | Pin map và compile-time hardware options cho board `main/boards/chd/chd-esp32s3-eye`. |
| `main/boards/chd/chd-esp32s3-eye/config.json` | `json` | 215 | tracked | Board/release config: target `esp32s3`, type `chd-esp32s3-eye`, variants: chd-esp32s3-eye. |
| `main/boards/common/adc_battery_monitor.cc` | `cc` | 3816 | tracked | Đọc và tính mức pin qua ADC. Key types/methods: `AdcBatteryMonitor::IsCharging`, `AdcBatteryMonitor::IsDischarging`, `AdcBatteryMonitor::GetBatteryLevel`, `AdcBatteryMonitor::OnChargingStatusChanged`, `AdcBatteryMonitor::CheckBatteryStatus`. |
| `main/boards/common/adc_battery_monitor.h` | `h` | 858 | tracked | Interface giám sát pin qua ADC. Key types/methods: `AdcBatteryMonitor`. |
| `main/boards/common/axp2101.cc` | `cc` | 815 | tracked | Driver PMIC AXP2101. (helper dùng chung; xem caller/board sử dụng). Key types/methods: `Axp2101::GetBatteryCurrentDirection`, `Axp2101::IsCharging`, `Axp2101::IsDischarging`, `Axp2101::IsChargingDone`, `Axp2101::GetBatteryLevel`, `Axp2101::GetTemperature`, `Axp2101::PowerOff`. |
| `main/boards/common/axp2101.h` | `h` | 384 | tracked | Driver PMIC AXP2101. (helper dùng chung; xem caller/board sử dụng). Key types/methods: `Axp2101`. |
| `main/boards/common/backlight.cc` | `cc` | 3518 | tracked | Implementation backlight dùng chung. Key types/methods: `Backlight::RestoreBrightness`, `Backlight::SetBrightness`, `Backlight::OnTransitionTimer`, `PwmBacklight::SetBrightnessImpl`. |
| `main/boards/common/backlight.h` | `h` | 794 | tracked | Interface và điều khiển backlight. Key types/methods: `Backlight`, `PwmBacklight`. |
| `main/boards/common/blufi.cpp` | `cpp` | 40959 | tracked | BluFi provisioning helper. (helper dùng chung; xem caller/board sử dụng). Key types/methods: `Blufi::GetInstance`, `Blufi::init`, `Blufi::deinit`, `Blufi::_host_init`, `Blufi::_host_deinit`, `Blufi::_gap_register_callback`, `Blufi::_host_and_cb_init`, `Blufi::_nimble_on_reset`. |
| `main/boards/common/blufi.h` | `h` | 5002 | tracked | BluFi provisioning helper. (helper dùng chung; xem caller/board sử dụng). Key types/methods: `Blufi`, `BlufiSecurity`. |
| `main/boards/common/board.cc` | `cc` | 5992 | tracked | Hành vi mặc định/shared cho Board và identity/device info. Key types/methods: `Board::GenerateUuid`, `std::string`, `Board::GetBatteryLevel`, `Board::GetTemperature`, `Board::GetDisplay`, `Board::GetCamera`, `Board::GetLed`, `Board::GetSystemInfoJson`. |
| `main/boards/common/board.h` | `h` | 3056 | tracked | Hợp đồng Board, khả năng tùy chọn và macro DECLARE_BOARD. Key types/methods: `NetworkEvent`, `PowerSaveLevel`, `AudioCodec`, `Display`, `Board`. |
| `main/boards/common/button.cc` | `cc` | 3904 | tracked | Quét/dispatch sự kiện nút bấm dùng chung. Key types/methods: `Button::OnPressDown`, `Button::OnPressUp`, `Button::OnLongPress`, `Button::OnClick`, `Button::OnDoubleClick`, `Button::OnMultipleClick`. |
| `main/boards/common/button.h` | `h` | 1402 | tracked | Abstraction nút bấm và sự kiện click/hold. Key types/methods: `Button`, `AdcButton`, `PowerSaveButton`. |
| `main/boards/common/camera.h` | `h` | 549 | tracked | Interface camera tùy chọn. Key types/methods: `Camera`. |
| `main/boards/common/dual_network_board.cc` | `cc` | 3178 | tracked | Điều phối failover/chuyển mạng cho board dual-network. Key types/methods: `DualNetworkBoard::LoadNetworkTypeFromSettings`, `DualNetworkBoard::SaveNetworkTypeToSettings`, `DualNetworkBoard::InitializeCurrentBoard`, `DualNetworkBoard::SwitchNetworkType`, `DualNetworkBoard::GetBoardType`, `DualNetworkBoard::StartNetwork`, `DualNetworkBoard::SetNetworkEventCallback`, `DualNetworkBoard::GetNetwork`. |
| `main/boards/common/dual_network_board.h` | `h` | 1888 | tracked | Abstraction chọn/chuyển giữa hai network interfaces. Key types/methods: `NetworkType`, `DualNetworkBoard`. |
| `main/boards/common/esp32_camera.cc` | `cc` | 13393 | tracked | Camera backend dùng ESP32 camera driver. Key types/methods: `Esp32Camera::SetExplainUrl`, `Esp32Camera::Capture`, `Esp32Camera::SetHMirror`, `Esp32Camera::SetVFlip`, `Esp32Camera::SetSwapBytes`, `Esp32Camera::Explain`, `std::unexpected`. |
| `main/boards/common/esp32_camera.h` | `h` | 1198 | tracked | Khai báo ESP32 camera backend. Key types/methods: `JpegChunk`, `Esp32Camera`. |
| `main/boards/common/esp_video.cc` | `cc` | 44433 | tracked | Camera/video backend dựa trên esp-video. Key types/methods: `v4l2_capability`, `v4l2_format`, `v4l2_fmtdesc`, `v4l2_requestbuffers`, `v4l2_buffer`, `v4l2_ext_controls`, `v4l2_ext_control`, `EspVideo::SetExplainUrl`. |
| `main/boards/common/esp_video.h` | `h` | 1456 | tracked | Khai báo esp-video backend. Key types/methods: `JpegChunk`, `EspVideo`, `FrameBuffer`, `MmapBuffer`. |
| `main/boards/common/ethernet_board.cc` | `cc` | 10489 | tracked | Khởi tạo và quản lý network Ethernet. Key types/methods: `EthernetBoard::GetBoardType`, `EthernetBoard::SetNetworkEventCallback`, `EthernetBoard::StartNetwork`, `EthernetBoard::NetworkTaskEntry`, `EthernetBoard::NetworkTask`, `EthernetBoard::EthEventHandler`, `EthernetBoard::GotIpEventHandler`, `EthernetBoard::OnNetworkEvent`. |
| `main/boards/common/ethernet_board.h` | `h` | 1426 | tracked | Interface/helper Ethernet board. Key types/methods: `EthernetBoard`, `esp_netif_obj`. |
| `main/boards/common/i2c_device.cc` | `cc` | 1637 | tracked | Implementation giao dịch thiết bị I2C. Key types/methods: `I2cDevice::WriteReg`, `I2cDevice::WriteRegs`, `I2cDevice::ReadReg`, `I2cDevice::ReadRegs`, `I2cDevice::ResetBus`. |
| `main/boards/common/i2c_device.h` | `h` | 572 | tracked | Base/helper giao tiếp thiết bị I2C. Key types/methods: `I2cDevice`. |
| `main/boards/common/knob.cc` | `cc` | 1409 | tracked | Rotary encoder/knob input. (helper dùng chung; xem caller/board sử dụng). Key types/methods: `Knob::OnRotate`, `Knob::knob_callback`. |
| `main/boards/common/knob.h` | `h` | 466 | tracked | Rotary encoder/knob input. (helper dùng chung; xem caller/board sử dụng). Key types/methods: `Knob`. |
| `main/boards/common/lamp_controller.h` | `h` | 1507 | tracked | Interface điều khiển lamp. (helper dùng chung; xem caller/board sử dụng). Key types/methods: `LampController`. |
| `main/boards/common/ml307_board.cc` | `cc` | 9268 | tracked | Điều khiển modem và network cellular ML307/EC801E. Key types/methods: `Ml307Board::GetBoardType`, `Ml307Board::SetNetworkEventCallback`, `Ml307Board::OnNetworkEvent`, `Ml307Board::NetworkTask`, `Ml307Board::StartNetwork`, `Ml307Board::GetNetwork`, `Ml307Board::GetNetworkStateIcon`, `Ml307Board::GetBoardJson`. |
| `main/boards/common/ml307_board.h` | `h` | 1226 | tracked | Interface modem cellular ML307/EC801E. Key types/methods: `Ml307Board`. |
| `main/boards/common/nt26_board.cc` | `cc` | 10633 | tracked | Điều khiển modem và network cellular NT26. Key types/methods: `Nt26Board::GetBoardType`, `Nt26Board::OnNetworkEvent`, `Nt26Board::OnNetworkReadyTimeout`, `Nt26Board::StartNetwork`, `Nt26Board::ScheduleAsyncStop`, `Nt26Board::SetNetworkEventCallback`, `Nt26Board::GetNetwork`, `Nt26Board::GetNetworkStateIcon`. |
| `main/boards/common/nt26_board.h` | `h` | 2020 | tracked | Interface modem cellular NT26. Key types/methods: `Nt26CeregState`, `Nt26Board`. |
| `main/boards/common/power_save_timer.cc` | `cc` | 4160 | tracked | Timer chuyển mức tiết kiệm điện. (helper dùng chung; xem caller/board sử dụng). Key types/methods: `PowerSaveTimer::SetEnabled`, `PowerSaveTimer::OnEnterSleepMode`, `PowerSaveTimer::OnExitSleepMode`, `PowerSaveTimer::OnShutdownRequest`, `PowerSaveTimer::PowerSaveCheck`, `PowerSaveTimer::WakeUp`. |
| `main/boards/common/power_save_timer.h` | `h` | 899 | tracked | Timer chuyển mức tiết kiệm điện. (helper dùng chung; xem caller/board sử dụng). Key types/methods: `PowerSaveTimer`. |
| `main/boards/common/press_to_talk_mcp_tool.cc` | `cc` | 1858 | tracked | MCP tool tích hợp nút press-to-talk. (helper dùng chung; xem caller/board sử dụng). Key types/methods: `PressToTalkMcpTool::Initialize`, `PressToTalkMcpTool::IsPressToTalkEnabled`, `PressToTalkMcpTool::HandleSetPressToTalk`, `std::unexpected`, `PressToTalkMcpTool::SetPressToTalkEnabled`. |
| `main/boards/common/press_to_talk_mcp_tool.h` | `h` | 683 | tracked | MCP tool tích hợp nút press-to-talk. (helper dùng chung; xem caller/board sử dụng). Key types/methods: `PressToTalkMcpTool`. |
| `main/boards/common/rndis_board.cc` | `cc` | 8049 | tracked | Khởi tạo và quản lý network RNDIS. Key types/methods: `RndisBoard::GetBoardType`, `RndisBoard::StartNetwork`, `RndisBoard::iot_event_handle`, `RndisBoard::OnNetworkEvent`, `RndisBoard::SetNetworkEventCallback`, `RndisBoard::install_rndis`, `RndisBoard::GetNetwork`, `RndisBoard::GetNetworkStateIcon`. |
| `main/boards/common/rndis_board.h` | `h` | 2248 | tracked | Interface network USB RNDIS. Key types/methods: `RndisBoard`. |
| `main/boards/common/sleep_timer.cc` | `cc` | 4682 | tracked | Timer điều phối sleep. (helper dùng chung; xem caller/board sử dụng). Key types/methods: `SleepTimer::SetEnabled`, `SleepTimer::OnEnterLightSleepMode`, `SleepTimer::OnExitLightSleepMode`, `SleepTimer::OnEnterDeepSleepMode`, `SleepTimer::CheckTimer`, `SleepTimer::WakeUp`. |
| `main/boards/common/sleep_timer.h` | `h` | 849 | tracked | Timer điều phối sleep. (helper dùng chung; xem caller/board sử dụng). Key types/methods: `SleepTimer`. |
| `main/boards/common/sy6970.cc` | `cc` | 1695 | tracked | Driver charger/power IC SY6970. (helper dùng chung; xem caller/board sử dụng). Key types/methods: `Sy6970::GetChangingStatus`, `Sy6970::IsCharging`, `Sy6970::IsPowerGood`, `Sy6970::IsChargingDone`, `Sy6970::GetBatteryVoltage`, `Sy6970::GetChargeTargetVoltage`, `Sy6970::GetBatteryLevel`, `Sy6970::PowerOff`. |
| `main/boards/common/sy6970.h` | `h` | 403 | tracked | Driver charger/power IC SY6970. (helper dùng chung; xem caller/board sử dụng). Key types/methods: `Sy6970`. |
| `main/boards/common/system_reset.cc` | `cc` | 2157 | tracked | Reset/reboot helper. (helper dùng chung; xem caller/board sử dụng). Key types/methods: `SystemReset::CheckButtons`, `SystemReset::ResetNvsFlash`, `SystemReset::ResetToFactory`, `SystemReset::RestartInSeconds`. |
| `main/boards/common/system_reset.h` | `h` | 408 | tracked | Reset/reboot helper. (helper dùng chung; xem caller/board sử dụng). Key types/methods: `SystemReset`. |
| `main/boards/common/wifi_board.cc` | `cc` | 11611 | tracked | Kết nối, provisioning và trạng thái network Wi-Fi dùng chung. Key types/methods: `WifiBoard::GetBoardType`, `WifiBoard::StartNetwork`, `WifiBoard::TryWifiConnect`, `WifiBoard::OnNetworkEvent`, `WifiBoard::SetNetworkEventCallback`, `WifiBoard::OnWifiConnectTimeout`, `WifiBoard::StartWifiConfigMode`, `WifiBoard::EnterWifiConfigMode`. |
| `main/boards/common/wifi_board.h` | `h` | 1925 | tracked | Interface board dùng Wi-Fi và network callbacks. Key types/methods: `WifiBoard`. |
| `main/boards/common/xpower.h` | `h` | 3500 | tracked | Interface power management. (helper dùng chung; xem caller/board sử dụng). Key types/methods: `Xpowers`. |
| `main/boards/dfrobot/df-k10/README.md` | `md` | 1238 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/dfrobot/df-k10`. Main section: DFRobot 行空板 K10. |
| `main/boards/dfrobot/df-k10/config.h` | `h` | 2278 | tracked | Pin map và compile-time hardware options cho board `main/boards/dfrobot/df-k10`. |
| `main/boards/dfrobot/df-k10/config.json` | `json` | 494 | tracked | Board/release config: target `esp32s3`, type `df-k10`, variants: df-k10. |
| `main/boards/dfrobot/df-k10/df_k10_board.cc` | `cc` | 11082 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `df_k10_board.cc` trong `main/boards/dfrobot/df-k10`. Key types/methods: `Df_K10Board`. |
| `main/boards/dfrobot/df-k10/k10_audio_codec.cc` | `cc` | 7743 | tracked | Cấu hình hoặc driver audio codec của board `k10_audio_codec.cc` trong `main/boards/dfrobot/df-k10`. Key types/methods: `K10AudioCodec::CreateDuplexChannels`, `K10AudioCodec::SetOutputVolume`, `K10AudioCodec::EnableInput`, `K10AudioCodec::EnableOutput`, `K10AudioCodec::Read`, `K10AudioCodec::Write`. |
| `main/boards/dfrobot/df-k10/k10_audio_codec.h` | `h` | 1365 | tracked | Cấu hình hoặc driver audio codec của board `k10_audio_codec.h` trong `main/boards/dfrobot/df-k10`. Key types/methods: `K10AudioCodec`. |
| `main/boards/dfrobot/df-k10/led_control.cc` | `cc` | 5408 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `led_control.cc` trong `main/boards/dfrobot/df-k10`. Key types/methods: `LedStripControl::LevelToBrightness`, `LedStripControl::RGBToColor`. |
| `main/boards/dfrobot/df-k10/led_control.h` | `h` | 432 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `led_control.h` trong `main/boards/dfrobot/df-k10`. Key types/methods: `LedStripControl`. |
| `main/boards/dfrobot/df-s3-ai-cam/README.md` | `md` | 2044 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/dfrobot/df-s3-ai-cam`. Main section: DFRobot ESP32-S3 AI智能摄像头模块. |
| `main/boards/dfrobot/df-s3-ai-cam/config.h` | `h` | 2128 | tracked | Pin map và compile-time hardware options cho board `main/boards/dfrobot/df-s3-ai-cam`. |
| `main/boards/dfrobot/df-s3-ai-cam/config.json` | `json` | 729 | tracked | Board/release config: target `esp32s3`, type `df-s3-ai-cam`, variants: df-s3-ai-cam. |
| `main/boards/dfrobot/df-s3-ai-cam/df_s3_ai_cam.cc` | `cc` | 3081 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `df_s3_ai_cam.cc` trong `main/boards/dfrobot/df-s3-ai-cam`. Key types/methods: `DfrobotEsp32S3AiCam`. |
| `main/boards/doit-s3-aibox/README.md` | `md` | 625 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/doit-s3-aibox`. Main section: 四博智联AI陪伴盒子. |
| `main/boards/doit-s3-aibox/config.h` | `h` | 821 | tracked | Pin map và compile-time hardware options cho board `main/boards/doit-s3-aibox`. |
| `main/boards/doit-s3-aibox/config.json` | `json` | 184 | tracked | Board/release config: target `esp32s3`, type `doit-s3-aibox`, variants: doit-s3-aibox. |
| `main/boards/doit-s3-aibox/doit_s3_aibox.cc` | `cc` | 4083 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `doit_s3_aibox.cc` trong `main/boards/doit-s3-aibox`. Key types/methods: `DoitS3AiBox`. |
| `main/boards/du-chatx/config.h` | `h` | 1190 | tracked | Pin map và compile-time hardware options cho board `main/boards/du-chatx`. |
| `main/boards/du-chatx/config.json` | `json` | 161 | tracked | Board/release config: target `esp32s3`, type `du-chatx`, variants: du-chatx. |
| `main/boards/du-chatx/du-chatx-wifi.cc` | `cc` | 5988 | tracked | Tích hợp mạng riêng của board `du-chatx-wifi.cc` trong `main/boards/du-chatx`. Key types/methods: `DuChatX`. |
| `main/boards/du-chatx/power_manager.h` | `h` | 6007 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/du-chatx`. Key types/methods: `PowerManager`. |
| `main/boards/electron-bot/README.md` | `md` | 7100 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/electron-bot`. Main section: 简介. |
| `main/boards/electron-bot/config.h` | `h` | 1426 | tracked | Pin map và compile-time hardware options cho board `main/boards/electron-bot`. |
| `main/boards/electron-bot/config.json` | `json` | 227 | tracked | Board/release config: target `esp32s3`, type `electron-bot`, variants: electron-bot. |
| `main/boards/electron-bot/electron_bot.cc` | `cc` | 5365 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `electron_bot.cc` trong `main/boards/electron-bot`. Key types/methods: `ElectronBot`. |
| `main/boards/electron-bot/electron_bot_controller.cc` | `cc` | 30679 | tracked | Điều khiển chức năng robot/peripheral riêng của board `electron_bot_controller.cc` trong `main/boards/electron-bot`. Key types/methods: `ElectronBotActionParams`, `ElectronBotController`, `ActionType`, `std::max`. |
| `main/boards/electron-bot/electron_emoji_display.cc` | `cc` | 3442 | tracked | Driver hoặc UI/display resource riêng của board `electron_emoji_display.cc` trong `main/boards/electron-bot`. Key types/methods: `ElectronEmojiDisplay::SetupUI`, `ElectronEmojiDisplay::SetStatus`. |
| `main/boards/electron-bot/electron_emoji_display.h` | `h` | 639 | tracked | Driver hoặc UI/display resource riêng của board `electron_emoji_display.h` trong `main/boards/electron-bot`. Key types/methods: `ElectronEmojiDisplay`. |
| `main/boards/electron-bot/movements.cc` | `cc` | 18777 | tracked | Điều khiển chức năng robot/peripheral riêng của board `movements.cc` trong `main/boards/electron-bot`. Key types/methods: `std::clamp`, `Otto::Init`, `Otto::AttachServos`, `Otto::DetachServos`, `Otto::SetTrims`, `Otto::MoveServos`, `Otto::MoveSingle`, `Otto::GetServoPositions`. |
| `main/boards/electron-bot/movements.h` | `h` | 2601 | tracked | Điều khiển chức năng robot/peripheral riêng của board `movements.h` trong `main/boards/electron-bot`. Key types/methods: `Otto`. |
| `main/boards/electron-bot/oscillator.cc` | `cc` | 3869 | tracked | Điều khiển chức năng robot/peripheral riêng của board `oscillator.cc` trong `main/boards/electron-bot`. Key types/methods: `Oscillator::AngleToCompare`, `Oscillator::NextSample`, `Oscillator::Attach`, `Oscillator::Detach`, `Oscillator::SetT`, `Oscillator::SetPosition`, `Oscillator::Refresh`, `Oscillator::Write`. |
| `main/boards/electron-bot/oscillator.h` | `h` | 2568 | tracked | Điều khiển chức năng robot/peripheral riêng của board `oscillator.h` trong `main/boards/electron-bot`. Key types/methods: `Oscillator`. |
| `main/boards/electron-bot/otto_icon_font.c` | `c` | 4320 | tracked | Driver hoặc UI/display resource riêng của board `otto_icon_font.c` trong `main/boards/electron-bot`. |
| `main/boards/electron-bot/power_manager.h` | `h` | 4195 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/electron-bot`. Key types/methods: `PowerManager`. |
| `main/boards/electron-bot/websocket_control_server.cc` | `cc` | 6982 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `websocket_control_server.cc` trong `main/boards/electron-bot`. Key types/methods: `WsBroadcastJob`, `WebSocketControlServer::WsHandler`, `WebSocketControlServer::Start`, `WebSocketControlServer::Stop`, `WebSocketControlServer::HandleMessage`, `WebSocketControlServer::AddClient`, `WebSocketControlServer::RemoveClient`, `WebSocketControlServer::GetClientCount`. |
| `main/boards/electron-bot/websocket_control_server.h` | `h` | 756 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `websocket_control_server.h` trong `main/boards/electron-bot`. Key types/methods: `WebSocketControlServer`. |
| `main/boards/espressif/esp-hi/README.md` | `md` | 2116 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/espressif/esp-hi`. Main section: ESP-Hi. |
| `main/boards/espressif/esp-hi/adc_pdm_audio_codec.cc` | `cc` | 9358 | tracked | Cấu hình hoặc driver audio codec của board `adc_pdm_audio_codec.cc` trong `main/boards/espressif/esp-hi`. Key types/methods: `AdcPdmAudioCodec::SetOutputVolume`, `AdcPdmAudioCodec::EnableInput`, `AdcPdmAudioCodec::EnableOutput`, `AdcPdmAudioCodec::Read`, `AdcPdmAudioCodec::Write`, `AdcPdmAudioCodec::Start`, `AdcPdmAudioCodec::OutputTimerCallback`. |
| `main/boards/espressif/esp-hi/adc_pdm_audio_codec.h` | `h` | 1153 | tracked | Cấu hình hoặc driver audio codec của board `adc_pdm_audio_codec.h` trong `main/boards/espressif/esp-hi`. Key types/methods: `AdcPdmAudioCodec`. |
| `main/boards/espressif/esp-hi/config.h` | `h` | 1574 | tracked | Pin map và compile-time hardware options cho board `main/boards/espressif/esp-hi`. |
| `main/boards/espressif/esp-hi/config.json` | `json` | 1443 | tracked | Board/release config: target `esp32c3`, type `esp-hi`, variants: esp-hi. |
| `main/boards/espressif/esp-hi/emoji_display.cc` | `cc` | 5780 | tracked | Driver hoặc UI/display resource riêng của board `emoji_display.cc` trong `main/boards/espressif/esp-hi`. Key types/methods: `EmojiPlayer::OnFlushIoReady`, `EmojiPlayer::OnFlush`, `EmojiPlayer::StartPlayer`, `EmojiPlayer::StopPlayer`, `EmojiWidget::SetEmotion`, `EmojiWidget::SetStatus`, `EmojiWidget::InitializePlayer`, `EmojiWidget::Lock`. |
| `main/boards/espressif/esp-hi/emoji_display.h` | `h` | 1679 | tracked | Driver hoặc UI/display resource riêng của board `emoji_display.h` trong `main/boards/espressif/esp-hi`. Key types/methods: `EmojiPlayer`, `EmojiWidget`. |
| `main/boards/espressif/esp-hi/esp_hi.cc` | `cc` | 17004 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp_hi.cc` trong `main/boards/espressif/esp-hi`. Key types/methods: `EspHi`. |
| `main/boards/espressif/esp-mosaico/README.md` | `md` | 1359 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/espressif/esp-mosaico`. Main section: ESP-Mosaico. |
| `main/boards/espressif/esp-mosaico/README_CN.md` | `md` | 1267 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/espressif/esp-mosaico`. Main section: ESP-Mosaico. |
| `main/boards/espressif/esp-mosaico/config.h` | `h` | 3506 | tracked | Pin map và compile-time hardware options cho board `main/boards/espressif/esp-mosaico`. |
| `main/boards/espressif/esp-mosaico/config.json` | `json` | 1157 | tracked | Board/release config: target `esp32s31`, type `esp-mosaico`, variants: esp-mosaico. |
| `main/boards/espressif/esp-mosaico/esp_mosaico.cc` | `cc` | 20537 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp_mosaico.cc` trong `main/boards/espressif/esp-mosaico`. Key types/methods: `BoardVariant`, `MosaicoBacklight`, `MosaicoDisplay`, `EspMosaicoBoard`, `std::memcmp`, `std::unexpected`, `Board::GetLed`. |
| `main/boards/espressif/esp-sensairshuttle/README.md` | `md` | 1111 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/espressif/esp-sensairshuttle`. Main section: ESP-SensairShuttle. |
| `main/boards/espressif/esp-sensairshuttle/adc_pdm_audio_codec.cc` | `cc` | 9346 | tracked | Cấu hình hoặc driver audio codec của board `adc_pdm_audio_codec.cc` trong `main/boards/espressif/esp-sensairshuttle`. Key types/methods: `AdcPdmAudioCodec::SetOutputVolume`, `AdcPdmAudioCodec::EnableInput`, `AdcPdmAudioCodec::EnableOutput`, `AdcPdmAudioCodec::Read`, `AdcPdmAudioCodec::Write`, `AdcPdmAudioCodec::Start`, `AdcPdmAudioCodec::OutputTimerCallback`. |
| `main/boards/espressif/esp-sensairshuttle/adc_pdm_audio_codec.h` | `h` | 1153 | tracked | Cấu hình hoặc driver audio codec của board `adc_pdm_audio_codec.h` trong `main/boards/espressif/esp-sensairshuttle`. Key types/methods: `AdcPdmAudioCodec`. |
| `main/boards/espressif/esp-sensairshuttle/config.h` | `h` | 1212 | tracked | Pin map và compile-time hardware options cho board `main/boards/espressif/esp-sensairshuttle`. |
| `main/boards/espressif/esp-sensairshuttle/config.json` | `json` | 1262 | tracked | Board/release config: target `esp32c5`, type `esp-sensairshuttle`, variants: esp-sensairshuttle. |
| `main/boards/espressif/esp-sensairshuttle/esp-sensairshuttle.cc` | `cc` | 10238 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp-sensairshuttle.cc` trong `main/boards/espressif/esp-sensairshuttle`. Key types/methods: `Cst816d`, `TouchPoint_t`, `TouchEvent`, `EspSensairShuttle`. |
| `main/boards/espressif/esp-sparkbot/config.h` | `h` | 3044 | tracked | Pin map và compile-time hardware options cho board `main/boards/espressif/esp-sparkbot`. |
| `main/boards/espressif/esp-sparkbot/config.json` | `json` | 399 | tracked | Board/release config: target `esp32s3`, type `esp-sparkbot`, variants: esp-sparkbot. |
| `main/boards/espressif/esp-sparkbot/esp_sparkbot_board.cc` | `cc` | 12332 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp_sparkbot_board.cc` trong `main/boards/espressif/esp-sparkbot`. Key types/methods: `SparkBotEs8311AudioCodec`, `EspSparkBot`, `std::unexpected`. |
| `main/boards/espressif/esp-spot/README.md` | `md` | 1637 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/espressif/esp-spot`. Main section: ESP-Spot. |
| `main/boards/espressif/esp-spot/config.h` | `h` | 2423 | tracked | Pin map và compile-time hardware options cho board `main/boards/espressif/esp-spot`. |
| `main/boards/espressif/esp-spot/config.json` | `json` | 480 | tracked | Board/release config: target `esp32c5`, type `esp-spot`, variants: esp-spot-c5. |
| `main/boards/espressif/esp-spot/esp_spot_board.cc` | `cc` | 15251 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp_spot_board.cc` trong `main/boards/espressif/esp-spot`. Key types/methods: `bmi2_sens_config`, `bmi2_int_pin_config`, `bmi2_sens_int_config`, `EspSpot`. |
| `main/boards/espressif/esp-vocat/README.md` | `md` | 4009 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/espressif/esp-vocat`. Main section: ESP-VoCat 喵伴. |
| `main/boards/espressif/esp-vocat/assets/360_360/emote.json` | `json` | 1680 | tracked | Tài nguyên hoặc ghi chú riêng của board `emote.json` trong `main/boards/espressif/esp-vocat`. |
| `main/boards/espressif/esp-vocat/config.h` | `h` | 3140 | tracked | Pin map và compile-time hardware options cho board `main/boards/espressif/esp-vocat`. |
| `main/boards/espressif/esp-vocat/config.json` | `json` | 369 | tracked | Board/release config: target `esp32s3`, type `esp-vocat`, variants: esp-vocat. |
| `main/boards/espressif/esp-vocat/emoji/battery_connected.eaf` | `eaf` | 98955 | tracked | Quản lý nguồn/pin/charger của board `battery_connected.eaf` trong `main/boards/espressif/esp-vocat`. |
| `main/boards/espressif/esp-vocat/emoji/low_battery.eaf` | `eaf` | 129314 | tracked | Quản lý nguồn/pin/charger của board `low_battery.eaf` trong `main/boards/espressif/esp-vocat`. |
| `main/boards/espressif/esp-vocat/esp_vocat.cc` | `cc` | 45064 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp_vocat.cc` trong `main/boards/espressif/esp-vocat`. Key types/methods: `EspVocat`, `Charge`, `Cst816s`, `TouchPoint_t`, `TouchEvent`, `bmi2_sens_data`. |
| `main/boards/espressif/esp-vocat/touch.h` | `h` | 1197 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `touch.h` trong `main/boards/espressif/esp-vocat`. |
| `main/boards/espressif/esp32-p4-function-ev-board/README.md` | `md` | 2169 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/espressif/esp32-p4-function-ev-board`. Main section: ESP32-P4-Function-EV-Board / ESP32-P4X-Function-EV-Board. |
| `main/boards/espressif/esp32-p4-function-ev-board/config.h` | `h` | 1238 | tracked | Pin map và compile-time hardware options cho board `main/boards/espressif/esp32-p4-function-ev-board`. |
| `main/boards/espressif/esp32-p4-function-ev-board/config.json` | `json` | 1032 | tracked | Board/release config: target `esp32p4`, type `esp32-p4-function-ev-board`, variants: esp32-p4-function-ev-board, esp32-p4x-function-ev-board. |
| `main/boards/espressif/esp32-p4-function-ev-board/esp32-p4-function-ev-board.cc` | `cc` | 10579 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32-p4-function-ev-board.cc` trong `main/boards/espressif/esp32-p4-function-ev-board`. Key types/methods: `ESP32P4FunctionEvBoard`. |
| `main/boards/espressif/esp32-s3-box-3/README.md` | `md` | 4262 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/espressif/esp32-s3-box-3`. Main section: ESP32-S3-BOX-3. |
| `main/boards/espressif/esp32-s3-box-3/config.h` | `h` | 1143 | tracked | Pin map và compile-time hardware options cho board `main/boards/espressif/esp32-s3-box-3`. |
| `main/boards/espressif/esp32-s3-box-3/config.json` | `json` | 252 | tracked | Board/release config: target `esp32s3`, type `esp-box-3`, variants: esp-box-3. |
| `main/boards/espressif/esp32-s3-box-3/esp_box3_board.cc` | `cc` | 6078 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp_box3_board.cc` trong `main/boards/espressif/esp32-s3-box-3`. Key types/methods: `EspBox3Board`. |
| `main/boards/espressif/esp32-s3-box-lite/box_audio_codec_lite.cc` | `cc` | 10249 | tracked | Cấu hình hoặc driver audio codec của board `box_audio_codec_lite.cc` trong `main/boards/espressif/esp32-s3-box-lite`. Key types/methods: `BoxAudioCodecLite::CreateDuplexChannels`, `BoxAudioCodecLite::SetOutputVolume`, `BoxAudioCodecLite::EnableInput`, `BoxAudioCodecLite::EnableOutput`, `BoxAudioCodecLite::Read`, `BoxAudioCodecLite::Write`. |
| `main/boards/espressif/esp32-s3-box-lite/box_audio_codec_lite.h` | `h` | 1694 | tracked | Cấu hình hoặc driver audio codec của board `box_audio_codec_lite.h` trong `main/boards/espressif/esp32-s3-box-lite`. Key types/methods: `BoxAudioCodecLite`. |
| `main/boards/espressif/esp32-s3-box-lite/config.h` | `h` | 1044 | tracked | Pin map và compile-time hardware options cho board `main/boards/espressif/esp32-s3-box-lite`. |
| `main/boards/espressif/esp32-s3-box-lite/config.json` | `json` | 261 | tracked | Board/release config: target `esp32s3`, type `esp-box-lite`, variants: esp-box-lite. |
| `main/boards/espressif/esp32-s3-box-lite/esp_box_lite_board.cc` | `cc` | 8299 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp_box_lite_board.cc` trong `main/boards/espressif/esp32-s3-box-lite`. Key types/methods: `EspBoxBoardLite`. |
| `main/boards/espressif/esp32-s3-box/config.h` | `h` | 1143 | tracked | Pin map và compile-time hardware options cho board `main/boards/espressif/esp32-s3-box`. |
| `main/boards/espressif/esp32-s3-box/config.json` | `json` | 193 | tracked | Board/release config: target `esp32s3`, type `esp-box`, variants: esp-box. |
| `main/boards/espressif/esp32-s3-box/esp_box_board.cc` | `cc` | 6080 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp_box_board.cc` trong `main/boards/espressif/esp32-s3-box`. Key types/methods: `EspBox3Board`. |
| `main/boards/espressif/esp32-s3-korvo-2-v3.0-rndis/config.h` | `h` | 2299 | tracked | Pin map và compile-time hardware options cho board `main/boards/espressif/esp32-s3-korvo-2-v3.0-rndis`. |
| `main/boards/espressif/esp32-s3-korvo-2-v3.0-rndis/config.json` | `json` | 362 | tracked | Board/release config: target `esp32s3`, type `esp32s3-korvo2-v3-rndis`, variants: esp32s3-korvo2-v3-rndis. |
| `main/boards/espressif/esp32-s3-korvo-2-v3.0-rndis/esp32s3_korvo2_v3_board.cc` | `cc` | 16635 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32s3_korvo2_v3_board.cc` trong `main/boards/espressif/esp32-s3-korvo-2-v3.0-rndis`. Key types/methods: `Esp32S3Korvo2V3Board`. |
| `main/boards/espressif/esp32-s3-korvo-2-v3.0-rndis/power_manager.h` | `h` | 9046 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/espressif/esp32-s3-korvo-2-v3.0-rndis`. Key types/methods: `PowerManager`. |
| `main/boards/espressif/esp32-s3-korvo-2-v3.0/config.h` | `h` | 2299 | tracked | Pin map và compile-time hardware options cho board `main/boards/espressif/esp32-s3-korvo-2-v3.0`. |
| `main/boards/espressif/esp32-s3-korvo-2-v3.0/config.json` | `json` | 350 | tracked | Board/release config: target `esp32s3`, type `esp32s3-korvo2-v3`, variants: esp32s3-korvo2-v3. |
| `main/boards/espressif/esp32-s3-korvo-2-v3.0/esp32s3_korvo2_v3_board.cc` | `cc` | 16799 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32s3_korvo2_v3_board.cc` trong `main/boards/espressif/esp32-s3-korvo-2-v3.0`. Key types/methods: `Esp32S3Korvo2V3Board`. |
| `main/boards/espressif/esp32-s3-korvo-2-v3.0/power_manager.h` | `h` | 9116 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/espressif/esp32-s3-korvo-2-v3.0`. Key types/methods: `PowerManager`. |
| `main/boards/espressif/esp32-s3-lcd-ev-board-2/README.md` | `md` | 481 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/espressif/esp32-s3-lcd-ev-board-2`. Main section: ESP32-S3-LCD-EV-Board-2. |
| `main/boards/espressif/esp32-s3-lcd-ev-board-2/config.h` | `h` | 1078 | tracked | Pin map và compile-time hardware options cho board `main/boards/espressif/esp32-s3-lcd-ev-board-2`. |
| `main/boards/espressif/esp32-s3-lcd-ev-board-2/config.json` | `json` | 221 | tracked | Board/release config: target `esp32s3`, type `esp-s3-lcd-ev-board-2`, variants: esp-s3-lcd-ev-board-2. |
| `main/boards/espressif/esp32-s3-lcd-ev-board-2/esp32-s3-lcd-ev-board-2.cc` | `cc` | 9576 | tracked | Driver hoặc UI/display resource riêng của board `esp32-s3-lcd-ev-board-2.cc` trong `main/boards/espressif/esp32-s3-lcd-ev-board-2`. Key types/methods: `ESP_S3_LCD_EV_Board_2`. |
| `main/boards/espressif/esp32-s3-lcd-ev-board-2/esp_lcd_gc9503.c` | `c` | 23253 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_gc9503.c` trong `main/boards/espressif/esp32-s3-lcd-ev-board-2`. |
| `main/boards/espressif/esp32-s3-lcd-ev-board-2/esp_lcd_gc9503.h` | `h` | 6917 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_gc9503.h` trong `main/boards/espressif/esp32-s3-lcd-ev-board-2`. |
| `main/boards/espressif/esp32-s3-lcd-ev-board-2/pin_config.h` | `h` | 2004 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `pin_config.h` trong `main/boards/espressif/esp32-s3-lcd-ev-board-2`. |
| `main/boards/espressif/esp32-s3-lcd-ev-board/README.md` | `md` | 480 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/espressif/esp32-s3-lcd-ev-board`. Main section: ESP32-S3-LCD-EV-Board. |
| `main/boards/espressif/esp32-s3-lcd-ev-board/config.h` | `h` | 1335 | tracked | Pin map và compile-time hardware options cho board `main/boards/espressif/esp32-s3-lcd-ev-board`. |
| `main/boards/espressif/esp32-s3-lcd-ev-board/config.json` | `json` | 565 | tracked | Board/release config: target `esp32s3`, type `esp-s3-lcd-ev-board`, variants: esp-s3-lcd-ev-board-1p4, esp-s3-lcd-ev-board-1p5. |
| `main/boards/espressif/esp32-s3-lcd-ev-board/esp32-s3-lcd-ev-board.cc` | `cc` | 8273 | tracked | Driver hoặc UI/display resource riêng của board `esp32-s3-lcd-ev-board.cc` trong `main/boards/espressif/esp32-s3-lcd-ev-board`. Key types/methods: `ESP_S3_LCD_EV_Board`. |
| `main/boards/espressif/esp32-s3-lcd-ev-board/esp_io_expander_tca9554.c` | `c` | 5528 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp_io_expander_tca9554.c` trong `main/boards/espressif/esp32-s3-lcd-ev-board`. |
| `main/boards/espressif/esp32-s3-lcd-ev-board/esp_io_expander_tca9554.h` | `h` | 3889 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `esp_io_expander_tca9554.h` trong `main/boards/espressif/esp32-s3-lcd-ev-board`. |
| `main/boards/espressif/esp32-s3-lcd-ev-board/esp_lcd_gc9503.c` | `c` | 23253 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_gc9503.c` trong `main/boards/espressif/esp32-s3-lcd-ev-board`. |
| `main/boards/espressif/esp32-s3-lcd-ev-board/esp_lcd_gc9503.h` | `h` | 7897 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_gc9503.h` trong `main/boards/espressif/esp32-s3-lcd-ev-board`. |
| `main/boards/espressif/esp32-s3-lcd-ev-board/pin_config.h` | `h` | 2267 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `pin_config.h` trong `main/boards/espressif/esp32-s3-lcd-ev-board`. |
| `main/boards/espressif/esp32-s31-function-coreboard-1/README.md` | `md` | 2342 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/espressif/esp32-s31-function-coreboard-1`. Main section: ESP32-S31-Function-CoreBoard-1. |
| `main/boards/espressif/esp32-s31-function-coreboard-1/config.h` | `h` | 729 | tracked | Pin map và compile-time hardware options cho board `main/boards/espressif/esp32-s31-function-coreboard-1`. |
| `main/boards/espressif/esp32-s31-function-coreboard-1/config.json` | `json` | 261 | tracked | Board/release config: target `esp32s31`, type `esp32-s31-function-coreboard-1`, variants: esp32-s31-function-coreboard-1. |
| `main/boards/espressif/esp32-s31-function-coreboard-1/esp32_s31_function_coreboard_1.cc` | `cc` | 1902 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32_s31_function_coreboard_1.cc` trong `main/boards/espressif/esp32-s31-function-coreboard-1`. Key types/methods: `Esp32S31FunctionCoreBoard1`. |
| `main/boards/espressif/esp32-s31-korvo-1/README.md` | `md` | 3121 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/espressif/esp32-s31-korvo-1`. Main section: ESP32-S31-Korvo-1. |
| `main/boards/espressif/esp32-s31-korvo-1/bsp_adc_calibration.h` | `h` | 659 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `bsp_adc_calibration.h` trong `main/boards/espressif/esp32-s31-korvo-1`. |
| `main/boards/espressif/esp32-s31-korvo-1/config.h` | `h` | 3499 | tracked | Pin map và compile-time hardware options cho board `main/boards/espressif/esp32-s31-korvo-1`. |
| `main/boards/espressif/esp32-s31-korvo-1/config.json` | `json` | 448 | tracked | Board/release config: target `esp32s31`, type `esp32-s31-korvo-1`, variants: esp32-s31-korvo-1. |
| `main/boards/espressif/esp32-s31-korvo-1/esp32_s31_adc_calibration.c` | `c` | 8840 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32_s31_adc_calibration.c` trong `main/boards/espressif/esp32-s31-korvo-1`. |
| `main/boards/espressif/esp32-s31-korvo-1/esp32_s31_korvo_1.cc` | `cc` | 13105 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32_s31_korvo_1.cc` trong `main/boards/espressif/esp32-s31-korvo-1`. Key types/methods: `Esp32S31Korvo1`. |
| `main/boards/folotoy/ai-passport/README.md` | `md` | 15491 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/folotoy/ai-passport`. Main section: FoloToy AI Passport (ai-passport). |
| `main/boards/folotoy/ai-passport/ai_passport_board.cc` | `cc` | 46761 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `ai_passport_board.cc` trong `main/boards/folotoy/ai-passport`. Key types/methods: `Es8311RegValue`, `AiPassportAudioCodec`, `PassportAdcButton`, `AiPassportBoard`. |
| `main/boards/folotoy/ai-passport/config.h` | `h` | 3074 | tracked | Pin map và compile-time hardware options cho board `main/boards/folotoy/ai-passport`. |
| `main/boards/folotoy/ai-passport/config.json` | `json` | 542 | tracked | Board/release config: target `esp32c3`, type `ai-passport`, variants: ai-passport. |
| `main/boards/folotoy/ai-passport/cw2017_battery_monitor.cc` | `cc` | 5551 | tracked | Quản lý nguồn/pin/charger của board `cw2017_battery_monitor.cc` trong `main/boards/folotoy/ai-passport`. Key types/methods: `Cw2017BatteryMonitor::ReadReg`, `Cw2017BatteryMonitor::WriteReg`, `Cw2017BatteryMonitor::ReadReg16`, `Cw2017BatteryMonitor::Initialize`, `Cw2017BatteryMonitor::EnterSleep`, `Cw2017BatteryMonitor::GetBatteryLevel`, `Cw2017BatteryMonitor::GetBatteryVoltageMv`. |
| `main/boards/folotoy/ai-passport/cw2017_battery_monitor.h` | `h` | 1614 | tracked | Quản lý nguồn/pin/charger của board `cw2017_battery_monitor.h` trong `main/boards/folotoy/ai-passport`. Key types/methods: `Cw2017BatteryMonitor`. |
| `main/boards/freenove-esp32s3-display-2.8-lcd/ReadMe.md` | `md` | 372 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/freenove-esp32s3-display-2.8-lcd`. Main section: Freenove ESP32-S3 ESP32 S3 Capacitive Touch Display CYD WiFi BT, 2.8 Inch 240x320 IPS Screen. |
| `main/boards/freenove-esp32s3-display-2.8-lcd/config.h` | `h` | 1656 | tracked | Pin map và compile-time hardware options cho board `main/boards/freenove-esp32s3-display-2.8-lcd`. |
| `main/boards/freenove-esp32s3-display-2.8-lcd/config.json` | `json` | 174 | tracked | Board/release config: target `esp32s3`, type `freenove-esp32s3-display-2.8-lcd`, variants: freenove-esp32s3-display-2.8-lcd. |
| `main/boards/freenove-esp32s3-display-2.8-lcd/freenove-esp32s3-display-2.8-lcd.cc` | `cc` | 7699 | tracked | Driver hoặc UI/display resource riêng của board `freenove-esp32s3-display-2.8-lcd.cc` trong `main/boards/freenove-esp32s3-display-2.8-lcd`. Key types/methods: `TouchDriver`, `FreenoveESP32S3Display`. |
| `main/boards/genjutech-s3-1.54tft/config.h` | `h` | 1222 | tracked | Pin map và compile-time hardware options cho board `main/boards/genjutech-s3-1.54tft`. |
| `main/boards/genjutech-s3-1.54tft/config.json` | `json` | 185 | tracked | Board/release config: target `esp32s3`, type `genjutech-s3-1.54tft`, variants: genjutech-s3-1.54tft. |
| `main/boards/genjutech-s3-1.54tft/genjutech-s3-1.54tft.cc` | `cc` | 9518 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `genjutech-s3-1.54tft.cc` trong `main/boards/genjutech-s3-1.54tft`. Key types/methods: `SparkBotEs8311AudioCodec`, `GenJuTech_s3_1_54TFT`. |
| `main/boards/genjutech-s3-1.54tft/power_manager.h` | `h` | 6007 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/genjutech-s3-1.54tft`. Key types/methods: `PowerManager`. |
| `main/boards/guition/jc4827w543/README.md` | `md` | 6188 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/guition/jc4827w543`. Main section: Guition JC4827W543. |
| `main/boards/guition/jc4827w543/config.h` | `h` | 3917 | tracked | Pin map và compile-time hardware options cho board `main/boards/guition/jc4827w543`. |
| `main/boards/guition/jc4827w543/config.json` | `json` | 871 | tracked | Board/release config: target `esp32s3`, type `guition-jc4827w543`, variants: guition-jc4827w543, guition-jc4827w543-ext-amp. |
| `main/boards/guition/jc4827w543/esp_lcd_nv3041a.c` | `c` | 10640 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_nv3041a.c` trong `main/boards/guition/jc4827w543`. |
| `main/boards/guition/jc4827w543/esp_lcd_nv3041a.h` | `h` | 1481 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_nv3041a.h` trong `main/boards/guition/jc4827w543`. |
| `main/boards/guition/jc4827w543/jc4827w543_board.cc` | `cc` | 11794 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `jc4827w543_board.cc` trong `main/boards/guition/jc4827w543`. Key types/methods: `JC4827W543Display`, `JC4827W543Board`. |
| `main/boards/hu-087/README.md` | `md` | 420 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/hu-087`. Main section: Programming ##. |
| `main/boards/hu-087/config.h` | `h` | 724 | tracked | Pin map và compile-time hardware options cho board `main/boards/hu-087`. |
| `main/boards/hu-087/config.json` | `json` | 158 | tracked | Board/release config: target `esp32s3`, type `hu-087`, variants: hu-087. |
| `main/boards/hu-087/hu_087_board.cc` | `cc` | 5186 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `hu_087_board.cc` trong `main/boards/hu-087`. Key types/methods: `Hu087Board`. |
| `main/boards/jiuchuan-s3/README.md` | `md` | 1416 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/jiuchuan-s3`. Main section: jiuchuan-xiaozhi-sound. |
| `main/boards/jiuchuan-s3/config.h` | `h` | 1432 | tracked | Pin map và compile-time hardware options cho board `main/boards/jiuchuan-s3`. |
| `main/boards/jiuchuan-s3/config.json` | `json` | 167 | tracked | Board/release config: target `esp32s3`, type `jiuchuan-s3`, variants: jiuchuan-s3. |
| `main/boards/jiuchuan-s3/esp_lcd_panel_gc9301.c` | `c` | 17229 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_panel_gc9301.c` trong `main/boards/jiuchuan-s3`. |
| `main/boards/jiuchuan-s3/esp_lcd_panel_gc9301.h` | `h` | 820 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_panel_gc9301.h` trong `main/boards/jiuchuan-s3`. |
| `main/boards/jiuchuan-s3/gpio_manager.h` | `h` | 1906 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `gpio_manager.h` trong `main/boards/jiuchuan-s3`. Key types/methods: `GpioManager`, `GpioMode`. |
| `main/boards/jiuchuan-s3/jiuchuan_dev_board.cc` | `cc` | 15104 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `jiuchuan_dev_board.cc` trong `main/boards/jiuchuan-s3`. Key types/methods: `CustomLcdDisplay`, `JiuchuanDevBoard`. |
| `main/boards/jiuchuan-s3/power_controller.h` | `h` | 1477 | tracked | Quản lý nguồn/pin/charger của board `power_controller.h` trong `main/boards/jiuchuan-s3`. Key types/methods: `PowerState`, `PowerController`. |
| `main/boards/jiuchuan-s3/power_manager.h` | `h` | 6840 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/jiuchuan-s3`. Key types/methods: `PowerManager`. |
| `main/boards/kevin/box-2/config.h` | `h` | 1132 | tracked | Pin map và compile-time hardware options cho board `main/boards/kevin/box-2`. |
| `main/boards/kevin/box-2/config.json` | `json` | 238 | tracked | Board/release config: target `esp32s3`, type `kevin-box-2`, variants: kevin-box-2. |
| `main/boards/kevin/box-2/kevin_box_board.cc` | `cc` | 9645 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `kevin_box_board.cc` trong `main/boards/kevin/box-2`. Key types/methods: `Pmic`, `KevinBoxBoard`. |
| `main/boards/kevin/c3/config.h` | `h` | 661 | tracked | Pin map và compile-time hardware options cho board `main/boards/kevin/c3`. |
| `main/boards/kevin/c3/config.json` | `json` | 297 | tracked | Board/release config: target `esp32c3`, type `kevin-c3`, variants: kevin-c3. |
| `main/boards/kevin/c3/kevin_c3_board.cc` | `cc` | 2837 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `kevin_c3_board.cc` trong `main/boards/kevin/c3`. Key types/methods: `KevinBoxBoard`. |
| `main/boards/kevin/c3/led_strip_control.cc` | `cc` | 5593 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `led_strip_control.cc` trong `main/boards/kevin/c3`. Key types/methods: `LedStripControl::LevelToBrightness`, `LedStripControl::RGBToColor`. |
| `main/boards/kevin/c3/led_strip_control.h` | `h` | 444 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `led_strip_control.h` trong `main/boards/kevin/c3`. Key types/methods: `LedStripControl`. |
| `main/boards/kevin/sp-v3-dev/config.h` | `h` | 1687 | tracked | Pin map và compile-time hardware options cho board `main/boards/kevin/sp-v3-dev`. |
| `main/boards/kevin/sp-v3-dev/kevin-sp-v3_board.cc` | `cc` | 5503 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `kevin-sp-v3_board.cc` trong `main/boards/kevin/sp-v3-dev`. Key types/methods: `KEVIN_SP_V3Board`. |
| `main/boards/kevin/sp-v4-dev/config.h` | `h` | 1918 | tracked | Pin map và compile-time hardware options cho board `main/boards/kevin/sp-v4-dev`. |
| `main/boards/kevin/sp-v4-dev/config.json` | `json` | 218 | tracked | Board/release config: target `esp32s3`, type `kevin-sp-v4-dev`, variants: kevin-sp-v4-dev. |
| `main/boards/kevin/sp-v4-dev/kevin-sp-v4_board.cc` | `cc` | 6062 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `kevin-sp-v4_board.cc` trong `main/boards/kevin/sp-v4-dev`. Key types/methods: `KEVIN_SP_V4Board`. |
| `main/boards/kevin/yuying-313lcd/config.h` | `h` | 955 | tracked | Pin map và compile-time hardware options cho board `main/boards/kevin/yuying-313lcd`. |
| `main/boards/kevin/yuying-313lcd/config.json` | `json` | 213 | tracked | Board/release config: target `esp32s3`, type `kevin-yuying-313lcd`, variants: kevin-yuying-313lcd. |
| `main/boards/kevin/yuying-313lcd/esp_lcd_gc9503.c` | `c` | 22603 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_gc9503.c` trong `main/boards/kevin/yuying-313lcd`. |
| `main/boards/kevin/yuying-313lcd/esp_lcd_gc9503.h` | `h` | 6975 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_gc9503.h` trong `main/boards/kevin/yuying-313lcd`. |
| `main/boards/kevin/yuying-313lcd/kevin_yuying_313lcd.cc` | `cc` | 5900 | tracked | Driver hoặc UI/display resource riêng của board `kevin_yuying_313lcd.cc` trong `main/boards/kevin/yuying-313lcd`. Key types/methods: `Yuying_313lcd`. |
| `main/boards/kevin/yuying-313lcd/pin_config.h` | `h` | 1781 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `pin_config.h` trong `main/boards/kevin/yuying-313lcd`. |
| `main/boards/labplus/ledong-v2/README.md` | `md` | 1321 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/labplus/ledong-v2`. Main section: labplus 乐动掌控V2. |
| `main/boards/labplus/ledong-v2/config.h` | `h` | 1070 | tracked | Pin map và compile-time hardware options cho board `main/boards/labplus/ledong-v2`. |
| `main/boards/labplus/ledong-v2/config.json` | `json` | 211 | tracked | Board/release config: target `esp32s3`, type `labplus-ledong-v2`, variants: labplus-ledong-v2. |
| `main/boards/labplus/ledong-v2/labplus_ledong_v2.cc` | `cc` | 5446 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `labplus_ledong_v2.cc` trong `main/boards/labplus/ledong-v2`. Key types/methods: `labplus_ledong_v2`. |
| `main/boards/labplus/mpython-v3/README.md` | `md` | 1290 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/labplus/mpython-v3`. Main section: labplus 掌控板V3. |
| `main/boards/labplus/mpython-v3/config.h` | `h` | 1069 | tracked | Pin map và compile-time hardware options cho board `main/boards/labplus/mpython-v3`. |
| `main/boards/labplus/mpython-v3/config.json` | `json` | 213 | tracked | Board/release config: target `esp32s3`, type `labplus-mpython-v3`, variants: labplus-mpython-v3. |
| `main/boards/labplus/mpython-v3/mpython_pro.cc` | `cc` | 4824 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `mpython_pro.cc` trong `main/boards/labplus/mpython-v3`. Key types/methods: `mpython_v3`. |
| `main/boards/lc-s3-wifi-1.54tft/README.md` | `md` | 518 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/lc-s3-wifi-1.54tft`. Main section: LC-S3-WIFI-1.54TFT. |
| `main/boards/lc-s3-wifi-1.54tft/config.h` | `h` | 1384 | tracked | Pin map và compile-time hardware options cho board `main/boards/lc-s3-wifi-1.54tft`. |
| `main/boards/lc-s3-wifi-1.54tft/config.json` | `json` | 181 | tracked | Board/release config: target `esp32s3`, type `lc-s3-wifi-1.54tft`, variants: lc-s3-wifi-1.54tft. |
| `main/boards/lc-s3-wifi-1.54tft/lc-s3-wifi-1.54tft.cc` | `cc` | 8259 | tracked | Tích hợp mạng riêng của board `lc-s3-wifi-1.54tft.cc` trong `main/boards/lc-s3-wifi-1.54tft`. Key types/methods: `lc_s3_wifi_1_54tft`. |
| `main/boards/lc-s3-wifi-1.54tft/power_manager.h` | `h` | 5998 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/lc-s3-wifi-1.54tft`. Key types/methods: `PowerManager`. |
| `main/boards/lcdwiki-es3c35p/README.md` | `md` | 4731 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/lcdwiki-es3c35p`. Main section: LCD Wiki ES3C35P. |
| `main/boards/lcdwiki-es3c35p/config.h` | `h` | 1684 | tracked | Pin map và compile-time hardware options cho board `main/boards/lcdwiki-es3c35p`. |
| `main/boards/lcdwiki-es3c35p/config.json` | `json` | 140 | tracked | Board/release config: target `esp32s3`, type `lcdwiki-es3c35p`, variants: lcdwiki-es3c35p. |
| `main/boards/lcdwiki-es3c35p/lcdwiki-es3c35p.cc` | `cc` | 15129 | tracked | Driver hoặc UI/display resource riêng của board `lcdwiki-es3c35p.cc` trong `main/boards/lcdwiki-es3c35p`. Key types/methods: `ST77922_Display`, `LCDWikiES3C35P_Board`. |
| `main/boards/lceda-course-examples/eda-robot-pro/README.md` | `md` | 404 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/lceda-course-examples/eda-robot-pro`. Main section: EDA-Robot-Pro 机器狗. |
| `main/boards/lceda-course-examples/eda-robot-pro/config.h` | `h` | 1172 | tracked | Pin map và compile-time hardware options cho board `main/boards/lceda-course-examples/eda-robot-pro`. |
| `main/boards/lceda-course-examples/eda-robot-pro/config.json` | `json` | 360 | tracked | Board/release config: target `esp32s3`, type `eda-robot-pro`, variants: eda-robot-pro. |
| `main/boards/lceda-course-examples/eda-robot-pro/eda_dog_controller.cc` | `cc` | 15822 | tracked | Điều khiển chức năng robot/peripheral riêng của board `eda_dog_controller.cc` trong `main/boards/lceda-course-examples/eda-robot-pro`. Key types/methods: `EDARobotDogController`, `DogActionParams`, `ActionType`. |
| `main/boards/lceda-course-examples/eda-robot-pro/eda_dog_movements.cc` | `cc` | 17005 | tracked | Điều khiển chức năng robot/peripheral riêng của board `eda_dog_movements.cc` trong `main/boards/lceda-course-examples/eda-robot-pro`. Key types/methods: `EDARobotDog::Init`, `EDARobotDog::AttachServos`, `EDARobotDog::DetachServos`, `EDARobotDog::SetTrims`, `EDARobotDog::MoveServos`, `EDARobotDog::MoveSingle`, `EDARobotDog::OscillateServos`, `EDARobotDog::Execute`. |
| `main/boards/lceda-course-examples/eda-robot-pro/eda_dog_movements.h` | `h` | 2743 | tracked | Điều khiển chức năng robot/peripheral riêng của board `eda_dog_movements.h` trong `main/boards/lceda-course-examples/eda-robot-pro`. Key types/methods: `EDARobotDog`. |
| `main/boards/lceda-course-examples/eda-robot-pro/eda_robot_pro.cc` | `cc` | 4153 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `eda_robot_pro.cc` trong `main/boards/lceda-course-examples/eda-robot-pro`. Key types/methods: `EDARobotPro`. |
| `main/boards/lceda-course-examples/eda-robot-pro/oscillator.cc` | `cc` | 4334 | tracked | Điều khiển chức năng robot/peripheral riêng của board `oscillator.cc` trong `main/boards/lceda-course-examples/eda-robot-pro`. Key types/methods: `Oscillator::AngleToCompare`, `Oscillator::NextSample`, `Oscillator::Attach`, `Oscillator::Detach`, `Oscillator::SetT`, `Oscillator::SetPosition`, `Oscillator::Refresh`, `Oscillator::Write`. |
| `main/boards/lceda-course-examples/eda-robot-pro/oscillator.h` | `h` | 2827 | tracked | Điều khiển chức năng robot/peripheral riêng của board `oscillator.h` trong `main/boards/lceda-course-examples/eda-robot-pro`. Key types/methods: `Oscillator`. |
| `main/boards/lceda-course-examples/eda-super-bear/README.md` | `md` | 414 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/lceda-course-examples/eda-super-bear`. Main section: EDA-Super-Bear 机器熊. |
| `main/boards/lceda-course-examples/eda-super-bear/config.h` | `h` | 809 | tracked | Pin map và compile-time hardware options cho board `main/boards/lceda-course-examples/eda-super-bear`. |
| `main/boards/lceda-course-examples/eda-super-bear/config.json` | `json` | 314 | tracked | Board/release config: target `esp32s3`, type `eda-super-bear`, variants: eda-super-bear. |
| `main/boards/lceda-course-examples/eda-super-bear/eda_super_bear.cc` | `cc` | 1721 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `eda_super_bear.cc` trong `main/boards/lceda-course-examples/eda-super-bear`. Key types/methods: `EdaSuperBear`. |
| `main/boards/lceda-course-examples/eda-super-bear/eda_super_bear_controller.cc` | `cc` | 25776 | tracked | Điều khiển chức năng robot/peripheral riêng của board `eda_super_bear_controller.cc` trong `main/boards/lceda-course-examples/eda-super-bear`. Key types/methods: `EdaSuperBearController`, `EdaRobotActionParams`, `ActionType`. |
| `main/boards/lceda-course-examples/eda-super-bear/eda_super_bear_movements.cc` | `cc` | 27207 | tracked | Điều khiển chức năng robot/peripheral riêng của board `eda_super_bear_movements.cc` trong `main/boards/lceda-course-examples/eda-super-bear`. Key types/methods: `EdaRobot::Init`, `EdaRobot::AttachServos`, `EdaRobot::DetachServos`, `EdaRobot::SetTrims`, `EdaRobot::MoveServos`, `EdaRobot::MoveSingle`, `EdaRobot::OscillateServos`, `EdaRobot::Execute`. |
| `main/boards/lceda-course-examples/eda-super-bear/eda_super_bear_movements.h` | `h` | 3511 | tracked | Điều khiển chức năng robot/peripheral riêng của board `eda_super_bear_movements.h` trong `main/boards/lceda-course-examples/eda-super-bear`. Key types/methods: `EdaRobot`. |
| `main/boards/lceda-course-examples/eda-super-bear/oscillator.cc` | `cc` | 4335 | tracked | Điều khiển chức năng robot/peripheral riêng của board `oscillator.cc` trong `main/boards/lceda-course-examples/eda-super-bear`. Key types/methods: `Oscillator::AngleToCompare`, `Oscillator::NextSample`, `Oscillator::Attach`, `Oscillator::Detach`, `Oscillator::SetT`, `Oscillator::SetPosition`, `Oscillator::Refresh`, `Oscillator::Write`. |
| `main/boards/lceda-course-examples/eda-super-bear/oscillator.h` | `h` | 2935 | tracked | Điều khiển chức năng robot/peripheral riêng của board `oscillator.h` trong `main/boards/lceda-course-examples/eda-super-bear`. Key types/methods: `Oscillator`. |
| `main/boards/lceda-course-examples/eda-tv-pro/README.md` | `md` | 383 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/lceda-course-examples/eda-tv-pro`. Main section: EDA-TV-Pro 小电视. |
| `main/boards/lceda-course-examples/eda-tv-pro/config.h` | `h` | 1296 | tracked | Pin map và compile-time hardware options cho board `main/boards/lceda-course-examples/eda-tv-pro`. |
| `main/boards/lceda-course-examples/eda-tv-pro/config.json` | `json` | 275 | tracked | Board/release config: target `esp32s3`, type `eda-tv-pro`, variants: eda-tv-pro. |
| `main/boards/lceda-course-examples/eda-tv-pro/eda-tv-pro.cc` | `cc` | 4183 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `eda-tv-pro.cc` trong `main/boards/lceda-course-examples/eda-tv-pro`. Key types/methods: `eda_tv_pro`. |
| `main/boards/lckfb/szpi-esp32c3/README.md` | `md` | 323 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/lckfb/szpi-esp32c3`. Main section: 立创·实战派ESP32-C3开发板. |
| `main/boards/lckfb/szpi-esp32c3/config.h` | `h` | 1286 | tracked | Pin map và compile-time hardware options cho board `main/boards/lckfb/szpi-esp32c3`. |
| `main/boards/lckfb/szpi-esp32c3/config.json` | `json` | 408 | tracked | Board/release config: target `esp32c3`, type `lichuang-c3-dev`, variants: lichuang-c3-dev. |
| `main/boards/lckfb/szpi-esp32c3/lichuang_c3_dev_board.cc` | `cc` | 4399 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `lichuang_c3_dev_board.cc` trong `main/boards/lckfb/szpi-esp32c3`. Key types/methods: `LichuangC3DevBoard`. |
| `main/boards/lckfb/szpi-esp32s3/config.h` | `h` | 1712 | tracked | Pin map và compile-time hardware options cho board `main/boards/lckfb/szpi-esp32s3`. |
| `main/boards/lckfb/szpi-esp32s3/config.json` | `json` | 254 | tracked | Board/release config: target `esp32s3`, type `lichuang-dev`, variants: lichuang-dev. |
| `main/boards/lckfb/szpi-esp32s3/lichuang_dev_board.cc` | `cc` | 10896 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `lichuang_dev_board.cc` trong `main/boards/lckfb/szpi-esp32s3`. Key types/methods: `Pca9557`, `CustomAudioCodec`, `LichuangDevBoard`. |
| `main/boards/lilygo/t-cameraplus-s3/README.md` | `md` | 1383 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/lilygo/t-cameraplus-s3`. Main section: LILYGO T-CameraPlus-S3. |
| `main/boards/lilygo/t-cameraplus-s3/config.h` | `h` | 1693 | tracked | Pin map và compile-time hardware options cho board `main/boards/lilygo/t-cameraplus-s3`. |
| `main/boards/lilygo/t-cameraplus-s3/config.json` | `json` | 1116 | tracked | Board/release config: target `esp32s3`, type `lilygo-t-cameraplus-s3`, variants: lilygo-t-cameraplus-s3, lilygo-t-cameraplus-s3-v1.2. |
| `main/boards/lilygo/t-cameraplus-s3/ir_filter_controller.h` | `h` | 1551 | tracked | Điều khiển chức năng robot/peripheral riêng của board `ir_filter_controller.h` trong `main/boards/lilygo/t-cameraplus-s3`. Key types/methods: `IrFilterController`. |
| `main/boards/lilygo/t-cameraplus-s3/lilygo-t-cameraplus-s3.cc` | `cc` | 11175 | tracked | Camera/video integration riêng của board `lilygo-t-cameraplus-s3.cc` trong `main/boards/lilygo/t-cameraplus-s3`. Key types/methods: `Cst816x`, `TouchPoint_t`, `Pmic`, `LilygoTCameraPlusS3Board`. |
| `main/boards/lilygo/t-cameraplus-s3/pin_config.h` | `h` | 3133 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `pin_config.h` trong `main/boards/lilygo/t-cameraplus-s3`. |
| `main/boards/lilygo/t-cameraplus-s3/tcamerapluss3_audio_codec.cc` | `cc` | 6258 | tracked | Cấu hình hoặc driver audio codec của board `tcamerapluss3_audio_codec.cc` trong `main/boards/lilygo/t-cameraplus-s3`. Key types/methods: `Tcamerapluss3AudioCodec::CreateVoiceHardware`, `Tcamerapluss3AudioCodec::SetOutputVolume`, `Tcamerapluss3AudioCodec::EnableInput`, `Tcamerapluss3AudioCodec::EnableOutput`, `Tcamerapluss3AudioCodec::Read`, `Tcamerapluss3AudioCodec::Write`. |
| `main/boards/lilygo/t-cameraplus-s3/tcamerapluss3_audio_codec.h` | `h` | 1347 | tracked | Cấu hình hoặc driver audio codec của board `tcamerapluss3_audio_codec.h` trong `main/boards/lilygo/t-cameraplus-s3`. Key types/methods: `Tcamerapluss3AudioCodec`. |
| `main/boards/lilygo/t-circle-s3-v11/README.md` | `md` | 2254 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/lilygo/t-circle-s3-v11`. Main section: LILYGO T-Circle-S3 V1.1. |
| `main/boards/lilygo/t-circle-s3-v11/config.h` | `h` | 1974 | tracked | Pin map và compile-time hardware options cho board `main/boards/lilygo/t-circle-s3-v11`. |
| `main/boards/lilygo/t-circle-s3-v11/config.json` | `json` | 220 | tracked | Board/release config: target `esp32s3`, type `lilygo-t-circle-s3-v11`, variants: lilygo-t-circle-s3-v11. |
| `main/boards/lilygo/t-circle-s3-v11/esp_lcd_gc9d01n.c` | `c` | 14869 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_gc9d01n.c` trong `main/boards/lilygo/t-circle-s3-v11`. |
| `main/boards/lilygo/t-circle-s3-v11/esp_lcd_gc9d01n.h` | `h` | 4238 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_gc9d01n.h` trong `main/boards/lilygo/t-circle-s3-v11`. |
| `main/boards/lilygo/t-circle-s3-v11/lilygo-t-circle-s3-v11.cc` | `cc` | 8846 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `lilygo-t-circle-s3-v11.cc` trong `main/boards/lilygo/t-circle-s3-v11`. Key types/methods: `TCircleS3V11AudioCodec`, `Cst816x`, `TouchPoint_t`, `LilygoTCircleS3V11Board`. |
| `main/boards/lilygo/t-circle-s3-v11/pin_config.h` | `h` | 1004 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `pin_config.h` trong `main/boards/lilygo/t-circle-s3-v11`. |
| `main/boards/lilygo/t-circle-s3/README.md` | `md` | 430 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/lilygo/t-circle-s3`. Main section: 编译配置命令. |
| `main/boards/lilygo/t-circle-s3/config.h` | `h` | 1506 | tracked | Pin map và compile-time hardware options cho board `main/boards/lilygo/t-circle-s3`. |
| `main/boards/lilygo/t-circle-s3/config.json` | `json` | 211 | tracked | Board/release config: target `esp32s3`, type `lilygo-t-circle-s3`, variants: lilygo-t-circle-s3. |
| `main/boards/lilygo/t-circle-s3/esp_lcd_gc9d01n.c` | `c` | 14869 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_gc9d01n.c` trong `main/boards/lilygo/t-circle-s3`. |
| `main/boards/lilygo/t-circle-s3/esp_lcd_gc9d01n.h` | `h` | 4238 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_gc9d01n.h` trong `main/boards/lilygo/t-circle-s3`. |
| `main/boards/lilygo/t-circle-s3/lilygo-t-circle-s3.cc` | `cc` | 8216 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `lilygo-t-circle-s3.cc` trong `main/boards/lilygo/t-circle-s3`. Key types/methods: `Cst816x`, `TouchPoint_t`, `LilygoTCircleS3Board`. |
| `main/boards/lilygo/t-circle-s3/pin_config.h` | `h` | 773 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `pin_config.h` trong `main/boards/lilygo/t-circle-s3`. |
| `main/boards/lilygo/t-circle-s3/tcircles3_audio_codec.cc` | `cc` | 5196 | tracked | Cấu hình hoặc driver audio codec của board `tcircles3_audio_codec.cc` trong `main/boards/lilygo/t-circle-s3`. Key types/methods: `Tcircles3AudioCodec::CreateVoiceHardware`, `Tcircles3AudioCodec::SetOutputVolume`, `Tcircles3AudioCodec::EnableInput`, `Tcircles3AudioCodec::EnableOutput`, `Tcircles3AudioCodec::Read`, `Tcircles3AudioCodec::Write`. |
| `main/boards/lilygo/t-circle-s3/tcircles3_audio_codec.h` | `h` | 1335 | tracked | Cấu hình hoặc driver audio codec của board `tcircles3_audio_codec.h` trong `main/boards/lilygo/t-circle-s3`. Key types/methods: `Tcircles3AudioCodec`. |
| `main/boards/lilygo/t-display-p4/README.md` | `md` | 1826 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/lilygo/t-display-p4`. Main section: LILYGO T-Display-P4. |
| `main/boards/lilygo/t-display-p4/config.h` | `h` | 2917 | tracked | Pin map và compile-time hardware options cho board `main/boards/lilygo/t-display-p4`. |
| `main/boards/lilygo/t-display-p4/hi8561_driver.cc` | `cc` | 17071 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `hi8561_driver.cc` trong `main/boards/lilygo/t-display-p4`. |
| `main/boards/lilygo/t-display-p4/hi8561_driver.h` | `h` | 2443 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `hi8561_driver.h` trong `main/boards/lilygo/t-display-p4`. |
| `main/boards/lilygo/t-display-p4/lilygo-t-display-p4.cc` | `cc` | 15419 | tracked | Driver hoặc UI/display resource riêng của board `lilygo-t-display-p4.cc` trong `main/boards/lilygo/t-display-p4`. Key types/methods: `CustomBacklight`, `LilygoTDisplayP4Board`. |
| `main/boards/lilygo/t-display-p4/rm69a10_driver.cc` | `cc` | 13125 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `rm69a10_driver.cc` trong `main/boards/lilygo/t-display-p4`. |
| `main/boards/lilygo/t-display-p4/rm69a10_driver.h` | `h` | 2533 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `rm69a10_driver.h` trong `main/boards/lilygo/t-display-p4`. |
| `main/boards/lilygo/t-display-p4/t_display_p4_config.h` | `h` | 6222 | tracked | Driver hoặc UI/display resource riêng của board `t_display_p4_config.h` trong `main/boards/lilygo/t-display-p4`. |
| `main/boards/lilygo/t-display-s3-pro-mvsrlora/README.md` | `md` | 685 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/lilygo/t-display-s3-pro-mvsrlora`. Main section: 编译配置命令. |
| `main/boards/lilygo/t-display-s3-pro-mvsrlora/config.h` | `h` | 1564 | tracked | Pin map và compile-time hardware options cho board `main/boards/lilygo/t-display-s3-pro-mvsrlora`. |
| `main/boards/lilygo/t-display-s3-pro-mvsrlora/config.json` | `json` | 239 | tracked | Board/release config: target `esp32s3`, type `lilygo-t-display-s3-pro-mvsrlora`, variants: lilygo-t-display-s3-pro-mvsrlora. |
| `main/boards/lilygo/t-display-s3-pro-mvsrlora/lilygo-t-display-s3-pro-mvsrlora.cc` | `cc` | 9422 | tracked | Driver hoặc UI/display resource riêng của board `lilygo-t-display-s3-pro-mvsrlora.cc` trong `main/boards/lilygo/t-display-s3-pro-mvsrlora`. Key types/methods: `Cst2xxse`, `TouchPoint_t`, `Sy6970`, `LilygoTDisplays3ProMVSRLoraBoard`. |
| `main/boards/lilygo/t-display-s3-pro-mvsrlora/pin_config.h` | `h` | 1374 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `pin_config.h` trong `main/boards/lilygo/t-display-s3-pro-mvsrlora`. |
| `main/boards/lilygo/t-display-s3-pro-mvsrlora/tdisplays3promvsrlora_audio_codec.cc` | `cc` | 5698 | tracked | Cấu hình hoặc driver audio codec của board `tdisplays3promvsrlora_audio_codec.cc` trong `main/boards/lilygo/t-display-s3-pro-mvsrlora`. Key types/methods: `Tdisplays3promvsrloraAudioCodec::CreateVoiceHardware`, `Tdisplays3promvsrloraAudioCodec::SetOutputVolume`, `Tdisplays3promvsrloraAudioCodec::EnableInput`, `Tdisplays3promvsrloraAudioCodec::EnableOutput`, `Tdisplays3promvsrloraAudioCodec::Read`, `Tdisplays3promvsrloraAudioCodec::Write`. |
| `main/boards/lilygo/t-display-s3-pro-mvsrlora/tdisplays3promvsrlora_audio_codec.h` | `h` | 1391 | tracked | Cấu hình hoặc driver audio codec của board `tdisplays3promvsrlora_audio_codec.h` trong `main/boards/lilygo/t-display-s3-pro-mvsrlora`. Key types/methods: `Tdisplays3promvsrloraAudioCodec`. |
| `main/boards/m5stack/atom-echos3r/README.md` | `md` | 1211 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/m5stack/atom-echos3r`. Main section: AtomEchoS3R. |
| `main/boards/m5stack/atom-echos3r/atom_echos3r.cc` | `cc` | 2683 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `atom_echos3r.cc` trong `main/boards/m5stack/atom-echos3r`. Key types/methods: `AtomEchoS3rBaseBoard`. |
| `main/boards/m5stack/atom-echos3r/config.h` | `h` | 828 | tracked | Pin map và compile-time hardware options cho board `main/boards/m5stack/atom-echos3r`. |
| `main/boards/m5stack/atom-echos3r/config.json` | `json` | 348 | tracked | Board/release config: target `esp32s3`, type `atom-echos3r`, variants: atom-echos3r. |
| `main/boards/m5stack/atommatrix-echo-base/README.md` | `md` | 279 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/m5stack/atommatrix-echo-base`. Main section: 编译配置命令. |
| `main/boards/m5stack/atommatrix-echo-base/atommatrix_echo_base.cc` | `cc` | 3807 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `atommatrix_echo_base.cc` trong `main/boards/m5stack/atommatrix-echo-base`. Key types/methods: `Pi4ioe`, `AtomMatrixEchoBaseBoard`. |
| `main/boards/m5stack/atommatrix-echo-base/config.h` | `h` | 795 | tracked | Pin map và compile-time hardware options cho board `main/boards/m5stack/atommatrix-echo-base`. |
| `main/boards/m5stack/atommatrix-echo-base/config.json` | `json` | 227 | tracked | Board/release config: target `esp32`, type `atommatrix-echo-base`, variants: atommatrix-echo-base. |
| `main/boards/m5stack/atoms3-echo-base/README.md` | `md` | 2065 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/m5stack/atoms3-echo-base`. Main section: M5Stack AtomS3 + Echo Base. |
| `main/boards/m5stack/atoms3-echo-base/atoms3_echo_base.cc` | `cc` | 12698 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `atoms3_echo_base.cc` trong `main/boards/m5stack/atoms3-echo-base`. Key types/methods: `AtomS3EchoBaseBoard`, `LcdPanelType`, `LcdPanelConfig`. |
| `main/boards/m5stack/atoms3-echo-base/config.h` | `h` | 1371 | tracked | Pin map và compile-time hardware options cho board `main/boards/m5stack/atoms3-echo-base`. |
| `main/boards/m5stack/atoms3-echo-base/config.json` | `json` | 390 | tracked | Board/release config: target `esp32s3`, type `atoms3-echo-base`, variants: atoms3-echo-base. |
| `main/boards/m5stack/atoms3r-cam-m12-echo-base/README.md` | `md` | 1680 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/m5stack/atoms3r-cam-m12-echo-base`. Main section: AtomS3R CAM/M12 + Echo Base. |
| `main/boards/m5stack/atoms3r-cam-m12-echo-base/atoms3r_cam_m12_echo_base.cc` | `cc` | 6466 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `atoms3r_cam_m12_echo_base.cc` trong `main/boards/m5stack/atoms3r-cam-m12-echo-base`. Key types/methods: `Pi4ioe`, `AtomS3rCamM12EchoBaseBoard`. |
| `main/boards/m5stack/atoms3r-cam-m12-echo-base/config.h` | `h` | 1535 | tracked | Pin map và compile-time hardware options cho board `main/boards/m5stack/atoms3r-cam-m12-echo-base`. |
| `main/boards/m5stack/atoms3r-cam-m12-echo-base/config.json` | `json` | 373 | tracked | Board/release config: target `esp32s3`, type `atoms3r-cam-m12-echo-base`, variants: atoms3r-cam-m12-echo-base. |
| `main/boards/m5stack/atoms3r-echo-base/README.md` | `md` | 1536 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/m5stack/atoms3r-echo-base`. Main section: M5Stack AtomS3R + Echo Base. |
| `main/boards/m5stack/atoms3r-echo-base/atoms3r_echo_base.cc` | `cc` | 15128 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `atoms3r_echo_base.cc` trong `main/boards/m5stack/atoms3r-echo-base`. Key types/methods: `Pi4ioe`, `Lp5562`, `CustomBacklight`, `AtomS3rEchoBaseBoard`, `LcdPanelType`, `LcdPanelConfig`. |
| `main/boards/m5stack/atoms3r-echo-base/config.h` | `h` | 1372 | tracked | Pin map và compile-time hardware options cho board `main/boards/m5stack/atoms3r-echo-base`. |
| `main/boards/m5stack/atoms3r-echo-base/config.json` | `json` | 357 | tracked | Board/release config: target `esp32s3`, type `atoms3r-echo-base`, variants: atoms3r-echo-base. |
| `main/boards/m5stack/atoms3r-echo-pyramid/README.md` | `md` | 1623 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/m5stack/atoms3r-echo-pyramid`. Main section: M5Stack AtomS3R + Echo Pyramid. |
| `main/boards/m5stack/atoms3r-echo-pyramid/atoms3r_echo_pyramid.cc` | `cc` | 31181 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `atoms3r_echo_pyramid.cc` trong `main/boards/m5stack/atoms3r-echo-pyramid`. Key types/methods: `Si5351`, `Aw87559`, `Stm32PyramidCtrl`, `PyramidStatusLed`, `Lp5562`, `CustomBacklight`, `PyramidAudioCodec`, `AtomS3rEchoPyramidBoard`. |
| `main/boards/m5stack/atoms3r-echo-pyramid/config.h` | `h` | 1485 | tracked | Pin map và compile-time hardware options cho board `main/boards/m5stack/atoms3r-echo-pyramid`. |
| `main/boards/m5stack/atoms3r-echo-pyramid/config.json` | `json` | 433 | tracked | Board/release config: target `esp32s3`, type `atoms3r-echo-pyramid`, variants: atoms3r-echo-pyramid. |
| `main/boards/m5stack/cardputer-adv/README.md` | `md` | 1968 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/m5stack/cardputer-adv`. Main section: M5Stack Cardputer Adv. |
| `main/boards/m5stack/cardputer-adv/config.h` | `h` | 2220 | tracked | Pin map và compile-time hardware options cho board `main/boards/m5stack/cardputer-adv`. |
| `main/boards/m5stack/cardputer-adv/config.json` | `json` | 401 | tracked | Board/release config: target `esp32s3`, type `m5stack-cardputer-adv`, variants: m5stack-cardputer-adv. |
| `main/boards/m5stack/cardputer-adv/m5stack_cardputer_adv.cc` | `cc` | 14675 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `m5stack_cardputer_adv.cc` trong `main/boards/m5stack/cardputer-adv`. Key types/methods: `M5StackCardputerAdvBoard`. |
| `main/boards/m5stack/cardputer-adv/tca8418_keyboard.cc` | `cc` | 14284 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `tca8418_keyboard.cc` trong `main/boards/m5stack/cardputer-adv`. Key types/methods: `KeyValue`, `Tca8418Keyboard::Initialize`, `Tca8418Keyboard::ConfigureMatrix`, `Tca8418Keyboard::EnableInterrupts`, `Tca8418Keyboard::FlushEvents`, `Tca8418Keyboard::GetEvent`, `Tca8418Keyboard::UpdateModifierState`, `Tca8418Keyboard::MapLegacyKeyCode`. |
| `main/boards/m5stack/cardputer-adv/tca8418_keyboard.h` | `h` | 3998 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `tca8418_keyboard.h` trong `main/boards/m5stack/cardputer-adv`. Key types/methods: `KeyModifier`, `KeyCode`, `KeyEvent`, `LegacyKeyCode`, `Tca8418Keyboard`. |
| `main/boards/m5stack/cardputer-adv/wifi_config_ui.cc` | `cc` | 22360 | tracked | Tích hợp mạng riêng của board `wifi_config_ui.cc` trong `main/boards/m5stack/cardputer-adv`. Key types/methods: `WifiConfigUI::Start`, `WifiConfigUI::StartWithSavedList`, `WifiConfigUI::StartScanning`, `WifiConfigUI::DoWifiScan`, `WifiConfigUI::ShowScanResults`, `WifiConfigUI::ShowPasswordInput`, `WifiConfigUI::RedrawPasswordInput`, `WifiConfigUI::ShowManualInput`. |
| `main/boards/m5stack/cardputer-adv/wifi_config_ui.h` | `h` | 4044 | tracked | Tích hợp mạng riêng của board `wifi_config_ui.h` trong `main/boards/m5stack/cardputer-adv`. Key types/methods: `WifiScanResult`, `WifiConfigState`, `WifiConfigResult`, `WifiConfigUI`. |
| `main/boards/m5stack/core-s3/README.md` | `md` | 356 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/m5stack/core-s3`. Main section: 使用说明. |
| `main/boards/m5stack/core-s3/config.h` | `h` | 1965 | tracked | Pin map và compile-time hardware options cho board `main/boards/m5stack/core-s3`. |
| `main/boards/m5stack/core-s3/config.json` | `json` | 573 | tracked | Board/release config: target `esp32s3`, type `m5stack-core-s3`, variants: m5stack-core-s3. |
| `main/boards/m5stack/core-s3/cores3_audio_codec.cc` | `cc` | 8384 | tracked | Cấu hình hoặc driver audio codec của board `cores3_audio_codec.cc` trong `main/boards/m5stack/core-s3`. Key types/methods: `CoreS3AudioCodec::CreateDuplexChannels`, `CoreS3AudioCodec::SetOutputVolume`, `CoreS3AudioCodec::EnableInput`, `CoreS3AudioCodec::EnableOutput`, `CoreS3AudioCodec::Read`, `CoreS3AudioCodec::Write`. |
| `main/boards/m5stack/core-s3/cores3_audio_codec.h` | `h` | 1356 | tracked | Cấu hình hoặc driver audio codec của board `cores3_audio_codec.h` trong `main/boards/m5stack/core-s3`. Key types/methods: `CoreS3AudioCodec`. |
| `main/boards/m5stack/core-s3/m5stack_core_s3.cc` | `cc` | 12394 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `m5stack_core_s3.cc` trong `main/boards/m5stack/core-s3`. Key types/methods: `Pmic`, `CustomBacklight`, `Aw9523`, `Ft6336`, `TouchPoint_t`, `M5StackCoreS3Board`. |
| `main/boards/m5stack/corep4/README.md` | `md` | 1876 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/m5stack/corep4`. Main section: M5Stack CoreP4. |
| `main/boards/m5stack/corep4/config.h` | `h` | 2318 | tracked | Pin map và compile-time hardware options cho board `main/boards/m5stack/corep4`. |
| `main/boards/m5stack/corep4/config.json` | `json` | 2117 | tracked | Board/release config: target `esp32p4`, type `m5stack-corep4`, variants: m5stack-corep4, m5stack-corep4x. |
| `main/boards/m5stack/corep4/m5stack_corep4.cc` | `cc` | 15035 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `m5stack_corep4.cc` trong `main/boards/m5stack/corep4`. Key types/methods: `M5IoE1Backlight`, `M5StackCoreP4Board`. |
| `main/boards/m5stack/stick-s3/README.md` | `md` | 2361 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/m5stack/stick-s3`. Main section: M5Stack Sticks3. |
| `main/boards/m5stack/stick-s3/config.h` | `h` | 1581 | tracked | Pin map và compile-time hardware options cho board `main/boards/m5stack/stick-s3`. |
| `main/boards/m5stack/stick-s3/config.json` | `json` | 391 | tracked | Board/release config: target `esp32s3`, type `m5stack-stick-s3`, variants: m5stack-stick-s3. |
| `main/boards/m5stack/stick-s3/m5stack_stick_s3.cc` | `cc` | 9341 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `m5stack_stick_s3.cc` trong `main/boards/m5stack/stick-s3`. Key types/methods: `Sticks3AudioCodec`, `M5StackStickS3Board`. |
| `main/boards/m5stack/stopwatch/README.md` | `md` | 3063 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/m5stack/stopwatch`. Main section: StopWatch. |
| `main/boards/m5stack/stopwatch/config.h` | `h` | 2329 | tracked | Pin map và compile-time hardware options cho board `main/boards/m5stack/stopwatch`. |
| `main/boards/m5stack/stopwatch/config.json` | `json` | 347 | tracked | Board/release config: target `esp32s3`, type `m5stack-stopwatch`, variants: m5stack-stopwatch. |
| `main/boards/m5stack/stopwatch/m5stack_stopwatch.cc` | `cc` | 12030 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `m5stack_stopwatch.cc` trong `main/boards/m5stack/stopwatch`. Key types/methods: `RoundLcdDisplay`, `StopwatchBacklight`, `M5StackStopwatchBoard`. |
| `main/boards/m5stack/tab5/README.md` | `md` | 2088 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/m5stack/tab5`. Main section: 使用说明. |
| `main/boards/m5stack/tab5/config.h` | `h` | 13325 | tracked | Pin map và compile-time hardware options cho board `main/boards/m5stack/tab5`. |
| `main/boards/m5stack/tab5/config.json` | `json` | 1695 | tracked | Board/release config: target `esp32p4`, type `m5stack-tab5`, variants: m5stack-tab5, m5stack-tab5-p4x. |
| `main/boards/m5stack/tab5/esp_lcd_st7121.c` | `c` | 14672 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_st7121.c` trong `main/boards/m5stack/tab5`. |
| `main/boards/m5stack/tab5/esp_lcd_st7121.h` | `h` | 6143 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_st7121.h` trong `main/boards/m5stack/tab5`. |
| `main/boards/m5stack/tab5/esp_lcd_st7123.c` | `c` | 15878 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_st7123.c` trong `main/boards/m5stack/tab5`. |
| `main/boards/m5stack/tab5/esp_lcd_st7123.h` | `h` | 4746 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_st7123.h` trong `main/boards/m5stack/tab5`. |
| `main/boards/m5stack/tab5/m5stack_tab5.cc` | `cc` | 24701 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `m5stack_tab5.cc` trong `main/boards/m5stack/tab5`. Key types/methods: `St712xPanel`, `Pi4ioe1`, `Pi4ioe2`, `M5StackTab5Board`. |
| `main/boards/m5stack/tab5/sdkconfig.tab5` | `tab5` | 615 | tracked | Tài nguyên hoặc ghi chú riêng của board `sdkconfig.tab5` trong `main/boards/m5stack/tab5`. |
| `main/boards/m5stack/tab5/tab5_audio_codec.cc` | `cc` | 8294 | tracked | Cấu hình hoặc driver audio codec của board `tab5_audio_codec.cc` trong `main/boards/m5stack/tab5`. Key types/methods: `Tab5AudioCodec::CreateDuplexChannels`, `Tab5AudioCodec::SetOutputVolume`, `Tab5AudioCodec::EnableInput`, `Tab5AudioCodec::EnableOutput`, `Tab5AudioCodec::Read`, `Tab5AudioCodec::Write`. |
| `main/boards/m5stack/tab5/tab5_audio_codec.h` | `h` | 1371 | tracked | Cấu hình hoặc driver audio codec của board `tab5_audio_codec.h` trong `main/boards/m5stack/tab5`. Key types/methods: `Tab5AudioCodec`. |
| `main/boards/magiclick/2p4/config.h` | `h` | 1371 | tracked | Pin map và compile-time hardware options cho board `main/boards/magiclick/2p4`. |
| `main/boards/magiclick/2p4/config.json` | `json` | 204 | tracked | Board/release config: target `esp32s3`, type `magiclick-2p4`, variants: magiclick-2p4. |
| `main/boards/magiclick/2p4/magiclick_2p4_board.cc` | `cc` | 9945 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `magiclick_2p4_board.cc` trong `main/boards/magiclick/2p4`. Key types/methods: `NV3023Display`, `magiclick_2p4`. |
| `main/boards/magiclick/2p5/config.h` | `h` | 1525 | tracked | Pin map và compile-time hardware options cho board `main/boards/magiclick/2p5`. |
| `main/boards/magiclick/2p5/config.json` | `json` | 217 | tracked | Board/release config: target `esp32s3`, type `magiclick-2p5`, variants: magiclick-2p5. |
| `main/boards/magiclick/2p5/magiclick_2p5_board.cc` | `cc` | 14807 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `magiclick_2p5_board.cc` trong `main/boards/magiclick/2p5`. Key types/methods: `magiclick_2p5`, `DisplayConfig`. |
| `main/boards/magiclick/2p5/power_manager.h` | `h` | 6308 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/magiclick/2p5`. Key types/methods: `PowerManager`. |
| `main/boards/magiclick/c3-v2/config.h` | `h` | 1192 | tracked | Pin map và compile-time hardware options cho board `main/boards/magiclick/c3-v2`. |
| `main/boards/magiclick/c3-v2/config.json` | `json` | 361 | tracked | Board/release config: target `esp32c3`, type `magiclick-c3-v2`, variants: magiclick-c3-v2. |
| `main/boards/magiclick/c3-v2/magiclick_c3_v2_board.cc` | `cc` | 8743 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `magiclick_c3_v2_board.cc` trong `main/boards/magiclick/c3-v2`. Key types/methods: `GC9107Display`, `magiclick_c3_v2`. |
| `main/boards/magiclick/c3/config.h` | `h` | 1191 | tracked | Pin map và compile-time hardware options cho board `main/boards/magiclick/c3`. |
| `main/boards/magiclick/c3/config.json` | `json` | 355 | tracked | Board/release config: target `esp32c3`, type `magiclick-c3`, variants: magiclick-c3. |
| `main/boards/magiclick/c3/magiclick_c3_board.cc` | `cc` | 7206 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `magiclick_c3_board.cc` trong `main/boards/magiclick/c3`. Key types/methods: `NV3023Display`, `magiclick_c3`. |
| `main/boards/maza-ai/esp32-s3/README.md` | `md` | 1740 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/maza-ai/esp32-s3`. Main section: Maza AI ESP32-S3. |
| `main/boards/maza-ai/esp32-s3/config.h` | `h` | 1161 | tracked | Pin map và compile-time hardware options cho board `main/boards/maza-ai/esp32-s3`. |
| `main/boards/maza-ai/esp32-s3/config.json` | `json` | 208 | tracked | Board/release config: target `esp32s3`, type `maza-ai-esp32-s3`, variants: maza-ai-esp32-s3. |
| `main/boards/maza-ai/esp32-s3/maza_ai_esp32_s3.cc` | `cc` | 4907 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `maza_ai_esp32_s3.cc` trong `main/boards/maza-ai/esp32-s3`. Key types/methods: `MazaAiEsp32S3`. |
| `main/boards/maza-ai/esp32-s31/README.md` | `md` | 1963 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/maza-ai/esp32-s31`. Main section: Maza AI ESP32-S31. |
| `main/boards/maza-ai/esp32-s31/config.h` | `h` | 1213 | tracked | Pin map và compile-time hardware options cho board `main/boards/maza-ai/esp32-s31`. |
| `main/boards/maza-ai/esp32-s31/config.json` | `json` | 268 | tracked | Board/release config: target `esp32s31`, type `maza-ai-esp32-s31`, variants: maza-ai-esp32-s31. |
| `main/boards/maza-ai/esp32-s31/maza_ai_esp32_s31.cc` | `cc` | 4911 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `maza_ai_esp32_s31.cc` trong `main/boards/maza-ai/esp32-s31`. Key types/methods: `MazaAiEsp32S31`. |
| `main/boards/minsi-k08-dual/README.md` | `md` | 794 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/minsi-k08-dual`. Main section: 编译配置命令. |
| `main/boards/minsi-k08-dual/config.h` | `h` | 1432 | tracked | Pin map và compile-time hardware options cho board `main/boards/minsi-k08-dual`. |
| `main/boards/minsi-k08-dual/config.json` | `json` | 173 | tracked | Board/release config: target `esp32s3`, type `minsi-k08-dual`, variants: minsi-k08-dual. |
| `main/boards/minsi-k08-dual/minsi_k08_dual.cc` | `cc` | 8847 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `minsi_k08_dual.cc` trong `main/boards/minsi-k08-dual`. Key types/methods: `MINSI_K08_DUAL`. |
| `main/boards/minsi-k08-dual/power_manager.h` | `h` | 6232 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/minsi-k08-dual`. Key types/methods: `PowerManager`. |
| `main/boards/mixgo-nova/README.md` | `md` | 1625 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/mixgo-nova`. Main section: Mixgo_Nova(元控·青春) 开发板. |
| `main/boards/mixgo-nova/config.h` | `h` | 1430 | tracked | Pin map và compile-time hardware options cho board `main/boards/mixgo-nova`. |
| `main/boards/mixgo-nova/config.json` | `json` | 404 | tracked | Board/release config: target `esp32s3`, type `mixgo-nova`, variants: mixgo-nova. |
| `main/boards/mixgo-nova/mixgo-nova.cc` | `cc` | 5865 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `mixgo-nova.cc` trong `main/boards/mixgo-nova`. Key types/methods: `MIXGO_NOVA`. |
| `main/boards/movecall/cuican-esp32s3/README.md` | `md` | 650 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/movecall/cuican-esp32s3`. Main section: ESP32-S3 编译配置指南. |
| `main/boards/movecall/cuican-esp32s3/config.h` | `h` | 1264 | tracked | Pin map và compile-time hardware options cho board `main/boards/movecall/cuican-esp32s3`. |
| `main/boards/movecall/cuican-esp32s3/config.json` | `json` | 427 | tracked | Board/release config: target `esp32s3`, type `movecall-cuican-esp32s3`, variants: movecall-cuican-esp32s3. |
| `main/boards/movecall/cuican-esp32s3/movecall_cuican_esp32s3.cc` | `cc` | 4484 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `movecall_cuican_esp32s3.cc` trong `main/boards/movecall/cuican-esp32s3`. Key types/methods: `MovecallCuicanESP32S3`. |
| `main/boards/movecall/moji-esp32s3/README.md` | `md` | 318 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/movecall/moji-esp32s3`. Main section: 编译配置命令. |
| `main/boards/movecall/moji-esp32s3/config.h` | `h` | 1258 | tracked | Pin map và compile-time hardware options cho board `main/boards/movecall/moji-esp32s3`. |
| `main/boards/movecall/moji-esp32s3/config.json` | `json` | 219 | tracked | Board/release config: target `esp32s3`, type `movecall-moji-esp32s3`, variants: movecall-moji-esp32s3. |
| `main/boards/movecall/moji-esp32s3/movecall_moji_esp32s3.cc` | `cc` | 5561 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `movecall_moji_esp32s3.cc` trong `main/boards/movecall/moji-esp32s3`. Key types/methods: `CustomLcdDisplay`, `MovecallMojiESP32S3`. |
| `main/boards/movecall/moji2-esp32c5/README.md` | `md` | 1302 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/movecall/moji2-esp32c5`. Main section: Build and Configuration Guide. |
| `main/boards/movecall/moji2-esp32c5/README_zh.md` | `md` | 1226 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/movecall/moji2-esp32c5`. Main section: 编译配置指南. |
| `main/boards/movecall/moji2-esp32c5/config.h` | `h` | 2451 | tracked | Pin map và compile-time hardware options cho board `main/boards/movecall/moji2-esp32c5`. Key types/methods: `PowerSupply`. |
| `main/boards/movecall/moji2-esp32c5/config.json` | `json` | 473 | tracked | Board/release config: target `esp32c5`, type `movecall-moji2-esp32c5`, variants: movecall-moji2-esp32c5. |
| `main/boards/movecall/moji2-esp32c5/movecall_moji2_esp32s3.cc` | `cc` | 15030 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `movecall_moji2_esp32s3.cc` trong `main/boards/movecall/moji2-esp32c5`. Key types/methods: `MovecallMoji2ESP32C5`. |
| `main/boards/nologo/xingzhi-abs-2.0/README.md` | `md` | 3057 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/nologo/xingzhi-abs-2.0`. Main section: 无名科技星智 ABS 2.0. |
| `main/boards/nologo/xingzhi-abs-2.0/config.h` | `h` | 2076 | tracked | Pin map và compile-time hardware options cho board `main/boards/nologo/xingzhi-abs-2.0`. |
| `main/boards/nologo/xingzhi-abs-2.0/config.json` | `json` | 218 | tracked | Board/release config: target `esp32s3`, type `xingzhi-abs-2.0`, variants: xingzhi-abs-2.0. |
| `main/boards/nologo/xingzhi-abs-2.0/customlcddisplay.h` | `h` | 3209 | tracked | Driver hoặc UI/display resource riêng của board `customlcddisplay.h` trong `main/boards/nologo/xingzhi-abs-2.0`. Key types/methods: `CustomLcdDisplay`. |
| `main/boards/nologo/xingzhi-abs-2.0/power_manager.h` | `h` | 11056 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/nologo/xingzhi-abs-2.0`. Key types/methods: `PowerManager`. |
| `main/boards/nologo/xingzhi-abs-2.0/xingzhi-abs-2.0.cc` | `cc` | 13793 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `xingzhi-abs-2.0.cc` trong `main/boards/nologo/xingzhi-abs-2.0`. Key types/methods: `XINGZHI_ABS_2_0`. |
| `main/boards/nologo/xingzhi-cube-0.85tft-ml307/config.h` | `h` | 1124 | tracked | Pin map và compile-time hardware options cho board `main/boards/nologo/xingzhi-cube-0.85tft-ml307`. |
| `main/boards/nologo/xingzhi-cube-0.85tft-ml307/config.json` | `json` | 227 | tracked | Board/release config: target `esp32s3`, type `xingzhi-cube-0.85tft-ml307`, variants: xingzhi-cube-0.85tft-ml307. |
| `main/boards/nologo/xingzhi-cube-0.85tft-ml307/xingzhi-cube-0.85tft-ml307.cc` | `cc` | 8951 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `xingzhi-cube-0.85tft-ml307.cc` trong `main/boards/nologo/xingzhi-cube-0.85tft-ml307`. Key types/methods: `XINGZHI_CUBE_0_85TFT_ML307`. |
| `main/boards/nologo/xingzhi-cube-0.85tft-wifi/config.h` | `h` | 1057 | tracked | Pin map và compile-time hardware options cho board `main/boards/nologo/xingzhi-cube-0.85tft-wifi`. |
| `main/boards/nologo/xingzhi-cube-0.85tft-wifi/config.json` | `json` | 225 | tracked | Board/release config: target `esp32s3`, type `xingzhi-cube-0.85tft-wifi`, variants: xingzhi-cube-0.85tft-wifi. |
| `main/boards/nologo/xingzhi-cube-0.85tft-wifi/xingzhi-cube-0.85tft-wifi.cc` | `cc` | 9094 | tracked | Tích hợp mạng riêng của board `xingzhi-cube-0.85tft-wifi.cc` trong `main/boards/nologo/xingzhi-cube-0.85tft-wifi`. Key types/methods: `XINGZHI_CUBE_0_85TFT_WIFI`. |
| `main/boards/nologo/xingzhi-cube-0.96oled-ml307/config.h` | `h` | 874 | tracked | Pin map và compile-time hardware options cho board `main/boards/nologo/xingzhi-cube-0.96oled-ml307`. |
| `main/boards/nologo/xingzhi-cube-0.96oled-ml307/config.json` | `json` | 229 | tracked | Board/release config: target `esp32s3`, type `xingzhi-cube-0.96oled-ml307`, variants: xingzhi-cube-0.96oled-ml307. |
| `main/boards/nologo/xingzhi-cube-0.96oled-ml307/xingzhi-cube-0.96oled-ml307.cc` | `cc` | 8249 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `xingzhi-cube-0.96oled-ml307.cc` trong `main/boards/nologo/xingzhi-cube-0.96oled-ml307`. Key types/methods: `XINGZHI_CUBE_0_96OLED_ML307`. |
| `main/boards/nologo/xingzhi-cube-0.96oled-wifi/config.h` | `h` | 807 | tracked | Pin map và compile-time hardware options cho board `main/boards/nologo/xingzhi-cube-0.96oled-wifi`. |
| `main/boards/nologo/xingzhi-cube-0.96oled-wifi/config.json` | `json` | 227 | tracked | Board/release config: target `esp32s3`, type `xingzhi-cube-0.96oled-wifi`, variants: xingzhi-cube-0.96oled-wifi. |
| `main/boards/nologo/xingzhi-cube-0.96oled-wifi/xingzhi-cube-0.96oled-wifi.cc` | `cc` | 7676 | tracked | Tích hợp mạng riêng của board `xingzhi-cube-0.96oled-wifi.cc` trong `main/boards/nologo/xingzhi-cube-0.96oled-wifi`. Key types/methods: `XINGZHI_CUBE_0_96OLED_WIFI`. |
| `main/boards/nologo/xingzhi-cube-1.54tft-ml307/config.h` | `h` | 1125 | tracked | Pin map và compile-time hardware options cho board `main/boards/nologo/xingzhi-cube-1.54tft-ml307`. |
| `main/boards/nologo/xingzhi-cube-1.54tft-ml307/config.json` | `json` | 227 | tracked | Board/release config: target `esp32s3`, type `xingzhi-cube-1.54tft-ml307`, variants: xingzhi-cube-1.54tft-ml307. |
| `main/boards/nologo/xingzhi-cube-1.54tft-ml307/xingzhi-cube-1.54tft-ml307.cc` | `cc` | 7970 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `xingzhi-cube-1.54tft-ml307.cc` trong `main/boards/nologo/xingzhi-cube-1.54tft-ml307`. Key types/methods: `XINGZHI_CUBE_1_54TFT_ML307`. |
| `main/boards/nologo/xingzhi-cube-1.54tft-wifi/config.h` | `h` | 1057 | tracked | Pin map và compile-time hardware options cho board `main/boards/nologo/xingzhi-cube-1.54tft-wifi`. |
| `main/boards/nologo/xingzhi-cube-1.54tft-wifi/config.json` | `json` | 225 | tracked | Board/release config: target `esp32s3`, type `xingzhi-cube-1.54tft-wifi`, variants: xingzhi-cube-1.54tft-wifi. |
| `main/boards/nologo/xingzhi-cube-1.54tft-wifi/power_manager.h` | `h` | 6007 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/nologo/xingzhi-cube-1.54tft-wifi`. Key types/methods: `PowerManager`. |
| `main/boards/nologo/xingzhi-cube-1.54tft-wifi/xingzhi-cube-1.54tft-wifi.cc` | `cc` | 7359 | tracked | Tích hợp mạng riêng của board `xingzhi-cube-1.54tft-wifi.cc` trong `main/boards/nologo/xingzhi-cube-1.54tft-wifi`. Key types/methods: `XINGZHI_CUBE_1_54TFT_WIFI`. |
| `main/boards/nologo/xingzhi-metal-1.54-wifi/README.md` | `md` | 1809 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/nologo/xingzhi-metal-1.54-wifi`. Main section: 无名科技星智 1.54 METAL (wifi). |
| `main/boards/nologo/xingzhi-metal-1.54-wifi/config.h` | `h` | 1657 | tracked | Pin map và compile-time hardware options cho board `main/boards/nologo/xingzhi-metal-1.54-wifi`. |
| `main/boards/nologo/xingzhi-metal-1.54-wifi/config.json` | `json` | 234 | tracked | Board/release config: target `esp32s3`, type `xingzhi-metal-1.54-wifi`, variants: xingzhi-metal-1.54-wifi. |
| `main/boards/nologo/xingzhi-metal-1.54-wifi/cst816x.cc` | `cc` | 9265 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `cst816x.cc` trong `main/boards/nologo/xingzhi-metal-1.54-wifi`. Key types/methods: `timeval`, `Cst816x::getThresholdConfig`, `Cst816x::getCurrentTimeUs`, `Cst816x::UpdateTouchPoint`, `Cst816x::resetTouchCounters`, `Cst816x::touchpad_daemon`, `Cst816x::InitCst816d`. |
| `main/boards/nologo/xingzhi-metal-1.54-wifi/cst816x.h` | `h` | 2803 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `cst816x.h` trong `main/boards/nologo/xingzhi-metal-1.54-wifi`. Key types/methods: `TouchEventType`, `TouchEvent`, `Cst816x`, `TouchPoint_t`, `TouchThresholdConfig`. |
| `main/boards/nologo/xingzhi-metal-1.54-wifi/power_manager.h` | `h` | 11594 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/nologo/xingzhi-metal-1.54-wifi`. Key types/methods: `PowerManager`. |
| `main/boards/nologo/xingzhi-metal-1.54-wifi/xingzhi-metal-1.54-wifi.cc` | `cc` | 6937 | tracked | Tích hợp mạng riêng của board `xingzhi-metal-1.54-wifi.cc` trong `main/boards/nologo/xingzhi-metal-1.54-wifi`. Key types/methods: `XINGZHI_METAL_1_54_WIFI`. |
| `main/boards/nulllab-ai-vox-v3/README.md` | `md` | 2582 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/nulllab-ai-vox-v3`. Main section: NULLLAB-AI-VOX3. |
| `main/boards/nulllab-ai-vox-v3/ai_vox3_audio_codec.h` | `h` | 9305 | tracked | Cấu hình hoặc driver audio codec của board `ai_vox3_audio_codec.h` trong `main/boards/nulllab-ai-vox-v3`. Key types/methods: `AIVOX3AudioCodec`. |
| `main/boards/nulllab-ai-vox-v3/ai_vox3_board.cc` | `cc` | 7272 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `ai_vox3_board.cc` trong `main/boards/nulllab-ai-vox-v3`. Key types/methods: `AIVOX3`. |
| `main/boards/nulllab-ai-vox-v3/config.h` | `h` | 1526 | tracked | Pin map và compile-time hardware options cho board `main/boards/nulllab-ai-vox-v3`. |
| `main/boards/nulllab-ai-vox-v3/config.json` | `json` | 181 | tracked | Board/release config: target `esp32s3`, type `nulllab-ai-vox-v3`, variants: nulllab-ai-vox-v3. |
| `main/boards/nulllab-ai-vox-v3/power_manager.h` | `h` | 4867 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/nulllab-ai-vox-v3`. Key types/methods: `PowerManager`. |
| `main/boards/ostb/ostb-xiaozhi-3st/README.md` | `md` | 2561 | tracked | Cấu hình source OSTB 3ST, phân biệt partition live/source và hướng dẫn profile phone-local AI. |
| `main/boards/ostb/ostb-xiaozhi-3st/config.h` | `h` | 1804 | tracked | Pin map và compile-time hardware options cho board `main/boards/ostb/ostb-xiaozhi-3st`. |
| `main/boards/ostb/ostb-xiaozhi-3st/config.json` | `json` | 473 | tracked | Board/release config: target `esp32s3`, type `ostb-xiaozhi-3st`, variants: ostb-xiaozhi-3st. |
| `main/boards/ostb/ostb-xiaozhi-3st/config.local-ai.json` | `json` | 749 | tracked | Build profile Nabi local AI, 16 MB OTA partition table, BLE 4.2 provisioning và DHCP gateway OTA fallback. |
| `main/boards/ostb/ostb-xiaozhi-3st/ostb_xiaozhi_3st.cc` | `cc` | 11398 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `ostb_xiaozhi_3st.cc` trong `main/boards/ostb/ostb-xiaozhi-3st`. Key types/methods: `OstbXiaozhi3stBoard`. |
| `main/boards/otto-robot/README.md` | `md` | 15976 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/otto-robot`. Main section: 简介. |
| `main/boards/otto-robot/config.h` | `h` | 4956 | tracked | Pin map và compile-time hardware options cho board `main/boards/otto-robot`. Key types/methods: `OttoCameraType`, `HardwareConfig`. |
| `main/boards/otto-robot/config.json` | `json` | 430 | tracked | Board/release config: target `esp32s3`, type `otto-robot`, variants: otto-robot. |
| `main/boards/otto-robot/oscillator.cc` | `cc` | 4335 | tracked | Điều khiển chức năng robot/peripheral riêng của board `oscillator.cc` trong `main/boards/otto-robot`. Key types/methods: `Oscillator::AngleToCompare`, `Oscillator::NextSample`, `Oscillator::Attach`, `Oscillator::Detach`, `Oscillator::SetT`, `Oscillator::SetPosition`, `Oscillator::Refresh`, `Oscillator::Write`. |
| `main/boards/otto-robot/oscillator.h` | `h` | 2935 | tracked | Điều khiển chức năng robot/peripheral riêng của board `oscillator.h` trong `main/boards/otto-robot`. Key types/methods: `Oscillator`. |
| `main/boards/otto-robot/otto_controller.cc` | `cc` | 51980 | tracked | Điều khiển chức năng robot/peripheral riêng của board `otto_controller.cc` trong `main/boards/otto-robot`. Key types/methods: `OttoController`, `OttoActionParams`, `ActionType`. |
| `main/boards/otto-robot/otto_emoji_display.cc` | `cc` | 5550 | tracked | Driver hoặc UI/display resource riêng của board `otto_emoji_display.cc` trong `main/boards/otto-robot`. Key types/methods: `OttoEmojiDisplay::SetupUI`, `OttoEmojiDisplay::SetupPreviewImage`, `OttoEmojiDisplay::InitializeOttoEmojis`, `OttoEmojiDisplay::SetStatus`, `OttoEmojiDisplay::SetPreviewImage`. |
| `main/boards/otto-robot/otto_emoji_display.h` | `h` | 775 | tracked | Driver hoặc UI/display resource riêng của board `otto_emoji_display.h` trong `main/boards/otto-robot`. Key types/methods: `OttoEmojiDisplay`. |
| `main/boards/otto-robot/otto_icon_font.c` | `c` | 4320 | tracked | Driver hoặc UI/display resource riêng của board `otto_icon_font.c` trong `main/boards/otto-robot`. |
| `main/boards/otto-robot/otto_movements.cc` | `cc` | 33965 | tracked | Điều khiển chức năng robot/peripheral riêng của board `otto_movements.cc` trong `main/boards/otto-robot`. Key types/methods: `Otto::Init`, `Otto::AttachServos`, `Otto::DetachServos`, `Otto::SetTrims`, `Otto::MoveServos`, `Otto::MoveSingle`, `Otto::OscillateServos`, `Otto::Execute`. |
| `main/boards/otto-robot/otto_movements.h` | `h` | 4165 | tracked | Điều khiển chức năng robot/peripheral riêng của board `otto_movements.h` trong `main/boards/otto-robot`. Key types/methods: `Otto`. |
| `main/boards/otto-robot/otto_robot.cc` | `cc` | 15556 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `otto_robot.cc` trong `main/boards/otto-robot`. Key types/methods: `OttoRobot`. |
| `main/boards/otto-robot/power_manager.h` | `h` | 5039 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/otto-robot`. Key types/methods: `PowerManager`. |
| `main/boards/otto-robot/websocket_control_server.cc` | `cc` | 8621 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `websocket_control_server.cc` trong `main/boards/otto-robot`. Key types/methods: `WsBroadcastJob`, `WebSocketControlServer::ws_handler`, `WebSocketControlServer::Start`, `WebSocketControlServer::Stop`, `WebSocketControlServer::HandleMessage`, `WebSocketControlServer::AddClient`, `WebSocketControlServer::RemoveClient`, `WebSocketControlServer::GetClientCount`. |
| `main/boards/otto-robot/websocket_control_server.h` | `h` | 1027 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `websocket_control_server.h` trong `main/boards/otto-robot`. Key types/methods: `WebSocketControlServer`, `ClientInfo`. |
| `main/boards/quandong-s3-dev/HARDWARE_DIFF.md` | `md` | 6817 | tracked | Tài nguyên hoặc ghi chú riêng của board `HARDWARE_DIFF.md` trong `main/boards/quandong-s3-dev`. Main section: quandong-s3-dev vs bread-compact-wifi 硬件差异. |
| `main/boards/quandong-s3-dev/config.h` | `h` | 1611 | tracked | Pin map và compile-time hardware options cho board `main/boards/quandong-s3-dev`. |
| `main/boards/quandong-s3-dev/config.json` | `json` | 176 | tracked | Board/release config: target `esp32s3`, type `quandong-s3-dev`, variants: quandong-s3-dev. |
| `main/boards/quandong-s3-dev/quandong_s3_dev_board.cc` | `cc` | 6512 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `quandong_s3_dev_board.cc` trong `main/boards/quandong-s3-dev`. Key types/methods: `QuandongS3DevBoard`. |
| `main/boards/rymcu/bigsmart/README.md` | `md` | 614 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/rymcu/bigsmart`. Main section: RYMCU BigSmart. |
| `main/boards/rymcu/bigsmart/config.h` | `h` | 1902 | tracked | Pin map và compile-time hardware options cho board `main/boards/rymcu/bigsmart`. |
| `main/boards/rymcu/bigsmart/config.json` | `json` | 252 | tracked | Board/release config: target `esp32s3`, type `bigsmart`, variants: rymcu-bigsmart. |
| `main/boards/rymcu/bigsmart/rymcu_bigsmart_board.cc` | `cc` | 9272 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `rymcu_bigsmart_board.cc` trong `main/boards/rymcu/bigsmart`. Key types/methods: `Pca9557`, `CustomAudioCodec`, `RymcuBigsmartBoard`. |
| `main/boards/sensecap-watcher/README.md` | `md` | 1408 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/sensecap-watcher`. Main section: 编译命令. |
| `main/boards/sensecap-watcher/README_en.md` | `md` | 1713 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/sensecap-watcher`. Main section: Build Instructions. |
| `main/boards/sensecap-watcher/config.h` | `h` | 5054 | tracked | Pin map và compile-time hardware options cho board `main/boards/sensecap-watcher`. |
| `main/boards/sensecap-watcher/config.json` | `json` | 551 | tracked | Board/release config: target `esp32s3`, type `sensecap-watcher`, variants: sensecap-watcher. |
| `main/boards/sensecap-watcher/sensecap_audio_codec.cc` | `cc` | 7231 | tracked | Cấu hình hoặc driver audio codec của board `sensecap_audio_codec.cc` trong `main/boards/sensecap-watcher`. Key types/methods: `SensecapAudioCodec::CreateDuplexChannels`, `SensecapAudioCodec::SetOutputVolume`, `SensecapAudioCodec::EnableInput`, `SensecapAudioCodec::EnableOutput`, `SensecapAudioCodec::Read`, `SensecapAudioCodec::Write`. |
| `main/boards/sensecap-watcher/sensecap_audio_codec.h` | `h` | 1437 | tracked | Cấu hình hoặc driver audio codec của board `sensecap_audio_codec.h` trong `main/boards/sensecap-watcher`. Key types/methods: `SensecapAudioCodec`. |
| `main/boards/sensecap-watcher/sensecap_watcher.cc` | `cc` | 26493 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `sensecap_watcher.cc` trong `main/boards/sensecap-watcher`. Key types/methods: `CustomLcdDisplay`, `SensecapWatcher`. |
| `main/boards/sensecap-watcher/sscma_camera.cc` | `cc` | 33790 | tracked | Camera/video integration riêng của board `sscma_camera.cc` trong `main/boards/sensecap-watcher`. Key types/methods: `SscmaCamera::InitializeMcpTools`, `std::string`, `SscmaCamera::SetExplainUrl`, `SscmaCamera::Capture`, `SscmaCamera::SetHMirror`, `SscmaCamera::SetVFlip`, `SscmaCamera::Explain`, `std::unexpected`. |
| `main/boards/sensecap-watcher/sscma_camera.h` | `h` | 2296 | tracked | Camera/video integration riêng của board `sscma_camera.h` trong `main/boards/sensecap-watcher`. Key types/methods: `SscmaData`, `JpegData`, `SscmaCamera`, `DetectionState`. |
| `main/boards/spotpear/sp-esp32-s3-1.28-box/README.md` | `md` | 609 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/spotpear/sp-esp32-s3-1.28-box`. Main section: 编译配置命令. |
| `main/boards/spotpear/sp-esp32-s3-1.28-box/config.h` | `h` | 1645 | tracked | Pin map và compile-time hardware options cho board `main/boards/spotpear/sp-esp32-s3-1.28-box`. |
| `main/boards/spotpear/sp-esp32-s3-1.28-box/config.json` | `json` | 218 | tracked | Board/release config: target `esp32s3`, type `sp-esp32-s3-1.28-box`, variants: sp-esp32-s3-1.28-box. |
| `main/boards/spotpear/sp-esp32-s3-1.28-box/power_manager.h` | `h` | 6136 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/spotpear/sp-esp32-s3-1.28-box`. Key types/methods: `PowerManager`. |
| `main/boards/spotpear/sp-esp32-s3-1.28-box/sp-esp32-s3-1.28-box.cc` | `cc` | 17194 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `sp-esp32-s3-1.28-box.cc` trong `main/boards/spotpear/sp-esp32-s3-1.28-box`. Key types/methods: `Cst816d`, `TouchPoint_t`, `CustomLcdDisplay`, `Spotpear_ESP32_S3_1_28_BOX`. |
| `main/boards/spotpear/sp-esp32-s3-1.54-muma/README.md` | `md` | 843 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/spotpear/sp-esp32-s3-1.54-muma`. Main section: 编译配置命令. |
| `main/boards/spotpear/sp-esp32-s3-1.54-muma/config.h` | `h` | 1624 | tracked | Pin map và compile-time hardware options cho board `main/boards/spotpear/sp-esp32-s3-1.54-muma`. |
| `main/boards/spotpear/sp-esp32-s3-1.54-muma/config.json` | `json` | 220 | tracked | Board/release config: target `esp32s3`, type `sp-esp32-s3-1.54-muma`, variants: sp-esp32-s3-1.54-muma. |
| `main/boards/spotpear/sp-esp32-s3-1.54-muma/power_manager.h` | `h` | 5983 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/spotpear/sp-esp32-s3-1.54-muma`. Key types/methods: `PowerManager`. |
| `main/boards/spotpear/sp-esp32-s3-1.54-muma/sp-esp32-s3-1.54-muma.cc` | `cc` | 11275 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `sp-esp32-s3-1.54-muma.cc` trong `main/boards/spotpear/sp-esp32-s3-1.54-muma`. Key types/methods: `Cst816d`, `TouchPoint_t`, `Spotpear_esp32_s3_lcd_1_54`. |
| `main/boards/surfer-c3-1.14tft/README.md` | `md` | 231 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/surfer-c3-1.14tft`. Main section: Surfer-ESP32-C3 开发板. |
| `main/boards/surfer-c3-1.14tft/config.h` | `h` | 1296 | tracked | Pin map và compile-time hardware options cho board `main/boards/surfer-c3-1.14tft`. |
| `main/boards/surfer-c3-1.14tft/config.json` | `json` | 341 | tracked | Board/release config: target `esp32c3`, type `surfer-c3-1.14tft`, variants: surfer-c3-1.14tft. |
| `main/boards/surfer-c3-1.14tft/power_manager.h` | `h` | 6494 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/surfer-c3-1.14tft`. Key types/methods: `PowerManager`. |
| `main/boards/surfer-c3-1.14tft/surfer-c3-1.14tft.cc` | `cc` | 7390 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `surfer-c3-1.14tft.cc` trong `main/boards/surfer-c3-1.14tft`. Key types/methods: `SurferC3114TFT`. |
| `main/boards/taiji-pi-s3/README.md` | `md` | 891 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/taiji-pi-s3`. Main section: 由于原来的麦克风型号停产，2025年7月之后的太极派（JC3636W518）更换了麦克风，并且更换了屏幕玻璃，所以在产品标签上批次号大于2528的用户请选择I2S Type PDM,. |
| `main/boards/taiji-pi-s3/config.h` | `h` | 2563 | tracked | Pin map và compile-time hardware options cho board `main/boards/taiji-pi-s3`. |
| `main/boards/taiji-pi-s3/config.json` | `json` | 502 | tracked | Board/release config: target `esp32s3`, type `taiji-pi-s3`, variants: taiji-pi-s3, taiji-pi-s3-pdm. |
| `main/boards/taiji-pi-s3/taiji_pi_s3.cc` | `cc` | 25297 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `taiji_pi_s3.cc` trong `main/boards/taiji-pi-s3`. Key types/methods: `TaijiPiS3Display`, `Cst816s`, `TouchPoint_t`, `TaijiPiS3Board`. |
| `main/boards/waveshare/esp32-c5-touch-lcd-1.69/README.md` | `md` | 604 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-c5-touch-lcd-1.69`. Main section: 产品链接. |
| `main/boards/waveshare/esp32-c5-touch-lcd-1.69/config.h` | `h` | 1419 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-c5-touch-lcd-1.69`. |
| `main/boards/waveshare/esp32-c5-touch-lcd-1.69/config.json` | `json` | 476 | tracked | Board/release config: target `esp32c5`, type `esp32-c5-touch-lcd-1.69`, variants: esp32-c5-touch-lcd-1.69. |
| `main/boards/waveshare/esp32-c5-touch-lcd-1.69/esp32-c5-touch-lcd-1.69.cc` | `cc` | 10026 | tracked | Driver hoặc UI/display resource riêng của board `esp32-c5-touch-lcd-1.69.cc` trong `main/boards/waveshare/esp32-c5-touch-lcd-1.69`. Key types/methods: `WaveshareEsp32c5TouchLCD1inch69`. |
| `main/boards/waveshare/esp32-c6-epaper-1.54/README.md` | `md` | 797 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-c6-epaper-1.54`. Main section: Waveshare ESP32-C6-ePaper-1.54. |
| `main/boards/waveshare/esp32-c6-epaper-1.54/board_power_bsp.cc` | `cc` | 2204 | tracked | Quản lý nguồn/pin/charger của board `board_power_bsp.cc` trong `main/boards/waveshare/esp32-c6-epaper-1.54`. Key types/methods: `BoardPowerBsp::PowerLedTask`, `BoardPowerBsp::PowerEpdOn`, `BoardPowerBsp::PowerEpdOff`, `BoardPowerBsp::PowerAudioOn`, `BoardPowerBsp::PowerAudioOff`, `BoardPowerBsp::VbatPowerOn`, `BoardPowerBsp::VbatPowerOff`. |
| `main/boards/waveshare/esp32-c6-epaper-1.54/board_power_bsp.h` | `h` | 776 | tracked | Quản lý nguồn/pin/charger của board `board_power_bsp.h` trong `main/boards/waveshare/esp32-c6-epaper-1.54`. Key types/methods: `BoardPowerBsp`. |
| `main/boards/waveshare/esp32-c6-epaper-1.54/config.h` | `h` | 1707 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-c6-epaper-1.54`. |
| `main/boards/waveshare/esp32-c6-epaper-1.54/config.json` | `json` | 232 | tracked | Board/release config: target `esp32c6`, type `esp32-c6-epaper-1.54`, variants: esp32-c6-epaper-1.54. |
| `main/boards/waveshare/esp32-c6-epaper-1.54/custom_lcd_display.cc` | `cc` | 11859 | tracked | Driver hoặc UI/display resource riêng của board `custom_lcd_display.cc` trong `main/boards/waveshare/esp32-c6-epaper-1.54`. Key types/methods: `CustomLcdDisplay::lvgl_flush_cb`, `CustomLcdDisplay::spi_gpio_init`, `CustomLcdDisplay::spi_port_init`, `CustomLcdDisplay::read_busy`, `CustomLcdDisplay::SPI_SendByte`, `CustomLcdDisplay::EPD_SendData`, `CustomLcdDisplay::EPD_SendCommand`, `CustomLcdDisplay::writeBytes`. |
| `main/boards/waveshare/esp32-c6-epaper-1.54/custom_lcd_display.h` | `h` | 2406 | tracked | Driver hoặc UI/display resource riêng của board `custom_lcd_display.h` trong `main/boards/waveshare/esp32-c6-epaper-1.54`. Key types/methods: `CustomLcdDisplay`. |
| `main/boards/waveshare/esp32-c6-epaper-1.54/waveshare-c6-epaper-1.54.cc` | `cc` | 6598 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `waveshare-c6-epaper-1.54.cc` trong `main/boards/waveshare/esp32-c6-epaper-1.54`. Key types/methods: `CustomBoard`. |
| `main/boards/waveshare/esp32-c6-lcd-0.85/README.md` | `md` | 769 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-c6-lcd-0.85`. Main section: 产品链接. |
| `main/boards/waveshare/esp32-c6-lcd-0.85/config.h` | `h` | 1492 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-c6-lcd-0.85`. |
| `main/boards/waveshare/esp32-c6-lcd-0.85/config.json` | `json` | 413 | tracked | Board/release config: target `esp32c6`, type `esp32-c6-lcd-0.85`, variants: esp32-c6-lcd-0.85. |
| `main/boards/waveshare/esp32-c6-lcd-0.85/esp32-c6-lcd-0.85.cc` | `cc` | 9171 | tracked | Driver hoặc UI/display resource riêng của board `esp32-c6-lcd-0.85.cc` trong `main/boards/waveshare/esp32-c6-lcd-0.85`. Key types/methods: `CustomButton`, `CustomBoard`. |
| `main/boards/waveshare/esp32-c6-lcd-0.85/led_strip_control.cc` | `cc` | 5730 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `led_strip_control.cc` trong `main/boards/waveshare/esp32-c6-lcd-0.85`. Key types/methods: `LedStripControl::LevelToBrightness`, `LedStripControl::RGBToColor`. |
| `main/boards/waveshare/esp32-c6-lcd-0.85/led_strip_control.h` | `h` | 444 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `led_strip_control.h` trong `main/boards/waveshare/esp32-c6-lcd-0.85`. Key types/methods: `LedStripControl`. |
| `main/boards/waveshare/esp32-c6-lcd-0.85/power_manager.h` | `h` | 6005 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/waveshare/esp32-c6-lcd-0.85`. Key types/methods: `PowerManager`. |
| `main/boards/waveshare/esp32-c6-lcd-1.69/README.md` | `md` | 878 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-c6-lcd-1.69`. Main section: 产品链接. |
| `main/boards/waveshare/esp32-c6-lcd-1.69/config.h` | `h` | 1689 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-c6-lcd-1.69`. |
| `main/boards/waveshare/esp32-c6-lcd-1.69/config.json` | `json` | 226 | tracked | Board/release config: target `esp32c6`, type `esp32-c6-lcd-1.69`, variants: esp32-c6-lcd-1.69. |
| `main/boards/waveshare/esp32-c6-lcd-1.69/esp32-c6-lcd-1.69.cc` | `cc` | 8810 | tracked | Driver hoặc UI/display resource riêng của board `esp32-c6-lcd-1.69.cc` trong `main/boards/waveshare/esp32-c6-lcd-1.69`. Key types/methods: `CustomLcdDisplay`, `CustomButton`, `CustomBoard`. |
| `main/boards/waveshare/esp32-c6-lcd-1.69/power_manager.h` | `h` | 6005 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/waveshare/esp32-c6-lcd-1.69`. Key types/methods: `PowerManager`. |
| `main/boards/waveshare/esp32-c6-touch-amoled-1.32/README.md` | `md` | 613 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-c6-touch-amoled-1.32`. Main section: 产品链接. |
| `main/boards/waveshare/esp32-c6-touch-amoled-1.32/config.h` | `h` | 1141 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-c6-touch-amoled-1.32`. |
| `main/boards/waveshare/esp32-c6-touch-amoled-1.32/config.json` | `json` | 244 | tracked | Board/release config: target `esp32c6`, type `esp32-c6-touch-amoled-1.32`, variants: esp32-c6-touch-amoled-1.32. |
| `main/boards/waveshare/esp32-c6-touch-amoled-1.32/esp32-c6-touch-amoled-1.32.cc` | `cc` | 8918 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32-c6-touch-amoled-1.32.cc` trong `main/boards/waveshare/esp32-c6-touch-amoled-1.32`. Key types/methods: `CustomLcdDisplay`, `CustomBoard`. |
| `main/boards/waveshare/esp32-c6-touch-amoled-1.43/README.md` | `md` | 722 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-c6-touch-amoled-1.43`. Main section: 产品链接. |
| `main/boards/waveshare/esp32-c6-touch-amoled-1.43/config.h` | `h` | 1337 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-c6-touch-amoled-1.43`. |
| `main/boards/waveshare/esp32-c6-touch-amoled-1.43/config.json` | `json` | 244 | tracked | Board/release config: target `esp32c6`, type `esp32-c6-touch-amoled-1.43`, variants: esp32-c6-touch-amoled-1.43. |
| `main/boards/waveshare/esp32-c6-touch-amoled-1.43/esp32-c6-touch-amoled-1.43.cc` | `cc` | 10429 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32-c6-touch-amoled-1.43.cc` trong `main/boards/waveshare/esp32-c6-touch-amoled-1.43`. Key types/methods: `CustomLcdDisplay`, `CustomBoard`. |
| `main/boards/waveshare/esp32-c6-touch-amoled-1.8/README.md` | `md` | 526 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-c6-touch-amoled-1.8`. Main section: Waveshare ESP32-C6-Touch-AMOLED-1.8. |
| `main/boards/waveshare/esp32-c6-touch-amoled-1.8/config.h` | `h` | 1270 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-c6-touch-amoled-1.8`. |
| `main/boards/waveshare/esp32-c6-touch-amoled-1.8/config.json` | `json` | 242 | tracked | Board/release config: target `esp32c6`, type `esp32-c6-touch-amoled-1.8`, variants: esp32-c6-touch-amoled-1.8. |
| `main/boards/waveshare/esp32-c6-touch-amoled-1.8/esp32-c6-touch-amoled-1.8.cc` | `cc` | 12943 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32-c6-touch-amoled-1.8.cc` trong `main/boards/waveshare/esp32-c6-touch-amoled-1.8`. Key types/methods: `Pmic`, `CustomLcdDisplay`, `CustomBacklight`, `WaveshareEsp32c6TouchAMOLED1inch8`. |
| `main/boards/waveshare/esp32-c6-touch-amoled-2.06/README.md` | `md` | 626 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-c6-touch-amoled-2.06`. Main section: Waveshare ESP32-C6-Touch-AMOLED-2.06. |
| `main/boards/waveshare/esp32-c6-touch-amoled-2.06/config.h` | `h` | 1328 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-c6-touch-amoled-2.06`. |
| `main/boards/waveshare/esp32-c6-touch-amoled-2.06/config.json` | `json` | 244 | tracked | Board/release config: target `esp32c6`, type `esp32-c6-touch-amoled-2.06`, variants: esp32-c6-touch-amoled-2.06. |
| `main/boards/waveshare/esp32-c6-touch-amoled-2.06/esp32-c6-touch-amoled-2.06.cc` | `cc` | 11563 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32-c6-touch-amoled-2.06.cc` trong `main/boards/waveshare/esp32-c6-touch-amoled-2.06`. Key types/methods: `Pmic`, `CustomLcdDisplay`, `CustomBacklight`, `WaveshareEsp32c6TouchAMOLED2inch06`. |
| `main/boards/waveshare/esp32-c6-touch-amoled-2.16/README.md` | `md` | 613 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-c6-touch-amoled-2.16`. Main section: 产品链接. |
| `main/boards/waveshare/esp32-c6-touch-amoled-2.16/config.h` | `h` | 1213 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-c6-touch-amoled-2.16`. |
| `main/boards/waveshare/esp32-c6-touch-amoled-2.16/config.json` | `json` | 352 | tracked | Board/release config: target `esp32c6`, type `esp32-c6-touch-amoled-2.16`, variants: esp32-c6-touch-amoled-2.16. |
| `main/boards/waveshare/esp32-c6-touch-amoled-2.16/esp32-c6-touch-amoled-2.16.cc` | `cc` | 12516 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32-c6-touch-amoled-2.16.cc` trong `main/boards/waveshare/esp32-c6-touch-amoled-2.16`. Key types/methods: `Pmic`, `CustomLcdDisplay`, `CustomBacklight`, `WaveshareEsp32c6TouchAMOLED2inch16`. |
| `main/boards/waveshare/esp32-c6-touch-lcd-1.54/README.md` | `md` | 691 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-c6-touch-lcd-1.54`. Main section: 产品链接. |
| `main/boards/waveshare/esp32-c6-touch-lcd-1.54/config.h` | `h` | 1565 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-c6-touch-lcd-1.54`. |
| `main/boards/waveshare/esp32-c6-touch-lcd-1.54/config.json` | `json` | 290 | tracked | Board/release config: target `esp32c6`, type `esp32-c6-touch-lcd-1.54`, variants: esp32-c6-touch-lcd-1.54. |
| `main/boards/waveshare/esp32-c6-touch-lcd-1.54/esp32-c6-touch-lcd-1.54.cc` | `cc` | 10589 | tracked | Driver hoặc UI/display resource riêng của board `esp32-c6-touch-lcd-1.54.cc` trong `main/boards/waveshare/esp32-c6-touch-lcd-1.54`. Key types/methods: `CustomButton`, `CustomBoard`. |
| `main/boards/waveshare/esp32-c6-touch-lcd-1.54/power_manager.h` | `h` | 6815 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/waveshare/esp32-c6-touch-lcd-1.54`. Key types/methods: `PowerManager`. |
| `main/boards/waveshare/esp32-c6-touch-lcd-1.83/README.md` | `md` | 603 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-c6-touch-lcd-1.83`. Main section: 产品链接. |
| `main/boards/waveshare/esp32-c6-touch-lcd-1.83/config.h` | `h` | 1522 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-c6-touch-lcd-1.83`. |
| `main/boards/waveshare/esp32-c6-touch-lcd-1.83/config.json` | `json` | 332 | tracked | Board/release config: target `esp32c6`, type `esp32-c6-touch-lcd-1.83`, variants: esp32-c6-touch-lcd-1.83. |
| `main/boards/waveshare/esp32-c6-touch-lcd-1.83/esp32-c6-touch-lcd-1.83.cc` | `cc` | 9296 | tracked | Driver hoặc UI/display resource riêng của board `esp32-c6-touch-lcd-1.83.cc` trong `main/boards/waveshare/esp32-c6-touch-lcd-1.83`. Key types/methods: `Pmic`, `WaveshareEsp32c6TouchLCD1inch83`. |
| `main/boards/waveshare/esp32-p4-nano/README.md` | `md` | 9679 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-p4-nano`. Main section: Waveshare ESP32-P4-NANO. |
| `main/boards/waveshare/esp32-p4-nano/config.h` | `h` | 1212 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-p4-nano`. |
| `main/boards/waveshare/esp32-p4-nano/config.json` | `json` | 1105 | tracked | Board/release config: target `esp32p4`, type `esp32-p4-nano`, variants: esp32-p4-nano-10.1-a, esp32-p4x-nano-10.1-a. |
| `main/boards/waveshare/esp32-p4-nano/esp32-p4-nano.cc` | `cc` | 10004 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32-p4-nano.cc` trong `main/boards/waveshare/esp32-p4-nano`. Key types/methods: `CustomBacklight`, `WaveshareEsp32p4nano`. |
| `main/boards/waveshare/esp32-p4-nano/lcd_init_cmds.h` | `h` | 7769 | tracked | Driver hoặc UI/display resource riêng của board `lcd_init_cmds.h` trong `main/boards/waveshare/esp32-p4-nano`. |
| `main/boards/waveshare/esp32-p4-wifi6-touch-lcd-3.5/README.md` | `md` | 298 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-p4-wifi6-touch-lcd-3.5`. Main section: Waveshare ESP32-P4-WIFI6-Touch-LCD-3.5. |
| `main/boards/waveshare/esp32-p4-wifi6-touch-lcd-3.5/config.h` | `h` | 1625 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-p4-wifi6-touch-lcd-3.5`. |
| `main/boards/waveshare/esp32-p4-wifi6-touch-lcd-3.5/config.json` | `json` | 1310 | tracked | Board/release config: target `esp32p4`, type `esp32-p4-wifi6-touch-lcd-3.5`, variants: esp32-p4-wifi6-touch-lcd-3.5, esp32-p4x-wifi6-touch-lcd-3.5. |
| `main/boards/waveshare/esp32-p4-wifi6-touch-lcd-3.5/esp32-p4-wifi6-touch-lcd-3.5.cc` | `cc` | 6652 | tracked | Driver hoặc UI/display resource riêng của board `esp32-p4-wifi6-touch-lcd-3.5.cc` trong `main/boards/waveshare/esp32-p4-wifi6-touch-lcd-3.5`. Key types/methods: `WaveshareEsp32p4`. |
| `main/boards/waveshare/esp32-p4-wifi6-touch-lcd/README.md` | `md` | 617 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-p4-wifi6-touch-lcd`. Main section: Waveshare ESP32-P4-WIFI6-Touch-LCD. |
| `main/boards/waveshare/esp32-p4-wifi6-touch-lcd/config.h` | `h` | 3877 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-p4-wifi6-touch-lcd`. |
| `main/boards/waveshare/esp32-p4-wifi6-touch-lcd/config.json` | `json` | 14047 | tracked | Board/release config: target `esp32p4`, type `esp32-p4-wifi6-touch-lcd`, variants: esp32-p4-wifi6-touch-lcd-4b, esp32-p4x-wifi6-touch-lcd-4b, esp32-p4-wifi6-touch-lcd-4.3, esp32-p4x-wifi6-touch-lcd-4.3, esp32-p4-wifi6-touch-lcd-5, esp32-p4x-wifi6-touch-lcd-5, esp32-p4-wifi6-touch-lcd-7b, esp32-p4x-wifi6-touch-lcd-7b, esp32-p4-wifi6-touch-lcd-3.4c, esp32-p4x-wifi6-touch-lcd-3.4c, esp32-p4-wifi6-touch-lcd-4c, esp32-p4x-wifi6-touch-lcd-4c, esp32-p4-wifi6-touch-lcd-7, esp32-p4x-wifi6-touch-lcd-7, esp32-p4-wifi6-touch-lcd-8, esp32-p4x-wifi6-touch-lcd-8, esp32-p4-wifi6-touch-lcd-10.1, esp32-p4x-wifi6-touch-lcd-10.1. |
| `main/boards/waveshare/esp32-p4-wifi6-touch-lcd/esp32-p4-wifi6-touch-lcd.cc` | `cc` | 17888 | tracked | Driver hoặc UI/display resource riêng của board `esp32-p4-wifi6-touch-lcd.cc` trong `main/boards/waveshare/esp32-p4-wifi6-touch-lcd`. Key types/methods: `WaveshareEsp32p4`. |
| `main/boards/waveshare/esp32-p4-wifi6-touch-lcd/lcd_init_cmds.h` | `h` | 40496 | tracked | Driver hoặc UI/display resource riêng của board `lcd_init_cmds.h` trong `main/boards/waveshare/esp32-p4-wifi6-touch-lcd`. |
| `main/boards/waveshare/esp32-s3-audio-board/README.md` | `md` | 117 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-audio-board`. |
| `main/boards/waveshare/esp32-s3-audio-board/config.h` | `h` | 2830 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-audio-board`. |
| `main/boards/waveshare/esp32-s3-audio-board/config.json` | `json` | 790 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-audio-board`, variants: esp32-s3-audio-board. |
| `main/boards/waveshare/esp32-s3-audio-board/esp32-s3-audio_board.cc` | `cc` | 9744 | tracked | Cấu hình hoặc driver audio codec của board `esp32-s3-audio_board.cc` trong `main/boards/waveshare/esp32-s3-audio-board`. Key types/methods: `CustomBoard`. |
| `main/boards/waveshare/esp32-s3-audio-board/esp_lcd_jd9853.c` | `c` | 18213 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_jd9853.c` trong `main/boards/waveshare/esp32-s3-audio-board`. |
| `main/boards/waveshare/esp32-s3-audio-board/esp_lcd_jd9853.h` | `h` | 3887 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_jd9853.h` trong `main/boards/waveshare/esp32-s3-audio-board`. |
| `main/boards/waveshare/esp32-s3-cam/README.md` | `md` | 278 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-cam`. |
| `main/boards/waveshare/esp32-s3-cam/config.h` | `h` | 3343 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-cam`. |
| `main/boards/waveshare/esp32-s3-cam/config.json` | `json` | 1465 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-cam`, variants: esp32-s3-cam-2, esp32-s3-cam-2.8, esp32-s3-cam-3.5, esp32-s3-cam-1.83. |
| `main/boards/waveshare/esp32-s3-cam/esp32-s3-cam-xxxx.cc` | `cc` | 10448 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32-s3-cam-xxxx.cc` trong `main/boards/waveshare/esp32-s3-cam`. Key types/methods: `CustomBacklight`, `CustomBoard`. |
| `main/boards/waveshare/esp32-s3-epaper-1.54/README.md` | `md` | 840 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-epaper-1.54`. Main section: 产品链接. |
| `main/boards/waveshare/esp32-s3-epaper-1.54/board_power_bsp.cc` | `cc` | 1990 | tracked | Quản lý nguồn/pin/charger của board `board_power_bsp.cc` trong `main/boards/waveshare/esp32-s3-epaper-1.54`. Key types/methods: `BoardPowerBsp::PowerLedTask`, `BoardPowerBsp::PowerEpdOn`, `BoardPowerBsp::PowerEpdOff`, `BoardPowerBsp::PowerAudioOn`, `BoardPowerBsp::PowerAudioOff`, `BoardPowerBsp::VbatPowerOn`, `BoardPowerBsp::VbatPowerOff`. |
| `main/boards/waveshare/esp32-s3-epaper-1.54/board_power_bsp.h` | `h` | 482 | tracked | Quản lý nguồn/pin/charger của board `board_power_bsp.h` trong `main/boards/waveshare/esp32-s3-epaper-1.54`. Key types/methods: `BoardPowerBsp`. |
| `main/boards/waveshare/esp32-s3-epaper-1.54/config.h` | `h` | 1277 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-epaper-1.54`. |
| `main/boards/waveshare/esp32-s3-epaper-1.54/config.json` | `json` | 919 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-epaper-1.54`, variants: esp32-s3-epaper-1.54-v2, esp32-s3-epaper-1.54-v1. |
| `main/boards/waveshare/esp32-s3-epaper-1.54/custom_lcd_display.cc` | `cc` | 11901 | tracked | Driver hoặc UI/display resource riêng của board `custom_lcd_display.cc` trong `main/boards/waveshare/esp32-s3-epaper-1.54`. Key types/methods: `CustomLcdDisplay::lvgl_flush_cb`, `CustomLcdDisplay::spi_gpio_init`, `CustomLcdDisplay::spi_port_init`, `CustomLcdDisplay::read_busy`, `CustomLcdDisplay::SPI_SendByte`, `CustomLcdDisplay::EPD_SendData`, `CustomLcdDisplay::EPD_SendCommand`, `CustomLcdDisplay::writeBytes`. |
| `main/boards/waveshare/esp32-s3-epaper-1.54/custom_lcd_display.h` | `h` | 2366 | tracked | Driver hoặc UI/display resource riêng của board `custom_lcd_display.h` trong `main/boards/waveshare/esp32-s3-epaper-1.54`. Key types/methods: `CustomLcdDisplay`. |
| `main/boards/waveshare/esp32-s3-epaper-1.54/waveshare-s3-epaper-1.54.cc` | `cc` | 6128 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `waveshare-s3-epaper-1.54.cc` trong `main/boards/waveshare/esp32-s3-epaper-1.54`. Key types/methods: `CustomBoard`. |
| `main/boards/waveshare/esp32-s3-epaper-3.97/README.md` | `md` | 595 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-epaper-3.97`. Main section: 产品链接. |
| `main/boards/waveshare/esp32-s3-epaper-3.97/config.h` | `h` | 1131 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-epaper-3.97`. |
| `main/boards/waveshare/esp32-s3-epaper-3.97/config.json` | `json` | 283 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-epaper-3.97`, variants: esp32-s3-epaper-3.97. |
| `main/boards/waveshare/esp32-s3-epaper-3.97/custom_lcd_display.cc` | `cc` | 11049 | tracked | Driver hoặc UI/display resource riêng của board `custom_lcd_display.cc` trong `main/boards/waveshare/esp32-s3-epaper-3.97`. Key types/methods: `CustomEpdDisplay::lvgl_flush_cb`, `CustomEpdDisplay::spi_gpio_init`, `CustomEpdDisplay::spi_port_init`, `CustomEpdDisplay::read_busy`, `CustomEpdDisplay::SPI_SendByte`, `CustomEpdDisplay::EPD_SendData`, `CustomEpdDisplay::EPD_SendCommand`, `CustomEpdDisplay::writeBytes`. |
| `main/boards/waveshare/esp32-s3-epaper-3.97/custom_lcd_display.h` | `h` | 2361 | tracked | Driver hoặc UI/display resource riêng của board `custom_lcd_display.h` trong `main/boards/waveshare/esp32-s3-epaper-3.97`. Key types/methods: `CustomEpdDisplay`. |
| `main/boards/waveshare/esp32-s3-epaper-3.97/waveshare-s3-epaper-3.97.cc` | `cc` | 6085 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `waveshare-s3-epaper-3.97.cc` trong `main/boards/waveshare/esp32-s3-epaper-3.97`. Key types/methods: `Pmic`, `WaveshareEsp32s3ePaper3inch97`. |
| `main/boards/waveshare/esp32-s3-lcd-0.85/README.md` | `md` | 769 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-lcd-0.85`. Main section: 产品链接. |
| `main/boards/waveshare/esp32-s3-lcd-0.85/config.h` | `h` | 1608 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-lcd-0.85`. |
| `main/boards/waveshare/esp32-s3-lcd-0.85/config.json` | `json` | 455 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-lcd-0.85`, variants: esp32-s3-lcd-0.85. |
| `main/boards/waveshare/esp32-s3-lcd-0.85/esp32-s3-lcd-0.85.cc` | `cc` | 10597 | tracked | Driver hoặc UI/display resource riêng của board `esp32-s3-lcd-0.85.cc` trong `main/boards/waveshare/esp32-s3-lcd-0.85`. Key types/methods: `CustomButton`, `CustomBoard`. |
| `main/boards/waveshare/esp32-s3-lcd-0.85/led_strip_control.cc` | `cc` | 5594 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `led_strip_control.cc` trong `main/boards/waveshare/esp32-s3-lcd-0.85`. Key types/methods: `LedStripControl::LevelToBrightness`, `LedStripControl::RGBToColor`. |
| `main/boards/waveshare/esp32-s3-lcd-0.85/led_strip_control.h` | `h` | 444 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `led_strip_control.h` trong `main/boards/waveshare/esp32-s3-lcd-0.85`. Key types/methods: `LedStripControl`. |
| `main/boards/waveshare/esp32-s3-lcd-0.85/power_manager.h` | `h` | 6815 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/waveshare/esp32-s3-lcd-0.85`. Key types/methods: `PowerManager`. |
| `main/boards/waveshare/esp32-s3-rgb-matrix/README.md` | `md` | 116 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-rgb-matrix`. |
| `main/boards/waveshare/esp32-s3-rgb-matrix/config.h` | `h` | 1686 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-rgb-matrix`. |
| `main/boards/waveshare/esp32-s3-rgb-matrix/config.json` | `json` | 325 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-rgb-matrix`, variants: esp32-s3-rgb-matrix. |
| `main/boards/waveshare/esp32-s3-rgb-matrix/rgb_matrix_board.cc` | `cc` | 2987 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `rgb_matrix_board.cc` trong `main/boards/waveshare/esp32-s3-rgb-matrix`. Key types/methods: `CustomBoard`, `MatrixBacklight`. |
| `main/boards/waveshare/esp32-s3-rgb-matrix/rgb_matrix_display.cc` | `cc` | 15234 | tracked | Driver hoặc UI/display resource riêng của board `rgb_matrix_display.cc` trong `main/boards/waveshare/esp32-s3-rgb-matrix`. Key types/methods: `Hub75Context`, `MapItem`, `CustomMatrixDisplay::Lock`, `CustomMatrixDisplay::Unlock`, `CustomMatrixDisplay::SetupUI`, `CustomMatrixDisplay::SetEmojiCollection`, `CustomMatrixDisplay::SetEmotion`, `CustomMatrixDisplay::SetChatMessage`. |
| `main/boards/waveshare/esp32-s3-rgb-matrix/rgb_matrix_display.h` | `h` | 1476 | tracked | Driver hoặc UI/display resource riêng của board `rgb_matrix_display.h` trong `main/boards/waveshare/esp32-s3-rgb-matrix`. Key types/methods: `Hub75Context`, `EmojiCollection`, `CustomMatrixDisplay`. |
| `main/boards/waveshare/esp32-s3-rlcd-4.2/README.md` | `md` | 586 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-rlcd-4.2`. Main section: 产品链接. |
| `main/boards/waveshare/esp32-s3-rlcd-4.2/config.h` | `h` | 1196 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-rlcd-4.2`. |
| `main/boards/waveshare/esp32-s3-rlcd-4.2/config.json` | `json` | 320 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-rlcd-4.2`, variants: esp32-s3-rlcd-4.2. |
| `main/boards/waveshare/esp32-s3-rlcd-4.2/custom_lcd_display.cc` | `cc` | 9174 | tracked | Driver hoặc UI/display resource riêng của board `custom_lcd_display.cc` trong `main/boards/waveshare/esp32-s3-rlcd-4.2`. Key types/methods: `CustomLcdDisplay::Lvgl_flush_cb`, `CustomLcdDisplay::InitPortraitLUT`, `CustomLcdDisplay::InitLandscapeLUT`, `CustomLcdDisplay::Set_ResetIOLevel`, `CustomLcdDisplay::RLCD_SendCommand`, `CustomLcdDisplay::RLCD_SendData`, `CustomLcdDisplay::RLCD_Sendbuffera`, `CustomLcdDisplay::RLCD_Reset`. |
| `main/boards/waveshare/esp32-s3-rlcd-4.2/custom_lcd_display.h` | `h` | 1763 | tracked | Driver hoặc UI/display resource riêng của board `custom_lcd_display.h` trong `main/boards/waveshare/esp32-s3-rlcd-4.2`. Key types/methods: `ColorSelection`, `CustomLcdDisplay`. |
| `main/boards/waveshare/esp32-s3-rlcd-4.2/waveshare-s3-rlcd-4.2.cc` | `cc` | 5513 | tracked | Driver hoặc UI/display resource riêng của board `waveshare-s3-rlcd-4.2.cc` trong `main/boards/waveshare/esp32-s3-rlcd-4.2`. Key types/methods: `CustomBoard`. |
| `main/boards/waveshare/esp32-s3-touch-amoled-1.32/README.md` | `md` | 613 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-touch-amoled-1.32`. Main section: 产品链接. |
| `main/boards/waveshare/esp32-s3-touch-amoled-1.32/config.h` | `h` | 1206 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-touch-amoled-1.32`. |
| `main/boards/waveshare/esp32-s3-touch-amoled-1.32/config.json` | `json` | 377 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-touch-amoled-1.32`, variants: esp32-s3-touch-amoled-1.32. |
| `main/boards/waveshare/esp32-s3-touch-amoled-1.32/esp32-s3-touch-amoled-1.32.cc` | `cc` | 8896 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32-s3-touch-amoled-1.32.cc` trong `main/boards/waveshare/esp32-s3-touch-amoled-1.32`. Key types/methods: `CustomLcdDisplay`, `CustomBoard`. |
| `main/boards/waveshare/esp32-s3-touch-amoled-1.43c/README.md` | `md` | 615 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-touch-amoled-1.43c`. Main section: 产品链接. |
| `main/boards/waveshare/esp32-s3-touch-amoled-1.43c/config.h` | `h` | 1387 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-touch-amoled-1.43c`. |
| `main/boards/waveshare/esp32-s3-touch-amoled-1.43c/config.json` | `json` | 379 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-touch-amoled-1.43c`, variants: esp32-s3-touch-amoled-1.43c. |
| `main/boards/waveshare/esp32-s3-touch-amoled-1.43c/esp32-s3-touch-amoled-1.43c.cc` | `cc` | 7942 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32-s3-touch-amoled-1.43c.cc` trong `main/boards/waveshare/esp32-s3-touch-amoled-1.43c`. Key types/methods: `CustomLcdDisplay`, `CustomBoard`. |
| `main/boards/waveshare/esp32-s3-touch-amoled-1.75/README.md` | `md` | 1778 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-touch-amoled-1.75`. Main section: Waveshare ESP32-S3-Touch-AMOLED-1.75. |
| `main/boards/waveshare/esp32-s3-touch-amoled-1.75/config.h` | `h` | 1887 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-touch-amoled-1.75`. |
| `main/boards/waveshare/esp32-s3-touch-amoled-1.75/config.json` | `json` | 706 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-touch-amoled-1.75`, variants: esp32-s3-touch-amoled-1.75, esp32-s3-touch-amoled-1.75c. |
| `main/boards/waveshare/esp32-s3-touch-amoled-1.75/esp32-s3-touch-amoled-1.75.cc` | `cc` | 13248 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32-s3-touch-amoled-1.75.cc` trong `main/boards/waveshare/esp32-s3-touch-amoled-1.75`. Key types/methods: `Pmic`, `CustomLcdDisplay`, `CustomBacklight`, `WaveshareEsp32s3TouchAMOLED1inch75`. |
| `main/boards/waveshare/esp32-s3-touch-amoled-1.8-v2/config.h` | `h` | 1273 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-touch-amoled-1.8-v2`. |
| `main/boards/waveshare/esp32-s3-touch-amoled-1.8-v2/config.json` | `json` | 299 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-touch-amoled-1.8-v2`, variants: esp32-s3-touch-amoled-1.8-v2. |
| `main/boards/waveshare/esp32-s3-touch-amoled-1.8-v2/esp32-s3-touch-amoled-1.8-v2.cc` | `cc` | 15250 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32-s3-touch-amoled-1.8-v2.cc` trong `main/boards/waveshare/esp32-s3-touch-amoled-1.8-v2`. Key types/methods: `Pmic`, `CustomLcdDisplay`, `CustomBacklight`, `WaveshareEsp32s3TouchAMOLED1inch8`. |
| `main/boards/waveshare/esp32-s3-touch-amoled-1.8/config.h` | `h` | 1272 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-touch-amoled-1.8`. |
| `main/boards/waveshare/esp32-s3-touch-amoled-1.8/config.json` | `json` | 293 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-touch-amoled-1.8`, variants: esp32-s3-touch-amoled-1.8. |
| `main/boards/waveshare/esp32-s3-touch-amoled-1.8/esp32-s3-touch-amoled-1.8.cc` | `cc` | 15897 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32-s3-touch-amoled-1.8.cc` trong `main/boards/waveshare/esp32-s3-touch-amoled-1.8`. Key types/methods: `Pmic`, `CustomLcdDisplay`, `CustomBacklight`, `WaveshareEsp32s3TouchAMOLED1inch8`. |
| `main/boards/waveshare/esp32-s3-touch-amoled-2.06/README.md` | `md` | 1227 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-touch-amoled-2.06`. Main section: Waveshare ESP32-S3-Touch-AMOLED-2.06. |
| `main/boards/waveshare/esp32-s3-touch-amoled-2.06/config.h` | `h` | 1303 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-touch-amoled-2.06`. |
| `main/boards/waveshare/esp32-s3-touch-amoled-2.06/config.json` | `json` | 338 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-touch-amoled-2.06`, variants: esp32-s3-touch-amoled-2.06. |
| `main/boards/waveshare/esp32-s3-touch-amoled-2.06/esp32-s3-touch-amoled-2.06.cc` | `cc` | 12917 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32-s3-touch-amoled-2.06.cc` trong `main/boards/waveshare/esp32-s3-touch-amoled-2.06`. Key types/methods: `Pmic`, `CustomLcdDisplay`, `CustomBacklight`, `WaveshareEsp32s3TouchAMOLED2inch06`. |
| `main/boards/waveshare/esp32-s3-touch-amoled-2.16/README.md` | `md` | 1774 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-touch-amoled-2.16`. Main section: Waveshare ESP32-S3-Touch-AMOLED-2.16. |
| `main/boards/waveshare/esp32-s3-touch-amoled-2.16/config.h` | `h` | 1447 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-touch-amoled-2.16`. |
| `main/boards/waveshare/esp32-s3-touch-amoled-2.16/config.json` | `json` | 414 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-touch-amoled-2.16`, variants: esp32-s3-touch-amoled-2.16. |
| `main/boards/waveshare/esp32-s3-touch-amoled-2.16/esp32-s3-touch-amoled-2.16.cc` | `cc` | 13246 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32-s3-touch-amoled-2.16.cc` trong `main/boards/waveshare/esp32-s3-touch-amoled-2.16`. Key types/methods: `Pmic`, `CustomLcdDisplay`, `CustomBacklight`, `WaveshareEsp32s3TouchAMOLED2inch16`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.46/README.md` | `md` | 210 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-touch-lcd-1.46`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.46/config.h` | `h` | 2487 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-touch-lcd-1.46`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.46/config.json` | `json` | 224 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-touch-lcd-1.46`, variants: esp32-s3-touch-lcd-1.46. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.46/esp32-s3-touch-lcd-1.46.cc` | `cc` | 11235 | tracked | Driver hoặc UI/display resource riêng của board `esp32-s3-touch-lcd-1.46.cc` trong `main/boards/waveshare/esp32-s3-touch-lcd-1.46`. Key types/methods: `CustomLcdDisplay`, `CustomBoard`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.54/README.md` | `md` | 691 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-touch-lcd-1.54`. Main section: 产品链接. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.54/config.h` | `h` | 1610 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-touch-lcd-1.54`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.54/config.json` | `json` | 333 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-touch-lcd-1.54`, variants: esp32-s3-touch-lcd-1.54. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.54/esp32-s3-touch-lcd-1.54.cc` | `cc` | 11860 | tracked | Driver hoặc UI/display resource riêng của board `esp32-s3-touch-lcd-1.54.cc` trong `main/boards/waveshare/esp32-s3-touch-lcd-1.54`. Key types/methods: `CustomButton`, `CustomBoard`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.54/power_manager.h` | `h` | 6815 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/waveshare/esp32-s3-touch-lcd-1.54`. Key types/methods: `PowerManager`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.83/README.md` | `md` | 554 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-touch-lcd-1.83`. Main section: Waveshare ESP32-S3-Touch-LCD-1.83. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.83/config.h` | `h` | 1428 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-touch-lcd-1.83`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.83/config.json` | `json` | 332 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-touch-lcd-1.83`, variants: esp32-s3-touch-lcd-1.83. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.83/esp32-s3-touch-lcd-1.83.cc` | `cc` | 9256 | tracked | Driver hoặc UI/display resource riêng của board `esp32-s3-touch-lcd-1.83.cc` trong `main/boards/waveshare/esp32-s3-touch-lcd-1.83`. Key types/methods: `Pmic`, `WaveshareEsp32s3TouchLCD1inch83`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.85/README.md` | `md` | 123 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-touch-lcd-1.85`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.85/config.h` | `h` | 2486 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-touch-lcd-1.85`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.85/config.json` | `json` | 224 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-touch-lcd-1.85`, variants: esp32-s3-touch-lcd-1.85. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.85/esp32-s3-touch-lcd-1.85.cc` | `cc` | 19404 | tracked | Driver hoặc UI/display resource riêng của board `esp32-s3-touch-lcd-1.85.cc` trong `main/boards/waveshare/esp32-s3-touch-lcd-1.85`. Key types/methods: `CustomBoard`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.85b/README.md` | `md` | 125 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-touch-lcd-1.85b`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.85b/config.h` | `h` | 2467 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-touch-lcd-1.85b`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.85b/config.json` | `json` | 335 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-touch-lcd-1.85b`, variants: esp32-s3-touch-lcd-1.85b. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.85b/esp32-s3-touch-lcd-1.85b.cc` | `cc` | 25054 | tracked | Driver hoặc UI/display resource riêng của board `esp32-s3-touch-lcd-1.85b.cc` trong `main/boards/waveshare/esp32-s3-touch-lcd-1.85b`. Key types/methods: `WaveshareEsp32s3TouchLcd1_85B`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.85c/README.md` | `md` | 125 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-touch-lcd-1.85c`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.85c/config.h` | `h` | 3005 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-touch-lcd-1.85c`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.85c/config.json` | `json` | 226 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-touch-lcd-1.85c`, variants: esp32-s3-touch-lcd-1.85c. |
| `main/boards/waveshare/esp32-s3-touch-lcd-1.85c/esp32-s3-touch-lcd-1.85c.cc` | `cc` | 17404 | tracked | Driver hoặc UI/display resource riêng của board `esp32-s3-touch-lcd-1.85c.cc` trong `main/boards/waveshare/esp32-s3-touch-lcd-1.85c`. Key types/methods: `CustomBoard`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.49-v2/README.md` | `md` | 356 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-touch-lcd-3.49-v2`. Main section: Waveshare ESP32-S3-Touch-LCD-3.49 V2. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.49-v2/config.h` | `h` | 1739 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-touch-lcd-3.49-v2`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.49-v2/config.json` | `json` | 339 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-touch-lcd-3.49-v2`, variants: esp32-s3-touch-lcd-3.49-v2. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.49-v2/custom_lcd_display.cc` | `cc` | 5335 | tracked | Driver hoặc UI/display resource riêng của board `custom_lcd_display.cc` trong `main/boards/waveshare/esp32-s3-touch-lcd-3.49-v2`. Key types/methods: `CustomLcdDisplay::lvgl_port_flush_io_ready_callback`, `CustomLcdDisplay::lvgl_port_flush_callback`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.49-v2/custom_lcd_display.h` | `h` | 681 | tracked | Driver hoặc UI/display resource riêng của board `custom_lcd_display.h` trong `main/boards/waveshare/esp32-s3-touch-lcd-3.49-v2`. Key types/methods: `CustomLcdDisplay`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.49-v2/waveshare-s3-touch-lcd-3.49-v2.cc` | `cc` | 9490 | tracked | Driver hoặc UI/display resource riêng của board `waveshare-s3-touch-lcd-3.49-v2.cc` trong `main/boards/waveshare/esp32-s3-touch-lcd-3.49-v2`. Key types/methods: `CustomBoard`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.49/README.md` | `md` | 123 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-touch-lcd-3.49`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.49/config.h` | `h` | 1738 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-touch-lcd-3.49`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.49/config.json` | `json` | 332 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-touch-lcd-3.49`, variants: esp32-s3-touch-lcd-3.49. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.49/custom_lcd_display.cc` | `cc` | 5338 | tracked | Driver hoặc UI/display resource riêng của board `custom_lcd_display.cc` trong `main/boards/waveshare/esp32-s3-touch-lcd-3.49`. Key types/methods: `CustomLcdDisplay::lvgl_port_flush_io_ready_callback`, `CustomLcdDisplay::lvgl_port_flush_callback`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.49/custom_lcd_display.h` | `h` | 680 | tracked | Driver hoặc UI/display resource riêng của board `custom_lcd_display.h` trong `main/boards/waveshare/esp32-s3-touch-lcd-3.49`. Key types/methods: `CustomLcdDisplay`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.49/waveshare-s3-touch-lcd-3.49.cc` | `cc` | 9286 | tracked | Driver hoặc UI/display resource riêng của board `waveshare-s3-touch-lcd-3.49.cc` trong `main/boards/waveshare/esp32-s3-touch-lcd-3.49`. Key types/methods: `CustomBoard`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.5/README.md` | `md` | 121 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-touch-lcd-3.5`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.5/config.h` | `h` | 2092 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-touch-lcd-3.5`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.5/config.json` | `json` | 794 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-touch-lcd-3.5`, variants: esp32-s3-touch-lcd-3.5. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.5/esp32-s3-touch-lcd-3.5.cc` | `cc` | 13792 | tracked | Driver hoặc UI/display resource riêng của board `esp32-s3-touch-lcd-3.5.cc` trong `main/boards/waveshare/esp32-s3-touch-lcd-3.5`. Key types/methods: `Pmic`, `CustomBoard`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.5b/README.md` | `md` | 123 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-touch-lcd-3.5b`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.5b/config.h` | `h` | 2307 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-touch-lcd-3.5b`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.5b/config.json` | `json` | 796 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-touch-lcd-3.5b`, variants: esp32-s3-touch-lcd-3.5b. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.5b/custom_lcd_display.cc` | `cc` | 11004 | tracked | Driver hoặc UI/display resource riêng của board `custom_lcd_display.cc` trong `main/boards/waveshare/esp32-s3-touch-lcd-3.5b`. Key types/methods: `CustomLcdDisplay::lvgl_port_flush_io_ready_callback`, `CustomLcdDisplay::lvgl_port_flush_callback`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.5b/custom_lcd_display.h` | `h` | 682 | tracked | Driver hoặc UI/display resource riêng của board `custom_lcd_display.h` trong `main/boards/waveshare/esp32-s3-touch-lcd-3.5b`. Key types/methods: `CustomLcdDisplay`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-3.5b/waveshare-s3-touch-lcd-3.5b.cc` | `cc` | 15737 | tracked | Driver hoặc UI/display resource riêng của board `waveshare-s3-touch-lcd-3.5b.cc` trong `main/boards/waveshare/esp32-s3-touch-lcd-3.5b`. Key types/methods: `Pmic`, `CustomBoard`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-4.3c/README.md` | `md` | 757 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-touch-lcd-4.3c`. Main section: 使用说明. |
| `main/boards/waveshare/esp32-s3-touch-lcd-4.3c/config.h` | `h` | 2947 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-touch-lcd-4.3c`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-4.3c/config.json` | `json` | 449 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-touch-lcd-4.3c`, variants: esp32-s3-touch-lcd-4.3c. |
| `main/boards/waveshare/esp32-s3-touch-lcd-4.3c/esp32_s3_touch_lcd_4.3c.cc` | `cc` | 8679 | tracked | Driver hoặc UI/display resource riêng của board `esp32_s3_touch_lcd_4.3c.cc` trong `main/boards/waveshare/esp32-s3-touch-lcd-4.3c`. Key types/methods: `CustomBacklight`, `WaveshareEsp32s3TouchLCD43c`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-4b/README.md` | `md` | 387 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-s3-touch-lcd-4b`. Main section: Waveshare ESP32-S3-Touch-LCD-4B. |
| `main/boards/waveshare/esp32-s3-touch-lcd-4b/config.h` | `h` | 2067 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-touch-lcd-4b`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-4b/config.json` | `json` | 328 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-touch-lcd-4b`, variants: esp32-s3-touch-lcd-4b. |
| `main/boards/waveshare/esp32-s3-touch-lcd-4b/esp32-s3-touch-lcd-4b.cc` | `cc` | 16428 | tracked | Driver hoặc UI/display resource riêng của board `esp32-s3-touch-lcd-4b.cc` trong `main/boards/waveshare/esp32-s3-touch-lcd-4b`. Key types/methods: `Pmic`, `WaveshareEsp32s3TouchLCD4b`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-7c/config.h` | `h` | 2978 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-s3-touch-lcd-7c`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-7c/config.json` | `json` | 580 | tracked | Board/release config: target `esp32s3`, type `esp32-s3-touch-lcd-7c`, variants: esp32-s3-touch-lcd-7c. |
| `main/boards/waveshare/esp32-s3-touch-lcd-7c/esp32_s3_touch_lcd_7c.cc` | `cc` | 10664 | tracked | Driver hoặc UI/display resource riêng của board `esp32_s3_touch_lcd_7c.cc` trong `main/boards/waveshare/esp32-s3-touch-lcd-7c`. Key types/methods: `CustomBacklight`, `WaveshareEsp32s3TouchLCD7c`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-7c/waveshare_audio_codec.cc` | `cc` | 9803 | tracked | Cấu hình hoặc driver audio codec của board `waveshare_audio_codec.cc` trong `main/boards/waveshare/esp32-s3-touch-lcd-7c`. Key types/methods: `WaveshareAudioCodec::CreateDuplexChannels`, `WaveshareAudioCodec::SetOutputVolume`, `WaveshareAudioCodec::EnableInput`, `WaveshareAudioCodec::EnableOutput`, `WaveshareAudioCodec::Read`, `WaveshareAudioCodec::Write`. |
| `main/boards/waveshare/esp32-s3-touch-lcd-7c/waveshare_audio_codec.h` | `h` | 1526 | tracked | Cấu hình hoặc driver audio codec của board `waveshare_audio_codec.h` trong `main/boards/waveshare/esp32-s3-touch-lcd-7c`. Key types/methods: `WaveshareAudioCodec`. |
| `main/boards/waveshare/esp32-touch-lcd-3.5/README.md` | `md` | 115 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/waveshare/esp32-touch-lcd-3.5`. |
| `main/boards/waveshare/esp32-touch-lcd-3.5/config.h` | `h` | 1564 | tracked | Pin map và compile-time hardware options cho board `main/boards/waveshare/esp32-touch-lcd-3.5`. |
| `main/boards/waveshare/esp32-touch-lcd-3.5/config.json` | `json` | 178 | tracked | Board/release config: target `esp32`, type `esp32-touch-lcd-3.5`, variants: esp32-touch-lcd-3.5. |
| `main/boards/waveshare/esp32-touch-lcd-3.5/esp32-touch-lcd-3.5.cc` | `cc` | 12757 | tracked | Driver hoặc UI/display resource riêng của board `esp32-touch-lcd-3.5.cc` trong `main/boards/waveshare/esp32-touch-lcd-3.5`. Key types/methods: `Pmic`, `WaveshareEsp32TouchLCD3inch5`. |
| `main/boards/wdmomo/esp32-cgc-144/README.md` | `md` | 686 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/wdmomo/esp32-cgc-144`. Main section: 相关资料：. |
| `main/boards/wdmomo/esp32-cgc-144/config.h` | `h` | 1984 | tracked | Pin map và compile-time hardware options cho board `main/boards/wdmomo/esp32-cgc-144`. |
| `main/boards/wdmomo/esp32-cgc-144/config.json` | `json` | 213 | tracked | Board/release config: target `esp32`, type `esp32-cgc-144`, variants: esp32-cgc-144. |
| `main/boards/wdmomo/esp32-cgc-144/esp32_cgc_144_board.cc` | `cc` | 6464 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32_cgc_144_board.cc` trong `main/boards/wdmomo/esp32-cgc-144`. Key types/methods: `ESP32_CGC_144`. |
| `main/boards/wdmomo/esp32-cgc-144/power_manager.h` | `h` | 6007 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/wdmomo/esp32-cgc-144`. Key types/methods: `PowerManager`. |
| `main/boards/wdmomo/esp32-cgc-144/power_manager_lite.h` | `h` | 6018 | tracked | Quản lý nguồn/pin/charger của board `power_manager_lite.h` trong `main/boards/wdmomo/esp32-cgc-144`. Key types/methods: `PowerManager`. |
| `main/boards/wdmomo/esp32-cgc/README.md` | `md` | 820 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/wdmomo/esp32-cgc`. Main section: 主板开源地址：. |
| `main/boards/wdmomo/esp32-cgc/config.h` | `h` | 7793 | tracked | Pin map và compile-time hardware options cho board `main/boards/wdmomo/esp32-cgc`. |
| `main/boards/wdmomo/esp32-cgc/config.json` | `json` | 251 | tracked | Board/release config: target `esp32`, type `esp32-cgc`, variants: esp32-cgc. |
| `main/boards/wdmomo/esp32-cgc/esp32_cgc_board.cc` | `cc` | 6285 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `esp32_cgc_board.cc` trong `main/boards/wdmomo/esp32-cgc`. Key types/methods: `ESP32_CGC`. |
| `main/boards/wk-esp32s3-dev/README.md` | `md` | 1110 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/wk-esp32s3-dev`. Main section: WK ESP32-S3 Dev Board（维控智能 ESP32-S3 开发板）. |
| `main/boards/wk-esp32s3-dev/config.h` | `h` | 11641 | tracked | Pin map và compile-time hardware options cho board `main/boards/wk-esp32s3-dev`. |
| `main/boards/wk-esp32s3-dev/config.json` | `json` | 138 | tracked | Board/release config: target `esp32s3`, type `wk-esp32s3-dev`, variants: wk-esp32s3-dev. |
| `main/boards/wk-esp32s3-dev/esp_lcd_ili9486.c` | `c` | 14569 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_ili9486.c` trong `main/boards/wk-esp32s3-dev`. |
| `main/boards/wk-esp32s3-dev/esp_lcd_ili9486.h` | `h` | 3895 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_ili9486.h` trong `main/boards/wk-esp32s3-dev`. |
| `main/boards/wk-esp32s3-dev/esp_lcd_nv3030b.c` | `c` | 14216 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_nv3030b.c` trong `main/boards/wk-esp32s3-dev`. |
| `main/boards/wk-esp32s3-dev/esp_lcd_nv3030b.h` | `h` | 3826 | tracked | Driver hoặc UI/display resource riêng của board `esp_lcd_nv3030b.h` trong `main/boards/wk-esp32s3-dev`. |
| `main/boards/wk-esp32s3-dev/wk-esp32s3-dev.cc` | `cc` | 11402 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `wk-esp32s3-dev.cc` trong `main/boards/wk-esp32s3-dev`. Key types/methods: `WkEsp32s3Dev`. |
| `main/boards/xmini/c3-4g/README.md` | `md` | 60 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/xmini/c3-4g`. Main section: 开源地址. |
| `main/boards/xmini/c3-4g/config.h` | `h` | 874 | tracked | Pin map và compile-time hardware options cho board `main/boards/xmini/c3-4g`. |
| `main/boards/xmini/c3-4g/config.json` | `json` | 492 | tracked | Board/release config: target `esp32c3`, type `xmini-c3-4g`, variants: xmini-c3-4g. |
| `main/boards/xmini/c3-4g/xmini_c3_4g_board.cc` | `cc` | 7097 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `xmini_c3_4g_board.cc` trong `main/boards/xmini/c3-4g`. Key types/methods: `XminiC3Board`. |
| `main/boards/xmini/c3-v3/README.md` | `md` | 57 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/xmini/c3-v3`. Main section: 开源地址. |
| `main/boards/xmini/c3-v3/config.h` | `h` | 773 | tracked | Pin map và compile-time hardware options cho board `main/boards/xmini/c3-v3`. |
| `main/boards/xmini/c3-v3/config.json` | `json` | 358 | tracked | Board/release config: target `esp32c3`, type `xmini-c3-v3`, variants: xmini-c3-v3. |
| `main/boards/xmini/c3-v3/xmini_c3_board.cc` | `cc` | 6909 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `xmini_c3_board.cc` trong `main/boards/xmini/c3-v3`. Key types/methods: `XminiC3Board`. |
| `main/boards/xmini/c3/config.h` | `h` | 774 | tracked | Pin map và compile-time hardware options cho board `main/boards/xmini/c3`. |
| `main/boards/xmini/c3/config.json` | `json` | 352 | tracked | Board/release config: target `esp32c3`, type `xmini-c3`, variants: xmini-c3. |
| `main/boards/xmini/c3/xmini_c3_board.cc` | `cc` | 7582 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `xmini_c3_board.cc` trong `main/boards/xmini/c3`. Key types/methods: `XminiC3Board`. |
| `main/boards/xorigin/aipi-lite/README.md` | `md` | 1030 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/xorigin/aipi-lite`. Main section: 编译命令. |
| `main/boards/xorigin/aipi-lite/README_en.md` | `md` | 1231 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/xorigin/aipi-lite`. Main section: Build Instructions. |
| `main/boards/xorigin/aipi-lite/aipi-lite.cc` | `cc` | 8754 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `aipi-lite.cc` trong `main/boards/xorigin/aipi-lite`. Key types/methods: `AIPILite`. |
| `main/boards/xorigin/aipi-lite/config.h` | `h` | 1557 | tracked | Pin map và compile-time hardware options cho board `main/boards/xorigin/aipi-lite`. |
| `main/boards/xorigin/aipi-lite/config.json` | `json` | 159 | tracked | Board/release config: target `esp32s3`, type `aipi-lite`, variants: aipi-lite. |
| `main/boards/xorigin/aipi-lite/power_manager.h` | `h` | 6142 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/xorigin/aipi-lite`. Key types/methods: `PowerManager`. |
| `main/boards/yunliao-s3/README.md` | `md` | 3026 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/yunliao-s3`. Main section: 小智云聊 S3. |
| `main/boards/yunliao-s3/config.h` | `h` | 2019 | tracked | Pin map và compile-time hardware options cho board `main/boards/yunliao-s3`. |
| `main/boards/yunliao-s3/config.json` | `json` | 220 | tracked | Board/release config: target `esp32s3`, type `yunliao-s3`, variants: yunliao-s3. |
| `main/boards/yunliao-s3/power_manager.cc` | `cc` | 7895 | tracked | Quản lý nguồn/pin/charger của board `power_manager.cc` trong `main/boards/yunliao-s3`. Key types/methods: `PowerManager::Initialize`, `PowerManager::CheckBatteryStatus`, `PowerManager::IsCharging`, `PowerManager::IsDischarging`, `PowerManager::IsChargingDone`, `PowerManager::GetBatteryLevel`, `PowerManager::OnChargingStatusChanged`, `PowerManager::OnChargingStatusDisChanged`. |
| `main/boards/yunliao-s3/power_manager.h` | `h` | 1247 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/yunliao-s3`. Key types/methods: `PowerManager`. |
| `main/boards/yunliao-s3/yunliao_s3.cc` | `cc` | 11514 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `yunliao_s3.cc` trong `main/boards/yunliao-s3`. Key types/methods: `YunliaoDisplay`, `YunliaoS3`. |
| `main/boards/zectrix/zectrix-s3-epaper-4.2/board_power_bsp.cc` | `cc` | 4905 | tracked | Quản lý nguồn/pin/charger của board `board_power_bsp.cc` trong `main/boards/zectrix/zectrix-s3-epaper-4.2`. Key types/methods: `BoardPowerBsp::PowerLedTask`, `BoardPowerBsp::PowerEpdOn`, `BoardPowerBsp::PowerEpdOff`, `BoardPowerBsp::PowerAmpOn`, `BoardPowerBsp::PowerAmpOff`, `BoardPowerBsp::PowerAudioOn`, `BoardPowerBsp::PowerAudioOff`, `BoardPowerBsp::VbatPowerOn`. |
| `main/boards/zectrix/zectrix-s3-epaper-4.2/board_power_bsp.h` | `h` | 916 | tracked | Quản lý nguồn/pin/charger của board `board_power_bsp.h` trong `main/boards/zectrix/zectrix-s3-epaper-4.2`. Key types/methods: `ChargeStatus`, `BoardPowerBsp`. |
| `main/boards/zectrix/zectrix-s3-epaper-4.2/charge_status.cc` | `cc` | 3649 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `charge_status.cc` trong `main/boards/zectrix/zectrix-s3-epaper-4.2`. Key types/methods: `ChargeStatus::Init`, `ChargeStatus::OnStateChanged`, `ChargeStatus::Tick`, `ChargeStatus::UpdateSnapshot`, `ChargeStatus::Pack`, `ChargeStatus::Unpack`, `ChargeStatus::Get`. |
| `main/boards/zectrix/zectrix-s3-epaper-4.2/charge_status.h` | `h` | 1372 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `charge_status.h` trong `main/boards/zectrix/zectrix-s3-epaper-4.2`. Key types/methods: `ChargeStatus`, `State`, `Snapshot`. |
| `main/boards/zectrix/zectrix-s3-epaper-4.2/config.h` | `h` | 1839 | tracked | Pin map và compile-time hardware options cho board `main/boards/zectrix/zectrix-s3-epaper-4.2`. |
| `main/boards/zectrix/zectrix-s3-epaper-4.2/config.json` | `json` | 301 | tracked | Board/release config: target `esp32s3`, type `zectrix-s3-epaper-4.2`, variants: zectrix-s3-epaper-4.2. |
| `main/boards/zectrix/zectrix-s3-epaper-4.2/custom_lcd_display.cc` | `cc` | 34534 | tracked | Driver hoặc UI/display resource riêng của board `custom_lcd_display.cc` trong `main/boards/zectrix/zectrix-s3-epaper-4.2`. Key types/methods: `FrameDiffResult`, `CustomLcdDisplay::lvgl_flush_cb`, `CustomLcdDisplay::start_refresh_task`, `CustomLcdDisplay::stop_refresh_task`, `CustomLcdDisplay::UpdateDisplayBusyLocked`, `CustomLcdDisplay::CheckRefreshIdleLocked`, `CustomLcdDisplay::IsRefreshPending`, `CustomLcdDisplay::RequestUrgentRefresh`. |
| `main/boards/zectrix/zectrix-s3-epaper-4.2/custom_lcd_display.h` | `h` | 4243 | tracked | Driver hoặc UI/display resource riêng của board `custom_lcd_display.h` trong `main/boards/zectrix/zectrix-s3-epaper-4.2`. Key types/methods: `TextItem`, `CustomLcdDisplay`. |
| `main/boards/zectrix/zectrix-s3-epaper-4.2/i2c_power_hook.cc` | `cc` | 252 | tracked | Quản lý nguồn/pin/charger của board `i2c_power_hook.cc` trong `main/boards/zectrix/zectrix-s3-epaper-4.2`. |
| `main/boards/zectrix/zectrix-s3-epaper-4.2/rtc_pcf8563.cc` | `cc` | 5701 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `rtc_pcf8563.cc` trong `main/boards/zectrix/zectrix-s3-epaper-4.2`. Key types/methods: `RtcPcf8563::Init`, `RtcPcf8563::SetTime`, `RtcPcf8563::GetTime`, `RtcPcf8563::SetAlarm`, `RtcPcf8563::DisableAlarm`, `RtcPcf8563::ClearAlarmFlag`, `RtcPcf8563::EnableInterrupt`, `RtcPcf8563::IsAlarmFired`. |
| `main/boards/zectrix/zectrix-s3-epaper-4.2/rtc_pcf8563.h` | `h` | 1107 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `rtc_pcf8563.h` trong `main/boards/zectrix/zectrix-s3-epaper-4.2`. Key types/methods: `RtcPcf8563`. |
| `main/boards/zectrix/zectrix-s3-epaper-4.2/sleep_manager_compat.h` | `h` | 512 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `sleep_manager_compat.h` trong `main/boards/zectrix/zectrix-s3-epaper-4.2`. Key types/methods: `SleepBusySrc`. |
| `main/boards/zectrix/zectrix-s3-epaper-4.2/zectrix-s3-epaper-4.2.cc` | `cc` | 12531 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `zectrix-s3-epaper-4.2.cc` trong `main/boards/zectrix/zectrix-s3-epaper-4.2`. Key types/methods: `CustomBoard`. |
| `main/boards/zectrix/zectrix-s3-epaper-4.2/zectrix_nfc.cc` | `cc` | 22321 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `zectrix_nfc.cc` trong `main/boards/zectrix/zectrix-s3-epaper-4.2`. Key types/methods: `ZectrixNfc::Init`, `ZectrixNfc::PowerOn`, `ZectrixNfc::PowerOff`, `ZectrixNfc::IsPowered`, `ZectrixNfc::HasField`, `ZectrixNfc::SetFieldCallback`, `ZectrixNfc::ReadBlock`, `ZectrixNfc::WriteBlock`. |
| `main/boards/zectrix/zectrix-s3-epaper-4.2/zectrix_nfc.h` | `h` | 3351 | tracked | Interface/helper riêng của board hoặc driver peripheral; đọc nơi được include `zectrix_nfc.h` trong `main/boards/zectrix/zectrix-s3-epaper-4.2`. Key types/methods: `ZectrixNfc`. |
| `main/boards/zhengchen/1.54tft-ml307/README.md` | `md` | 506 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/zhengchen/1.54tft-ml307`. Main section: 产品相关介绍网址. |
| `main/boards/zhengchen/1.54tft-ml307/config.h` | `h` | 1129 | tracked | Pin map và compile-time hardware options cho board `main/boards/zhengchen/1.54tft-ml307`. |
| `main/boards/zhengchen/1.54tft-ml307/config.json` | `json` | 224 | tracked | Board/release config: target `esp32s3`, type `zhengchen-1.54tft-ml307`, variants: zhengchen-1.54tft-ml307. |
| `main/boards/zhengchen/1.54tft-ml307/zhengchen-1.54tft-ml307.cc` | `cc` | 7769 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `zhengchen-1.54tft-ml307.cc` trong `main/boards/zhengchen/1.54tft-ml307`. Key types/methods: `ZHENGCHEN_1_54TFT_ML307`. |
| `main/boards/zhengchen/1.54tft-wifi/README.md` | `md` | 505 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/zhengchen/1.54tft-wifi`. Main section: 产品相关介绍网址. |
| `main/boards/zhengchen/1.54tft-wifi/config.h` | `h` | 1062 | tracked | Pin map và compile-time hardware options cho board `main/boards/zhengchen/1.54tft-wifi`. |
| `main/boards/zhengchen/1.54tft-wifi/config.json` | `json` | 222 | tracked | Board/release config: target `esp32s3`, type `zhengchen-1.54tft-wifi`, variants: zhengchen-1.54tft-wifi. |
| `main/boards/zhengchen/1.54tft-wifi/power_manager.h` | `h` | 8001 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/zhengchen/1.54tft-wifi`. Key types/methods: `PowerManager`. |
| `main/boards/zhengchen/1.54tft-wifi/zhengchen-1.54tft-wifi.cc` | `cc` | 8188 | tracked | Tích hợp mạng riêng của board `zhengchen-1.54tft-wifi.cc` trong `main/boards/zhengchen/1.54tft-wifi`. Key types/methods: `ZHENGCHEN_1_54TFT_WIFI`. |
| `main/boards/zhengchen/1.54tft-wifi/zhengchen_lcd_display.h` | `h` | 2301 | tracked | Driver hoặc UI/display resource riêng của board `zhengchen_lcd_display.h` trong `main/boards/zhengchen/1.54tft-wifi`. Key types/methods: `ZHENGCHEN_LcdDisplay`. |
| `main/boards/zhengchen/cam-ml307/README.md` | `md` | 1240 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/zhengchen/cam-ml307`. Main section: 产品相关介绍网址. |
| `main/boards/zhengchen/cam-ml307/config.h` | `h` | 1796 | tracked | Pin map và compile-time hardware options cho board `main/boards/zhengchen/cam-ml307`. |
| `main/boards/zhengchen/cam-ml307/config.json` | `json` | 534 | tracked | Board/release config: target `esp32s3`, type `zhengchen-cam-ml307`, variants: zhengchen-cam-ml307. |
| `main/boards/zhengchen/cam-ml307/mcp_controller.cc` | `cc` | 3136 | tracked | Điều khiển chức năng robot/peripheral riêng của board `mcp_controller.cc` trong `main/boards/zhengchen/cam-ml307`. Key types/methods: `MCPController`. |
| `main/boards/zhengchen/cam-ml307/power_manager.h` | `h` | 7966 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/zhengchen/cam-ml307`. Key types/methods: `PowerManager`. |
| `main/boards/zhengchen/cam-ml307/zhengchen_cam_board_ml307.cc` | `cc` | 11910 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `zhengchen_cam_board_ml307.cc` trong `main/boards/zhengchen/cam-ml307`. Key types/methods: `Pca9557`, `CustomAudioCodec`, `ZhengchenCamBoard_ML307`. |
| `main/boards/zhengchen/cam/README.md` | `md` | 1198 | tracked | Hướng dẫn/phần cứng/build notes cho board `main/boards/zhengchen/cam`. Main section: 产品相关介绍网址. |
| `main/boards/zhengchen/cam/config.h` | `h` | 1730 | tracked | Pin map và compile-time hardware options cho board `main/boards/zhengchen/cam`. |
| `main/boards/zhengchen/cam/config.json` | `json` | 522 | tracked | Board/release config: target `esp32s3`, type `zhengchen-cam`, variants: zhengchen-cam. |
| `main/boards/zhengchen/cam/mcp_controller.cc` | `cc` | 3136 | tracked | Điều khiển chức năng robot/peripheral riêng của board `mcp_controller.cc` trong `main/boards/zhengchen/cam`. Key types/methods: `MCPController`. |
| `main/boards/zhengchen/cam/power_manager.h` | `h` | 7966 | tracked | Quản lý nguồn/pin/charger của board `power_manager.h` trong `main/boards/zhengchen/cam`. Key types/methods: `PowerManager`. |
| `main/boards/zhengchen/cam/zhengchen_cam_board.cc` | `cc` | 11508 | tracked | Triển khai board và kết nối phần cứng cụ thể qua các Board interface `zhengchen_cam_board.cc` trong `main/boards/zhengchen/cam`. Key types/methods: `Pca9557`, `CustomAudioCodec`, `ZhengchenCamBoard`. |
| `main/cjson_utils.h` | `h` | 544 | tracked | Helper truy cập/serialize JSON với cJSON. Key types/methods: `CJsonDeleter`, `CJsonStringDeleter`. |
| `main/device_state.h` | `h` | 427 | tracked | Enum và type trạng thái thiết bị. Key types/methods: `DeviceState`. |
| `main/device_state_machine.cc` | `cc` | 5221 | tracked | Quy tắc và thực thi chuyển trạng thái hợp lệ. Key types/methods: `DeviceStateMachine::GetStateName`, `DeviceStateMachine::IsValidTransition`, `DeviceStateMachine::CanTransitionTo`, `DeviceStateMachine::TransitionTo`, `DeviceStateMachine::AddStateChangeListener`, `DeviceStateMachine::RemoveStateChangeListener`, `DeviceStateMachine::NotifyStateChange`. |
| `main/device_state_machine.h` | `h` | 2283 | tracked | Giao diện state machine và callback state change. Key types/methods: `DeviceStateMachine`. |
| `main/display/display.cc` | `cc` | 1432 | tracked | Hành vi cơ sở và helper dùng chung của Display. Key types/methods: `Display::SetPreviewImage`, `Display::SetStatus`, `Display::ShowNotification`, `Display::UpdateStatusBar`, `Display::SetEmotion`, `Display::SetChatMessage`, `Display::ClearChatMessages`, `Display::SetTheme`. |
| `main/display/display.h` | `h` | 3966 | tracked | Interface display và optional GUI operations. Key types/methods: `LvglFont`, `LvglImage`, `Theme`, `Display`, `DisplayLockGuard`, `NoDisplay`. |
| `main/display/emote_display.cc` | `cc` | 8442 | tracked | UI hiển thị trạng thái/emote. Key types/methods: `EmoteDisplay`, `EmoteDisplay::SetEmotion`, `EmoteDisplay::SetChatMessage`, `EmoteDisplay::SetStatus`, `EmoteDisplay::ShowNotification`, `EmoteDisplay::UpdateStatusBar`, `EmoteDisplay::SetPowerSaveMode`, `EmoteDisplay::SetPreviewImage`. |
| `main/display/emote_display.h` | `h` | 1607 | tracked | Interface/path hiển thị kiểu emote. Key types/methods: `EmoteDisplay`. |
| `main/display/epd_display/epd_display.cc` | `cc` | 10382 | tracked | Interface/driver màn hình giấy điện tử. Key types/methods: `EpdDisplay::lvgl_flush_cb`, `EpdDisplay::Initialize`, `EpdDisplay::spi_gpio_init`, `EpdDisplay::spi_port_init`, `EpdDisplay::read_busy`, `EpdDisplay::SPI_SendByte`, `EpdDisplay::EPD_SendData`, `EpdDisplay::EPD_SendCommand`. |
| `main/display/epd_display/epd_display.h` | `h` | 2704 | tracked | Interface/driver màn hình giấy điện tử. Key types/methods: `COLOR_IMAGE`, `custom_lcd_spi_t`, `EpdDisplay`, `Waveform`. |
| `main/display/epd_display/epd_display_2_9.cc` | `cc` | 799 | tracked | Interface/driver màn hình giấy điện tử. Key types/methods: `EpdDisplay_2_9::GetFullWaveform`, `EpdDisplay_2_9::GetPartialWaveform`. |
| `main/display/epd_display/epd_display_2_9.h` | `h` | 438 | tracked | Interface/driver màn hình giấy điện tử. Key types/methods: `EpdDisplay_2_9`. |
| `main/display/lcd_display.cc` | `cc` | 58398 | tracked | Display interface hoặc implementation LCD/OLED/LVGL/emote. Key types/methods: `LcdDisplay::InitializeLcdThemes`, `LcdDisplay::Lock`, `LcdDisplay::Unlock`, `LcdDisplay::SetupUI`, `LcdDisplay::SetChatMessage`, `LcdDisplay::SetPreviewImage`, `LcdDisplay::RemoveChatMessage`, `LcdDisplay::ClearChatMessages`. |
| `main/display/lcd_display.h` | `h` | 2869 | tracked | Display interface hoặc implementation LCD/OLED/LVGL/emote. Key types/methods: `LcdDisplay`, `SpiLcdDisplay`, `RgbLcdDisplay`, `MipiLcdDisplay`. |
| `main/display/lvgl_display/dynamic_glyph_cache.cc` | `cc` | 6194 | tracked | Font, text glyph hoặc glyph cache logic của LVGL. Key types/methods: `Range`, `DynamicGlyphCache::EnsureFont`, `DynamicGlyphCache::BitmapBytes`, `DynamicGlyphCache::AddGlyphs`, `DynamicGlyphCache::Clear`, `DynamicGlyphCache::Rebuild`. |
| `main/display/lvgl_display/dynamic_glyph_cache.h` | `h` | 1229 | tracked | Font, text glyph hoặc glyph cache logic của LVGL. Key types/methods: `DynamicGlyphCache`, `Entry`. |
| `main/display/lvgl_display/emoji_collection.cc` | `cc` | 647 | tracked | Chọn/load emoji collection cho LVGL display. Key types/methods: `EmojiCollection::AddEmoji`, `EmojiCollection::GetEmojiImage`. |
| `main/display/lvgl_display/emoji_collection.h` | `h` | 466 | tracked | Chọn/load emoji collection cho LVGL display. Key types/methods: `EmojiCollection`. |
| `main/display/lvgl_display/gif/LICENSE.txt` | `txt` | 130 | tracked | Image/JPEG/GIF decoding/rendering cho LVGL. |
| `main/display/lvgl_display/gif/README.md` | `md` | 368 | tracked | Image/JPEG/GIF decoding/rendering cho LVGL. Main section: 说明 / Description. |
| `main/display/lvgl_display/gif/gifdec.c` | `c` | 22702 | tracked | Image/JPEG/GIF decoding/rendering cho LVGL. |
| `main/display/lvgl_display/gif/gifdec.h` | `h` | 1373 | tracked | Image/JPEG/GIF decoding/rendering cho LVGL. Key types/methods: `_gd_GIF`. |
| `main/display/lvgl_display/gif/gifdec_mve.h` | `h` | 5338 | tracked | Image/JPEG/GIF decoding/rendering cho LVGL. |
| `main/display/lvgl_display/gif/lvgl_gif.cc` | `cc` | 6224 | tracked | Image/JPEG/GIF decoding/rendering cho LVGL. Key types/methods: `LvglGif::image_dsc`, `LvglGif::Start`, `LvglGif::Pause`, `LvglGif::Resume`, `LvglGif::Stop`, `LvglGif::IsPlaying`, `LvglGif::IsLoaded`, `LvglGif::GetLoopCount`. |
| `main/display/lvgl_display/gif/lvgl_gif.h` | `h` | 2327 | tracked | Image/JPEG/GIF decoding/rendering cho LVGL. Key types/methods: `LvglGif`. |
| `main/display/lvgl_display/jpg/image_to_jpeg.cpp` | `cpp` | 16007 | tracked | Image/JPEG/GIF decoding/rendering cho LVGL. |
| `main/display/lvgl_display/jpg/image_to_jpeg.h` | `h` | 3124 | tracked | Image/JPEG/GIF decoding/rendering cho LVGL. |
| `main/display/lvgl_display/jpg/jpeg_to_image.c` | `c` | 8687 | tracked | Image/JPEG/GIF decoding/rendering cho LVGL. |
| `main/display/lvgl_display/jpg/jpeg_to_image.h` | `h` | 2914 | tracked | Image/JPEG/GIF decoding/rendering cho LVGL. |
| `main/display/lvgl_display/lvgl_display.cc` | `cc` | 12911 | tracked | UI, display và helper cho LVGL. Key types/methods: `tm`, `LvglDisplay::SetTextFont`, `LvglDisplay::AddTextGlyphs`, `LvglDisplay::ClearTextGlyphs`, `LvglDisplay::SetStatus`, `LvglDisplay::ShowNotification`, `LvglDisplay::UpdateStatusBar`, `LvglDisplay::SetPreviewImage`. |
| `main/display/lvgl_display/lvgl_display.h` | `h` | 2024 | tracked | UI, display và helper cho LVGL. Key types/methods: `DynamicGlyphCache`, `LvglFont`, `LvglDisplay`. |
| `main/display/lvgl_display/lvgl_font.cc` | `cc` | 251 | tracked | Font, text glyph hoặc glyph cache logic của LVGL. |
| `main/display/lvgl_display/lvgl_font.h` | `h` | 1097 | tracked | Font, text glyph hoặc glyph cache logic của LVGL. Key types/methods: `LvglFont`, `LvglBuiltInFont`, `LvglCBinFont`. |
| `main/display/lvgl_display/lvgl_image.cc` | `cc` | 1994 | tracked | Image/JPEG/GIF decoding/rendering cho LVGL. Key types/methods: `LvglRawImage::IsGif`. |
| `main/display/lvgl_display/lvgl_image.h` | `h` | 1183 | tracked | Image/JPEG/GIF decoding/rendering cho LVGL. Key types/methods: `LvglImage`, `LvglRawImage`, `LvglCBinImage`, `LvglAllocatedImage`. |
| `main/display/lvgl_display/lvgl_theme.cc` | `cc` | 1027 | tracked | Theme/color/style logic của LVGL display. Key types/methods: `LvglTheme::ParseColor`, `LvglThemeManager::GetTheme`, `LvglThemeManager::RegisterTheme`. |
| `main/display/lvgl_display/lvgl_theme.h` | `h` | 4526 | tracked | Theme/color/style logic của LVGL display. Key types/methods: `LvglTheme`, `LvglThemeManager`. |
| `main/display/lvgl_no_psram_pool.h` | `h` | 432 | tracked | Display interface hoặc implementation LCD/OLED/LVGL/emote. |
| `main/display/lvgl_psram_pool.h` | `h` | 548 | tracked | Display interface hoặc implementation LCD/OLED/LVGL/emote. |
| `main/display/oled_display.cc` | `cc` | 17203 | tracked | Display interface hoặc implementation LCD/OLED/LVGL/emote. Key types/methods: `OledDisplay::SetupUI`, `OledDisplay::Lock`, `OledDisplay::Unlock`, `OledDisplay::SetChatMessage`, `OledDisplay::RemoveChatMessage`, `OledDisplay::SetupUI_128x64`, `OledDisplay::SetupUI_128x32`, `OledDisplay::SetEmotion`. |
| `main/display/oled_display.h` | `h` | 1399 | tracked | Display interface hoặc implementation LCD/OLED/LVGL/emote. Key types/methods: `OledDisplay`. |
| `main/display/text_glyph.cc` | `cc` | 118 | tracked | Helper chuyển đổi/validation glyph văn bản. |
| `main/display/text_glyph.h` | `h` | 1751 | tracked | Mô hình dữ liệu glyph văn bản. Key types/methods: `TextGlyphAllocator`, `TextGlyph`. |
| `main/idf_component.yml` | `yml` | 4130 | tracked | Khai báo dependency/component của main ESP-IDF component. |
| `main/led/circular_strip.cc` | `cc` | 8103 | tracked | LED abstraction hoặc GPIO/circular-strip implementation. Key types/methods: `CircularStrip::SetAllColor`, `CircularStrip::SetSingleColor`, `CircularStrip::SetMultiColors`, `CircularStrip::Blink`, `CircularStrip::FadeOut`, `CircularStrip::Breathe`, `CircularStrip::Scroll`, `CircularStrip::StartStripTask`. |
| `main/led/circular_strip.h` | `h` | 1905 | tracked | LED abstraction hoặc GPIO/circular-strip implementation. Key types/methods: `StripColor`, `CircularStrip`. |
| `main/led/gpio_led.cc` | `cc` | 8136 | tracked | LED abstraction hoặc GPIO/circular-strip implementation. Key types/methods: `GpioLed::SetBrightness`, `GpioLed::TurnOn`, `GpioLed::TurnOff`, `GpioLed::BlinkOnce`, `GpioLed::Blink`, `GpioLed::StartContinuousBlink`, `GpioLed::StartBlinkTask`, `GpioLed::OnBlinkTimer`. |
| `main/led/gpio_led.h` | `h` | 1334 | tracked | LED abstraction hoặc GPIO/circular-strip implementation. Key types/methods: `GpioLed`. |
| `main/led/led.h` | `h` | 281 | tracked | LED abstraction hoặc GPIO/circular-strip implementation. Key types/methods: `Led`, `NoLed`. |
| `main/led/single_led.cc` | `cc` | 4451 | tracked | LED abstraction hoặc GPIO/circular-strip implementation. Key types/methods: `SingleLed::SetColor`, `SingleLed::TurnOn`, `SingleLed::TurnOff`, `SingleLed::BlinkOnce`, `SingleLed::Blink`, `SingleLed::StartContinuousBlink`, `SingleLed::StartBlinkTask`, `SingleLed::OnBlinkTimer`. |
| `main/led/single_led.h` | `h` | 938 | tracked | LED abstraction hoặc GPIO/circular-strip implementation. Key types/methods: `SingleLed`. |
| `main/main.cc` | `cc` | 798 | tracked | Entry point app_main: NVS init rồi khởi chạy Application. |
| `main/mcp_server.cc` | `cc` | 26717 | tracked | MCP JSON-RPC parsing, tool listing/calling và built-in tools. Key types/methods: `McpServer::AddCommonTools`, `std::unexpected`, `std::move`, `McpServer::AddUserOnlyTools`, `McpServer::AddTool`, `McpServer::AddUserOnlyTool`, `McpServer::ParseMessage`, `McpServer::ParseCapabilities`. |
| `main/mcp_server.h` | `h` | 18287 | tracked | MCP tool/property types, callbacks và server API. Key types/methods: `ImageContent`, `PropertyList`, `PropertyType`, `Property`, `McpTool`, `McpServer`, `std::unexpected`, `std::string`. |
| `main/nabi_esp_contract.h` | `h` | 630 | first-party untracked | Generated constants for Nabi BLE, OTA, WebSocket and protocol-v3 contract. |
| `main/nabi_esp_provisioning.cc` | `cc` | 11245 | first-party untracked | Protocomm BLE Security 2, first-pair code, device key, hotspot credential provisioning and DHCP gateway lookup. |
| `main/nabi_esp_provisioning.h` | `h` | 1074 | first-party untracked | OSTB Nabi provisioning service interface and pairing/session state. |
| `main/notify/notify_player.cc` | `cc` | 10124 | tracked | Phát audio thông báo và đồng bộ phụ đề. Key types/methods: `NotifyPlayer::Start`, `NotifyPlayer::Stop`, `NotifyPlayer::IsActive`, `NotifyPlayer::IsBusy`, `NotifyPlayer::IsCancelled`, `NotifyPlayer::OnPlaybackProgress`, `NotifyPlayer::CompleteLocked`, `NotifyPlayer::OnPlaybackDrained`. |
| `main/notify/notify_player.h` | `h` | 1877 | tracked | Phát audio thông báo và đồng bộ phụ đề. Key types/methods: `NotifySubtitle`, `NotifyPlayer`. |
| `main/ota.cc` | `cc` | 19554 | tracked | OTA download/check/flash logic. Key types/methods: `timeval`, `Ota::GetCheckVersionUrl`, `Ota::SetupHttp`, `Ota::CheckVersion`, `std::unexpected`, `Ota::MarkCurrentVersionValid`, `Ota::Upgrade`, `Ota::StartUpgrade`. |
| `main/ota.h` | `h` | 2226 | tracked | Interface firmware/asset update. Key types/methods: `Ota`. |
| `main/protocols/mqtt_protocol.cc` | `cc` | 20773 | tracked | MQTT control messages và encrypted UDP audio transport. Key types/methods: `hostent`, `MqttProtocol::Start`, `MqttProtocol::StartMqttClient`, `MqttProtocol::SendText`, `MqttProtocol::SendAudio`, `MqttProtocol::CloseAudioChannel`, `MqttProtocol::OpenAudioChannel`, `MqttProtocol::GetHelloMessage`. |
| `main/protocols/mqtt_protocol.h` | `h` | 2137 | tracked | MQTT/UDP transport interface/state. Key types/methods: `MqttProtocol`. |
| `main/protocols/protocol.cc` | `cc` | 3815 | tracked | Message helpers và callback semantics dùng chung. Key types/methods: `Protocol::AddTextFontCapabilities`, `Protocol::OnIncomingJson`, `Protocol::OnIncomingAudio`, `Protocol::OnAudioChannelOpened`, `Protocol::OnAudioChannelClosed`, `Protocol::OnNetworkError`, `Protocol::OnConnected`, `Protocol::OnDisconnected`. |
| `main/protocols/protocol.h` | `h` | 3330 | tracked | Interface transport-neutral, packet audio và callback giao thức. Key types/methods: `AudioStreamPacket`, `BinaryProtocol2`, `BinaryProtocol3`, `AbortReason`, `ListeningMode`, `Protocol`. |
| `main/protocols/text_glyph_payload.cc` | `cc` | 4433 | tracked | Parse/validate glyph push payload trước khi áp dụng. |
| `main/protocols/text_glyph_payload.h` | `h` | 246 | tracked | Types/validation interface cho payload glyph network. |
| `main/protocols/websocket_protocol.cc` | `cc` | 10383 | tracked | WebSocket session, JSON và binary audio. Key types/methods: `WebsocketProtocol::Start`, `WebsocketProtocol::SendAudio`, `WebsocketProtocol::SendText`, `WebsocketProtocol::IsAudioChannelOpened`, `WebsocketProtocol::CloseAudioChannel`, `WebsocketProtocol::OpenAudioChannel`, `WebsocketProtocol::GetHelloMessage`, `WebsocketProtocol::ParseServerHello`. |
| `main/protocols/websocket_protocol.h` | `h` | 851 | tracked | WebSocket transport interface/state. Key types/methods: `WebsocketProtocol`. |
| `main/sdkconfig.rename` | `rename` | 361 | tracked | Ánh xạ/đổi tên Kconfig symbols giữa phiên bản SDK. |
| `main/settings.cc` | `cc` | 2945 | tracked | Lưu và tải settings qua NVS. Key types/methods: `Settings::GetString`, `Settings::SetString`, `Settings::GetInt`, `Settings::SetInt`, `Settings::GetBool`, `Settings::SetBool`, `Settings::EraseKey`, `Settings::EraseAll`. |
| `main/settings.h` | `h` | 792 | tracked | API đọc/ghi cấu hình persistent. Key types/methods: `Settings`. |
| `main/system_info.cc` | `cc` | 4978 | tracked | Thu thập và serialize thông tin thiết bị/build. Key types/methods: `SystemInfo::GetFlashSize`, `SystemInfo::GetMinimumFreeHeapSize`, `SystemInfo::GetFreeHeapSize`, `SystemInfo::GetMacAddress`, `std::string`, `SystemInfo::GetChipModelName`, `SystemInfo::GetUserAgent`, `SystemInfo::PrintTaskCpuUsage`. |
| `main/system_info.h` | `h` | 579 | tracked | Interface dữ liệu hệ thống thiết bị. Key types/methods: `SystemInfo`. |
| `partitions/ostb-xiaozhi-3st-16m.csv` | `csv` | 541 | tracked | Bảng phân vùng source OSTB 3ST 16 MB với hai OTA app slots, assets, data và nvs_user. |
| `partitions/v1/16m.csv` | `csv` | 329 | tracked | Bố cục phân vùng flash ESP-IDF; xác định offset và kích thước NVS/OTA/model/assets. |
| `partitions/v1/16m_custom_wakeword.csv` | `csv` | 329 | tracked | Bố cục phân vùng flash ESP-IDF; xác định offset và kích thước NVS/OTA/model/assets. |
| `partitions/v1/16m_echoear.csv` | `csv` | 372 | tracked | Bố cục phân vùng flash ESP-IDF; xác định offset và kích thước NVS/OTA/model/assets. |
| `partitions/v1/32m.csv` | `csv` | 474 | tracked | Bố cục phân vùng flash ESP-IDF; xác định offset và kích thước NVS/OTA/model/assets. |
| `partitions/v1/4m.csv` | `csv` | 289 | tracked | Bố cục phân vùng flash ESP-IDF; xác định offset và kích thước NVS/OTA/model/assets. |
| `partitions/v1/4m_esp-hi.csv` | `csv` | 334 | tracked | Bố cục phân vùng flash ESP-IDF; xác định offset và kích thước NVS/OTA/model/assets. |
| `partitions/v1/8m.csv` | `csv` | 341 | tracked | Bố cục phân vùng flash ESP-IDF; xác định offset và kích thước NVS/OTA/model/assets. |
| `partitions/v2/16m.csv` | `csv` | 335 | tracked | Bố cục phân vùng flash ESP-IDF; xác định offset và kích thước NVS/OTA/model/assets. |
| `partitions/v2/16m_c3.csv` | `csv` | 338 | tracked | Bố cục phân vùng flash ESP-IDF; xác định offset và kích thước NVS/OTA/model/assets. |
| `partitions/v2/32m.csv` | `csv` | 402 | tracked | Bố cục phân vùng flash ESP-IDF; xác định offset và kích thước NVS/OTA/model/assets. |
| `partitions/v2/4m.csv` | `csv` | 295 | tracked | Bố cục phân vùng flash ESP-IDF; xác định offset và kích thước NVS/OTA/model/assets. |
| `partitions/v2/8m.csv` | `csv` | 335 | tracked | Bố cục phân vùng flash ESP-IDF; xác định offset và kích thước NVS/OTA/model/assets. |
| `partitions/v2/README.md` | `md` | 4193 | tracked | Design rationale and migration guidance for partition-table generation. Main section: Version 2 Partition Table. |
| `phone_app/.gitignore` | `no extension` | 746 | tracked | Bỏ qua output build, cache, IDE và file riêng tư của ứng dụng Flutter. |
| `phone_app/.metadata` | `no extension` | 968 | tracked | Metadata Flutter dùng để nhận diện loại dự án và phiên bản công cụ. |
| `phone_app/README.md` | `md` | 4522 | tracked | Hướng dẫn nạp model local, chạy foreground server và cấu hình OTA URL trên ESP. |
| `phone_app/analysis_options.yaml` | `yaml` | 1547 | tracked | Quy tắc lint và phân tích tĩnh cho Dart. |
| `phone_app/android/.gitignore` | `no extension` | 263 | tracked | Bỏ qua cache/build Android, Gradle wrapper cục bộ và signing keys. |
| `phone_app/android/app/build.gradle.kts` | `kts` | 1793 | tracked | Cấu hình Android application, SDK và build APK cho app Flutter. |
| `phone_app/android/app/src/debug/AndroidManifest.xml` | `xml` | 378 | tracked | Manifest bổ sung dành riêng cho debug build. |
| `phone_app/android/app/src/main/AndroidManifest.xml` | `xml` | 2952 | tracked | Khai báo app Android, quyền mạng local, foreground service connectedDevice, notification và cleartext LAN. |
| `phone_app/android/app/src/main/kotlin/com/xiaozhi/xiaozhi_local_ai/MainActivity.kt` | `kt` | 5042 | tracked | Activity Flutter giữ engine trong cache và nối quyền runtime cùng native service channels. |
| `phone_app/android/app/src/main/kotlin/com/xiaozhi/xiaozhi_local_ai/XiaoZhiServerService.kt` | `kt` | 6108 | first-party untracked | Android connectedDevice foreground service, notification điều khiển server và partial CPU wake lock. |
| `phone_app/android/app/src/main/res/drawable-v21/launch_background.xml` | `xml` | 438 | tracked | Nền màn hình khởi chạy cho Android API 21 trở lên. |
| `phone_app/android/app/src/main/res/drawable/launch_background.xml` | `xml` | 434 | tracked | Nền màn hình khởi chạy Android mặc định. |
| `phone_app/android/app/src/main/res/mipmap-hdpi/ic_launcher.png` | `png` | 544 | tracked | Launcher icon PNG cho density hdpi của Android. |
| `phone_app/android/app/src/main/res/mipmap-mdpi/ic_launcher.png` | `png` | 442 | tracked | Launcher icon PNG cho density mdpi của Android. |
| `phone_app/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` | `png` | 721 | tracked | Launcher icon PNG cho density xhdpi của Android. |
| `phone_app/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` | `png` | 1031 | tracked | Launcher icon PNG cho density xxhdpi của Android. |
| `phone_app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | `png` | 1443 | tracked | Launcher icon PNG cho density xxxhdpi của Android. |
| `phone_app/android/app/src/main/res/values-night/styles.xml` | `xml` | 995 | tracked | Theme/style Android dùng khi hệ thống ở chế độ tối. |
| `phone_app/android/app/src/main/res/values/styles.xml` | `xml` | 996 | tracked | Theme/style Android mặc định và splash screen. |
| `phone_app/android/app/src/profile/AndroidManifest.xml` | `xml` | 378 | tracked | Manifest bổ sung dành cho profile build. |
| `phone_app/android/build.gradle.kts` | `kts` | 537 | tracked | Cấu hình Gradle cấp dự án Android. |
| `phone_app/android/gradle.properties` | `properties` | 300 | tracked | Tuỳ chọn runtime và bộ nhớ cho Gradle/Android build. |
| `phone_app/android/gradle/wrapper/gradle-wrapper.properties` | `properties` | 202 | tracked | Phiên bản Gradle distribution được Flutter Android build dùng. |
| `phone_app/android/settings.gradle.kts` | `kts` | 770 | tracked | Khai báo plugin loader và module Android của app Flutter. |
| `phone_app/lib/main.dart` | `dart` | 39823 | tracked | Giao diện chat/model/ESP, chọn interface hotspot và điều khiển server nền. |
| `phone_app/lib/models/local_model.dart` | `dart` | 1940 | tracked | Thông tin catalog model local, nguồn tải và checksum. |
| `phone_app/lib/services/local_ai_service.dart` | `dart` | 4218 | tracked | Nạp model GGUF, chạy suy luận local và nhận dạng giọng nói Whisper. |
| `phone_app/lib/services/model_service.dart` | `dart` | 7877 | tracked | Tải, xác thực, nhập và lưu model trong vùng dữ liệu riêng của app. |
| `phone_app/lib/services/phone_server_lifecycle.dart` | `dart` | 1243 | first-party untracked | MethodChannel bridge giữa Flutter server và Android foreground service/notification. |
| `phone_app/lib/services/voice_service.dart` | `dart` | 6968 | tracked | TTS Android, chuyển audio thành PCM và đóng gói Opus cho ESP. |
| `phone_app/lib/services/xiaozhi_server.dart` | `dart` | 15404 | tracked | HTTP OTA và WebSocket XiaoZhi; bind IPv4 chọn trước, giám sát đổi IP và xử lý STT/LLM/TTS local. |
| `phone_app/pubspec.lock` | `lock` | 22796 | tracked | Khoá phiên bản dependency Dart/Flutter đã phân giải. |
| `phone_app/pubspec.yaml` | `yaml` | 4183 | tracked | Metadata package và dependency của ứng dụng Flutter. |
| `scripts/Image_Converter/LVGLImage.py` | `py` | 46186 | tracked | Công cụ chuyển ảnh cho LVGL hoặc tài liệu/dependency liên quan. Entry points/types: `uint8_t`, `uint16_t`, `uint24_t`, `uint32_t`, `color_pre_multiply`, `Error`, `FormatError`, `ParameterError`. |
| `scripts/Image_Converter/README.md` | `md` | 1075 | tracked | Công cụ chuyển ảnh cho LVGL hoặc tài liệu/dependency liên quan. Main section: LVGL图片转换工具. |
| `scripts/Image_Converter/lvgl_tools_gui.py` | `py` | 11003 | tracked | Công cụ chuyển ảnh cho LVGL hoặc tài liệu/dependency liên quan. Entry points/types: `ImageConverterApp`. |
| `scripts/Image_Converter/requirements.txt` | `txt` | 46 | tracked | Công cụ chuyển ảnh cho LVGL hoặc tài liệu/dependency liên quan. |
| `scripts/audio_debug_server.py` | `py` | 1802 | tracked | Development/build/release helper `audio_debug_server.py`; inspect entry point and references before running. Entry points/types: `main`. |
| `scripts/build.py` | `py` | 73765 | tracked | Entry point build board/variant, list, CI selection và sdkconfig orchestration. Entry points/types: `_emit_build_stage`, `get_project_version`, `_get_idf_command`, `_run_idf`, `merge_bin`, `zip_bin`, `_get_manufacturer`, `_validate_reported_identifier`. |
| `scripts/build_default_assets.py` | `py` | 44023 | tracked | Đóng gói assets mặc định/models theo sdkconfig và partition. Entry points/types: `struct_pack_string`, `read_data`, `pack_models`, `ensure_dir`, `copy_file`, `copy_directory`, `copy_wakenet_model`, `process_sr_models`. |
| `scripts/ci/blufi.sdkconfig.defaults` | `defaults` | 80 | tracked | CI-specific sdkconfig defaults or representative variant selection. |
| `scripts/ci/representative-variants.json` | `json` | 3133 | tracked | CI-specific sdkconfig defaults or representative variant selection. Top-level fields: `schema_version`, `selection_date`, `selection_basis`, `variants`. |
| `scripts/download_github_runs.py` | `py` | 8940 | tracked | Development/build/release helper `download_github_runs.py`; inspect entry point and references before running. Entry points/types: `parse_github_run_url`, `get_artifacts`, `download_artifact`, `rename_artifact`, `get_default_releases_dir`, `main`. |
| `scripts/gen_lang.py` | `py` | 7021 | tracked | Sinh lang_config.h từ locale JSON và Ogg prompts. Entry points/types: `load_base_language`, `get_sound_files`, `generate_header`. |
| `scripts/mp3_to_ogg.sh` | `sh` | 134 | tracked | Development/build/release helper `mp3_to_ogg.sh`; inspect entry point and references before running. |
| `scripts/ogg_converter/README.md` | `md` | 999 | tracked | Công cụ chuyển đổi Ogg/Opus hoặc tài liệu sử dụng. Main section: ogg_covertor 小智AI OGG 音效批量转换器. |
| `scripts/ogg_converter/xiaozhi_ogg_converter.py` | `py` | 9665 | tracked | Công cụ chuyển đổi Ogg/Opus hoặc tài liệu sử dụng. Entry points/types: `AudioConverterApp`. |
| `scripts/p3_tools/README.md` | `md` | 2260 | tracked | Công cụ chuyển đổi/phát file âm thanh P3, tài liệu hoặc tài nguyên. Main section: P3音频格式转换与播放工具. |
| `scripts/p3_tools/batch_convert_gui.py` | `py` | 9321 | tracked | Công cụ chuyển đổi/phát file âm thanh P3, tài liệu hoặc tài nguyên. Entry points/types: `AudioConverterApp`. |
| `scripts/p3_tools/convert_audio_to_p3.py` | `py` | 2786 | tracked | Công cụ chuyển đổi/phát file âm thanh P3, tài liệu hoặc tài nguyên. Entry points/types: `encode_audio_to_opus`. |
| `scripts/p3_tools/convert_p3_to_audio.py` | `py` | 1395 | tracked | Công cụ chuyển đổi/phát file âm thanh P3, tài liệu hoặc tài nguyên. Entry points/types: `decode_p3_to_audio`. |
| `scripts/p3_tools/img/img.png` | `png` | 144945 | tracked | Công cụ chuyển đổi/phát file âm thanh P3, tài liệu hoặc tài nguyên. |
| `scripts/p3_tools/p3_gui_player.py` | `py` | 8445 | tracked | Công cụ chuyển đổi/phát file âm thanh P3, tài liệu hoặc tài nguyên. Entry points/types: `play_p3_file`, `P3PlayerApp`. |
| `scripts/p3_tools/play_p3.py` | `py` | 2071 | tracked | Công cụ chuyển đổi/phát file âm thanh P3, tài liệu hoặc tài nguyên. Entry points/types: `play_p3_file`, `main`. |
| `scripts/p3_tools/requirements.txt` | `txt` | 113 | tracked | Công cụ chuyển đổi/phát file âm thanh P3, tài liệu hoặc tài nguyên. |
| `scripts/release.py` | `py` | 11638 | tracked | Helper tạo/kiểm tra firmware release packages. Entry points/types: `gh_json`, `find_release`, `preflight`, `create_manifest`, `firmware_metadata`, `verify_assets`, `publish`, `main`. |
| `scripts/spiffs_assets/README.md` | `md` | 3091 | tracked | Công cụ build, chuyển đổi hoặc đóng gói SPIFFS/assets/model. Main section: SPIFFS Assets Builder. |
| `scripts/spiffs_assets/build.py` | `py` | 13996 | tracked | Công cụ build, chuyển đổi hoặc đóng gói SPIFFS/assets/model. Entry points/types: `ensure_dir`, `copy_file`, `copy_directory`, `process_wakenet_model`, `process_text_font`, `process_emoji_collection`, `load_emoji_config`, `process_board_emoji_collection`. |
| `scripts/spiffs_assets/build_all.py` | `py` | 4619 | tracked | Công cụ build, chuyển đổi hoặc đóng gói SPIFFS/assets/model. Entry points/types: `ensure_dir`, `get_file_path`, `build_assets`, `main`. |
| `scripts/spiffs_assets/pack_model.py` | `py` | 3941 | tracked | Công cụ build, chuyển đổi hoặc đóng gói SPIFFS/assets/model. Entry points/types: `struct_pack_string`, `read_data`, `pack_models`. |
| `scripts/spiffs_assets/spiffs_assets_gen.py` | `py` | 23174 | tracked | Công cụ build, chuyển đổi hoặc đóng gói SPIFFS/assets/model. Entry points/types: `AssetCopyConfig`, `PackModelsConfig`, `generate_header_filename`, `compute_checksum`, `sort_key`, `download_v8_script`, `download_v9_script`, `split_image`. |
| `scripts/tests/test_assets.py` | `py` | 19591 | tracked | Host-side test cases for `assets` tooling/logic; not firmware hardware validation. Entry points/types: `AssetsTest`. |
| `scripts/tests/test_build.py` | `py` | 74578 | tracked | Host-side test cases for `build` tooling/logic; not firmware hardware validation. Entry points/types: `VersionTests`, `BoardSelectionTests`, `BoardMenuTests`, `InvalidConfigTests`, `PreviewTargetTests`, `TargetConfigurationTests`, `BuildOptionTests`, `LanguageBuildTests`. |
| `scripts/tests/test_build_default_assets.py` | `py` | 12443 | tracked | Host-side test cases for `build_default_assets` tooling/logic; not firmware hardware validation. Entry points/types: `BuildDefaultAssetsTest`, `ConfiguredAssetsTest`. |
| `scripts/tests/test_ci_selection.py` | `py` | 11033 | tracked | Host-side test cases for `ci_selection` tooling/logic; not firmware hardware validation. Entry points/types: `CiSelectionTests`, `WorkflowDiffTests`. |
| `scripts/tests/test_esp_vocat_i2c.py` | `py` | 5867 | tracked | Host-side test cases for `esp_vocat_i2c` tooling/logic; not firmware hardware validation. Entry points/types: `function`, `EspVocatI2cTests`. |
| `scripts/tests/test_mcp_server.py` | `py` | 10575 | tracked | Host-side test cases for `mcp_server` tooling/logic; not firmware hardware validation. Entry points/types: `McpServerTest`. |
| `scripts/tests/test_ogg_demuxer.py` | `py` | 7061 | tracked | Host-side test cases for `ogg_demuxer` tooling/logic; not firmware hardware validation. Entry points/types: `OggDemuxerTest`. |
| `scripts/tests/test_release.py` | `py` | 10635 | tracked | Host-side test cases for `release` tooling/logic; not firmware hardware validation. Entry points/types: `ReleaseTests`. |
| `scripts/tests/test_startup_wake_word_hint.py` | `py` | 16900 | tracked | Host-side test cases for `startup_wake_word_hint` tooling/logic; not firmware hardware validation. Entry points/types: `definition`, `StartupWakeWordHintTests`. |
| `scripts/versions.py` | `py` | 8595 | tracked | Thông tin phiên bản/dependency cho build và release. Entry points/types: `get_chip_id_string`, `get_flash_size`, `get_app_desc`, `get_board_name`, `find_app_partition`, `read_binary`, `extract_zip`, `upload_dir_to_oss`. |
| `sdkconfig.defaults` | `defaults` | 2060 | tracked | Mặc định Kconfig dùng chung cho build. |
| `sdkconfig.defaults.esp32` | `esp32` | 128 | tracked | ESP-IDF default Kconfig overrides for target `esp32`. |
| `sdkconfig.defaults.esp32c3` | `esp32c3` | 386 | tracked | ESP-IDF default Kconfig overrides for target `esp32c3`. |
| `sdkconfig.defaults.esp32c5` | `esp32c5` | 257 | tracked | ESP-IDF default Kconfig overrides for target `esp32c5`. |
| `sdkconfig.defaults.esp32c6` | `esp32c6` | 99 | tracked | ESP-IDF default Kconfig overrides for target `esp32c6`. |
| `sdkconfig.defaults.esp32p4` | `esp32p4` | 676 | tracked | ESP-IDF default Kconfig overrides for target `esp32p4`. |
| `sdkconfig.defaults.esp32s3` | `esp32s3` | 1365 | tracked | ESP-IDF default Kconfig overrides for target `esp32s3`. |
| `sdkconfig.defaults.esp32s31` | `esp32s31` | 643 | tracked | ESP-IDF default Kconfig overrides for target `esp32s31`. |
