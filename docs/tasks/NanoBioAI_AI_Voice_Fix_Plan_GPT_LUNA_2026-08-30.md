# NanoBioAI — Kế hoạch fix AI Voice cho GPT LUNA

**Ngày lập:** 2026-08-30  
**Repository canonical:** `daovanhung-dev/NanoBioAI`  
**Baseline khảo sát:** branch `main`, commit gần nhất khi lập kế hoạch: `696172ac95b0dd3f0e5f4685d8b47f8f22277379`  
**Module:** M07 `AI_CHAT` / Sequential AI Voice  
**Loại công việc:** Direct bugfix + AI backend compatibility + Android physical-device verification  
**Trạng thái:** **PLAN ONLY — CHƯA ĐƯỢC PHÉP SỬA CODE/DEPLOY cho đến khi người dùng xác nhận plan.**  
**Agent thực thi mục tiêu:** **GPT LUNA**

---

# 0. Mục tiêu cuối cùng

Fix triệt để lỗi **không thể trò chuyện với Nabi bằng giọng nói** trên runtime hiện tại của NanoBioAI.

Luồng bắt buộc sau fix:

```text
AI Chat
  -> nhấn icon Mic
  -> authGuard
  -> AiVoiceAccessGate
  -> tài khoản Plus/FamilyPlus hợp lệ từ backend
  -> AiVoicePage
  -> nhấn Bắt đầu
  -> SpeechToText nhận giọng Việt
  -> transcript hợp lệ
  -> AiVoiceRepository
  -> GeminiVoiceChatTurnDatasource
  -> NabiAiBackendClient
  -> Supabase Edge Function: nabi-ai-generate
  -> Gemini provider
  -> text response hợp lệ
  -> FlutterTTS đọc tiếng Việt
  -> quay lại Listening
  -> tiếp tục lượt kế tiếp
```

Task **không được ghi DONE** chỉ vì:

- build thành công;
- unit test thành công;
- mic mở được;
- STT nhận được chữ;
- backend AI text khác hoạt động;
- AI Chat dạng text hoạt động;
- emulator hoạt động.

Task chỉ được DONE khi **luồng Voice E2E trên Android thật** chạy được nhiều lượt liên tục bằng **tài khoản trả phí thật được backend xác nhận**.

---

# 1. Kết luận chẩn đoán hiện tại

## 1.1. Root cause chính — P0, độ tin cậy cao

Runtime Voice hiện gửi:

```dart
GeminiGenerationConfig(
  candidateCount: null,
  maxOutputTokens: 256,
  thinkingLevel: 'MINIMAL',
)
```

Tức request serialize thành:

```json
{
  "maxOutputTokens": 256,
  "thinkingConfig": {
    "thinkingLevel": "MINIMAL"
  }
}
```

Voice đồng thời resolve model theo:

```text
GEMINI_CHAT_MODEL
-> GEMINI_MODEL
-> gemini-3.5-flash
```

Nhưng transport production hiện **không gọi Gemini trực tiếp**. Từ migration ngày 28/08, Voice gọi:

```text
GeminiVoiceChatTurnDatasource
-> NabiAiBackendClient
-> nabi-ai-generate
```

Edge Function hiện chọn model thực thi bằng:

```text
nếu input.model nằm trong GEMINI_ALLOWED_MODELS
    -> dùng input.model
ngược lại
    -> fallback về server GEMINI_MODEL
    -> nếu server không có GEMINI_MODEL: gemini-2.5-flash
```

Vấn đề: **khi Edge đổi model thì `generationConfig` vẫn được forward nguyên trạng**.

Do đó có thể xảy ra request thực tế:

```text
Flutter Voice:
model = gemini-3.5-flash
thinkingLevel = MINIMAL
        |
        v
Edge allowlist không nhận model đó
        |
        v
model thực thi = gemini-2.5-flash
generationConfig vẫn chứa thinkingLevel = MINIMAL
        |
        v
Gemini 2.5 nhận parameter không tương thích
        |
        v
provider error
        |
        v
Edge handler chuyển thành HTTP 502
        |
        v
VoiceChatException
        |
        v
AiVoiceController dừng session
```

Theo contract Gemini hiện hành, `thinkingLevel` thuộc dòng Gemini mới hơn; với Gemini 2.5 cần contract thinking tương thích riêng (`thinkingBudget`) hoặc không gửi thinking config. Vì Edge thay model mà không normalize config theo **model cuối cùng**, request Voice có thể trở thành invalid ngay sau fallback.

Đây là regression kiến trúc quan trọng nhất cần GPT LUNA sửa.

---

## 1.2. Regression timeline

### 23/08 — Voice từng PASS trên Android thật

Tài liệu dự án đã ghi nhận:

- Xiaomi `220333QPG`, Android 11;
- STT tiếng Việt PASS;
- reaction speed PASS;
- STT -> Gemini -> TTS -> STT PASS;
- Stop/restart/background PASS;
- lỗi cũ `speech_to_text 7.4.0` đã được sửa.

Runtime lúc đó là **client-only Gemini sequential voice**.

