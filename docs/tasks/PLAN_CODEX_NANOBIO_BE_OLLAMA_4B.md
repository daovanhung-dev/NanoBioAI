# PLAN — Codex kết nối NanoBioAI FastAPI Backend tới Ollama (`qwen3:4b-instruct`)

> **Trạng thái:** KẾ HOẠCH / CHƯA CODE / CHƯA DEPLOY / CHỜ PHÊ DUYỆT.
>
> **Ngày xác minh:** 2026-10-30 (Asia/Bangkok).
>
> **Repository:** https://github.com/daovanhung-dev/NanoBioAI.git
>
> **Branch:** `main`, commit nguồn đã đọc `52605d56d5db06a809f91d75a4978a01fc1bad95` (Codex PHẢI đối chiếu HEAD thực tế trước khi chỉnh sửa).
>
> **Nhiệm vụ:** Chỉ triển khai **Backend FastAPI → Ollama text inference** trên máy Ubuntu hiện có, dùng **`qwen3:4b-instruct`**, API riêng của NanoBioAI và xác thực JWT. Không thay Flutter, Supabase, Admin Web hoặc router/Nginx trong task này.

## 0. Kết luận hiện trạng — evidence, không suy đoán

1. `backend/src/nanobio_backend/modules/edge_api/router.py` đang có `@router.post('/ai/generate')` nhưng luôn `raise ApiError(503, 'FEATURE_NOT_ENABLED', ...)`. Vậy **backend CHƯA trỏ tới Ollama** trong mã nguồn được xác minh.
2. `backend/src/nanobio_backend/api/v1/router.py` đã đăng ký `edge_router`, route đầy đủ là `POST /api/v1/ai/generate`. Tuyệt đối không tạo thêm route trùng.
3. `backend/src/nanobio_backend/core/config.py` chưa có `ollama_*` settings. `backend/pyproject.toml` **đã có `httpx>=0.28,<1`**, không tự động thêm dependency trùng.
4. `backend/src/nanobio_backend/core/security.py` đã có `current_user` xác thực **JWT do FastAPI phát**, khác với tài khoản/token Supabase cũ. `backend/src/nanobio_backend/core/responses.py` định nghĩa envelope chuẩn `success`, `businessCode`, `message`, `data`, `meta`, `traceId`.
5. `backend/src/nanobio_backend/main.py` đã có `create_app` để inject settings/DB test và `GET /health/live`, `GET /health/ready` cho PostgreSQL. Không thay đổi semantics của 2 health endpoint này.
6. Theo log thực tế do người dùng cung cấp **ngày 2026-10-30** trên **server mới**: Ollama `0.40.13`, systemd `active/enabled`, lắng nghe **`127.0.0.1:11434`**; `qwen3:4b-instruct` có sẵn, warm-up PASS, single PASS (0.55 s, 82.7 tok/s), 3 request đồng thời PASS (~0.63–0.64 s), `ollama ps` báo `100% GPU`, context 2048, GTX 1080 Ti dùng ~9,611/11,264 MiB VRAM. **Chứng minh inference cơ bản, KHÔNG chứng minh tải 50 req/phút hay người dùng đông.** RAM OS nhận ~30 GiB, không tự coi là 96 GiB.
7. Trên server mới, backend đã được người dùng kiểm chứng `GET http://127.0.0.1:8000/health/ready` HTTP 200 và PostgreSQL ready; service `nanobio-backend` dùng systemd với **2 Uvicorn workers**. Chưa có bằng chứng môi trường production đã chứa biến Ollama hoặc endpoint AI trả thành công.
8. `.codex/domains/ai-service.md`, `backend/.agents/AGENTS.md`, `backend/.agents/project/13-decisions.md` hiện coi AI inference là **on-device**, AI generation 503 theo quyết định `NBI-BE-005`. Task này là một **thay đổi kiến trúc có chủ đích, chỉ trong backend**; cần cập nhật tài liệu quyết định sau khi được duyệt, KHÔNG âm thầm đổi Flutter sang remote AI.
9. Supabase `supabase/functions/nabi-ai-generate/handler.ts` từng dùng hợp đồng Gemini (`contents`, `generation_config`, `system_instruction`, `operation`). Không copy giả định request Gemini sang Ollama. Quy định API mới trong FastAPI rõ ràng, bảo toàn đường dẫn để tránh conflict; việc chuyển client Supabase cũ nằm ngoài task.

## 1. Mục tiêu và phạm vi

