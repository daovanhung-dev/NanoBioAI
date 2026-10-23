Commit de xuat: docs(iot): mo ta luong AI local phone-ESP32

# Worklog - Mô tả luồng AI local giữa điện thoại và ESP32

## Thời gian

- Ngày: 2026-10-23
- Bắt đầu: 12:18
- Kết thúc: 12:26
- Timezone: Asia/Saigon

## Phạm vi

- Loại task: docs-context
- Module chính: `iot/xiaozhi-esp32/`, phone-local AI và WebSocket firmware
- Yêu cầu gốc: mô tả chi tiết luồng AI local giữa ESP32 và điện thoại bằng file Markdown.

## Đã làm

- Đối chiếu luồng app HTTP OTA, WebSocket, Whisper, GGUF, Android TTS và luồng chọn protocol của firmware.
- Viết tài liệu tiếng Việt về trình tự kết nối, audio version 3, xử lý hội thoại, OTA URL/NVS, giới hạn hiện tại, bảo mật LAN và checklist nghiệm thu MVP.
- Thêm liên kết tới tài liệu từ hướng dẫn kết nối ESP trong `phone_app/README.md`.
- Đồng bộ danh mục `FILE_INDEX.md` với trạng thái Git hiện tại và thêm tài liệu mới.

## File code/docs đã sửa

- `iot/xiaozhi-esp32/docs/phone-local-ai-flow_vi.md` - tạo - mô tả flow đầu cuối dựa trên source hiện hành.
- `iot/xiaozhi-esp32/phone_app/README.md` - sửa - liên kết tới tài liệu chi tiết.
- `iot/xiaozhi-esp32/docs/agent-context/FILE_INDEX.md` - sửa - cập nhật inventory, trạng thái file và metadata.
- `.codex/history/WORKLOG_INDEX.md`, `.codex/history/LEARNED_SKILLS.md`, `.codex/task-skills/docs-context.md` - sinh lại sau khi thêm worklog.

## Tài liệu liên quan

- `iot/xiaozhi-esp32/phone_app/lib/services/xiaozhi_server.dart`
- `iot/xiaozhi-esp32/phone_app/lib/services/local_ai_service.dart`
- `iot/xiaozhi-esp32/phone_app/lib/services/voice_service.dart`
- `iot/xiaozhi-esp32/main/ota.cc`
- `iot/xiaozhi-esp32/main/application.cc`
- `iot/xiaozhi-esp32/main/protocols/websocket_protocol.cc`
- `iot/xiaozhi-esp32/main/boards/ostb/ostb-xiaozhi-3st/config.local-ai.json`

## Commands

- `git status --short --branch`: PASS - giữ nguyên file audit chưa track có từ trước.
- Đối chiếu source bằng `grep`, `sed` và `nl`: PASS - các mô tả kỹ thuật được so với implementation hiện tại.
- `python3 .codex/tools/update_worklog_learning.py --write`: PASS - history/task-skill được sinh lại.
- Kiểm tra Markdown bằng Python: PASS - link tương đối tồn tại, không có trailing whitespace.
- Kiểm tra `FILE_INDEX.md` bằng Python: PASS - 1772 đường dẫn, trạng thái, metadata và tổng vùng khớp Git hiện tại.
- `git diff --check`: PASS.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL - báo thiếu `docs/audit/source_truth_manifest.json` được tham chiếu từ file audit chưa track có sẵn lúc bắt đầu; đồng thời báo stale paths trong `.codex/history/WORKLOG_2026-08-16_meal_nutrition_estimation.md` và `.codex/task-skills/nabi-character/SKILL.md`. Các file/lỗi này nằm ngoài phạm vi task.
- Flutter/ESP-IDF tests và build: SKIPPED - chỉ thay đổi tài liệu.

## Lỗi/Rủi ro

- Đã fix: nhãn trạng thái và số lượng file trong IoT FILE_INDEX không còn khớp Git; đã cập nhật cùng lượt.
- Chưa fix: không có thay đổi runtime trong phạm vi này.
- Cần kiểm tra tiếp: kết nối mạng, audio mic/loa, trạng thái nền Android và inference thực tế cần nghiệm thu trên điện thoại/ESP32; tài liệu không thay thế bằng chứng thiết bị.

## Tỷ lệ hoàn thành

- Hoàn thành: 100% yêu cầu tạo tài liệu và liên kết.
- Đang đo: 0% runtime; không thuộc yêu cầu hiện tại.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - tài liệu mô tả luồng theo source và ghi rõ giới hạn/điều chưa xác minh trên thiết bị.
- Mức độ hoàn thành task: hoàn tất; validator repo-wide có lỗi sẵn ngoài phạm vi.
- Bằng chứng kiểm chứng: đối chiếu source; kiểm tra link tương đối, file index và diff whitespace đều PASS.
- Điểm tốn token/chưa tối ưu: cần đọc nhiều owner do luồng trải qua Android app, HTTP OTA và firmware protocol.
- Cách tối ưu cho phiên sau: dùng bảng source-of-truth trong tài liệu này để định tuyến nhanh tới owner theo lớp khi sửa implementation.
- Task-skill cần đọc lần sau: `.codex/task-skills/docs-context.md`
