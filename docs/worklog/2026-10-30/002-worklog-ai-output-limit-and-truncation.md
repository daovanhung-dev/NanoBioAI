Commit de xuat: feat(backend): raise AI output limit and classify truncation

# Worklog - Nang gioi han phan hoi AI va phan biet output bi cat

## Thoi gian

- Ngay: 2026-10-30
- Bat dau: 15:00 (uoc tinh theo phien)
- Ket thuc: 15:22
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: coding, test, diagnostic va cap nhat context backend
- Module chinh: FastAPI edge API va Ollama HTTPX provider
- Yeu cau goc: thuc thi `docs/tasks/PLAN_CODEX_NANOBIO_AI_EXTENDED_OUTPUT.md`; tang output budget, phan loai rieng `done_reason=length`, retry co dieu kien; khong deploy.

## Da lam

- Tim duoc request Thunder Client gay 502. Khong ghi body request hoac text response vao worklog/log.
- Tai Ollama `0.40.13`, chay serial dung request va system instruction hien co: `num_ctx=2048`, `num_predict=96` tra `done=true`, `done_reason=length`, `eval_count=96`, `prompt_eval_count=313`, khoang 4.1 giay; cung request voi `num_predict=1024` tra `done_reason=stop`, `eval_count=175`, khoang 2.3 giay. Xac nhan 96 token la nguyen nhan 502 quan sat duoc.
- Chay probe `num_ctx=4096`, `num_predict=2048`: request ket thuc `stop`, dung 134 output tokens, khoang 23.7 giay; VRAM dinh khoang 9731 MiB, con it nhat khoang 1434 MiB trong probe. Tien trinh `ollama ps` khong xac nhan duoc model van 100% GPU, nen chua du bang chung de bat retry tren server.
- Nang default `OLLAMA_NUM_PREDICT` len 1024, cho phep toi da 2048; `OLLAMA_NUM_CTX` van mac dinh 2048 va cho phep toi da 4096. Retry 2048 mac dinh tat, chi duoc phep khi bat co retry, context dung 4096, con du token context va it nhat 30 giay trong tong deadline 120 giay.
- Tach `done_reason=length` thanh output incomplete; chi tra text khi hoan tat. Neu khong retry duoc hoac retry van bi cat, API tra HTTP 502 `AI_RESPONSE_TRUNCATED`, khong tra partial text. Phan hoi sai dinh dang tiep tuc la `AI_PROVIDER_FAILURE`.
- Ghi telemetry chi gom trace ID, status, done reason da allowlist, token counts, latency va retry count. Dieu chinh system instruction cho cau hoi nhieu y co the giai thich theo buoc/doan ngan.
- Smoke test route FastAPI local voi SQLite in-memory, tai khoan JWT test va SSH tunnel tam toi Ollama: HTTP 200 `AI_GENERATED`, model dung, usage 333 input/489 output, khoang 11.1 giay. Tunnel da dong; khong deploy hay sua config server.

## File code/docs da sua

- `backend/src/nanobio_backend/core/config.py` - tang bounded output/context, them feature flag retry va tong timeout.
- `backend/src/nanobio_backend/services/ollama_client.py` - phan loai truncated, retry toi da mot lan, timeout chung va log metadata an toan.
- `backend/src/nanobio_backend/modules/edge_api/view.py` - sua instruction do dai va map `AI_RESPONSE_TRUNCATED`.
- `backend/tests/test_ai_ollama.py` - cap nhat default/options va them retry, truncation, context/deadline, log privacy tests.
- `backend/.env.example`, `backend/README.md`, `backend/.agents/project/05-api-contract.md` - cap nhat settings/API contract; chuan hoa CORS sample thanh JSON de Pydantic nap duoc file mau.
- `docs/worklog/2026-10-30/002-worklog-ai-output-limit-and-truncation.md` - ghi lai bang chung va gioi han.

## Tai lieu lien quan

- `docs/tasks/PLAN_CODEX_NANOBIO_AI_EXTENDED_OUTPUT.md`
- `backend/.agents/project/06-validation.md`
- `backend/.agents/project/09-error-observability.md`

## Commands

- `uv run --no-sync pytest`: PASS, 54 passed; 2 PostgreSQL-only tests skipped vi khong co `NANOBIO_TEST_DATABASE_URL`.
- `uv run --no-sync ruff check .`: PASS.
- `uv run --no-sync ruff format --check .`: PASS, 112 files formatted.
- `uv run --no-sync mypy src/nanobio_backend`: PASS, 80 source files.
- `python3 scripts/validate_agent_context.py` (tu `backend/`): PASS, 21 required files va Markdown local links.
- `Settings(_env_file='.env.example')` voi cac assert cho output/context/retry/timeout va CORS: PASS.
- `git diff --check`: PASS.
- Ollama serial diagnostic va FastAPI local -> SSH tunnel -> Ollama smoke: PASS; chi in metadata, khong in prompt/response text.

## Loi/Rui ro

- Da fix: `done_reason=length` truoc day bi map thanh `AI_PROVIDER_FAILURE`; gio co status code rieng va khong tra text chua hoan tat.
- Chua fix: chua xac nhan Ollama context 4096 chay 100% tren GPU trong staging; retry van default off.
- Can kiem tra tiep: neu muon bat retry, bench context 4096 tren staging, xac nhan `ollama ps` bao 100% GPU va latency/VRAM/OOM dat yeu cau; deploy can approval rieng.

## Ty le hoan thanh

- Hoan thanh: code, regression tests, direct provider diagnostic va local API integration smoke.
- Dang do: staging benchmark/rollout cho retry context 4096 va deployment backend.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - root cause duoc tai hien bang dung request gay loi, contract tach rieng output incomplete va malformed.
- Muc do hoan thanh task: code/test local hoan tat; retry van tat cho den khi staging GPU benchmark duoc xac nhan.
- Bang chung kiem chung: 54 tests pass, 2 PostgreSQL tests skip; Ruff, mypy, context validation va local FastAPI-to-Ollama smoke pass.
- Diem ton token/chua toi uu: format check phat hien mot file chua format, da format rieng file do truoc full validation.
- Cach toi uu cho phien sau: neu thuc hien staging, thu thap chi GPU/model state va aggregate latency, khong xuat request/response text.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
