# PLAN — Nâng giới hạn trả lời AI NanoBioAI và sửa lỗi 502 AI_PROVIDER_FAILURE

**Ngày:** 2026-10-30 · **Trạng thái:** Chờ duyệt, chưa sửa code, chưa deploy

**Repository:** https://github.com/daovanhung-dev/NanoBioAI · **Model cố định:** `qwen3:4b-instruct` · **Ollama:** `127.0.0.1:11434` · **FastAPI:** `127.0.0.1:8000` · **API:** `POST /api/v1/ai/generate`

## 1. Bằng chứng và kết luận ban đầu

Ảnh Thunder Client cho thấy `502 AI_PROVIDER_FAILURE`, `message: Trợ lý chưa thể tạo câu trả lời hợp lệ.` Sau xác thực API đã đi đến tầng xử lý AI; lỗi này **không phải `429 RATE_LIMITED`**.

Đã kiểm tra source GitHub:

- `backend/src/nanobio_backend/core/config.py`: `ollama_num_ctx = Field(default=2048, ge=256, le=2048)` và `ollama_num_predict = Field(default=96, ge=1, le=96)`. **Không tăng `OLLAMA_NUM_PREDICT=512`/`OLLAMA_NUM_CTX=4096` ngay trong `.env` của production** vì Pydantic sẽ từ chối config và service có thể không khởi động.
- `backend/src/nanobio_backend/services/ollama_client.py`: dùng `stream:false`, provider max JSON body 64 KiB; reject mọi phản hồi `done != true`, `done_reason == "length"`, `message.content` rỗng hoặc sai kiểu -> `OllamaInvalidResponseError`.
- `backend/src/nanobio_backend/modules/edge_api/view.py`: bắt `OllamaInvalidResponseError`, trả `502 AI_PROVIDER_FAILURE`; system prompt yêu cầu *trả lời ngắn gọn, thường 2–4 câu, phù hợp voice*. Giới hạn phong cách này không hợp lý với mọi câu hỏi text cần giải thích.
- `backend/src/nanobio_backend/modules/edge_api/models.py`: body là danh sách 1..8 messages, mỗi phần `user|assistant`, message cuối phải là user; không có configurable output mode.
- `backend/tests/test_ai_ollama.py`: test cứng options `{num_ctx:2048,num_predict:96}` và test giá trị 97/4096 bị reject. Bắt buộc cập nhật test khi tăng giới hạn.
- Server mới GTX 1080 Ti 11 GiB, log trước: `qwen3:4b-instruct` tải `100% GPU` ở ctx 2048, GPU dùng khoảng 9611/11264 MiB; VRAM còn ~1653 MiB lúc idle, phải bench lại trước khi tăng context hay concurrency.

**Giả thuyết mạnh nhất:** 96 output tokens gây `done_reason=length` và backend cố ý trả 502. **Chưa kết luận chắc chắn** trước khi nhìn `done_reason`, `eval_count`, độ dài `message.content`, và ngoại lệ upstream; các tình huống khác cũng có thể gây lỗi 502.

## 2. Mục tiêu

1. Trả lời câu hỏi nhiều bước hoặc cần giải thích với đủ token; không bị lỗi 502 chỉ vì output budget mặc định quá nhỏ.
2. Giữ nguyên HTTP endpoint, JWT auth, response envelope, model `qwen3:4b-instruct`, safety instruction; không đổi Flutter / CSDL / Supabase / Nginx.
3. Không cấp token/output/context vô hạn. Tăng có kiểm soát dựa trên benchmark thật và GPU headroom.
4. Phân biệt rõ `truncated`, upstream malformed, timeout, unavailable. Không che giấu câu trả lời y tế bị cắt mà báo là hoàn chỉnh.
5. Không ghi prompt, token, nội dung sức khỏe hay thông tin riêng tư vào log; log chỉ `traceId`, `done_reason`, token count, latency và trạng thái.

## 3. Các giai đoạn Codex cần thực hiện (sau khi plan được duyệt)