### In scope — bắt buộc

- Bật được request **text-only**, **non-streaming (phase 1)** từ tài khoản FastAPI hợp lệ → `POST /api/v1/ai/generate` → `http://127.0.0.1:11434/api/chat` → nhận câu trả lời thực của `qwen3:4b-instruct` → trả envelope chuẩn.
- API phải được **feature-gated**, mặc định tắt cho đến khi đã test và được phép mở; phân biệt lỗi disabled với lỗi upstream.
- Model ID chỉ do backend xác định; người dùng không thể chọn model, URL Ollama, prompt hệ thống, tham số inference tùy ý.
- Kiểm soát request size, context, output, thời gian chờ, lỗi provider; không để dữ liệu sức khỏe/token/prompt rò vào log.
- Bắt buộc xác thực JWT FastAPI qua `current_user`, từ chối account `is_active=False`.
- Có rate limit **kỹ thuật theo user** chống spam/DoS (tận dụng cơ chế PostgreSQL `RateLimitBucket` sẵn có), thử nghiệm cạnh tranh đồng thời; không đánh tráo nó thành quota gói trả phí.
- Test tự động bằng fake HTTPX provider, không gọi Ollama thật trong CI; smoke test có điều kiện trên server thật; có runbook cấu hình, rollback.

### Out of scope — không tự ý triển khai

- Flutter `lib/**`, bản local AI, tính năng chat mic, voice ASR/TTS, streaming SSE/WebSocket, vision/food scan, fine-tune model, thay Ollama bằng Qwen khác.
- API public qua IP/WAN, domain, DNS, Nginx, Port Forward, HTTPS: đây là **task mạng riêng**; không mở cổng `11434`.
- Import/link account Supabase cũ, cấp AI cho account chưa tồn tại trong DB FastAPI, tạo payment/quota Free–Plus–FamilyPlus tùy ý, sửa bảng membership hoặc thay đổi chính sách Google Play.
- Mọi hành động ghi lên production DB/server, push/merge/deploy khi chưa được người dùng đồng ý.

### Tách riêng các quyết định nghiệp vụ

Vì người dùng có mục tiêu dài hạn “cấp AI cho các tài khoản”, nhưng task hiện tại là **trỏ BE đến AI**, Codex cần đánh dấu rõ:

- **Task này:** mọi user **FastAPI hợp lệ** có thể gọi API **chỉ khi operator bật feature flag trong môi trường kiểm thử có kiểm soát**, chịu rate limit kỹ thuật; **không tuyên bố đã cấp quyền Plus/FamilyPlus hoặc quota thương mại**.
- **Task tiếp theo, bắt buộc trước khi mở thương mại rộng rãi:** approval policy cấp/thu hồi AI riêng theo account, quota/ngày theo plan, idempotent metering, atomic reservation/refund, admin grant/revoke, audit, concurrency budget. Nếu yêu cầu mới bao hàm cấp AI thương mại thì **dừng và xin duyệt** thay vì tự mở AI vô hạn.
- Cần duyệt chính sách lưu/không lưu nội dung hội thoại và consent gửi dữ liệu sức khỏe tới server nếu sau này Flutter gửi prompt thực.

## 2. Bắt buộc nạp context theo quy tắc repo

Codex phải kiểm tra `git status --short`, HEAD, worktree và đọc:

1. `AGENTS.md`, `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md`, `.codex/history/LEARNED_SKILLS.md`.
2. `.codex/workflows/coding.md`, `.codex/task-skills/coding.md`, `.codex/domains/backend.md` (đọc thêm `.codex/domains/ai-service.md` để hiểu rào chắn app-local).
3. `backend/AGENTS.md`, `backend/.agents/AGENTS.md`, `backend/.agents/context-map.md`, `backend/.agents/project/INDEX.md`, `backend/.agents/project/{01-product-context,02-architecture,05-api-contract,06-validation,08-auth-security,09-error-observability,10-testing,11-devops-operations,12-task-workflows,13-decisions}.md`.
4. File source đích ở mục 3, test, Alembic hiện tại và call sites. Đọc `supabase/functions/nabi-ai-generate/handler.ts` **chỉ để xác định contract cũ**. Nếu có điểm source mâu thuẫn plan, ưu tiên source HEAD và ghi lý do điều chỉnh trước khi code.
5. Không đọc đổ toàn bộ ảnh/assets, generated data, backup PII; tuân thủ routing/context lean của repo. Nếu có `AGENTS.md` cấp con, đọc trước khi sửa.

