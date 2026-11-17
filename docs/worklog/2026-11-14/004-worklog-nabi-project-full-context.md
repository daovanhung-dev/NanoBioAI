Commit de xuat: docs(iot): tong hop context du an nabi esp32

# Worklog - Tổng hợp context Nabi ESP32 cho CV và phát triển tiếp

## Thời gian

- Ngày: 2026-11-14
- Bắt đầu: khoảng 21:55
- Kết thúc: khoảng 22:05
- Timezone: Asia/Bangkok

## Phạm vi

- Loại task: docs-context / tổng hợp thông tin dự án
- Module chính: `iot/nabi-esp32`, feature Nabi ESP trong ứng dụng NanoBioAI
- Yêu cầu gốc: gom full context dự án vào một file Markdown để dùng tham khảo và đưa thông tin chính xác vào CV

## Đã làm

- Tạo `NABI_PROJECT_FULL_CONTEXT.md` làm tài liệu tổng hợp duy nhất cho bối cảnh sản phẩm, app boundaries, kiến trúc, phần cứng OSTB 3ST, network/BLE contract, UI cấu hình Nabi, build/partition, kiểm thử, bằng chứng trên thiết bị, giới hạn nghiệm thu và CV-ready copy tiếng Việt/Anh.
- Đối chiếu feature-specific source/DD để phân biệt pipeline app chính (Whisper local + NanoBio backend + Android TTS offline) với `iot/nabi-esp32/phone_app/` riêng có luồng GGUF local.
- Nêu rõ các phân biệt evidence: firmware cuối đã build/flash/boot đến board/audio init; portal chưa được mở bằng trình duyệt sau lần flash cuối; voice round-trip chưa nghiệm thu; E2E BLE/network lịch sử dùng firmware trước đó.
- Ghi rõ phân vùng source khác phân vùng live và profile OSTB còn giữ board/variant ID legacy `ostb-xiaozhi-3st` để tương thích.
- Thêm liên kết tài liệu trong context README và đồng bộ inventory/metadata của `FILE_INDEX.md`.

## File code/docs đã sửa

- `iot/nabi-esp32/docs/agent-context/NABI_PROJECT_FULL_CONTEXT.md` — tạo tài liệu context tổng hợp và CV copy.
- `iot/nabi-esp32/docs/agent-context/README.md` — thêm lối vào tài liệu tổng hợp.
- `iot/nabi-esp32/docs/agent-context/FILE_INDEX.md` — thêm entry, cập nhật số lượng và byte size.
- `docs/worklog/2026-11-14/004-worklog-nabi-project-full-context.md` — ghi nhận phiên.

## Tài liệu liên quan

- `iot/nabi-esp32/docs/agent-context/CONNECTED_DEVICE_OSTB_3ST.md`
- `iot/nabi-esp32/docs/agent-context/ARCHITECTURE.md`
- `iot/nabi-esp32/docs/phone-local-ai-flow_vi.md`
- `iot/nabi-esp32/docs/features/phone-local-ai/001-feature-phone-hotspot-server.md`
- `docs/features/nabi_esp_assistant/001-feature-nabi-esp-assistant.md`
- `docs/DD/nabi_esp_assistant/README.md`
- `docs/worklog/2026-11-14/002-worklog-iot-nabi-esp-network-config.md`
- `docs/worklog/2026-11-14/003-worklog-nabi-wifi-portal-refresh.md`

## Commands

- Python Markdown link check: PASS — tất cả relative links trong context mới resolve.
- Python whitespace check: PASS — context mới và context README không còn trailing whitespace.
- `git diff --check`: PASS trên diff tracked hiện tại.
- `pwsh -File .codex/tools/validate_codex_integrity.ps1`: SKIPPED — `pwsh` không có trên host; thực hiện kiểm tra link/whitespace/inventory có mục tiêu.
- Firmware/app tests/build: SKIPPED — chỉ thay đổi tài liệu/context.
- `python3 .codex/tools/update_worklog_learning.py --write`: chạy sau khi tạo worklog để cập nhật history/task-skill được sinh.

## Lỗi/Rủi ro

- Đã xử lý trong tài liệu: tránh nhầm ứng dụng companion GGUF local với feature Nabi ESP tích hợp chính; tránh suy diễn voice E2E hoặc portal vật lý từ build/boot.
- Chưa kiểm tra: captive portal trực tiếp sau firmware cuối, hiển thị LCD thực tế và voice round-trip backend/TTS/loa.
- Cần kiểm tra tiếp: nghiệm thu thiết bị theo checklist trong `NABI_PROJECT_FULL_CONTEXT.md` trước khi mô tả hệ thống là hoàn chỉnh hoặc production-ready.

## Tỷ lệ hoàn thành

- Hoàn thành: tạo file Markdown tổng hợp dự án, nội dung CV song ngữ, nguồn tham chiếu, README entry và file index.
- Đang chờ: các nghiệm thu vật lý/runtime được phân loại rõ nhưng không thuộc phạm vi tài liệu này.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt — nội dung gom trong một tài liệu chính, có link nguồn và tách rõ source/build/device/history.
- Mức độ hoàn thành task: hoàn tất yêu cầu tạo file context và CV text; không sửa runtime.
- Bằng chứng kiểm chứng: relative links và whitespace pass; `git diff --check` pass; xác nhận source chính cho route/voice pipeline và snapshot thiết bị.
- Điểm tốn token/chưa tối ưu: repo có tài liệu tổng quát và feature-specific cập nhật không cùng trạng thái; phải đối chiếu source để tránh dùng nhầm tuyên bố local LLM.
- Cách tối ưu cho phiên sau: bắt đầu từ file context này rồi xác minh lại các claim runtime dễ thay đổi với source/code và device snapshot hiện tại.
- Task-skill cần đọc lần sau: `.codex/task-skills/docs-context.md`
