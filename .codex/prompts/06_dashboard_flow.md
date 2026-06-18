Đọc `.codex/AGENTS.md` trước, sau đó đọc `.codex/playbooks/dashboard.md`.

Task: sửa đúng luồng Dashboard NanoBio.

Luồng bắt buộc:
Onboarding thành công -> tạo lịch trình cá nhân -> lưu DB -> dashboard tính điểm từ DB -> notification theo task -> user action cập nhật DB -> dashboard refresh.

Yêu cầu:
- Loại bỏ mock/fake production.
- Không bypass DAO/data layer.
- Tách score calculator nếu cần để unit test.
- Chạy quick check.
- Báo cáo file sửa và command.
