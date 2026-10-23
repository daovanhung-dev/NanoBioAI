# Backend Agent Context — Reusable FastAPI Template

> **Mục đích:** bộ tri thức/quy tắc dành cho coding agent (Codex, Claude Code, Cursor hoặc AI coding agent tương tự) để triển khai **một backend khác** theo phong cách đã kiểm chứng từ `Study2Work/apps/study-server`, nhưng **không sao chép nghiệp vụ, database, secret hoặc hạn chế kiến trúc cũ**.
>
> Snapshot nguồn đối chiếu: `daovanhung-dev/Study2Work`, branch `main`, đọc ngày **2026-10-22**. Đây là **agent context + template tài liệu**, **không phải ứng dụng FastAPI hoàn chỉnh/runnable**.

## Bắt đầu trong 3 bước

1. Giải nén vào root của một repository backend mới (để `AGENTS.md` ở root). Có thể tạo repo trắng trước. Không chép đè một `AGENTS.md` đã có mà chưa hợp nhất rule.
2. Điền các ô `TODO` tại `.agents/project/01-product-context.md` và quyết định tùy chọn trong `.agents/project/03-technology.md`.
3. Mở `prompts/01-bootstrap-with-codex.md`, gửi prompt đó cho agent có quyền đọc/ghi repo để yêu cầu **tạo source thực tế, chạy lệnh, viết test**.

```bash
# Đứng tại thư mục repository mới, sau khi giải nén bộ context:
python3 scripts/validate_agent_context.py
python3 scripts/select_worklogs.py --type coding --limit 3
```

## File nào làm nhiệm vụ gì?

- `AGENTS.md`: điểm vào **bắt buộc** cho agent.
- `.agents/AGENTS.md`: registry, trạng thái và thứ tự ưu tiên nguồn.
- `.agents/context-map.md`: đồ thị nạp context có chọn lọc.
- `.agents/project/`: rules kiến trúc, API, DB, security, testing, operations, conventions, workflows.
- `.agents/modules/`: quy ước module + template context một module.
- `.agents/worklog/`: history theo task, template nhật ký, cách preflight.
- `templates/`: cấu hình và contract **tham khảo**, không phải code triển khai đã được test.
- `prompts/`: prompt Codex để bootstrap, implement API, fix bug, chuyển đổi repo cũ.
- `scripts/`: 2 tiện ích Python stdlib để chọn worklog + kiểm tra cấu trúc agent context.
- `FULL_CONTEXT.md` (tại thư mục chứa ZIP, hoặc đi cùng gói): phiên bản đọc liền toàn bộ context.

## Những gì được giữ lại và được cải tiến

**Giữ từ Study Server:** FastAPI; Python typed; chia tầng `models.py -> validate.py -> query.py -> view.py -> router`; Session theo request; transaction thuộc use case; SQL bind parameters; JWT access + opaque refresh; Argon2id; shared response envelope + trace ID; tests, Ruff, mypy; worklog, evidence/state và coding workflow.

**Cải tiến đề xuất cho project mới (không khẳng định là runtime gốc):** `pydantic-settings` + env/secret manager; readiness **thực sự probe** DB và các dependency thiết yếu; Alembic migration quản lý được; cơ chế refresh rotation chống race; logging/metrics có kiểm soát, CI/CD, production hardening, phân biệt `sync`/`async` rõ ràng.

**Không sao chép:** bảng `users/courses` của Study2Work, API `/api/v1/auth/*`, role `STUDENT`, business code `DESIGN_*`, khóa JWT, DSN Neon, CORS domain, `DB_SCHEMA`, tài liệu UC/AC/DD đặc thù, 160 tests hay tuyên bố runtime `VERIFIED` của dự án cũ.

## Checklist sau khi tạo code mới

- Chạy được `uv sync`, `uv run ruff check .`, `uv run ruff format --check .`, `uv run mypy app`, `uv run pytest`.
- Endpoint OpenAPI và route thực có bằng chứng bằng test; readiness kiểm tra dependency theo quy ước mới.
- Database schema được quản lý bằng Alembic; migration ứng dụng được trên DB thử nghiệm từ trạng thái trống.
- Nghiệp vụ từ requirements của dự án mới; không dùng lại hardcoded API/domain của Study2Work.
- `python3 scripts/validate_agent_context.py` pass; log lại lệnh đã/không chạy.

## Phạm vi và an toàn

Đây là baseline để AI lập trình có kỷ luật, **không thay thế** threat modeling, review chuyên gia hoặc kiểm toán production. Các quy tắc được đưa ra theo ưu tiên: contract/requirements của **dự án mới** > source/test runtime của **dự án mới** > docs context mới > ví dụ trong gói.