### 28/08 — transport AI được harden

Repo chuyển AI production sang:

```text
Flutter
-> NabiAiBackendClient
-> Supabase Edge Function nabi-ai-generate
-> Gemini
```

Mục tiêu bảo mật là đúng: provider credential không còn nằm trong APK.

Tuy nhiên Voice giữ payload/model assumptions cũ. Vì vậy **physical-device acceptance ngày 23/08 không còn chứng minh transport Voice hiện tại hoạt động**.

---

# 2. Những thứ KHÔNG được chẩn đoán lại như root cause nếu không có bằng chứng mới

## 2.1. Lỗi `SpeechToText.listen()` cũ

Đã sửa trong source hiện tại.

`DeviceSpeechRecognitionGateway` hiện:

- chỉ `await _speech.listen(...)`;
- không coi return value là boolean;
- chờ status `listening`;
- chờ `done/notListening`;
- có start timeout;
- có terminal timeout;
- tránh `concurrent startListening`;
- delayed-arm `pauseFor` sau partial non-empty đầu tiên.

**Không rollback code này.**

---

## 2.2. Thiếu `RECORD_AUDIO`

Android manifest hiện đã có:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

Đồng thời có query cho:

```xml
<action android:name="android.speech.RecognitionService"/>
<action android:name="android.intent.action.TTS_SERVICE"/>
```

Không thêm permission vô nghĩa nếu device evidence không yêu cầu.

---

## 2.3. Gemini Live / native PCM

Repo từng có Gemini Live + `RealtimeVoiceAudioController`, nhưng sau đó đã chủ động chuyển sang **Sequential Voice** và gỡ native realtime audio.

Không tự ý:

- khôi phục WebSocket Gemini Live;
- khôi phục PCM native;
- khôi phục `RealtimeVoiceAudioController`;
- thêm lại `MODIFY_AUDIO_SETTINGS`;
- thêm lại Bluetooth handling;

trừ khi có bằng chứng mới chứng minh Sequential Voice không thể đáp ứng product requirement.

Task hiện tại là **fix implementation đang reachable**, không viết lại Voice architecture.

---

# 3. Blocker quyền truy cập — phải phân biệt với bug runtime

Route `/ai-voice` hiện có:

```text
authGuard
-> AiVoiceAccessGate
```

`AiVoiceAccessGate` chỉ mount `AiVoicePage` khi:

- có `currentUserId`;
- access record đúng chính user đó;
- không anonymous;
- `effectiveAccess.hasPaidAccess == true`.

Free user được đưa tới màn yêu cầu Plus.

Đây là **business rule hiện hành**, không phải bug cần bypass.

## 3.1. Tình trạng test device gần nhất

Worklog 30/08 ghi nhận sau khi clear/reinstall app:

- device ở trạng thái guest/free;
- session Plus cũ bị mất;
- chưa xác minh lại Plus;
- không dùng client-side Plus override.

Vì vậy physical-device test của task Voice bắt buộc phải:

1. đăng nhập bằng **tài khoản Plus/FamilyPlus thật**;
2. xác minh `effectiveAccess` đến từ Supabase/trusted backend;
3. tuyệt đối không override provider local;
4. tuyệt đối không hard-code `hasPaidAccess=true`;
5. nếu chưa có account hợp lệ thì ghi **BLOCKED_EXTERNAL / BLOCKED_ACCOUNT**, không claim Voice fixed.

---

# 4. Scope chính xác

## 4.1. Source bắt buộc đọc trước khi sửa

### Context/workflow

```text
AGENTS.md
.codex/AGENTS.md
.codex/PROJECT_MAP.md
.codex/history/LEARNED_SKILLS.md
.codex/workflows/bugfix.md
.codex/task-skills/bugfix.md
.codex/domains/ai-service.md
.codex/domains/access-membership-referral.md
.codex/history/OPEN_RISKS.md
.codex/DOCS_WORKFLOW.md
```

### Voice

```text
lib/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_access_gate.dart
lib/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_page.dart
lib/app_versions/v1/features/ai_voice/presentation/controllers/ai_voice_controller.dart
lib/app_versions/v1/features/ai_voice/providers/ai_voice_providers.dart
lib/app_versions/v1/features/ai_voice/providers/voice_dependencies.dart
lib/app_versions/v1/features/ai_voice/data/datasources/voice_chat_turn_datasource.dart
lib/app_versions/v1/features/ai_voice/data/gateways/speech_to_text_gateway.dart
lib/app_versions/v1/features/ai_voice/data/gateways/flutter_tts_gateway.dart
lib/app_versions/v1/features/ai_voice/data/repositories/ai_voice_repository_impl.dart
lib/app_versions/v1/features/ai_voice/domain/**
```

### AI transport

```text
lib/app_versions/v1/services/ai/nabi_ai_backend_client.dart
lib/app_versions/v1/services/ai/gemini_rest_client.dart
lib/app_versions/v1/services/ai/ai_trace_logger.dart
lib/core/config/app_env.dart
```

### Backend