### P0 — Nạp context, chốt source HEAD, diagnostic nguyên nhân

- Đọc `AGENTS.md`, `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md`, `.codex/workflows/coding.md`, `backend/AGENTS.md`, `backend/.agents/AGENTS.md`, `backend/.agents/context-map.md`, `backend/.agents/project/INDEX.md` cùng hướng dẫn matching, các file scope và tests.
- Kiểm tra `git status --short`, `git log`, HEAD trên GitHub/server, tránh overwrite thay đổi local.
- Chạy **serial** local Ollama `POST /api/chat`, dùng cùng model + system prompt + câu hỏi test, lần lượt `num_ctx=2048`, `num_predict=96` và `512`; ghi `done`, `done_reason`, `eval_count`, `prompt_eval_count`, `message.content` length, `message.thinking` length (nếu có), `ollama ps`/`nvidia-smi`. Không cần in toàn văn prompt hoặc response.
- Nếu baseline không trả `length`, kiểm tra `done`, empty content, malformed JSON, response bytes, timeout và system prompt; **không fix mù**.

### P1 — Nâng output một cách tương thích

- Trong `core/config.py`, đổi **upper bound** `ollama_num_predict` từ 96 thành ít nhất 1024, vẫn `>=1`, đảm bảo không tự bật 1024 mặc định nếu chưa được test. Khuyến nghị default và production `512` tokens.
- Giữ `ollama_num_ctx=2048` trong rollout đầu tiên; chỉ mở **upper bound** lên 4096 để thử nghiệm staging sau khi GPU benchmark PASS, nhưng không buộc production đổi theo. Cần cân đối input tokens + output max trong `num_ctx` của model.
- `OLLAMA_READ_TIMEOUT_SECONDS`: giữ `120s`, chưa tăng nếu output 512 có latency chấp nhận được; chỉ nới sau đo live.
- Trong `.env.example`, ghi `OLLAMA_NUM_PREDICT=512`, `OLLAMA_NUM_CTX=2048` và các giá trị mới. Không tạo/thay `.env` chứa secrets trong gói ZIP.
- Mọi options do server quyết định, client không được gửi `model`, `num_predict`, `num_ctx` tùy ý.

### P2 — Xử lý output bị cắt hợp lý, ổn định

- Trong `services/ollama_client.py`: đọc `done_reason`, `eval_count`, `message.content`; tách trường hợp `done_reason="length"` khỏi lỗi JSON/empty/missing. Giữ strict parser, cap body/response và safe exceptions.
- Chiến lược chấp nhận: kết quả hoàn chỉnh -> 200. Bị cắt -> thử **một lần duy nhất** khi budget/latency cho phép, với output cap <=1024, hoặc trả businessCode riêng `AI_RESPONSE_TRUNCATED` với status/metadata được định nghĩa rõ (không giả trả 200 complete). Tránh retry vô hạn, đặc biệt không lặp request nếu prompt quá dài mà không thay được token budget.
- Cần xác nhận với test rằng `done_reason=length` là nguyên nhân 502 rồi chọn nhánh retry/partial tương ứng. Nếu tự retry có thể làm tăng latency và tải GPU; thống kê retry.
- System prompt ở `edge_api/view.py`: giữ toàn bộ nguyên tắc an toàn sức khỏe; đổi chỉ dẫn độ dài thành đáp ứng mức độ phức tạp: câu đơn/voice ngắn, câu hỏi có nhiều yêu cầu có thể trình bày rõ ràng thành các đoạn hoặc bước, không ép cứng 2–4 câu. Nếu có mode `brief|detailed` phải định nghĩa contract và test; phase này ưu tiên giữ body cũ, không thêm options tùy ý.

### P3 — Test tự động và hợp đồng API

