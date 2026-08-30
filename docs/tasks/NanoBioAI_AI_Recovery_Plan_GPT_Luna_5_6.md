# NanoBioAI — Kế hoạch khôi phục AI end-to-end cho GPT Luna 5.6

**Ngày lập:** 2026-08-29  
**Repository canonical:** `daovanhung-dev/NanoBioAI`  
**Supabase project ref hiện tại:** `rnwohifdnylqfofkydfl`  
**Loại công việc:** Direct bugfix + runtime/backend configuration + E2E verification  
**Trạng thái:** PLAN ONLY — chưa thực thi coding/deploy trong kế hoạch này.

---

## 0. Mục tiêu cuối cùng và định nghĩa “AI hoạt động 100%”

Mục tiêu không phải chỉ làm hết HTTP 502. Task chỉ được đóng khi toàn bộ tuyến AI production của NanoBioAI chạy thật theo kiến trúc:

```text
Flutter app
  -> AIService / AIChatService / AI Voice datasource / các AI feature khác
  -> NabiAiBackendClient
  -> Supabase Edge Function: nabi-ai-generate
  -> Gemini GenerateContent API
  -> response hợp lệ
  -> Flutter validate/normalize
  -> UI hiển thị/lưu dữ liệu đúng
```

“100%” trong plan này được hiểu là **100% các acceptance gate trong mục 19 PASS tại thời điểm nghiệm thu**. Không được tuyên bố bảo đảm uptime vĩnh viễn của Google Gemini, Supabase, Internet hoặc dịch vụ bên thứ ba.

### 0.1. Điều kiện bắt buộc để được ghi DONE

1. Gemini key production mới/đã rotate gọi trực tiếp Gemini thành công.
2. Edge Function `nabi-ai-generate` trả HTTP 200 bằng request thật.
3. Guest request qua Edge Function thành công.
4. Authenticated request qua Edge Function thành công.
5. AI Chat nhận câu trả lời thật từ backend.
6. AI Voice đi đủ STT -> backend AI -> TTS trên thiết bị thật.
7. Onboarding tạo initial plan bằng AI thật; **không tính local fallback là PASS**.
8. Meal plan và exercise generation xác nhận `PlanGenerationSource.ai` ít nhất một lần trong E2E verification.
9. Các feature đang dùng cùng `NabiAiBackendClient` được inventory và smoke-test.
10. Provider lỗi 400/401/403/404/429/5xx có log chẩn đoán an toàn, không lộ key/prompt/health data.
11. Flutter log AI có thể bắt được trong debug session.
12. Targeted Flutter tests, Deno tests, analyze và debug APK build PASS.
13. Không có `GEMINI_API_KEY` trong Flutter asset, APK, Git, Dart define release hoặc Android BuildConfig.
14. Supabase secrets, function config, model allowlist và Flutter model candidates không còn lệch nhau.
15. Thiết bị Android thật xác nhận chat + onboarding/plan + voice hoạt động.

---

## 1. Bằng chứng lỗi hiện tại — không được chẩn đoán lại từ đầu nếu chưa có bằng chứng mới

### 1.1. Đã xác nhận

- Flutter build/cài app thành công.
- Log startup có jank lớn (`Skipped frames`, `Davey`, SQLite/TTS delays), nhưng chưa phải bằng chứng AI fail.
- `flutter run | tee` không thu được AI trace vì app logger dùng `developer.log` qua `TerminalLogSink`.
- Supabase project đang là `rnwohifdnylqfofkydfl`.
- Remote secret list có `GEMINI_API_KEY`.
- Remote secret list tại thời điểm chẩn đoán **không có** `GEMINI_MODEL` và `GEMINI_ALLOWED_MODELS`.
- Request trực tiếp tới `https://<project>.supabase.co/functions/v1/nabi-ai-generate` trả:
  - HTTP `502`
  - `sb-error-code: EDGE_FUNCTION_ERROR`
  - body: `{"success":false,"message":"Dịch vụ AI tạm thời chưa sẵn sàng."}`
- Vì handler chỉ trả 502 khi provider generation ném lỗi, root cause hiện nằm trong nhánh **Edge Function -> Gemini/provider**, không phải build Flutter.

### 1.2. Split-brain model config hiện tại

Các lớp đang không dùng cùng một model configuration:

- `.env` local của developer: `GEMINI_MODEL=gemini-3.5-flash`.
- `supabase/functions/nabi-ai-generate/index.ts`: nếu server không có `GEMINI_MODEL`, mặc định `gemini-2.5-flash`.
- `AIModelCandidates` cho plan: primary mặc định `gemini-3.1-flash-lite`, fallback có `gemini-3.5-flash`, `gemini-2.5-flash-lite`, `gemini-2.5-flash`.
- `AIChatModelCandidates`: primary mặc định `gemini-3.1-flash-lite`, fallback có `gemini-3.5-flash`.
- `GeminiVoiceChatTurnDatasource`: mặc định `gemini-3.5-flash`.

Đây phải được xử lý trong task; không được chỉ thay key rồi bỏ qua.

### 1.3. Security incident cần xử lý trước coding

