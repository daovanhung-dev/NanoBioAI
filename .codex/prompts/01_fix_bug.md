Đọc `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md`, `.codex/DOCS_WORKFLOW.md`.
Chọn đúng 1 playbook theo module lỗi.

Bug/log:
[PASTE BUG/LOG]

Yêu cầu:
1. Xác định triệu chứng và nguyên nhân gốc.
2. Dùng `rg` tìm usage trước khi đổi public API/provider/route/schema.
3. Sửa nhỏ nhất, không refactor lan.
4. Thêm/cập nhật regression test nếu phù hợp.
5. Chạy quick check hoặc báo rõ blocker.
6. Tạo/cập nhật `docs/fixbug/<bug-slug>/<NNN>-fixbug-<bug-slug>.md` nếu có sửa bug.
7. Tạo/cập nhật worklog và link tới docs liên quan.
8. Nếu còn lỗi chưa fix được, ghi `docs/issues/...`.
9. Báo cáo nguyên nhân, file sửa, docs, command, rủi ro.
