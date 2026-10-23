# Prompt: Implement một API theo Backend Rules

Task: `<DÁN REQUIREMENT / API CONTRACT / ACCEPTANCE CRITERIA Ở ĐÂY>`

Bạn là Senior Backend Engineer. Thực hiện trong repo hiện tại:

1. Theo `AGENTS.md` và worklog preflight. Xác định module owner, contract và expected/current.
2. Trace route -> model -> special validation -> view -> query -> schema/transaction/service -> response -> tests.
3. Nếu contract đủ, implement tối thiểu theo layer chuẩn; không viết SQL trong router, không DB IO trong validate; query bound parameters; view sở hữu transaction; authorization/ownership phía server.
4. Nếu cần schema: tạo/review Alembic migration, unique/FK/index, rollback strategy, test DB disposable. Không tự sửa production DB.
5. Giữ error envelope, trace ID, HTTP/business code theo contract; không leak secret.
6. Viết happy/422/401/403/404/409/500 hoặc 503 phù hợp, dependency failures/concurrency khi có; chạy focused + full suite + lint/typecheck.
7. Cập nhật context module và worklog. Báo `VERIFIED | NOT_RUN | BLOCKED` thành thật cùng file paths.

Không tự tạo nghiệp vụ ngoài requirement. Với lỗ hổng contract: ghi discrepancy/assumption trước.