Gemini API key cũ đã từng được paste trực tiếp trong conversation. Xem key đó là **compromised**.

Bắt buộc:

- revoke/rotate key cũ;
- không log key mới;
- không ghi key mới vào plan/worklog/zip;
- không commit `.env` thật;
- không đưa Gemini key trở lại Flutter/Gradle/APK.

---

## 2. Source-of-truth và context bắt buộc GPT Luna 5.6 phải đọc

Trước khi chỉnh bất kỳ file runtime nào, agent phải làm đúng router của repository.

### 2.1. Repository/context

Đọc theo thứ tự:

1. `AGENTS.md`
2. `.codex/AGENTS.md`
3. `.codex/PROJECT_MAP.md`
4. `.codex/history/LEARNED_SKILLS.md`
5. `.codex/workflows/bugfix.md`
6. `.codex/task-skills/bugfix.md`
7. `.codex/domains/ai-service.md`
8. `.codex/history/OPEN_RISKS.md` — bắt buộc vì task liên quan Supabase/release readiness.

### 2.2. Runtime files bắt buộc đọc trước khi code

Backend AI:

- `supabase/config.toml`
- `supabase/functions/nabi-ai-generate/index.ts`
- `supabase/functions/nabi-ai-generate/handler.ts`
- `supabase/functions/nabi-ai-generate/handler_test.ts`

Flutter transport/config:

- `lib/main.dart`
- `lib/core/config/app_env.dart`
- `lib/app_versions/v1/services/ai/nabi_ai_backend_client.dart`
- `lib/app_versions/v1/services/ai/gemini_rest_client.dart`
- `lib/app_versions/v1/services/ai/ai_exceptions.dart`
- `lib/app_versions/v1/services/ai/ai_trace_logger.dart`
- `lib/app_versions/v1/services/ai/ai_service.dart`
- `lib/app_versions/v1/services/ai/ai_chat_service.dart`
- `lib/app_versions/v1/services/ai/generated_plan_service.dart`

Voice AI:

- `lib/app_versions/v1/features/ai_voice/providers/voice_dependencies.dart`
- `lib/app_versions/v1/features/ai_voice/data/datasources/voice_chat_turn_datasource.dart`
- repository/controller/page liên quan AI voice tìm bằng `rg`.

Logging:

- `lib/core/utils/logger/app_logger.dart`
- `lib/core/utils/logger/terminal_log_sink.dart`
- `lib/core/utils/logger/log_redactor.dart`

Tests:

- `test/services/ai/ai_service_test.dart`
- `test/services/ai/gemini_rest_client_test.dart`
- `test/services/ai/nabi_ai_backend_client_contract_test.dart`
- toàn bộ test trực tiếp của `ai_chat` và `ai_voice` được tìm bằng `rg --files test | rg 'ai_chat|ai_voice|voice_chat'`.

### 2.3. Inventory AI usage trước code

Agent phải chạy:

```bash
rg -n "NabiAiBackendClient|AiTextClient|GeminiRestClient|generateText|generateContent|GEMINI_|AIService|AIChatService" lib test supabase tools
```

Mục tiêu là lập danh sách **tất cả feature runtime đang phụ thuộc AI backend**, không được mặc định chỉ có chat và meal plan.

---

## 3. Phạm vi task

### In scope

- Gemini provider credential/runtime verification.
- Supabase project link/configuration.
- Supabase Edge Function secrets.
- `nabi-ai-generate` code, test, config, deploy, logs.
- Model configuration và allowlist.
- Flutter backend transport.
- AI Chat.
- AI plan generation.
- Onboarding initial generated plan.
- AI Voice sequential turn.
- Các AI feature khác tìm được qua inventory và dùng cùng backend transport.
- Debug observability cần thiết để bắt lỗi AI.
- Tests, deploy validation, physical-device E2E.
- Docs/worklog/history sau khi hoàn tất.

### Không tự ý mở rộng

- Không refactor toàn app.
- Không fix Gradle/AGP/Kotlin warning trong cùng task trừ khi nó chặn build.
- Không tối ưu toàn bộ startup jank/SQLite/TTS trong cùng task trừ khi nó chặn trực tiếp AI E2E.
- Không thay membership/product business rules.
- Không đổi kiến trúc sang Gemini SDK trực tiếp trên Flutter.
- Không đưa provider key vào client.

---

## 4. Kiến trúc mục tiêu sau fix

```text
[Public Flutter config]
SUPABASE_URL
SUPABASE_ANON_KEY / publishable key
GEMINI_* model names only (optional, non-secret)
         |
         v
Flutter AI services
         |
         v
NabiAiBackendClient
         |
         v
Supabase Edge Function nabi-ai-generate
  - verify_jwt=false at gateway because guest onboarding AI is allowed
  - optional auth is validated inside function
  - bounded request
  - server-side rate guard
  - server model allowlist
  - safe structured logging
         |
         v
Gemini API
  x-goog-api-key = server secret only
```

### 4.1. `verify_jwt=false` không được đổi tùy tiện

`supabase/config.toml` hiện cấu hình:

