# Prompt: Diagnose and Fix Backend Bug

Bug description: `<PASTE LOG / REPRO STEPS / EXPECTED VS ACTUAL>`

1. Đọc `AGENTS.md`, context liên quan, worklog preflight cùng type `fix`.
2. Tạo failing test/repro case trước khi sửa (nếu khả thi).
3. Trace exact owner: client/HTTP -> router -> models/validate -> view -> query/DB/external -> response -> exceptions -> tests.
4. Tìm **root cause**, không 'fix' symptom bằng catch-all/bỏ validation/bỏ assertion.
5. Minimal patch only, giữ compatibility trừ khi ticket yêu cầu thay đổi.
6. Regression tests + affected suite + ruff/mypy; kiểm tra commit/rollback, auth, trace, errors và secrets.
7. Cập nhật worklog, context nếu semantic changed; cuối cùng mô tả root cause, patch, test evidence, unresolved risks.