```text
supabase/config.toml
supabase/functions/nabi-ai-generate/index.ts
supabase/functions/nabi-ai-generate/handler.ts
supabase/functions/nabi-ai-generate/handler_test.ts
```

### Platform

```text
android/app/src/main/AndroidManifest.xml
android/app/src/main/kotlin/com/example/nano_app/MainActivity.kt
pubspec.yaml
```

### Tests

```text
test/app_versions/v1/features/ai_voice/ai_voice_access_gate_test.dart
test/app_versions/v1/features/ai_voice/ai_voice_controller_test.dart
test/app_versions/v1/features/ai_voice/ai_voice_page_test.dart
test/app_versions/v1/features/ai_voice/ai_voice_repository_test.dart
test/app_versions/v1/features/ai_voice/voice_chat_turn_datasource_test.dart
test/app_versions/v1/features/ai_voice/voice_device_gateways_test.dart
test/services/ai/nabi_ai_backend_client_contract_test.dart
```

---

## 4.2. Files có khả năng phải sửa

### P0

```text
lib/app_versions/v1/features/ai_voice/data/datasources/voice_chat_turn_datasource.dart
supabase/functions/nabi-ai-generate/index.ts
test/app_versions/v1/features/ai_voice/voice_chat_turn_datasource_test.dart
supabase/functions/nabi-ai-generate/handler_test.ts
```

### Có thể cần sửa sau khi xác minh

```text
lib/app_versions/v1/services/ai/gemini_rest_client.dart
lib/app_versions/v1/services/ai/nabi_ai_backend_client.dart
.env.example
tools/validate_docs_source_truth.py
```

### Chỉ sửa khi physical-device evidence chứng minh cần thiết

```text
lib/app_versions/v1/features/ai_voice/data/gateways/speech_to_text_gateway.dart
lib/app_versions/v1/features/ai_voice/data/gateways/flutter_tts_gateway.dart
lib/app_versions/v1/features/ai_voice/presentation/controllers/ai_voice_controller.dart
android/app/src/main/AndroidManifest.xml
```

Không được “tiện tay refactor” các file trên.

---

# 5. Kiến trúc fix mục tiêu

Nguyên tắc quan trọng:

> **Backend chọn model cuối cùng thì backend cũng phải chịu trách nhiệm đảm bảo generationConfig tương thích với model cuối cùng.**

Không để:

```text
client tạo config cho model A
-> server fallback model B
-> server forward config của A sang B
```

Mục tiêu:

```text
Flutter Voice
  |
  | model intent + bounded contents + generic generation intent
  v
NabiAiBackendClient
  |
  v
nabi-ai-generate
  |
  +--> resolve finalProviderModel()
  |
  +--> normalizeGenerationConfigForModel(finalProviderModel)
  |
  v
Gemini provider
```

---

# 6. PHASE 0 — Reproduce lỗi trước khi sửa

GPT LUNA phải tái hiện lỗi hiện tại trước khi code nếu có thiết bị/tài khoản phù hợp.

## 6.1. Baseline repo

```bash
cd ~/Desktop/Develop/NanoBioAI

git remote -v
git branch --show-current
git rev-parse HEAD
git status --short
```

Không xóa hoặc ghi đè thay đổi của developer.

Ghi baseline commit vào worklog.

---

## 6.2. Toolchain

```bash
flutter --version
dart --version
npx supabase --version
adb version
adb devices -l
```

Nếu không có `adb` hoặc không có physical device:

- vẫn được làm unit/static fix;
- nhưng task cuối cùng phải giữ trạng thái **DEVICE VERIFICATION PENDING**;
- không claim DONE.

---

## 6.3. Xác nhận thiết bị thật

Ưu tiên thiết bị từng dùng:

```text
Xiaomi 220333QPG
Android 11
```

Nếu dùng device khác, ghi:

```bash
adb -s <serial> shell getprop ro.product.manufacturer
adb -s <serial> shell getprop ro.product.model
adb -s <serial> shell getprop ro.build.version.release
adb -s <serial> shell getprop ro.build.version.sdk
```

**Emulator không được dùng làm acceptance cuối.**

---

## 6.4. Xác nhận paid access thật

Trên app:

1. login user thật;
2. chờ auth sync hoàn tất;
3. mở AI Chat;
4. nhấn icon mic;
5. phải vào `AiVoicePage`, không dừng ở Plus-required page.

Nếu bị Plus gate:

- kiểm tra Supabase membership/effective access;
- không bypass UI;
- không local mock;
- không sửa gate để “test cho tiện”.

Nếu access không hợp lệ: ghi blocker và xử lý membership test account ngoài phạm vi bugfix Voice.

---

## 6.5. Reproduce

Trên `AiVoicePage`:

1. nhấn **Bắt đầu**;
2. cho phép microphone nếu hệ điều hành hỏi;
3. nói một câu ngắn:
   - ví dụ “Nabi ơi, hôm nay tôi nên ngủ lúc mấy giờ?”
4. quan sát state:
   - Listening
   - transcript
   - Thinking
   - Speaking hoặc Error.

### Kỳ vọng lỗi hiện tại

