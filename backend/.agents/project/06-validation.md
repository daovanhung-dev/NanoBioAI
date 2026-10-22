# Validation

Validate in layers: HTTP parsing, Pydantic field constraints, pure contract rules, then DB-backed ownership/state checks in the view protected by constraints. Do not turn database/provider failures into 422. Keep behavior evidence explicit.

Backend commands (from `backend/`): `uv sync`, `uv run ruff check .`, `uv run ruff format --check .`, `uv run mypy src/nanobio_backend`, `uv run pytest`. Context validation: `python3 scripts/validate_agent_context.py`. A migration is verified only when applied to a disposable empty PostgreSQL database; SQLite unit tests do not prove PostgreSQL migration compatibility.