## 3. File map chính xác cho Codex

| Path (từ root repo) | Hành động dự kiến | Nội dung |
|---|---|---|
| `backend/src/nanobio_backend/modules/edge_api/router.py` | SỬA | Giữ **đúng một** `POST /ai/generate`; thêm `Depends(current_user)`, model input, `Depends(get_db)` nếu rate limit dùng DB; gọi `view.generate_ai`; giữ nguyên food-scan route 503. |
| `backend/src/nanobio_backend/modules/edge_api/models.py` | SỬA | Pydantic strict request input (messages text) và typed response nội bộ. Có thể tạo file mới ở module nếu có lý do, không tạo thư mục/module AI trùng route. |
| `backend/src/nanobio_backend/modules/edge_api/view.py` | SỬA | Gọi nghiệp vụ AI, account/rate limit, map lỗi và envelope (router vẫn mỏng). Không giữ DB transaction xuyên inference. |
| `backend/src/nanobio_backend/services/ollama_client.py` | TẠO | HTTPX Ollama provider, HTTP errors/timeouts/response parser, validate finish/content, kiểm soát model và options. |
| `backend/src/nanobio_backend/core/config.py` | SỬA | Settings Ollama typed, defaults an toàn và validation; feature flag default OFF. |
| `backend/.env.example` | SỬA | Chỉ thêm các key + ví dụ không bí mật. |
| `backend/tests/test_ai_ollama.py` | TẠO | Unit/API contract tests, fake Ollama, JWT, validation, lỗi provider, không gọi Internet. |
| `backend/tests/test_postgres_concurrency.py` | SỬA **nếu cần** | Kiểm tra rate limit cạnh tranh trên disposable PostgreSQL; không phá test có sẵn. |
| `backend/README.md` | SỬA | Cấu hình, smoke test, failure/rollback, cảnh báo Ollama loopback. |
| `backend/.agents/project/13-decisions.md` | SỬA sau duyệt | Ghi rõ NBI-BE-005 được sửa riêng **backend inference**, app-local chưa đổi. |
| `backend/.agents/modules/README.md` | SỬA sau duyệt | `nabi-ai-generate` chuyển `DECLARED_NOT_ENABLED` → `CODED`/`VERIFIED` theo thực tế, không tuyên bố đã chạy thật khi chỉ có tests. |
| `docs/worklog/<yyyy-mm-dd>/<NNN>-worklog-...md` + generated `.codex/history/*` | Cập nhật theo workflow repo | Bằng chứng coding/test; chỉ các file thực sự thay đổi đưa vào gói bàn giao. |

**Không tạo migration PostgreSQL** cho nhiệm vụ kết nối đơn giản; dùng bảng `rate_limit_buckets` sẵn có. Nếu Codex phát hiện không thể đạt acceptance về concurrency/rate limit nếu thiếu schema, phải báo blocker và xin duyệt migration trước khi thêm.

## 4. API contract đề xuất — backend only

### Endpoint

`POST /api/v1/ai/generate`

Headers:

- `Authorization: Bearer <FASTAPI_ACCESS_JWT>` (BẮT BUỘC; **không phải Supabase JWT**).
- `Content-Type: application/json`.
- `X-Trace-Id: <UUID>` không bắt buộc, middleware đã hỗ trợ.

Body mẫu tối thiểu:

```json
{
  "messages": [
    {"role": "user", "content": "Nabi ơi, hôm nay tôi rất mệt."}
  ]
}
```

- `messages`: 1..8 tin nhắn, chỉ `user`/`assistant`; nội dung text không rỗng, giới hạn độ dài **theo ngân sách context**; có ít nhất một user message và tin nhắn cuối bắt buộc là `user`.
- Cấm role `system`/`tool` do client gửi; không nhận `model`, `base_url`, `think`, `temperature`, `num_ctx`, `num_predict` từ client.
- Response đề xuất dùng envelope repo:

```json
{
  "success": true,
  "businessCode": "AI_GENERATED",
  "message": "Nabi đã trả lời.",
  "data": {
    "text": "<actual Ollama text>",
    "model": "qwen3:4b-instruct",
    "usage": {"inputTokens": 12, "outputTokens": 36}
  },
  "meta": {},
  "traceId": "<UUID>"
}
```