Nếu root cause đã chẩn đoán đúng:

```text
Listening PASS
-> transcript PASS
-> Thinking
-> backend request
-> provider error
-> Voice session dừng
```

---

## 6.6. Capture evidence an toàn

Không log:

- transcript người dùng;
- prompt đầy đủ;
- health data;
- access token;
- Gemini key;
- Supabase session token.

Được log:

- traceId;
- stage;
- model requested;
- model selected;
- modelFallback bool;
- status code;
- safe error code;
- duration;
- response length;
- STT/TTS state.

Có thể dùng:

```bash
adb logcat -c
adb logcat
```

Filter theo tag/metadata của app nếu có.

Nếu dùng Supabase function logs, đối chiếu bằng `x-ai-trace-id`.

### Gate P0

Trước code cần có ít nhất một trong hai:

- device trace chứng minh Voice fail ở backend/provider; hoặc
- static reproduction/test chứng minh payload `gemini-2.5-flash + thinkingLevel` invalid theo provider contract.

Nếu physical account chưa available, static evidence đủ để bắt đầu coding nhưng **không đủ để DONE**.

---

# 7. PHASE 1 — Viết regression test trước fix

## 7.1. Test hiện tại đang encode bug

`voice_chat_turn_datasource_test.dart` hiện mong:

```json
"thinkingConfig": {
  "thinkingLevel": "MINIMAL"
}
```

Test này được viết theo transport direct cũ và không mô phỏng:

```text
client model 3.x
-> Edge fallback 2.5
-> config giữ thinkingLevel
```

Do đó test xanh nhưng production vẫn hỏng.

---

## 7.2. Regression test mới bắt buộc

### TC-VOICE-BACKEND-001

**Given**

- Voice gửi model không nằm trong server allowlist;
- Edge fallback về `gemini-2.5-flash`;
- incoming generation config có `thinkingLevel`.

**When**

- Edge build Gemini provider request.

**Then**

- provider request **không chứa `thinkingLevel`** cho Gemini 2.5;
- request vẫn giữ `maxOutputTokens=256`;
- request hợp lệ;
- model selected = `gemini-2.5-flash`.

---

### TC-VOICE-BACKEND-002

Khi final model thuộc family hỗ trợ `thinkingLevel`:

- config hợp lệ được giữ;
- không xóa bừa thinking setting hợp lệ.

Không hard-code assertion vào preview model nếu provider docs không đảm bảo stable.

---

### TC-VOICE-BACKEND-003

Edge fallback phải normalize **cả model + config**, không chỉ model.

---

### TC-VOICE-DATASOURCE-001

Voice datasource dùng model mặc định canonical đang được backend support.

Không giữ split:

```text
client default = 3.5
server default = 2.5
```

---

### TC-VOICE-ERROR-001

Provider 400 do request malformed:

- server log có safe code;
- client nhận user-safe lỗi;
- không lộ raw provider message.

---

### TC-VOICE-ACCESS-001

Free user vẫn bị gate.

Fix Voice backend **không được mở miễn phí ngoài business rule**.

---

# 8. PHASE 2 — Fix model/config compatibility

## 8.1. Quyết định canonical model

Tại baseline gần nhất, AI backend đã được live-smoke thành công với:

```text
gemini-2.5-flash
```

Do đó bugfix này ưu tiên **model đã có runtime evidence**, không tự chuyển sang model mới chỉ vì tên mới hơn.

GPT LUNA phải kiểm tra:

```bash
npx supabase secrets list --project-ref rnwohifdnylqfofkydfl
```

Chỉ kiểm tra **tên secret**, không in giá trị secret.

Xác minh:

```text
GEMINI_MODEL
GEMINI_ALLOWED_MODELS
```

Nếu remote đang cố ý dùng model khác và model đó đã được smoke PASS, cập nhật plan implementation theo evidence thực tế.

Nếu không có evidence mới, canonical bugfix model:

```text
gemini-2.5-flash
```

---

## 8.2. Fix Voice datasource

Mục tiêu:

- không default về model lệch server;
- không tự gửi provider-specific thinking option không tương thích với server fallback;
- giữ giới hạn input/history/response hiện tại;
- giữ system instruction hiện tại;
- giữ timeout 30 giây;
- giữ transport `NabiAiBackendClient`.

### Hướng mặc định

Trong:

```text
lib/app_versions/v1/features/ai_voice/data/datasources/voice_chat_turn_datasource.dart
```

Thực hiện:

1. align default model với canonical backend model;
2. bỏ `thinkingLevel: MINIMAL` khỏi Voice request **nếu final production model là Gemini 2.5**;
3. không thêm sampling fields nếu không cần;
4. không đổi bounds hiện tại trừ khi test chứng minh phải đổi.

Cấu hình tối thiểu an toàn cho Voice 2.5:

```text
maxOutputTokens = 256
no model-incompatible thinkingLevel
```

Nếu muốn điều khiển thinking ở Gemini 2.5, chỉ dùng contract được provider hỗ trợ và phải có test. Không bắt buộc task này phải bật thinking.

Voice ưu tiên:

- latency;
- ổn định;
- response ngắn để TTS;
- không cần reasoning budget phức tạp cho mỗi turn.

---

## 8.3. Hardening bắt buộc ở Edge Function

Chỉ sửa Flutter là chưa đủ.

Trong:

```text
supabase/functions/nabi-ai-generate/index.ts
```

sau khi resolve:

```ts
const model = allowedModels.has(input.model)
  ? input.model
  : defaultModel;
```

phải có bước tương đương:

```text
const generationConfig =
  normalizeGenerationConfigForModel(model, input.generationConfig);
```

### Contract

Nếu final model khác requested model:

- mọi field model-dependent phải được revalidate;
- không forward blind config.

### Gemini 2.5

Không gửi:

```text
thinkingConfig.thinkingLevel
```

Nếu incoming config chứa field này:

- strip an toàn; hoặc
- map sang contract tương thích chỉ khi mapping là rõ ràng và được test.

**Ưu tiên strip thay vì suy diễn semantics.**

### Gemini generation khác

Không xóa generic field:

```text
maxOutputTokens
temperature
topP
responseMimeType
candidateCount
```

nếu field đó hợp lệ với model/provider.

---

## 8.4. Không biến Edge thành parser quá rộng

Normalization chỉ xử lý fields cần để giải quyết compatibility bug.

Không:

- viết hệ thống schema engine lớn;
- thêm dozens of model-specific rules không có test;
- refactor toàn bộ AI backend.

Patch phải nhỏ và chứng minh được.

---

# 9. PHASE 3 — Đồng bộ model configuration

## 9.1. `.env.example`

Hiện đang ghi:

```text
GEMINI_MODEL=gemini-3.5-flash
```

Trong khi Edge default/runtime verified gần nhất là:

```text
gemini-2.5-flash
```

Sau khi chốt canonical model:

- cập nhật `.env.example`;
- có thể thêm `GEMINI_CHAT_MODEL` nếu thật sự cần tách chat/voice;
- không thêm API key thật.

---

## 9.2. Source-truth validator

Nếu:

```text
tools/validate_docs_source_truth.py
```

đang assert model cũ trong Voice source, cập nhật assertion theo contract mới.

Validator phải kiểm tra kiến trúc, không khóa cứng một model lỗi thời nếu không cần thiết.

---

## 9.3. Server secrets

Nếu cần đổi model remote:

```bash
read -rp "GEMINI_MODEL: " GEMINI_MODEL
```

Không cần hidden cho model name vì không secret.

Với allowlist:

```text
GEMINI_ALLOWED_MODELS
```

chỉ chứa model đã được provider smoke-test.

Không đưa `GEMINI_API_KEY` vào:

- Git;
- `.env.example`;
- Flutter asset;
- Dart source;
- Gradle BuildConfig;
- APK;
- worklog.

---

# 10. PHASE 4 — Backend validation trước device

## 10.1. Deno tests

Chạy test Edge Function:

```bash
deno test supabase/functions/nabi-ai-generate/handler_test.ts
```

Nếu repo có thêm test file trực tiếp cho index/provider adapter, chạy cả file đó.

---

## 10.2. Voice tests

```bash
flutter test test/app_versions/v1/features/ai_voice/
```

Bắt buộc PASS:

- datasource;
- repository;
- controller;
- page;
- access gate;
- device gateway fakes.

---

## 10.3. AI backend contract

```bash
flutter test test/services/ai/nabi_ai_backend_client_contract_test.dart
```

Nếu file path đã đổi, tìm bằng:

```bash
rg --files test | rg 'nabi_ai_backend|ai_backend'
```

---

## 10.4. Targeted analyze

```bash
flutter analyze \
  lib/app_versions/v1/features/ai_voice \
  lib/app_versions/v1/services/ai/nabi_ai_backend_client.dart \
  lib/app_versions/v1/services/ai/gemini_rest_client.dart
```

Không chạy repo-wide trước targeted checks.

---

## 10.5. Format

```bash
dart format \
  lib/app_versions/v1/features/ai_voice \
  lib/app_versions/v1/services/ai
```

Chỉ format file touched nếu có thể.

---

# 11. PHASE 5 — Deploy Edge Function

Chỉ deploy sau:

- Deno test PASS;
- Flutter targeted tests PASS;
- analyze PASS;
- diff review sạch.

## 11.1. Link đúng project

```bash
npx supabase link --project-ref rnwohifdnylqfofkydfl
```

---

## 11.2. Deploy

Giữ contract hiện tại cho guest AI:

```bash
npx supabase functions deploy nabi-ai-generate \
  --project-ref rnwohifdnylqfofkydfl \
  --no-verify-jwt \
  --use-api
```

Không tự bật JWT gateway nếu điều đó làm hỏng guest onboarding AI.

---

## 11.3. Safe backend smoke

Gửi request không chứa dữ liệu sức khỏe thật.

Ví dụ nội dung:

```text
"Tra loi dung mot tu: OK"
```

Bắt buộc:

- HTTP 200;
- response text non-empty;
- trace ID có;
- model selected đúng;
- không còn provider 400 do thinking config.

