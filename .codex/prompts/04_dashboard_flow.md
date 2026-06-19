Đọc `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md`, `.codex/DOCS_WORKFLOW.md`, `.codex/playbooks/dashboard.md`.

Task: sửa đúng luồng Dashboard.

Luồng bắt buộc:

```text
Onboarding thành công
-> tạo meal/tasks/schedule
-> lưu SQLite
-> dashboard tính điểm/timeline từ SQLite
-> notification action cập nhật SQLite
-> dashboard refresh
```

Yêu cầu:
- Loại bỏ mock/fake production.
- Không bypass provider/repository/datasource/DAO.
- Tách calculator/mapper nếu cần để test.
- Cập nhật docs fixbug/feature/test/issues theo phạm vi thay đổi.
- Cập nhật worklog.
- Chạy quick check và báo cáo rõ.
