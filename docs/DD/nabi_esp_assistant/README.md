# DD — Nabi - Siêu trợ lý AI kết nối ESP OSTB 3ST

> Runtime update 2026-10-30: Nabi ESP no longer checks or loads the app's
> local GGUF text model. It keeps local Whisper speech recognition, local
> audio/ESP transport, and offline TTS; each generated reply goes through the
> authenticated NanoBio backend. ESP AI replies therefore require sign-in and
> Internet access. Firmware protocol and firmware source are unchanged.

| Thuộc tính | Giá trị |
|---|---|
| Module Code | `NABI_ESP_ASSISTANT` |
| Version | `v1.0-draft` |
| Lifecycle | `Current` |
| DD Decision | `Draft` |
| Implementation | `In Progress` |
| Verification | `App/firmware build and install; BLE/Wi-Fi/OTA config/WebSocket control verified; voice round trip pending` |
| Owner | `NanoBio product / mobile / IoT` |
| Created / Updated | `2026-10-23 / 2026-10-23` |
| Source | `Explicit user request and approved plan in conversation; no dedicated BD exists yet` |

## Phạm vi

Định nghĩa luồng Android phục vụ một ESP OSTB 3ST qua mạng LAN riêng. Runtime dùng Whisper local cho nhận dạng, backend NanoBio cho câu trả lời AI, và Android TTS offline. Tech, QA và Privacy chưa duyệt. Source giữ tile Android trong nhóm “Sắp ra mắt” và trang điều khiển theo release gate. Build/cài đặt, BLE pairing, cấp Wi-Fi, OTA config và WebSocket control đã được thử thật; backend voice round trip, lifecycle nền và phát tiếng qua ESP vẫn cần nghiệm thu.

## Tài liệu

- [Overall](Overall.md) — ranh giới và luồng đề xuất.
- [Features](List_Features.md) — feature và acceptance criteria.
- [Functions](Function_List.md) — hàm hiện có và phần cần xây dựng.
- [Views](Views.md) — trạng thái trang và thao tác.
- [Import map](Import_File.md) — source hiện có và thay đổi dự kiến.
- [Diagrams](diagrams/README.md) — sequence và trạng thái kết nối.
- [Assets](assets/README.md) — asset/copy cần thiết.
- [History](history/CHANGELOG.md) — lịch sử DD.

## Cổng phát hành

Không chuyển DD sang Approved hoặc bật luồng kết nối trước khi có Tech, QA, Privacy và hoàn tất thử nghiệm Android/OSTB. Thiết bị hiện đã nạp firmware XiaoZhi tích hợp với partition OTA tương thích; lần nạp tiếp theo cần kiểm tra lại bảng phân vùng và chỉ ghi đúng OTA app slot.