Token usage chỉ lấy từ dữ liệu provider nếu có; **không tự bịa** khi thiếu (nullable hoặc bỏ field). Giữ đúng casing với chuẩn repo. Nội dung trong JSON minh họa không phải fake production.

### Bảng lỗi cần nghiệm thu

| Tình huống | HTTP | `businessCode` ví dụ |
|---|---:|---|
| Thiếu/sai JWT FastAPI | 401 | `AUTHENTICATION_REQUIRED` |
| Account bị vô hiệu hóa | 401 | `AUTHENTICATION_REQUIRED` |
| Feature flag OFF | 503 | `FEATURE_NOT_ENABLED` |
| Body sai schema/role/content | 422 | `VALIDATION_ERROR` |
| Input vượt ngân sách context | 413 | `MODEL_CONTEXT_LIMIT_EXCEEDED` |
| User vượt rate limit kỹ thuật | 429 | `RATE_LIMITED` |
| Ollama unreachable/load model failed | 503 | `AI_UNAVAILABLE` |
| Ollama trả 5xx/invalid JSON/empty output | 502 hoặc 503 | `AI_PROVIDER_FAILURE` |
| Provider read timeout | 504 | `AI_TIMEOUT` |

Lỗi phải dùng `ApiError`, format chuẩn repo; không trả full upstream body, path, bí mật hay raw prompt.

## 5. Settings và cấu hình runtime

Thêm typed settings tương ứng vào `backend/src/nanobio_backend/core/config.py`, có xác nhận min/max:

```dotenv
OLLAMA_ENABLED=false
OLLAMA_BASE_URL=http://127.0.0.1:11434
OLLAMA_MODEL=qwen3:4b-instruct
OLLAMA_CONNECT_TIMEOUT_SECONDS=3
OLLAMA_READ_TIMEOUT_SECONDS=120
OLLAMA_NUM_CTX=2048
OLLAMA_NUM_PREDICT=96
OLLAMA_TECHNICAL_REQUESTS_PER_MINUTE=6
```

- Tên/giá trị là **proposal**, không có chứng cứ những key này đã tồn tại; Codex phải thêm vào Settings, `.env.example`, tests đúng một lần.
- `OLLAMA_ENABLED` là gate hệ thống, default `false`; chỉ bật sau smoke test môi trường kiểm thử, không bật tự động chỉ vì service online.
- Reject invalid URL hoặc URL từ client. Với deployment này, chỉ cho loopback; không cho backend bị SSRF đến host tùy ý.
- Dùng `httpx` đã có trong `pyproject.toml`; caller test inject client/transport (MockTransport) thay cho monkeypatch network thật.
- `num_ctx=2048`, `num_predict=96`, `keep_alive` phù hợp cấu hình kiểm thử; kiểm tra output overflow và token accounting. Không cho client ghi đè options.
- `think=false` **chỉ gửi nếu Ollama/runtime của model hỗ trợ và đã test**; model Instruct đã được kiểm thử thành công mà không truyền field này.
- **Đa worker:** systemd đang chạy Uvicorn `--workers 2`. Không tuyên bố `threading.Semaphore(3)` trong FastAPI là giới hạn toàn server (mỗi process có semaphore riêng). Nếu cần global cap/queue thật, dùng phối hợp cơ chế dùng chung hoặc triển khai phase công suất riêng; không tự tăng `OLLAMA_NUM_PARALLEL` vì GPU còn ~1.6 GiB VRAM ở snapshot đã tải.

## 6. Thứ tự CODING cho Codex (chỉ thực hiện khi kế hoạch đã được duyệt)

### P0 — Preflight, scope lock, rollback

1. Đọc context mục 2; kiểm tra HEAD, `git status --short` và những thay đổi chưa commit; không ghi đè người khác.
2. Tìm chính xác route, settings, app factory, service wrapper pattern, `RateLimitBucket` và tests hiện tại.
3. Đối chiếu server code version (`git -C /opt/nanobio rev-parse HEAD`) với GitHub để không deploy bản bất đồng.
4. Lấy baseline tests, **không làm thay đổi môi trường hoặc dữ liệu production**. Backup git commit/branch trước khi triển khai; rollback bằng release trước + `OLLAMA_ENABLED=false`, không chỉnh DB migration.

### P1 — Provider adapter

