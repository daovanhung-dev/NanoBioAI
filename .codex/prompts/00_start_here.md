Đọc `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md`, và `.codex/DOCS_WORKFLOW.md` nếu task có sửa file.
Chỉ mở 1 playbook liên quan trực tiếp. Dùng `rg` trước khi mở rộng phạm vi.

Task:
[VIẾT TASK Ở ĐÂY]

Yêu cầu:
- Sửa nhỏ nhất đúng nguyên nhân gốc.
- Không bypass Clean Architecture.
- Không thêm mock/fake production.
- Cập nhật worklog trong `docs/worklog/<yyyy-mm-dd>/` nếu có sửa file/review/test.
- Cập nhật docs feature/fixbug/test/issues nếu phát sinh.
- Chạy quick check nếu phù hợp, hoặc ghi rõ lý do skip.
- Báo cáo file sửa, docs, command, kết quả, rủi ro.
