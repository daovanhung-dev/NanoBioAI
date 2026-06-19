Đọc `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md`, `.codex/DOCS_WORKFLOW.md`.
Chọn đúng 1 playbook theo feature.

Task: triển khai chức năng
[MÔ TẢ CHỨC NĂNG]

Yêu cầu:
- Lập plan ngắn trước khi sửa nếu phạm vi lớn hơn 1 file.
- Giữ Feature-first + Clean Architecture.
- Không đổi public API nếu chưa `rg` usage.
- Thêm/cập nhật test cho logic mới.
- Tạo/cập nhật `docs/features/<feature-slug>/<NNN>-feature-<feature-slug>.md`.
- Tạo/cập nhật worklog và link tới docs liên quan.
- Nếu test có kết quả đáng ghi, tạo/cập nhật `docs/test/...`.
- Nếu phát hiện lỗi chưa fix được, ghi `docs/issues/...`.
- Chạy quick check hoặc báo rõ blocker.