1. Viết `services/ollama_client.py`: build `POST /api/chat` từ **server-controlled** model/options, `stream:false`, messages đã validate.
2. Dùng HTTPX timeouts, parse JSON, `done`, `message.content`, usage từ `prompt_eval_count`, `eval_count`, mapping network/protocol errors.
3. Không expose `OLLAMA_BASE_URL` ra API public. Không log contents hoặc upstream raw JSON. Không trả empty output là thành công.
4. Unit test fake Ollama: success, timeout, connect refused, HTTP error, malformed JSON, no content, done=false, provider metrics missing.

### P2 — HTTP API authenticated

1. Trong `edge_api/router.py`, thay đúng handler stub `/ai/generate` bằng `payload` typed, `user: User = Depends(current_user)`, `db: Session = Depends(get_db)` nếu cần, chuyển business logic sang `edge_api/view.py`.
2. Luồng `feature flag` + auth + validation + rate limit per-account; account ID chỉ lấy từ JWT và DB, **không đọc từ request body**.
3. Dùng `RateLimitBucket` và `consume_rate_limit` hiện có trong `modules/auth/view.py` để giới hạn theo user với HMAC scope `ai-generate`, mà **không giữ transaction trong HTTP call đến Ollama**. Quan sát logic ghi/cộng của helper để đảm bảo commit rate limit ngắn, rollback đúng và không tranh chấp DB. Không tăng quota thương mại.
4. Nếu provider offline, trả lỗi có trace ID; `/health/live` và `/health/ready` vẫn thể hiện sức khỏe FastAPI/PostgreSQL như cũ.
5. Không sửa `food/scan/analyze` (vẫn 503), early-access, payment, membership logic.

### P3 — API tests và quality gates

1. Test thiếu JWT, fake/expired JWT, disabled/inactive user; feature disabled, invalid body, role giả mạo, client-supplied model/options, oversize/context, rate limit.
2. Test `HTTP 200`, response envelope/casing/headers, UTF-8 tiếng Việt, token stats có/không.
3. Test upstream refused, timeout, overload, malformed JSON, null/empty content, partial done; không làm lộ PII hay stack trace.
4. Nếu thay rate limit, test tranh chấp thật với PostgreSQL disposable (đừng coi SQLite là evidence tương đương). Kiểm thử tối thiểu 2 Uvicorn workers hoặc giải thích giới hạn global in-flight chưa có.
5. Chạy từ thư mục `backend/`:

```bash
uv sync --locked
uv run ruff check .
uv run ruff format --check .
uv run mypy src/nanobio_backend
uv run pytest
python3 scripts/validate_agent_context.py
```

6. Ghi chính xác PASS/FAIL/SKIPPED và lý do, không tự nhận đã test server thật từ laptop/local CI.

### P4 — Đối chiếu live Ubuntu và rollout có kiểm soát

Các lệnh sau dành cho operator trên **server mới**, **không tự ý thực thi/deploy**:

```bash
systemctl is-active ollama nanobio-backend
sudo ss -lntp | grep -E ':(11434|8000|5432)\b'
curl --fail --max-time 5 http://127.0.0.1:11434/api/version
ollama list
ollama ps
curl --fail --max-time 5 http://127.0.0.1:8000/health/ready
```

- Ollama `127.0.0.1:11434`; backend `127.0.0.1:8000`; PostgreSQL không công khai. Từ user `nanobio-backend`, kiểm tra có thể tới localhost Ollama.
- Sau deploy code **đã duyệt**: config `/etc/nanobio-backend/backend.env` bằng quyền phù hợp, không dump secrets; bật `OLLAMA_ENABLED=true` trong giai đoạn kiểm thử có JWT; `sudo systemctl restart nanobio-backend`.
- Tạo/tải **tài khoản FastAPI test** được cấp theo cơ chế hiện hành; gọi qua `curl` nội bộ hoặc SSH tunnel, không đăng raw token vào logs/chats. Token phải đến từ `/api/v1/auth/login`; tài khoản Supabase cũ không tự dùng được.
- Thực hiện API E2E: login → JWT → `POST /api/v1/ai/generate` → câu trả lời thực → lỗi xác thực → lỗi Ollama offline → phục hồi khi online. Duy trì `/health/ready` 200 sau restart.
- Theo dõi `journalctl -u nanobio-backend` (chỉ metadata an toàn), `ollama ps`, `nvidia-smi`. Nếu timeouts hoặc VRAM OOM, tắt flag/rollback; không tăng parallel/context vô căn cứ.
- WAN/HTTPS chỉ khi đã có task mạng riêng và policy quota/access được chốt, không mở ngay endpoint AI vô giới hạn trên HTTP plaintext.