- Update `backend/tests/test_ai_ollama.py`: default options mới; upper-bound `1025` invalid, `512` valid, `4096` chỉ valid nếu cho phép tại settings; `done_reason=length` có content/không content; provider malformed/timeout; 200 success; 502 chỉ cho malformed thực; 401 JWT; 429 rate limit; request size 413; model client override 422; tests không rò PII.
- Chạy `uv run ruff check .`, `uv run ruff format --check .`, `uv run mypy src/nanobio_backend`, `uv run pytest` và kiểm tra context/worklog theo repo.
- Không thay đổi `OLLAMA_TECHNICAL_REQUESTS_PER_MINUTE=6`, vì rate limit này không liên quan đến lỗi 502; quota thương mại thuộc task khác.

### P4 — Load-test và triển khai server theo từng mức

- Trước khi deploy, ghi lại commit cũ, backup environment file/không sao chép secrets lên chat, kiểm tra Ollama và DB health, không thay schema.
- Rollout bắt đầu: `OLLAMA_NUM_CTX=2048`, `OLLAMA_NUM_PREDICT=512`, `OLLAMA_READ_TIMEOUT_SECONDS=120` với model đúng. Restart FastAPI; test chính câu hỏi gây lỗi bằng JWT qua HTTPS hoặc localhost/tunnel.
- Test serial: câu đơn, câu hỏi y tế thông thường, nhiều yêu cầu, dài hơn; theo dõi latency/p95, `done_reason`, correctness, `nvidia-smi`/`ollama ps`, OOM và GPU offload.
- Nếu ổn: thử lần lượt `OLLAMA_NUM_CTX=3072` rồi `4096`, **chỉ khi VRAM headroom đủ** và model vẫn 100% GPU. Không tự tăng `OLLAMA_NUM_PARALLEL`; phải benchmark 1/2/3 concurrent riêng, cân bằng tail latency và GPU memory. Ollama memory có thể tăng theo parallel × context.
- Chỉ giữ mức cao hơn nếu không OOM, không degrade khó chấp nhận, câu hỏi test được trả lời hoàn chỉnh. Không hứa mô hình 4B sẽ có năng lực tương đương model lớn hơn chỉ nhờ token budget.

### P5 — Rollback, bàn giao

- Nếu startup `ValidationError`: kiểm tra bound trong `config.py`, chính xác biến env, quay về bản code trước hoặc giảm env phù hợp.
- Nếu GPU OOM/tải CPU: quay về `num_ctx=2048`, `num_predict=256/512`, giảm parallel hoặc quay lại commit đã chạy ổn.
- Bàn giao **ZIP theo cấu trúc dự án**, chỉ file code/config sample/test/docs bắt buộc đã sửa hoặc tạo; không patch/dump/log/token. Ghi test thật và test chưa chạy trung thực; chỉ deploy khi người dùng chấp thuận.

## 4. Danh mục file coding chính xác

```text
backend/src/nanobio_backend/core/config.py
backend/src/nanobio_backend/services/ollama_client.py
backend/src/nanobio_backend/modules/edge_api/view.py
backend/.env.example
backend/tests/test_ai_ollama.py
```

Có thể thêm test file hoặc tài liệu tương ứng nếu bắt buộc theo quy trình AGENTS nhưng không sửa module ngoài scope.

## 5. Acceptance criteria

- AC-01: Với `num_predict=512`, model tạo phản hồi hợp lệ cho câu hỏi đã gây 502 (qua đường API JWT thực tế), không chỉ direct Ollama.
- AC-02: Không còn `502 AI_PROVIDER_FAILURE` chỉ vì `done_reason=length` của 96-token config trước; nếu vẫn truncated, cung cấp trạng thái riêng và giải thích đúng.
- AC-03: Không có startup `ValidationError` với env phù hợp giới hạn source mới.
- AC-04: Không mất JWT, rate limit, safety rules và cấu trúc response; không thêm model khác.
- AC-05: Ollama vẫn local-only, model load GPU không OOM; xác minh `nvidia-smi` và `ollama ps` khi đang tải.
- AC-06: Unit + integration tests pass, commit/source thực tế đúng và có cách rollback xác định.

**Nhắc lại:** File này là bản kế hoạch, chưa có code hoặc cấu hình production nào được thay đổi.