```toml
[functions.nabi-ai-generate]
verify_jwt = false
```

Giữ nguyên trong bugfix trừ khi product requirement thay đổi, vì guest onboarding cần AI generation. Function vẫn tự xác minh Bearer token khi có token và dùng guest/IP path khi không xác minh được user.

---

# PHẦN A — DIAGNOSIS VÀ CREDENTIAL RECOVERY

## 5. Phase 0 — Baseline, branch, backup và security reset

### 5.1. Chốt working tree

```bash
cd ~/Desktop/Develop/NanoBioAI
git remote -v
git status --short
git branch --show-current
git rev-parse HEAD
```

Nếu có thay đổi chưa commit không thuộc task: **không xóa/ghi đè**. Ghi nhận trước khi làm.

Tạo branch nếu workflow cho phép:

```bash
git switch -c fix/ai-backend-502-e2e
```

### 5.2. Rotate Gemini key cũ

Thực hiện trong Google AI account đã dùng cho project:

1. Revoke key đã bị lộ.
2. Tạo credential mới có quyền Gemini API.
3. Không paste key vào chat/log/worklog.
4. Chỉ nhập vào terminal bằng hidden prompt:

```bash
read -rsp "GEMINI_API_KEY moi: " GEMINI_API_KEY
echo
```

### Gate A0

- Key cũ revoked.
- `$GEMINI_API_KEY` mới chỉ tồn tại trong shell memory.
- Không có key thật trong git diff.

---

## 6. Phase 1 — Test Gemini provider trực tiếp, chưa qua Supabase

Không được chỉnh Flutter trước khi provider direct test PASS.

### 6.1. Probe model IDs ổn định

Theo Gemini docs hiện tại, các stable IDs cần probe tối thiểu:

- `gemini-3.5-flash`
- `gemini-3.6-flash` nếu account/quota hỗ trợ
- `gemini-2.5-flash`

Không dùng preview model làm primary của production bugfix nếu stable model đáp ứng.

### 6.2. Direct GenerateContent smoke

Ví dụ với model mục tiêu:

```bash
MODEL="gemini-3.5-flash"

curl -sS \
  -o /tmp/gemini-provider-smoke.json \
  -w 'HTTP_STATUS=%{http_code}\n' \
  -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent" \
  -H 'Content-Type: application/json' \
  -H "x-goog-api-key: ${GEMINI_API_KEY}" \
  -d '{
    "contents":[{"role":"user","parts":[{"text":"Tra loi dung mot tu: OK"}]}],
    "generationConfig":{"maxOutputTokens":32,"temperature":0.1}
  }'
```

Không upload `/tmp/gemini-provider-smoke.json` nếu response chứa dữ liệu không cần thiết.

### 6.3. Decision tree provider

- 200: model/key usable -> tiếp tục.
- 400: kiểm tra payload/model parameters.
- 401/403: credential/API access/restriction sai -> sửa credential, chưa chạm app.
- 404: model ID/account availability sai -> thử stable model khác.
- 429: quota/billing/provider capacity -> xử lý quota/billing trước.
- 5xx: thử lại có kiểm soát; nếu kéo dài thì provider incident, không claim app fixed.

### Gate A1

Có ít nhất **2 direct requests liên tiếp HTTP 200** bằng model primary được chọn.

---

# PHẦN B — SUPABASE CONFIGURATION

## 7. Phase 2 — Link và xác minh đúng Supabase project

```bash
npx supabase --version
npx supabase login
npx supabase projects list
npx supabase link --project-ref rnwohifdnylqfofkydfl
```

Xác minh public project config đọc từ source:

```bash
grep '^SUPABASE_URL=' assets/config/auth.env
grep '^SUPABASE_ANON_KEY=' assets/config/auth.env | sed 's/=.*/=<CONFIGURED>/'
```

Không in full anon key vào worklog; public key không phải server secret nhưng vẫn không cần copy lan truyền.

### Gate B2

- Project ref local/remote đúng `rnwohifdnylqfofkydfl`.
- `SUPABASE_URL` trong app trỏ đúng project.

---

## 8. Phase 3 — Chuẩn hóa Supabase secrets

### 8.1. Chọn model policy theo kết quả direct probe

Quy tắc:

1. Chỉ allow stable model đã direct-test PASS.
2. Ưu tiên giữ `gemini-3.5-flash` làm primary nếu nó PASS để khớp `.env` hiện tại và voice default, giảm thay đổi không cần thiết.
3. Thêm model fallback stable chỉ sau khi probe PASS.
4. Không để Edge Function silently rơi về một model khác với model policy của app mà không có log.

Ví dụ policy nếu cả 3 PASS:

```text
primary: gemini-3.5-flash
allowed: gemini-3.5-flash,gemini-3.6-flash,gemini-2.5-flash
```

### 8.2. Set secrets remote

```bash
npx supabase secrets set \
  GEMINI_API_KEY="$GEMINI_API_KEY" \
  GEMINI_MODEL="gemini-3.5-flash" \
  GEMINI_ALLOWED_MODELS="gemini-3.5-flash,gemini-3.6-flash,gemini-2.5-flash" \
  --project-ref rnwohifdnylqfofkydfl
```