---

## 11.4. Voice-shaped smoke

Ngoài generic smoke, gửi request có shape tương đương Voice:

- system instruction;
- one user message;
- `maxOutputTokens=256`;
- generation config sau fix.

Bắt buộc HTTP 200.

Đây là test quan trọng vì generic plan request PASS **không tự động chứng minh Voice payload PASS**.

---

# 12. PHASE 6 — Build Android

```bash
flutter build apk --debug
```

Bắt buộc PASS.

Sau build, không cần scan toàn binary nếu không có security change ngoài model config, nhưng phải xác nhận provider key không quay lại client.

Có thể kiểm tra source:

```bash
rg -n "GEMINI_API_KEY" lib android assets
```

Không được xuất giá trị key.

---

# 13. PHASE 7 — PHYSICAL DEVICE ACCEPTANCE — BẮT BUỘC

## 13.1. Quy tắc

**Không được đánh dấu task DONE nếu chưa chạy phase này.**

Emulator:

```text
không thay thế physical device
```

Widget/unit tests:

```text
không thay thế physical device
```

Backend curl:

```text
không thay thế physical device
```

---

## 13.2. Cài app

Liệt kê device:

```bash
adb devices -l
```

Build/install:

```bash
flutter run -d <PHYSICAL_DEVICE_ID>
```

hoặc:

```bash
adb -s <PHYSICAL_DEVICE_ID> install -r \
  build/app/outputs/flutter-apk/app-debug.apk
```

---

## 13.3. Permission test

### Case A — first grant

1. reset app permission nếu cần;
2. mở Voice;
3. nhấn Bắt đầu;
4. Android hiện mic permission;
5. chọn Allow.

Bắt buộc:

- app không crash;
- state chuyển Listening;
- recognizer hoạt động.

### Case B — deny

1. deny RECORD_AUDIO;
2. nhấn Bắt đầu.

Bắt buộc:

- không crash;
- UI hiển thị Nabitone permission error;
- session dừng sạch.

### Case C — grant lại

Bật permission trong Android Settings rồi quay app.

Bắt buộc:

- Start hoạt động lại mà không cần reinstall.

---

# 14. Voice E2E matrix trên máy thật

## DEV-VOICE-01 — một lượt cơ bản

Nói một câu tiếng Việt ngắn.

PASS khi:

```text
Listening
-> transcript xuất hiện
-> Thinking
-> AI response xuất hiện
-> TTS đọc response
-> quay lại Listening
```

Không PASS nếu chỉ transcript hiện mà không có AI/TTS.

---

## DEV-VOICE-02 — 10 lượt liên tục

Thực hiện tối thiểu **10 turn**.

Bắt buộc:

- không `concurrent startListening`;
- không deadlock;
- không mic giữ vĩnh viễn;
- không duplicate AI request;
- không duplicate TTS;
- history RAM hoạt động;
- session không tự dừng do transport bug.

---

## DEV-VOICE-03 — reaction speed

Test đủ:

```text
200 ms
500 ms
1000 ms
2000 ms
```

Bắt buộc:

- 200 ms không đóng mic trước khi user bắt đầu nói;
- selector khóa khi session active;
- Stop/Start giữ behavior đúng;
- không regression delayed-arm.

---

## DEV-VOICE-04 — Stop khi Listening

Nhấn Stop trong Listening.

PASS:

- mic dừng;
- state về Idle;
- không tự restart.

---

## DEV-VOICE-05 — Stop khi Thinking

Sau khi nói xong, khi AI đang Thinking, nhấn Stop.

PASS:

- late backend response bị generation guard bỏ;
- không phát TTS sau Stop;
- không restart mic.

---

## DEV-VOICE-06 — Stop khi Speaking

Khi TTS đang đọc, nhấn Stop.

PASS:

- TTS dừng;
- mic không mở lại;
- state Idle.

---

## DEV-VOICE-07 — background/resume

Trong session:

1. Home app;
2. chờ;
3. quay lại.

PASS:

- session cũ đã stop;
- không có microphone zombie;
- user có thể Start session mới.

---

## DEV-VOICE-08 — mất mạng

1. bắt đầu Voice;
2. nói câu;
3. tắt Wi-Fi/mobile data trước AI response.

PASS:

- app không crash;
- hiện lỗi an toàn;
- session stop sạch.

Bật mạng lại và Start mới.

PASS:

- Voice recover mà không reinstall.

---

## DEV-VOICE-09 — backend/provider failure

Nếu có sandbox/staging cách inject provider 5xx:

- UI nhận lỗi an toàn;
- không raw provider error;
- không transcript trong logs.

Không cố tình phá production secret.

---

## DEV-VOICE-10 — TTS tiếng Việt

Xác nhận trên device:

- `vi-VN` available;
- response được đọc;
- không mở STT trước khi speech hoàn tất;
- không audio overlap.

Nếu device không có Vietnamese TTS:

- ghi device/environment blocker;
- test device khác hoặc cài voice data;
- không sửa app thành language khác chỉ để pass.

