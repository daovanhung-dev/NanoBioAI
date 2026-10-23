# Prompt: Khởi tạo Backend mới từ Agent Context

Bạn là Senior Backend Architect + Senior Python/FastAPI Engineer. Làm việc **trực tiếp trong repository hiện tại**, không động chạm repository Study2Work.

1. Đọc `AGENTS.md`, `.agents/AGENTS.md`, `.agents/context-map.md`, toàn bộ `.agents/project/` và `.agents/modules/README.md` để hiểu guideline; đọc worklogs theo preflight.
2. Đọc `.agents/project/01-product-context.md` để lấy domain/actors/requirements. Nếu còn `TODO`, **không tự bịa nghiệp vụ**: bootstrap **core infrastructure và 1 endpoint generic health/hello**; tạo `docs/OPEN_DECISIONS.md` ghi các dữ kiện còn thiếu. Chỉ ask nếu không thể hoàn thành một hành động an toàn có ích.
3. Sử dụng modular-monolith FastAPI Python >=3.12, uv, Pydantic v2, PostgreSQL + SQLAlchemy 2 sync + psycopg 3, Alembic, Ruff, mypy strict, pytest; optional service chỉ khi cần. Tạo code hoàn chỉnh, không để placeholder import làm app lỗi.
4. Tạo `app/main.py:create_app`, core/config qua pydantic-settings env, database DI/session lifecycle, trace middleware, canonical response/error, `/health/live` và `/health/ready` (ready dùng bounded DB probe), structured safe logging.
5. Tạo minimal example `modules` theo 4-layer `models.py / validate.py? / query.py? / view.py`, **chỉ khi có feature contract**. Không import bảng/role/API từ Study2Work.
6. Cấu hình `.gitignore`, `.env.example` giả lập, `pyproject.toml`, `uv.lock`, Alembic migrations, Dockerfile production-safe, README commands. Không đưa secret vào code/fixtures/docs/log.
7. Tạo pytest tests cho create_app, errors/envelopes, trace, health live/ready mock DB, config validation; DB integration nếu có local PostgreSQL/CI. Tạo GitHub Actions CI hoặc pipeline tương ứng nếu repo có CI được xác nhận.
8. Chạy thực tế `uv sync`, `uv run ruff check .`, `uv run ruff format --check .`, `uv run mypy app`, `uv run pytest` và `python3 scripts/validate_agent_context.py`; fix lỗi trong scope, log chính xác command/outcome.
9. Ghi worklog và cập nhật context module khi triển khai. Cuối cùng trả lời: tree + decisions + các lệnh pass/fail/not-run + blockers + khuyến nghị tiếp theo.

Lưu ý: Không clone source secrets, không tự tạo tables/users/roles không có requirement, không triển khai feature business ngẫu nhiên. Không claim production-ready nếu chưa security/CI/integration review.