Điều chỉnh allowlist theo model thực tế đã probe PASS.

Sau đó:

```bash
unset GEMINI_API_KEY
npx supabase secrets list --project-ref rnwohifdnylqfofkydfl
```

Theo Supabase contract hiện tại, secret update có hiệu lực cho Edge Function mà không bắt buộc redeploy; tuy nhiên task này vẫn redeploy sau khi sửa code.

### Gate B3

Remote list có:

- `GEMINI_API_KEY`
- `GEMINI_MODEL`
- `GEMINI_ALLOWED_MODELS`

Không có secret value xuất hiện trong output lưu trữ.

---

# PHẦN C — EDGE FUNCTION BUGFIX

## 9. Phase 4 — Nâng observability của `nabi-ai-generate`

### File chính

- `supabase/functions/nabi-ai-generate/index.ts`
- `supabase/functions/nabi-ai-generate/handler.ts`
- `supabase/functions/nabi-ai-generate/handler_test.ts`

### 9.1. Sửa lỗi mất provider status

Hiện `generateWithGemini()` đã tạo `provider_<HTTP_STATUS>` nhưng handler chỉ log `error.name`, khiến `403`, `429`, `404`, `503` biến thành chữ `Error`.

Sửa trực tiếp source để log **safe structured metadata**, tối thiểu:

- `providerHttpStatus`
- provider status symbolic nếu payload có (`PERMISSION_DENIED`, `RESOURCE_EXHAUSTED`, ...)
- `model`
- request execution/correlation ID nếu Supabase env cung cấp
- duration

Không log:

- API key
- Authorization header
- prompt
- contents
- systemInstruction
- response body raw
- health profile

### 9.2. Chuẩn hóa provider error classification

Tạo internal mapping rõ:

- 400 -> provider request/config invalid
- 401/403 -> provider credential/access invalid
- 404 -> model unavailable
- 408/429 -> transient/quota
- 5xx -> transient provider failure
- empty response -> provider invalid response

User response vẫn là Vietnamese safe copy. Internal logs phải phân biệt được nguyên nhân.

### 9.3. Model resolution phải log safe summary

Khi function khởi động/request, log model được chọn, nhưng không log secret.

Nếu client gửi model ngoài allowlist:

- dùng configured server default;
- log `requestedModelAllowed=false` và `selectedModel=<default>` hoặc tương đương;
- không silent fallback hoàn toàn.

### 9.4. Không phá guest contract

Giữ request bounds và guest path hiện tại.

### Gate C4

Unit test chứng minh provider failure không còn là “unknown/Error-only” trong internal diagnostic path.

---

## 10. Phase 5 — Edge Function tests

### 10.1. Bổ sung/điều chỉnh Deno tests

`handler_test.ts` phải cover ít nhất:

1. valid authenticated request -> 200.
2. valid guest request -> generation allowed khi rate limit pass.
3. rate limit reject -> 429.
4. malformed request -> 400.
5. oversized -> 413.
6. provider failure -> non-success.
7. provider 403 classification.
8. provider 429 classification.
9. provider 404/model classification.
10. provider empty response -> non-success.
11. response over max -> 502.

Nếu provider mapping nằm trong `index.ts` khó unit-test, tách pure helper nhỏ trong cùng function folder; không tạo abstraction thừa.

### 10.2. Run tests

Dùng Deno/runtime được project hỗ trợ. Nếu repo không có Deno CLI local, dùng Supabase function local test/tooling phù hợp; không fake PASS.

### Gate C5

Toàn bộ targeted Edge Function tests PASS.

---

## 11. Phase 6 — Deploy Edge Function

### 11.1. Confirm config

`supabase/config.toml` phải tiếp tục chứa:

```toml
[functions.nabi-ai-generate]
verify_jwt = false
```

### 11.2. Deploy

```bash
npx supabase functions deploy nabi-ai-generate \
  --project-ref rnwohifdnylqfofkydfl \
  --use-api
```

Không cần CLI flag `--no-verify-jwt` nếu `config.toml` là source-of-truth và CLI version tôn trọng function config; nếu cần tương thích CLI, dùng flag nhưng phải giữ `config.toml` đồng nhất.

### 11.3. Record deployment evidence

Ghi:

- deployment ID/version nếu có;
- timestamp;
- project ref;
- không ghi secret.

### Gate C6

Function deploy thành công vào đúng project.

---

## 12. Phase 7 — Remote Edge Function smoke tests

### 12.1. Guest smoke

Đọc public config từ `assets/config/auth.env`, không hardcode key trong script/worklog.

Gọi `nabi-ai-generate` với request nhỏ.

PASS:

```text
HTTP 200
success=true
text non-empty
```

### 12.2. Authenticated smoke

Đăng nhập bằng test account hợp lệ, lấy session JWT qua app/test harness, rồi gọi function với Bearer JWT.

PASS:

- 200
- logs xác nhận `userId` path được resolve (chỉ log presence/hash-safe identifier nếu policy cho phép; không log token).