### P5 — Handover/rollback

1. Trước khi đóng task, cập nhật tài liệu decision và module inventory cho trung thực với trạng thái CODED vs VERIFIED, file `README.md` với lệnh vận hành và khôi phục.
2. Tạo worklog canonical theo workflow repo; refresh history nếu công cụ hỗ trợ; kiểm tra `git diff --check`.
3. Trả ZIP **chỉ gồm những file mới/sửa thực sự** theo đúng path repo, không patch, không files bình luận thừa. Không đưa `.env` có secrets, dữ liệu người dùng, model weights, logs, DB dump vào ZIP.
4. Bàn giao status table: source modified, tests, local server verification, WAN deployment — trạng thái nào chưa test ghi `UNVERIFIED`.
5. Rollback tối thiểu: `OLLAMA_ENABLED=false` + restart service; giữ API stable 503; nếu cần revert release thì deploy last-known-good commit; không đụng database.

## 7. Acceptance criteria bắt buộc

| ID | Tiêu chí | Kiểm chứng |
|---|---|---|
| AC-01 | Đúng 1 endpoint `POST /api/v1/ai/generate` | OpenAPI route registry/test |
| AC-02 | Mặc định chưa duyệt (`OLLAMA_ENABLED=false`) vẫn trả 503 | API test |
| AC-03 | JWT FastAPI hợp lệ + enabled → `qwen3:4b-instruct` trả text thật | Live smoke test có operator |
| AC-04 | 401 nếu không hợp lệ/bị disable | API test |
| AC-05 | Không nhận model URL/options/system role từ user | Validation test |
| AC-06 | Lỗi upstream trả HTTP code + `businessCode` đúng, không lộ prompt | Fake provider tests |
| AC-07 | Rate limit kỹ thuật theo account có commit nguyên tử và load test cạnh tranh (nếu áp dụng) | PG disposable test |
| AC-08 | Không đụng Flutter/food scan/payment/legacy Supabase | Git changed files + regression |
| AC-09 | `/health/live`, `/health/ready`, auth, membership regression không lỗi | Backend tests / live curl |
| AC-10 | Ollama và DB không public; giới hạn VRAM vẫn an toàn | Server `ss`, `ollama ps`, `nvidia-smi` |
| AC-11 | Biên bản test minh bạch; ZIP chuẩn cấu trúc repo | Delivery checklist |

## 8. Điều kiện dừng (blocker) cần xin quyết định, không bịa

- HEAD/source trên server không tương thích, có changes chưa commit chồng lên phạm vi.
- Model `qwen3:4b-instruct` không còn trong `ollama list` của server thật hoặc service user không truy cập được 11434.
- Muốn **đổi luôn Flutter** hoặc dùng lại JWT Supabase → ngoài scope; cần chốt migration/client auth.
- Muốn **phân quyền AI theo gói/quota thương mại** ngay trong task này → cần business rules Free/Plus/FamilyPlus, số lượt, chu kỳ reset, grant và rollback; không tự chọn con số.
- Hợp đồng cũ Gemini được app nào đó đang gọi đến `/api/v1/ai/generate` bằng `contents` → phải xác định consumer rồi chọn adapter hoặc API versioning, không phá ngầm.
- Muốn expose ra WAN trước khi HTTPS + account quota/rate limits được nghiệm thu → không mở tự động.

---

## 9. Prompt giao Codex (chỉ gửi sau khi người dùng duyệt plan)

> Hãy đọc `PLAN_CODEX_NANOBIO_BE_OLLAMA_4B.md` và áp dụng nghiêm toàn bộ gate của repository. Chỉ code FastAPI backend tích hợp với dịch vụ Ollama **`qwen3:4b-instruct` tại `http://127.0.0.1:11434`** theo các phase P0–P5; giữ nguyên `POST /api/v1/ai/generate`, JWT, response envelope, không phá local AI Flutter, không mở port Ollama public. Trước khi sửa, kiểm tra actual HEAD và AGENTS files. Cần test bằng fake provider, không truy cập dữ liệu production. Nghiệm thu đúng AC-01..AC-11, ghi rõ các bước chưa live-verified. Bàn giao ZIP chỉ chứa file thực sự mới/sửa theo cấu trúc repo, không patch hoặc file nhận xét ngoài scope. Không triển khai WAN/production khi chưa được duyệt.

**Chỉ có plan; hiện tại không có code/deployment nào được thực hiện.**
