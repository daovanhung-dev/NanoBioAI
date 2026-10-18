# XiaoZhi ESP32 Agent Context

Thư mục này là bản đồ dự án dành cho coding agent. Tài liệu giải thích quyền sở hữu subsystem và hướng xử lý các nhóm task để agent đọc đúng những file cần thiết trước khi sửa firmware.

## Cách nạp context

1. Read the repository [`AGENTS.md`](../../AGENTS.md), then run `git status --short`. Preserve changes already present in the worktree.
2. Read [`ARCHITECTURE.md`](ARCHITECTURE.md) for the subsystem boundaries and runtime/data flow.
3. Use [`TASK_ROUTING.md`](TASK_ROUTING.md) to select the owning source, authoritative project docs, and validation for the requested task.
4. For board selection, variants, Kconfig, CMake, partitions, or releases, also read [`BOARDS_AND_BUILD.md`](BOARDS_AND_BUILD.md).
5. Use [`FILE_INDEX.md`](FILE_INDEX.md) to find any individual file and understand its role. Read the current file before editing it; the index is an orientation aid, not a substitute for source inspection.

Sau điểm vào này, chỉ nạp các nhánh context liên quan đến task. Không chép toàn bộ file index hoặc mọi board implementation vào context của task thông thường.

## Thứ tự nguồn sự thật

- Current source, Kconfig, CMake, board `config.json`/`config.h`, partition CSV, and scripts define implemented behavior and build selection.
- `AGENTS.md` defines safety, scope, and contribution constraints for agents.
- The linked `docs/` files explain intended board, audio, protocol, MCP, style, and release behavior. If a document conflicts with current code, report the mismatch and ground implementation claims in the current source.
- `README.md` is the project overview and SDK policy, not the authority for every current board count or implementation detail.
- `sdkconfig` and `build/` are local generated state. Read them only when a task explicitly depends on the current configured build, and never treat them as portable project defaults.
- `managed_components/` is resolved dependency source. Inspect it only when a dependency/API behavior makes it necessary; do not copy its contents into project context or edit it as project-owned code.

## Project map

| Khu vực | Phạm vi phụ trách | Bắt đầu tại |
| --- | --- | --- |
| Boot and runtime | NVS startup, application lifecycle, event loop, state transitions | `main/main.cc`, `main/application.*`, `main/device_state*` |
| Hardware abstraction | Board contract and reusable network, power, input, camera, and peripheral helpers | `main/boards/common/` |
| Board implementations | Pins, peripheral composition, board-specific controls, and release identity | `main/boards/**/` |
| Audio | Codec IO, capture/playback tasks, engines, wake/VAD/AEC, Opus, and queues | `main/audio/`, `docs/audio-codec-input-audit.md` |
| Network protocol | Shared protocol semantics and WebSocket or MQTT/UDP transports | `main/protocols/`, `docs/websocket.md`, `docs/mqtt-udp.md` |
| MCP | Device tool registration, JSON-RPC dispatch, and common/user-only tools | `main/mcp_server.*`, `docs/mcp-protocol.md`, `docs/mcp-usage.md` |
| Display and status | Optional display implementations, LVGL UI, text/emoji assets, LEDs, notifications | `main/display/`, `main/led/`, `main/notify/` |
| Persistence and updates | Settings, OTA, asset loading, system information | `main/settings.*`, `main/ota.*`, `main/assets.*`, `main/system_info.*` |
| Build and packaging | Target options, board/variant selection, generated assets, CI and release packages | `main/Kconfig.projbuild`, `main/CMakeLists.txt`, `scripts/`, `.github/workflows/` |

## Cập nhật context

Khi project có file được thêm, xóa, đổi tên hoặc di chuyển, cập nhật `FILE_INDEX.md` từ `git ls-files` cùng các file first-party chưa được Git theo dõi (`git ls-files --others --exclude-standard`). Kiểm tra lại nhóm generated/vendor và `git status` hiện tại; không khôi phục file đang thiếu hoặc đưa output build cục bộ vào index chỉ để đủ danh sách. Chỉ sửa kiến trúc hoặc định tuyến task khi quyền sở hữu/hành vi thực sự thay đổi; gắn mỗi nhận định quan trọng với source hiện hành hoặc tài liệu chuẩn.

## Ranh giới phạm vi

File index bao phủ mọi đường dẫn được Git theo dõi và các file first-party chưa được theo dõi có mặt lúc cập nhật, gồm media assets và cả đường dẫn tracked hiện không có trong worktree. `.git/`, `build/`, `managed_components/`, `sdkconfig*` cục bộ bị ignore và output build khác được mô tả theo vai trò, không liệt kê từng file.