### 12.3. Error smoke

Dùng test seam/local unit test để simulate 403/429/5xx; không cố tình phá production secret.

### Gate C7

Guest + authenticated live function đều PASS.

---

# PHẦN D — FLUTTER RUNTIME FIX

## 13. Phase 8 — Chuẩn hóa client/server model configuration

### Files

- `lib/core/config/app_env.dart`
- `lib/app_versions/v1/services/ai/ai_service.dart`
- `lib/app_versions/v1/services/ai/ai_chat_service.dart`
- `lib/app_versions/v1/features/ai_voice/data/datasources/voice_chat_turn_datasource.dart`
- `.env.example`
- local `.env` chỉ chỉnh trên máy user, không commit secret.

### 13.1. Mục tiêu

Không còn 4 default primary khác nhau mà không có chủ đích.

### 13.2. Quy tắc cấu hình

Public client có thể giữ model names:

```text
GEMINI_PLAN_MODEL
GEMINI_PLAN_FALLBACK_MODELS
GEMINI_CHAT_MODEL
GEMINI_CHAT_FALLBACK_MODELS
```

Nhưng server luôn enforce allowlist.

Đề xuất sau khi provider probe PASS:

```text
GEMINI_PLAN_MODEL=gemini-3.5-flash
GEMINI_PLAN_FALLBACK_MODELS=gemini-3.6-flash,gemini-2.5-flash
GEMINI_CHAT_MODEL=gemini-3.5-flash
GEMINI_CHAT_FALLBACK_MODELS=gemini-3.6-flash,gemini-2.5-flash
```

Không bắt buộc dùng 3.6 nếu direct probe/quota không PASS.

### 13.3. `.env` cleanup

Local developer `.env` cuối task:

- giữ public Supabase config nếu workflow local cần;
- giữ model names nếu cần;
- **xóa `GEMINI_API_KEY` khỏi Flutter `.env`**;
- chuẩn hóa `ONBOARDING_AI_DEV_CHECK_ENABLED=true` không có khoảng trắng quanh key;
- `.env` phải ở `.gitignore`.

`.env.example`:

- không hướng dẫn đưa Gemini key vào Flutter runtime;
- mô tả provider key là Edge Function secret;
- model examples phải khớp policy mới.

### Gate D8

Flutter release path không chứa provider credential và model candidates đều thuộc server allowlist.

---

## 14. Phase 9 — Fix Flutter backend error observability

### 14.1. `NabiAiBackendClient`

Kiểm tra/điều chỉnh sao cho:

- function non-2xx giữ được HTTP status;
- network errors phân biệt với backend/provider errors;
- không nuốt stack context cần thiết;
- không log response raw/prompt/secret.

Nếu `FunctionException` expose safe `details`, chỉ parse các code đã được Edge Function chủ động trả về; không dump object thô.

### 14.2. `GeminiApiException`

Đảm bảo backend 429/5xx/transient mapping phù hợp retry policy.

Provider auth/server-config error không được hiển thị như user nhập sai password/token.

### Gate D9

Unit test cover status mapping và user-safe failure mapping.

---

## 15. Phase 10 — Fix debug logging để bắt AI trace bằng terminal

Hiện:

```text
AITraceLogger -> AppLogger -> TerminalLogSink -> developer.log
```

nên `flutter run | tee` không bắt được business trace như mong đợi.

### 15.1. Yêu cầu

Trong debug mode, `TerminalLogSink` phải có một terminal-visible sink an toàn, ví dụ `debugPrint`, nhưng release không spam log.

Không được làm duplicate log quá mức trong production/profile.

### 15.2. Validation

Chạy:

```bash
flutter run 2>&1 | tee /tmp/nanobio-ai-debug.log
```

Gửi một AI request và:

```bash
grep -nEi 'AI_SERVICE|AI_CHAT|ai\]|Supabase|backend|model|retry' /tmp/nanobio-ai-debug.log
```

phải thấy trace sanitized.

### Gate D10

Có thể bắt AI lifecycle từ terminal trong debug build, không lộ prompt/secret.

---

# PHẦN E — FEATURE VERIFICATION

## 16. Phase 11 — AI Plan / onboarding initial plan

### 16.1. `AIService.checkConnection`

Chạy developer check với backend client thật.

PASS khi response JSON connection check validate thành công.

### 16.2. Meal plan

Test `generateMealPlanWithSource`.

PASS bắt buộc:

```text
source == PlanGenerationSource.ai
```

Nếu `localFallback`, test được đánh dấu FAIL cho “AI E2E”, dù UI vẫn có dữ liệu.

### 16.3. Exercise plan

Tương tự meal plan:

```text
source == PlanGenerationSource.ai
```

### 16.4. Onboarding

Reset một test profile/clean app state phù hợp, hoàn thành onboarding và xác minh:

- catalog available;
- AI backend request thật xảy ra;
- generated initial plan thành công;
- meal/task/schedule lưu SQLite;
- dashboard đọc được dữ liệu;
- notification scheduling không chặn completion.

### Gate E11

Initial onboarding generation thật sự dùng AI, không fallback.

