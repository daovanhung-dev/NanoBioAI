Commit de xuat: feat(backend): connect AI generation to local Ollama

# Worklog - FastAPI Ollama text endpoint

## Thoi gian

- Ngay: 2026-10-30
- Bat dau: 14:00
- Ket thuc: 14:16
- Timezone: Asia/Saigon

## Pham vi

- Loai task: coding, test va cap nhat context backend
- Module chinh: `backend/modules/edge_api`, `backend/services/ollama_client.py`
- Yeu cau goc: trien khai `docs/tasks/PLAN_CODEX_NANOBIO_BE_OLLAMA_4B.md`; ket noi backend text API toi Ollama Qwen3 4B; khong deploy len server.

## Da lam

- Noi `POST /api/v1/ai/generate` vao Ollama `/api/chat`; bat buoc JWT FastAPI va tai khoan active; feature flag mac dinh tat.
- Them schema 1-8 message `user`/`assistant`, body toi da 16 KiB, prompt Nabi phia server, model/options do server kiem soat.
- Them settings loopback-only, timeout/context/output bounds, provider error mapping, gioi han 6 request/user/phut qua `RateLimitBucket`; khong giu transaction trong inference.
- Them fake-provider/API tests va test PostgreSQL concurrency tuy chon; cap nhat backend README, environment example, contracts, decisions, module inventory, AI domain va feature note.
- Kiem tra Ollama `0.40.13` va `qwen3:4b-instruct` tren server; chay mot inference truc tiep thanh cong. Sau do chay endpoint code local qua SSH tunnel va SQLite in-memory: HTTP 200 `AI_GENERATED`, usage metrics 310 input/31 output, khoang 4.2 giay. Tunnel da dong; khong deploy hay ghi config len server.
- Giu nguyen ba tai lieu untracked da co trong `docs/tasks/`.

## File code/docs da sua

- `backend/src/nanobio_backend/core/config.py` - them settings Ollama va chan URL khong loopback/model ngoai pham vi.
- `backend/src/nanobio_backend/core/request_limits.py`, `main.py` - gioi han body endpoint AI 16 KiB truoc khi parse.
- `backend/src/nanobio_backend/services/ollama_client.py` - tao provider client HTTPX non-streaming, parse response co gioi han va chuan hoa loi.
- `backend/src/nanobio_backend/modules/edge_api/{models,router,view}.py` - them contract, auth, prompt Nabi, rate limit va mapping loi.
- `backend/tests/test_ai_ollama.py`, `test_api_core.py`, `test_postgres_concurrency.py` - them unit/API va concurrency coverage.
- `backend/.env.example`, `backend/README.md`, `backend/.agents/**`, `.codex/domains/ai-service.md`, `docs/features/self-hosted-backend/001-feature-self-hosted-backend.md` - cap nhat huong dan va trang thai.
- `docs/worklog/2026-10-30/001-worklog-backend-ollama-text-api.md` - ghi nhan phien va bang chung.

## Tai lieu lien quan

- `docs/tasks/PLAN_CODEX_NANOBIO_BE_OLLAMA_4B.md`
- `backend/.agents/context-map.md`
- `.codex/domains/ai-service.md`

## Commands

- `uv sync --locked`: PASS.
- `uv run --no-sync pytest`: PASS, 43 passed; 2 PostgreSQL-only tests skipped vi khong co `NANOBIO_TEST_DATABASE_URL`.
- `uv run --no-sync ruff check .`: PASS.
- `uv run --no-sync ruff format --check .`: PASS.
- `uv run --no-sync mypy src/nanobio_backend`: PASS, 80 source files.
- `python3 scripts/validate_agent_context.py`: PASS, 21 required files va local Markdown links.
- `git diff --check`: PASS.
- Local FastAPI -> SSH tunnel -> Ollama inference smoke: PASS; khong deploy va khong dung production DB.

## Loi/Rui ro

- Da fix: test route registry ban dau doc `app.routes` truc tiep, nhung FastAPI hien tai dung lazy included router; test chuyen sang OpenAPI path.
- Chua fix: chua chay concurrency test tren PostgreSQL disposable; chua deploy backend endpoint len Ubuntu server.
- Can kiem tra tiep: sau khi co phe duyet deploy rieng, cau hinh `OLLAMA_ENABLED` trong moi truong test, smoke-test endpoint tren service backend that, va giu Ollama/DB loopback.

## Ty le hoan thanh

- Hoan thanh: code, docs va local test theo pham vi da chot.
- Dang do: PostgreSQL concurrency va deployment/live backend endpoint chua xac minh.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - API, provider va server-side contract co test fake; mot request tich hop voi model that cung da qua.
- Muc do hoan thanh task: hoan tat phan code/test local; deploy va PostgreSQL-only check con ngoai bang chung.
- Bang chung kiem chung: 43 test pass; Ruff, mypy, context validation, diff check pass; inference that qua SSH tunnel pass.
- Diem ton token/chua toi uu: assertion dau tien kiem route truc tiep khong tuong thich lazy router cua FastAPI.
- Cach toi uu cho phien sau: kiem contract qua OpenAPI va de PostgreSQL concurrency test tu skip neu chua co disposable target.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