---

## DEV-VOICE-11 — paid gate

Test bằng user Free:

- Voice page thật không được mount;
- mic không được mở;
- màn Plus hiện đúng.

Test bằng user Plus:

- Voice được mount;
- E2E hoạt động.

Điều này đảm bảo bugfix không phá entitlement.

---

# 15. Log acceptance trên máy thật

Trong physical-device test, evidence cần lưu:

```text
device manufacturer/model
Android version/API
app build/commit
auth mode: authenticated
access class: paid (không lưu user id nếu không cần)
Voice phases
AI trace id
backend status
provider selected model
model fallback bool
durations
STT/TTS terminal state
test case PASS/FAIL
```

Không lưu:

```text
email
user id đầy đủ
access token
refresh token
Gemini key
actual transcript
AI health response
personal health data
```

---

# 16. Nếu lỗi vẫn tồn tại sau model/config fix

Không đoán. Dùng decision tree:

## 16.1. Không vào được Voice page

Kiểm tra:

```text
authGuard
effectiveAccessProvider
currentAuthUserIdProvider
paid membership backend
```

Không sửa STT.

---

## 16.2. Nhấn Start nhưng không Listening

Kiểm tra:

```text
RECORD_AUDIO
SpeechToText.initialize
recognition service
vi_VN locale
status callbacks
```

Đây mới là STT/device issue.

---

## 16.3. Listening nhưng transcript rỗng

Kiểm tra:

- speech service;
- locale;
- mic routing;
- Android speech recognizer;
- delayed endpointing.

Không sửa backend trước.

---

## 16.4. Transcript có, Thinking rồi Error

Kiểm tra:

```text
AI_BACKEND trace
Edge logs
model requested
model selected
generation config normalized
HTTP status
```

Đây là nhánh root cause hiện tại.

---

## 16.5. AI response có nhưng không nghe tiếng

Kiểm tra:

```text
FlutterTTS
vi-VN availability
awaitSpeakCompletion
audio volume
device TTS engine
```

Không sửa STT.

---

## 16.6. Một turn được, turn 2 fail

Kiểm tra:

```text
native done/notListening
_activeListen
_nativeSessionPending
generation token
TTS completion
300ms delay
```

Không rollback toàn transport.

---

# 17. Automated regression matrix bắt buộc

| Nhóm | Yêu cầu |
|---|---|
| Access gate | Free blocked, Plus allowed, wrong user blocked |
| STT init | permission, unavailable, status start |
| STT endpointing | 200/500/1000/2000 delayed-arm |
| STT lifecycle | stop/cancel/terminal timeout/no concurrent start |
| Voice controller | listening -> thinking -> speaking -> listening |
| Voice controller | Stop ở từng phase |
| Voice repository | bounded history, reset session |
| Voice datasource | bounded message/history/response |
| Voice model | canonical model resolve |
| Voice config | 2.5 request không chứa thinkingLevel |
| Edge fallback | fallback model + config normalize cùng nhau |
| Edge errors | 400/429/5xx safe mapping |
| Backend client | function invocation contract |
| Security | no provider key in client |
| Build | Android debug APK PASS |

---

# 18. Không được sửa trong task

Trừ khi trở thành blocker trực tiếp:

- Splash.
- Onboarding UI.
- Dashboard.
- Meal catalog.
- Health score.
- Google Play billing.
- FamilyPlus UX.
- Sleep Safety.
- Admin.
- Sale/referral.
- Gradle/AGP warnings không liên quan.
- toàn bộ Nabi animation system.
- toàn bộ Gemini SDK architecture.
- Gemini Live.

Nếu thấy bug khác, ghi riêng.

---

# 19. Docs/worklog sau fix

Nếu implementation được user duyệt và thực thi, tạo/cập nhật:

```text
docs/fixbug/ai-voice-sequential/
```

Khuyến nghị thêm file mới:

```text
002-fixbug-ai-voice-backend-model-config-regression.md
```

Không rewrite lịch sử file `001` như thể bug cũ chưa từng PASS.

Tạo worklog ngày thực thi:

```text
docs/worklog/2026-08-30/<next>-worklog-ai-voice-backend-regression.md
```

Worklog phải có:

- baseline;
- reproduction;
- root cause;
- exact files changed;
- tests;
- Edge deploy evidence;
- physical device evidence;
- PASS/FAIL;
- blocker còn lại;
- self-review.

Sau đó:

```bash
powershell -ExecutionPolicy Bypass \
  -File .codex/tools/update_worklog_learning.ps1
```

Nếu Linux có `pwsh`:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass \
  -File .codex/tools/update_worklog_learning.ps1