---

## 17. Phase 12 — AI Chat

### 17.1. Text chat

Test logged-in user theo access rule hiện tại:

- gửi câu tiếng Việt;
- response non-empty;
- `AIVietnameseTextValidator` PASS;
- history bounded;
- response hiển thị UI;
- quota app/backend được áp dụng đúng, không bypass.

### 17.2. Fallback model behavior

Trong unit test/fake transport:

- primary transient fail -> thử fallback;
- permanent config/model failure -> behavior đúng contract;
- cooldown không khóa tất cả model sai cách.

### Gate E12

Ít nhất 3 chat turns liên tiếp trên device trả response thật và không lỗi.

---

## 18. Phase 13 — AI Voice

Voice route hiện dùng:

```text
Device STT
 -> GeminiVoiceChatTurnDatasource
 -> NabiAiBackendClient
 -> Edge Function
 -> Gemini
 -> response text
 -> Device TTS
```

### 18.1. Validate model

`GeminiVoiceChatTurnDatasource` phải resolve model nằm trong server allowlist.

### 18.2. Physical device test

Trên thiết bị `220333QPG` hoặc device user chọn:

1. cấp microphone permission;
2. mở AI Voice theo đúng membership gate;
3. nói câu đơn giản;
4. STT nhận transcript;
5. backend request HTTP 200;
6. Nabi response text hợp lệ;
7. TTS bắt đầu đọc;
8. turn tiếp theo giữ history đúng giới hạn;
9. timeout/error có copy thân thiện.

### Gate E13

3 voice turns liên tiếp PASS trên physical device.

---

## 19. Phase 14 — Inventory và smoke toàn bộ AI features

Agent phải dùng inventory ở Phase 2 để tìm mọi callsite của:

- `NabiAiBackendClient`
- `AiTextClient`
- `GeminiRestClient`
- `generateText`

Với mỗi production callsite, tạo matrix:

| Feature | Route/service | Model | Auth requirement | Backend | Smoke result |
|---|---|---|---|---|---|
| AI Plan | AIService | ... | guest/member | nabi-ai-generate | PASS/FAIL |
| AI Chat | AIChatService | ... | login/quota | nabi-ai-generate | PASS/FAIL |
| AI Voice | Voice datasource | ... | paid gate | nabi-ai-generate | PASS/FAIL |
| NaBi Care | discovered path | ... | ... | ... | ... |
| Food Scan | discovered path | ... | ... | ... | ... |
| Sleep Analysis | discovered path | ... | ... | ... | ... |
| Other | discovered path | ... | ... | ... | ... |

Không ghi PASS cho feature chưa chạy được theo runtime path hiện tại.

---

# PHẦN F — TEST / BUILD / RELEASE SAFETY

## 20. Phase 15 — Targeted automated validation

### 20.1. Format

Chỉ format touched files:

```bash
dart format <touched-dart-files>
```

Deno/TS format theo project tooling.

### 20.2. Flutter targeted analyze

Ví dụ:

```bash
flutter analyze \
  lib/core/config/app_env.dart \
  lib/core/utils/logger/terminal_log_sink.dart \
  lib/app_versions/v1/services/ai \
  lib/app_versions/v1/features/ai_voice
```

Điều chỉnh theo touched files.

### 20.3. Targeted tests

```bash
flutter test test/services/ai
```

Thêm AI chat/voice tests discovered từ inventory.

### 20.4. Architecture tests nếu dependency thay đổi

```bash
flutter test test/architecture_version_boundary_test.dart
flutter test test/architecture_preservation_property_test.dart
```

### 20.5. Build

```bash
flutter build apk --debug
```

Nếu task release scope cần native validation rộng hơn thì chạy project check command từ `.codex/AGENTS.md`.

### Gate F15

Không có targeted analyzer/test/build failure do task tạo ra.

---

## 21. Phase 16 — Device E2E validation

### 21.1. Clean-ish device run

```bash
flutter run 2>&1 | tee /tmp/nanobio-ai-final-e2e.log
```

Không nhất thiết wipe user data nếu có dữ liệu quan trọng; dùng test account/profile hoặc backup trước.

### 21.2. E2E sequence bắt buộc

1. App bootstrap -> Supabase ready.
2. Guest onboarding AI plan -> PASS AI source.
3. Login test account.
4. AI Chat 3 turns -> PASS.
5. AI Voice 3 turns -> PASS nếu entitlement hợp lệ.
6. Trigger một AI feature khác từ inventory -> PASS.
7. Tắt/bật mạng có kiểm soát -> app hiện safe error, không crash.
8. Khôi phục mạng -> AI request tiếp theo hoạt động lại.

### 21.3. Kiểm tra log

Không được xuất hiện:

- provider key
- Authorization bearer
- full health prompt
- full model response nếu chứa user data

### Gate F16

Physical device E2E matrix 100% PASS cho các capability được quyền truy cập bởi test account.

---

## 22. Phase 17 — Security verification

### 22.1. Repo secret scan

