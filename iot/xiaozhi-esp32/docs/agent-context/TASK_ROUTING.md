# Định tuyến task

Trước mọi thay đổi, đọc `AGENTS.md`, `docs/agent-context/README.md`, và trạng thái `git status --short`. Xác định một hành vi/owner cụ thể; đọc implementation gần nhất và caller/callee liên quan trước khi chọn phạm vi chỉnh sửa. Giữ các thay đổi worktree có sẵn và không mở rộng sang subsystem không cần thiết.

| Task | Đọc đầu tiên | Ranh giới và kiểm chứng phù hợp |
| --- | --- | --- |
| Thêm board hoặc release variant | `docs/custom-board.md`, board gần nhất, `main/boards/**/config.json`, `config.h`, source, `main/Kconfig.projbuild`, `main/CMakeLists.txt`, partition CSV | Giữ board identity riêng; nối đủ chuỗi config → build.py → Kconfig → CMake → source; đúng target, flash/partition và một `DECLARE_BOARD`. Build variant và kiểm tra phần cứng liên quan. |
| Application, trạng thái, event/callback | `main/application.*`, `main/device_state*`, `main/boards/common/board.h` | Đổi state qua `Application::SetDeviceState`; callback ngoài main task phải schedule/event; không block event loop. Kiểm tra luồng state/error/reconnect bị ảnh hưởng. |
| Audio, wake word, VAD, AEC hoặc codec | `main/audio/README.md`, `main/audio/audio_service.*`, engine/codec tương ứng, board `config.h`, `docs/audio-codec-input-audit.md` | Giữ queue bounded và realtime tasks ngắn; xét capture/playback/wake/interruption/reconnect/AEC; build chip/board phù hợp và ghi rõ phần cần phần cứng. |
| Protocol, message hoặc audio transport | `main/protocols/protocol.*` và transport implementation; `docs/websocket.md`, `docs/mqtt-udp.md`, `docs/glyph-push.md` | Hợp đồng chung phải nhất quán ở WebSocket và MQTT/UDP; validate input, bảo toàn ownership `cJSON`; xem timeout, reconnect, packet bounds và crypto path. |
| MCP tool hoặc device control | `main/mcp_server.*`, nơi board đăng ký tool, `docs/mcp-protocol.md`, `docs/mcp-usage.md` | Phân biệt tool AI-callable với user-only; giữ JSON-RPC/schema/ownership; xác minh cả tool chung và tool board liên quan. |
| Display, LED, theme, font, locale hoặc assets | `main/display/`, `main/led/`, `main/assets.*`, `main/CMakeLists.txt`, asset scripts, `docs/glyph-push.md` | Các capability có thể không tồn tại; không sửa output sinh như `lang_config.h`; kiểm tra cấu hình no-display/OLED/LVGL và partition khi code/assets thực sự đổi. |
| Wi-Fi, Ethernet, cellular, provisioning hoặc nguồn | board/common helper tương ứng, board implementation và `config.h`, `docs/blufi.md` | Ưu tiên common helper khi semantics dùng chung; board-specific wiring ở board owner; kiểm tra disconnect/reconnect, optional features và target gates. |
| OTA, settings, system info hoặc persistent state | `main/ota.*`, `main/settings.*`, `main/system_info.*`, `main/application.cc` | NVS keys là persistent API; đánh giá migration và OTA board identity; không đổi dữ liệu tồn tại mà thiếu tương thích. |
| Build, dependency, CI hoặc release | root `CMakeLists.txt`, `main/idf_component.yml`, `main/Kconfig.projbuild`, `main/CMakeLists.txt`, `scripts/build.py`, workflows và tài liệu release | Kiểm tra target/variant/partition/asset artifact bị ảnh hưởng; không build bằng sdkconfig cũ mà chưa xác minh target. |
| Tài liệu hoặc file không rõ owner | [`FILE_INDEX.md`](FILE_INDEX.md), heading gần nhất trong `docs/`, references trong source | Tìm source-of-truth trước khi suy luận; đánh dấu điểm chưa xác nhận thay vì biến mô tả lịch sử thành hành vi hiện tại. |

## Mẫu báo cáo sau task

Nêu file/subsystem đã đổi, lý do và cách tác động tới luồng thực tế; báo lệnh/check đã chạy; tách kết quả build/source khỏi xác minh thiết bị; nêu điều còn chưa được kiểm chứng. Với docs-only, báo đối chiếu coverage/liên kết thay vì khẳng định firmware đã được test.