```

Hoặc dùng Python refresh command canonical nếu repo hỗ trợ.

Không chỉnh tay generated task-skill/history nếu script chạy được.

---

# 20. Definition of Done

GPT LUNA chỉ được ghi **DONE** khi tất cả điều kiện dưới đây PASS.

## Code

- [ ] Voice model/config contract đã thống nhất.
- [ ] Edge fallback không tạo invalid generation config.
- [ ] Không còn split-brain model gây lỗi Voice.
- [ ] Không đưa Gemini API key về client.
- [ ] Không bypass paid gate.
- [ ] Không regression STT lifecycle.

## Tests

- [ ] Voice datasource tests PASS.
- [ ] Voice controller tests PASS.
- [ ] Voice device gateway tests PASS.
- [ ] Voice page/access tests PASS.
- [ ] Backend client contract tests PASS.
- [ ] Deno handler/provider tests PASS.
- [ ] New cross-contract fallback test PASS.
- [ ] Targeted analyze PASS.
- [ ] Android debug build PASS.

## Backend

- [ ] `nabi-ai-generate` deploy đúng project.
- [ ] generic safe smoke HTTP 200.
- [ ] Voice-shaped backend smoke HTTP 200.
- [ ] no provider 400 do thinking config.
- [ ] safe trace logging hoạt động.

## Physical device — mandatory

- [ ] Physical Android device được ADB xác nhận.
- [ ] Real Plus/FamilyPlus access được backend xác nhận.
- [ ] Mic permission flow PASS.
- [ ] Vietnamese STT PASS.
- [ ] transcript -> backend -> response PASS.
- [ ] Vietnamese TTS PASS.
- [ ] quay lại Listening PASS.
- [ ] 10 sequential turns PASS.
- [ ] 4 reaction speeds PASS.
- [ ] Stop Listening PASS.
- [ ] Stop Thinking PASS.
- [ ] Stop Speaking PASS.
- [ ] Background/resume PASS.
- [ ] Network failure/recovery PASS.
- [ ] không `concurrent startListening`.
- [ ] không crash/ANR.
- [ ] logs không lộ dữ liệu riêng tư/secret.

Nếu bất kỳ mục physical-device nào chưa chạy:

```text
STATUS = PARTIAL / DEVICE VERIFICATION PENDING
```

Không được ghi:

```text
DONE
100%
PRODUCTION VERIFIED
```

---

# 21. Rollback strategy

Nếu Edge deploy mới làm hỏng AI khác:

1. giữ commit SHA trước deploy;
2. rollback Edge source về revision trước;
3. redeploy `nabi-ai-generate`;
4. chạy generic AI smoke;
5. ghi incident trong worklog.

Nếu Flutter Voice fix gây regression:

1. rollback chỉ các file Voice/config liên quan;
2. không rollback những fix AI onboarding ngày 30/08;
3. không rollback meal catalog merge/upsert;
4. không rollback secret-hardening.

---

# 22. Output cuối cùng GPT LUNA phải trả cho người dùng

Sau khi thực thi, GPT LUNA phải báo theo format ngắn:

```text
Root cause:
- ...

Files changed:
- ...

Automated validation:
- ...

Backend deploy:
- ...

Physical-device test:
- Device:
- Android:
- Plus access:
- STT:
- AI backend:
- TTS:
- Multi-turn:
- Stop/background:
- Result:

Remaining blockers:
- ...

Final status:
PASS / PARTIAL / FAIL
```

Không ghi “PASS” nếu thiếu physical-device acceptance.

---

# 23. Chỉ dẫn thực thi dành riêng cho GPT LUNA

1. Đọc context theo Section 4 trước code.
2. Reproduce / xác minh root cause trước patch.
3. Không sửa old STT fix nếu không có device evidence.
4. Viết cross-contract regression test cho **Edge model fallback + generation config**.
5. Fix ở đúng layer:
   - Flutter Voice: không gửi config phụ thuộc model sai.
   - Edge: final model phải đi cùng final compatible config.
6. Chọn model có runtime evidence, không chạy theo model name mới.
7. Không khôi phục Gemini key về APK.
8. Không bypass Plus gate.
9. Deploy chỉ sau tests.
10. Bắt buộc chạy Voice-shaped backend smoke.
11. Bắt buộc chạy Android physical-device E2E.
12. Test tối thiểu 10 turn.
13. Chỉ DONE khi device PASS.
14. Sau code, tạo worklog/history theo repo workflow.
15. Khi gửi deliverable coding cho người dùng, zip **chỉ file mới/file sửa**, giữ nguyên cấu trúc project, không kèm patch/review file.

---

# 24. Kết luận ngắn

Lỗi hiện tại không còn giống lỗi mic ngày 23/08.

**Root cause trọng tâm hiện tại là compatibility regression sau khi Voice chuyển từ Gemini direct sang `NabiAiBackendClient`: client vẫn gửi model/thinking config theo contract cũ, còn Edge có thể fallback sang `gemini-2.5-flash` nhưng không normalize generation config theo model cuối cùng.**

Cùng lúc, test device gần nhất đang guest/free nên phải đăng nhập **paid account thật** mới có thể nghiệm thu Voice runtime.

Hướng sửa đúng là:

```text
không bypass access
không sửa mic mù quáng
không khôi phục Gemini Live
không đưa key vào client

=> thống nhất model
=> normalize config theo final model tại backend
=> thêm cross-contract regression
=> deploy
=> test Voice-shaped HTTP
=> test 10 turn trên Android thật
```