```bash
rg -n "GEMINI_API_KEY\s*=|x-goog-api-key|AIza|AQ\." \
  --glob '!build/**' \
  --glob '!.dart_tool/**' \
  --glob '!.git/**'
```

Review từng match; test fixtures có placeholder thì được, real secret thì FAIL.

### 22.2. APK inspection

Sau build, kiểm tra strings/artifact để đảm bảo provider key mới không nằm trong APK.

### 22.3. `.gitignore`

Xác minh `.env` thật không tracked.

### Gate F17

Không có Gemini production credential trong source tree hoặc APK.

---

# PHẦN G — CONFIG CLEANUP VÀ DOCUMENTATION

## 23. Phase 18 — Chuẩn hóa file config/documentation

Các file có thể cần cập nhật tùy diff thực tế:

- `.env.example`
- `lib/app_versions/v1/services/ai/README_FIX.md`
- docs liên quan AI runtime/release nếu current-state docs đang sai
- `.codex/history/OPEN_RISKS.md` chỉ cập nhật trạng thái nếu runtime evidence thật sự đủ

### 23.1. Không được cập nhật docs kiểu false-positive

Chỉ đóng `NB-RISK-003 AI/Supabase runtime deployment evidence pending` khi đã có:

- deployed function evidence;
- guest HTTP PASS;
- authenticated HTTP PASS;
- device AI PASS;
- secret config verified;
- test evidence.

---

## 24. Phase 19 — Worklog và project memory

Theo repo workflow:

1. Tạo `docs/fixbug/<slug>/` nếu bugfix đủ lớn theo convention hiện tại.
2. Tạo worklog ngày hiện tại.
3. Ghi:
   - root cause thật;
   - files changed;
   - Supabase deploy evidence không chứa secrets;
   - tests;
   - device results;
   - remaining risks.
4. Thêm self-review theo `.codex/history/SESSION_QUALITY_REVIEW.md`.
5. Chạy history refresh script theo `.codex/AGENTS.md`.
6. Chạy `git diff --check`.

---

# PHẦN H — FINAL ACCEPTANCE MATRIX

## 25. Checklist nghiệm thu bắt buộc

Agent chỉ được kết luận **FIXED / AI READY** khi tất cả ô áp dụng đều PASS.

### Provider

- [ ] Old exposed Gemini key revoked.
- [ ] New key direct Gemini request 200 x2.
- [ ] Primary model stable và usable.
- [ ] Fallback models chỉ gồm model đã probe PASS.

### Supabase

- [ ] Correct project linked.
- [ ] `GEMINI_API_KEY` secret configured.
- [ ] `GEMINI_MODEL` configured.
- [ ] `GEMINI_ALLOWED_MODELS` configured.
- [ ] `nabi-ai-generate` deployed.
- [ ] `config.toml` đúng guest/auth contract.
- [ ] Guest function call 200.
- [ ] Authenticated function call 200.
- [ ] Provider errors có safe diagnostic logs.

### Flutter transport

- [ ] `NabiAiBackendClient` receives live response.
- [ ] Error mapping tested.
- [ ] Model requests all thuộc server allowlist.
- [ ] No Gemini key in Flutter runtime.
- [ ] Debug AI logs visible and sanitized.

### AI Plan

- [ ] AI connection check PASS.
- [ ] Meal generation `source=ai`.
- [ ] Exercise generation `source=ai`.
- [ ] Onboarding initial plan `source=ai`.
- [ ] SQLite persistence PASS.
- [ ] Dashboard refresh PASS.

### AI Chat

- [ ] 3 consecutive live turns PASS.
- [ ] Vietnamese validation PASS.
- [ ] Quota/access rules preserved.
- [ ] Retry/fallback test PASS.

### AI Voice

- [ ] STT PASS.
- [ ] Backend AI PASS.
- [ ] TTS PASS.
- [ ] 3 consecutive voice turns PASS.
- [ ] Access gate preserved.

### Other AI features

- [ ] Full callsite inventory complete.
- [ ] Every reachable production AI callsite has smoke-test result.

### Quality/security

- [ ] Targeted Deno tests PASS.
- [ ] Targeted Flutter tests PASS.
- [ ] Targeted analyze PASS.
- [ ] Debug APK build PASS.
- [ ] Physical-device E2E PASS.
- [ ] Secret scan PASS.
- [ ] APK secret inspection PASS.
- [ ] Worklog/history updated.

---

# PHẦN I — ROOT-CAUSE DECISION TREE CHO GPT LUNA 5.6

## 26. Không sửa mò — xử lý theo status

### Direct Gemini fail

```text
Direct Gemini != 200
 -> Không sửa Flutter
 -> Sửa key / API access / model / quota / billing
 -> Retest đến 200 x2
```

### Direct Gemini 200 nhưng Edge Function 502

```text
Provider OK
 -> kiểm tra remote secrets digest/names
 -> kiểm tra function model allowlist
 -> đọc Edge logs
 -> kiểm tra deployment version
 -> fix Edge Function
 -> redeploy
```

### Edge Function 200 nhưng Flutter AI fail

```text
Backend OK
 -> kiểm tra Supabase initialization
 -> NabiAiBackendClient
 -> FunctionException/status mapping
 -> model requested by Flutter
 -> access/quota gate
 -> UI/controller/repository
```

### Chat PASS nhưng onboarding plan fallback

```text
Transport OK
 -> kiểm tra catalog
 -> prompt/JSON schema
 -> maxOutputTokens / request bounds
 -> normalizer validation
 -> model-specific JSON response
```

### Text AI PASS nhưng Voice fail

```text
Backend AI OK
 -> kiểm tra membership gate
 -> microphone permission
 -> STT lifecycle
 -> voice model config
 -> request timeout
 -> TTS engine
```

---

# PHẦN J — FILE IMPACT DỰ KIẾN

## 27. File dự kiến sửa

Chỉ sửa sau khi Phase diagnosis xác nhận cần thiết.

### High confidence

```text
supabase/functions/nabi-ai-generate/index.ts
supabase/functions/nabi-ai-generate/handler.ts
supabase/functions/nabi-ai-generate/handler_test.ts
lib/core/utils/logger/terminal_log_sink.dart
.env.example
lib/app_versions/v1/services/ai/README_FIX.md
```

### Conditional

```text
lib/app_versions/v1/services/ai/nabi_ai_backend_client.dart
lib/app_versions/v1/services/ai/ai_service.dart
lib/app_versions/v1/services/ai/ai_chat_service.dart
lib/core/config/app_env.dart
lib/app_versions/v1/features/ai_voice/data/datasources/voice_chat_turn_datasource.dart
test/services/ai/*
<discovered ai_chat tests>
<discovered ai_voice tests>
docs/fixbug/<slug>/*
docs/worklog/2026-08-29/*
.codex/history/* generated by refresh workflow
```

### Không đưa vào delivery

```text
.env thật
API keys
service-role keys
session JWTs
/tmp logs chứa private data
*.patch
review/comment files ngoài project convention
```

---

# PHẦN K — ROLLBACK

## 28. Rollback strategy

### Source rollback

Trước khi code, record base commit. Nếu fix gây regression:

- restore chỉ các touched files bằng Git từ base commit;
- không dùng patch artifact trong delivery;
- không reset/xóa thay đổi user khác.

### Edge Function rollback

- record deployment version trước/sau nếu dashboard/CLI expose;
- nếu deployment mới lỗi, redeploy source version đã known-good;
- secrets mới không rollback về compromised Gemini key.

### Model rollback

Nếu new primary model có lỗi:

- set `GEMINI_MODEL` về stable model đã direct-test PASS;
- giữ allowlist chỉ các model verified;
- không cần đưa key về client.

---

# PHẦN L — OUTPUT CỦA GPT LUNA 5.6 KHI THỰC THI

## 29. Báo cáo cuối task

Agent phải trả:

1. Root cause chính xác.
2. Các root cause phụ nếu có.
3. Danh sách file mới/sửa.
4. Supabase configuration đã thiết lập — chỉ names/status, không values.
5. Edge Function deployment evidence.
6. Provider/Edge/Flutter/device test matrix.
7. Các command validation đã chạy và exit status.
8. Remaining external risks, nếu có.
9. Không nói “100% fixed” nếu acceptance matrix còn ô FAIL/BLOCKED.

## 30. ZIP delivery

Sau khi task thực thi hoàn tất:

- nén **chỉ file mới và file được sửa**;
- giữ nguyên cấu trúc path như repository;
- không thêm patch/review/secret file;
- tên đề xuất:

```text
NanoBioAI_fix_ai_backend_e2e.zip
```

Ví dụ cấu trúc:

```text
NanoBioAI_fix_ai_backend_e2e.zip
├── supabase/
│   └── functions/
│       └── nabi-ai-generate/
│           ├── index.ts
│           ├── handler.ts
│           └── handler_test.ts
├── lib/
│   └── ...
├── test/
│   └── ...
└── docs/
    └── ...
```

Không đưa `.env` thật hoặc secret vào ZIP.

---

# 31. Thứ tự thực thi rút gọn — tuyệt đối không đảo

```text
1. Read AGENTS/context
2. Record git baseline
3. Rotate leaked Gemini key
4. Direct Gemini test
5. Probe stable models
6. Link correct Supabase project
7. Set server secrets/model allowlist
8. Improve Edge Function diagnostics
9. Run Edge unit tests
10. Deploy Edge Function
11. Guest live HTTP test
12. Auth live HTTP test
13. Align Flutter model config
14. Improve Flutter error/log observability if needed
15. AI plan E2E; source must be AI
16. AI chat E2E
17. AI voice E2E
18. Inventory + smoke all remaining AI callsites
19. Targeted analyze/tests/build
20. Physical-device final E2E
21. Secret/APK scan
22. Docs/worklog/history
23. Final acceptance matrix
24. ZIP only changed/new project files
```

**Hard stop rule:** Nếu bước 4 (direct Gemini) chưa PASS, không được sửa Flutter để “fix” 502. Nếu bước 11 (Edge Function live) chưa PASS, không được claim client fix. Nếu plan generation chỉ chạy local fallback, không được claim AI generation PASS.
