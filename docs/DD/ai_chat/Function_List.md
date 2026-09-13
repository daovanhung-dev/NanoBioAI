# Function List — AI_CHAT / AI Chat

## 0. Layer Convention

`	ext
View / Presentation
  -> Provider / Controller / API handler
  -> Use case / Service
  -> Repository
  -> Datasource / DAO / API client
  -> Database / External service
`

- Presentation must not call DAO/API/database directly.
- Business rules stay in use case/service or trusted backend policy.
- Financial, quota, family, Sale, and Admin writes require idempotency and audit.

## 1. Function Registry

| ID | Function / Use Case | Feature | Layer | Planned File | Trigger | Input | Output | Side Effect | Status |
|---|---|---|---|---|---|---|---|---|---|
| AI_CHAT-FN01 | openAiChatWithEntitlement | AI_CHAT-F01 | Use case / Service | planned:lib/app_versions/v2/features/ai_chat/application/ai_chat_fn01.dart | Mở AI Chat | Command + actor context | Result/Error | Audit/event when required | Approved - DD docs complete |
| AI_CHAT-FN02 | sendAiChatQuestion | AI_CHAT-F02 | Use case / Service | planned:lib/app_versions/v2/features/ai_chat/application/ai_chat_fn02.dart | Submit chat question | Command + actor context | Result/Error | Audit/event when required | Approved - DD docs complete |
| AI_CHAT-FN03 | runSequentialVoiceConversation | AI_CHAT-F03 | Controller -> Repository -> Datasource -> GeminiRestClient | `lib/app_versions/v1/features/ai_voice/` | Chọn reaction speed, nhấn Bắt đầu / mỗi STT final, endpointing hoặc hard cap | Reaction-speed selection + 180.000 ms listen cap + transcript + bounded RAM history + AppEnv config | Voice state + safe text/error | RAM selection/history; STT/TTS lifecycle | Reaction-speed Android PASS; 3-minute source/test/build/install PASS, >60-second continuity pending; iOS pending |

---

<a id="ai_chat-fn01"></a>
# AI_CHAT-FN01 — openAiChatWithEntitlement

## A. Định danh và trách nhiệm

| Trường | Nội dung |
|---|---|
| Feature cha | AI_CHAT-F01 |
| Layer | Use case / Service, called by controller/provider/API handler |
| Loại thực thi | Sync for validation and state read; async/job only when BD requires background processing |
| File dự kiến | planned:lib/app_versions/v2/features/ai_chat/application/ai_chat_fn01.dart |
| Hàm export / endpoint | execute(command, actorContext) hoặc API contract tương ứng |
| Mục tiêu duy nhất | Chỉ actor có entitlement hợp lệ được vào chat. |
| Không chịu trách nhiệm | Không tự chốt product questions; không truy cập trực tiếp UI hoặc storage ngoài layer được phép. |
| Được gọi bởi | AI_CHAT-V01 hoặc event/API source trong BD M07 luồng, AC-03/AC-06 |
| Gọi tiếp | Repository/datasource/service planned trong Import_File.md |
| Rule áp dụng | AI_CHAT-BR01 |

## B. Hợp đồng input/output

| Field | Type | Required | Validation | Nguồn | Nhạy cảm | Ví dụ |
|---|---|---:|---|---|---:|---|
| actor_id | UUID/string | Y | Actor phải có quyền theo BD sections 3 và 5 | Auth/session context | Y | current user/admin |
| command | Object | Y | Schema theo feature và business rule | UI/API/event | Depends | module-specific request |
| correlation_id | String | Y for writes | Unique per request/job | UI/API/job | N | retry-safe key |

| Tình huống | Kiểu output / HTTP | Nội dung | Consumer xử lý |
|---|---|---|---|
| Thành công | Result / 200 hoặc 201 | Entity/view model cập nhật | Refresh UI hoặc phát event sau commit |
| Validation lỗi | Error / 400 | Field or business validation code | Hiển thị lỗi an toàn |
| Không quyền | 401/403 | AUTH_REQUIRED hoặc FORBIDDEN | Redirect/hide action and log when needed |
| Conflict | 409 | DUPLICATE_OR_INVALID_STATE | Refresh state and prevent double write |
| Lỗi hệ thống | 500/503 | Safe error + correlation id | Retry/support flow |

## C. Luồng xử lý chi tiết

1. Parse command và kiểm tra schema.
2. Xác thực actor, role, package entitlement, Sale/Admin scope nếu có.
3. Tải entity liên quan: @{Id=ai_request; Name=AI Request; Purpose=Theo dõi request chat; Attributes=request_id, user, status, quota impact; Relationships=Uses quota ledger}, @{Id=chat_message; Name=Chat Message; Purpose=Tin nhắn chat nếu lưu; Attributes=owner, role, content summary, created_at; Relationships=Subject to privacy policy}.
4. Áp dụng AI_CHAT-BR01 và các rule cross-module từ BD sections 14, 15.
5. Thực thi transaction/idempotency: Yes - write operations that affect quyền, tiền, điểm, quota, family scope, or audit must commit atomically.
6. Ghi audit nếu có tác động quyền, tiền, điểm, cấu hình, dữ liệu gia đình hoặc export.
7. Trả Result chuẩn hóa, không trả raw stack trace, raw payment evidence, secret, hoặc health PII không cần thiết.

## D. Transaction, side effect và độ tin cậy

| Nội dung | Quy định |
|---|---|
| Transaction boundary | Yes - write operations that affect quyền, tiền, điểm, quota, family scope, or audit must commit atomically. |
| Event/outbox | Phát event sau commit khi feature tạo quyền, quota, notification, point, report hoặc audit. |
| Retry | Retry theo correlation_id/request_id; retry không tạo bản ghi trùng. |
| Fallback / compensation | Khi dependency lỗi, giữ trạng thái hiện tại hoặc tạo adjustment/reversal theo BD nếu tài chính đã chốt. |
| Observability | Log an toàn gồm module, function ID, actor type, status, correlation id; không log secret/PII/raw payment. |

## E. Documented Function Test Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| AI_CHAT-FN-EV01-01 | Happy path cho AI_CHAT-FN01. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-FN-EV01-02 | Business rule violation cho AI_CHAT-BR01. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-FN-EV01-03 | Permission denied theo role/scope. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-FN-EV01-04 | Idempotency/retry nếu có ghi dữ liệu. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-FN-EV01-05 | Audit hoặc event được tạo khi BD yêu cầu. | Documented | Required in implementation/test phase; not executed in this DD docs pass |

---

<a id="ai_chat-fn02"></a>
# AI_CHAT-FN02 — sendAiChatQuestion

## A. Định danh và trách nhiệm

| Trường | Nội dung |
|---|---|
| Feature cha | AI_CHAT-F02 |
| Layer | Use case / Service, called by controller/provider/API handler |
| Loại thực thi | Sync for validation and state read; async/job only when BD requires background processing |
| File dự kiến | planned:lib/app_versions/v2/features/ai_chat/application/ai_chat_fn02.dart |
| Hàm export / endpoint | execute(command, actorContext) hoặc API contract tương ứng |
| Mục tiêu duy nhất | Gửi câu hỏi khi quota/rate policy cho phép. |
| Không chịu trách nhiệm | Không tự chốt product questions; không truy cập trực tiếp UI hoặc storage ngoài layer được phép. |
| Được gọi bởi | AI_CHAT-V02 hoặc event/API source trong BD M07 rules, AC-04 |
| Gọi tiếp | Repository/datasource/service planned trong Import_File.md |
| Rule áp dụng | AI_CHAT-BR02 |

## B. Hợp đồng input/output

| Field | Type | Required | Validation | Nguồn | Nhạy cảm | Ví dụ |
|---|---|---:|---|---|---:|---|
| actor_id | UUID/string | Y | Actor phải có quyền theo BD sections 3 và 5 | Auth/session context | Y | current user/admin |
| command | Object | Y | Schema theo feature và business rule | UI/API/event | Depends | module-specific request |
| correlation_id | String | Y for writes | Unique per request/job | UI/API/job | N | retry-safe key |

| Tình huống | Kiểu output / HTTP | Nội dung | Consumer xử lý |
|---|---|---|---|
| Thành công | Result / 200 hoặc 201 | Entity/view model cập nhật | Refresh UI hoặc phát event sau commit |
| Validation lỗi | Error / 400 | Field or business validation code | Hiển thị lỗi an toàn |
| Không quyền | 401/403 | AUTH_REQUIRED hoặc FORBIDDEN | Redirect/hide action and log when needed |
| Conflict | 409 | DUPLICATE_OR_INVALID_STATE | Refresh state and prevent double write |
| Lỗi hệ thống | 500/503 | Safe error + correlation id | Retry/support flow |

## C. Luồng xử lý chi tiết

1. Parse command và kiểm tra schema.
2. Xác thực actor, role, package entitlement, Sale/Admin scope nếu có.
3. Tải entity liên quan: @{Id=ai_request; Name=AI Request; Purpose=Theo dõi request chat; Attributes=request_id, user, status, quota impact; Relationships=Uses quota ledger}, @{Id=chat_message; Name=Chat Message; Purpose=Tin nhắn chat nếu lưu; Attributes=owner, role, content summary, created_at; Relationships=Subject to privacy policy}.
4. Áp dụng AI_CHAT-BR02 và các rule cross-module từ BD sections 14, 15.
5. Thực thi transaction/idempotency: Yes - write operations that affect quyền, tiền, điểm, quota, family scope, or audit must commit atomically.
6. Ghi audit nếu có tác động quyền, tiền, điểm, cấu hình, dữ liệu gia đình hoặc export.
7. Trả Result chuẩn hóa, không trả raw stack trace, raw payment evidence, secret, hoặc health PII không cần thiết.

## D. Transaction, side effect và độ tin cậy

| Nội dung | Quy định |
|---|---|
| Transaction boundary | Yes - write operations that affect quyền, tiền, điểm, quota, family scope, or audit must commit atomically. |
| Event/outbox | Phát event sau commit khi feature tạo quyền, quota, notification, point, report hoặc audit. |
| Retry | Retry theo correlation_id/request_id; retry không tạo bản ghi trùng. |
| Fallback / compensation | Khi dependency lỗi, giữ trạng thái hiện tại hoặc tạo adjustment/reversal theo BD nếu tài chính đã chốt. |
| Observability | Log an toàn gồm module, function ID, actor type, status, correlation id; không log secret/PII/raw payment. |

## E. Documented Function Test Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| AI_CHAT-FN-EV02-01 | Happy path cho AI_CHAT-FN02. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-FN-EV02-02 | Business rule violation cho AI_CHAT-BR02. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-FN-EV02-03 | Permission denied theo role/scope. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-FN-EV02-04 | Idempotency/retry nếu có ghi dữ liệu. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-FN-EV02-05 | Audit hoặc event được tạo khi BD yêu cầu. | Documented | Required in implementation/test phase; not executed in this DD docs pass |

---

<a id="ai_chat-fn03"></a>
# AI_CHAT-FN03 — runSequentialVoiceConversation

## A. Định danh và trách nhiệm

| Trường | Nội dung |
|---|---|
| Feature cha | AI_CHAT-F03 |
| Layer | Presentation controller điều phối; repository sở hữu history RAM; datasource gọi `GeminiRestClient` trực tiếp. |
| File dự kiến | `lib/app_versions/v1/features/ai_voice/presentation/controllers/ai_voice_controller.dart`; `domain/repositories/ai_voice_repository.dart`; `data/repositories/ai_voice_repository_impl.dart`; `data/datasources/voice_chat_turn_datasource.dart` |
| Trigger | `setReactionSpeed()` khi session dừng; `start()` do người dùng gọi; mỗi STT final/endpointing timeout khi session còn active. |
| Mục tiêu duy nhất | Điều phối hội thoại half-duplex liên tục không chồng STT/TTS; gate non-paid trong app và gọi Gemini client-only theo rủi ro đã chấp nhận. |
| Không chịu trách nhiệm | Full-duplex, barge-in, custom PCM, Bluetooth, offline, persistence hoặc quota NanoBio. |
| Rule áp dụng | AI_CHAT-BR03..AI_CHAT-BR11 |

## B. Hợp đồng app input/output

| Input | Type | Validation / source |
|---|---|---|
| current user/access | Auth + `EffectiveAccess` | Exact user match, not anonymous, Plus/FamilyPlus; otherwise fail-closed before mount. |
| transcript | String | `trim`, non-empty, tối đa 6.000 ký tự trước API. |
| history | List of `{role,text}` | RAM only, role `user`/`model`, tối đa 12 item và 6.000 ký tự/item; repository trim sau mỗi successful pair. |
| reaction speed | Enum/value object | 200/500/1.000/2.000 ms; default 1.000 ms; chỉ cho đổi khi session không in-progress. |
| listen hard cap | Duration | 180.000 ms/3 phút mỗi lượt; final, endpointing, lifecycle hoặc platform recognizer được phép kết thúc sớm hơn. |
| operation generation | Integer/token | Tăng khi Start/Stop/background/dispose để callback cũ không đổi state. |

| Output | Nội dung |
|---|---|
| State | `idle`, `listening`, `thinking`, `speaking`, `error`/permission denied. |
| Success | Last transcript + last response tối đa 2.000 ký tự; history chỉ append đủ user/model pair sau response hợp lệ. |
| Failure | Typed/safe error; session dừng, STT/TTS tắt, không tự restart. |

## C. Luồng xử lý app

1. Khi session không in-progress, `setReactionSpeed()` cập nhật selection
   RAM. Selection giữ qua Stop/Start trong cùng controller/page; controller
   mới dùng default 1 giây.
2. `start()` tăng generation, dừng audio cũ, reset repository và khởi tạo STT/TTS.
3. Chuyển `listening`; recognizer nghe từng câu với `listenFor = 180.000 ms`
   và `pauseFor: null`. Gateway chỉ áp 200/500/1.000/2.000 ms sau partial
   non-empty đầu tiên.
4. Khi final hoặc endpointing timeout, dừng recognizer trước khi xử lý
   transcript. Mỗi result nhận dạng mới reset pause timer.
5. Nếu transcript rỗng và generation còn hợp lệ, quay lại listen mà không gọi API.
6. Nếu hợp lệ, chuyển `thinking` và gọi repository `sendTurn(message)`.
7. Repository gửi message + history hiện có qua datasource; datasource gọi
   `AI_CHAT-API03` trực tiếp bằng `GeminiRestClient`.
8. Response non-empty thành công mới append user/model pair, trim còn 12 item và
   trả text cho controller.
9. Controller kiểm tra generation, chuyển `speaking`, chờ TTS completion, đợi
   300 ms rồi mới listen lại.
10. Stop/background/dispose tăng generation trước, cancel STT, stop TTS, reset
   history, về idle và không xử lý late response.

## D. Luồng xử lý datasource client-only

1. Validate message/history trước khi gọi provider; user message và mỗi history
   item tối đa 6.000 ký tự, history tối đa 12 item.
2. Đọc `GEMINI_API_KEY` từ `AppEnv`; resolve model theo
   `GEMINI_CHAT_MODEL -> GEMINI_MODEL -> gemini-3.5-flash`.
3. Lắp `systemInstruction`, bounded contents và `generationConfig` với
   không truyền `maxOutputTokens`; gọi Gemini qua transport dùng chung.
4. Timeout turn sau 30 giây. 408/429/network/5xx thành lỗi tạm thời; key/auth/
   model/config thành unavailable; response rỗng hoặc quá 2.000 ký tự thành
   invalid response.
5. Chỉ log stage/status/error type an toàn; không log message, history, key,
   header/URL chứa key hoặc raw response.
6. Không có server kiểm tra paid access lại trước Gemini; app gate và key/APK
   exposure là rủi ro client-only được chấp nhận.

## E. Error mapping

| Failure/domain | Điều kiện | Controller behavior |
|---|---|---|
| Access fail-closed | Session/effective access không hợp lệ trước khi mount | Không mount Voice hoặc dừng session; hiển thị login/CTA phù hợp. |
| `invalid_request` | Message/history sai contract | Dừng session, copy lỗi an toàn. |
| `temporarily_unavailable` | 408/429/network/5xx/timeout | Dừng, yêu cầu thử lại sau. |
| `invalid_response` | Gemini response rỗng/không hợp lệ | Dừng, không append history. |
| `voice_unavailable` | Key/auth/model/config lỗi | Dừng, yêu cầu chủ động thử lại. |
| Device permission/TTS | STT/TTS failure | Cancel audio, dừng session, không mở micro lại. |

## F. Side effects và độ tin cậy

| Nội dung | Quy định |
|---|---|
| Persistence | None; không SQLite/Supabase table/RPC mới. |
| Quota | Không check/commit NanoBio quota; không tạo ledger/event Voice. |
| Retry | Không auto retry turn Gemini/TTS lỗi; người dùng chủ động Bắt đầu lại. |
| Concurrency | Một operation generation active; late completion không đổi state/history. |
| Reaction speed | Chỉ endpointing sau speech result; không phải Gemini/network latency. Dropdown và setter bị khóa khi session in-progress. |
| Listen duration/text bounds | 180.000 ms là hard cap phía app/plugin, không phải cam kết raw audio/recognizer luôn chạy đủ 3 phút. Final, endpointing và platform stop vẫn thắng. User/history item tối đa 6.000 ký tự; response tối đa 2.000 ký tự. |
| Secret / accepted risk | Key lấy từ `AppEnv`, không hard-code/commit/log nhưng hiện diện trong APK/runtime và có thể bị trích xuất. Paid gate chỉ ở Flutter. |

## G. Test requirements

- `AI_CHAT-TC04..TC08`: fake STT/repository/TTS chứng minh thứ tự, lifecycle,
  error và bounded history.
- `AI_CHAT-TC09..TC12`: Flutter plugin/datasource/static tests chứng minh STT
  null-return/native settle, Gemini request/config/timeout/error mapping, no
  sensitive log và không còn runtime `voice-chat-turn`.
- `AI_CHAT-TC13`: baseline Android build/multi-turn smoke đã PASS; giữ làm
  regression evidence.
- `AI_CHAT-TC14`: iOS build + real-device smoke vẫn pending.
- `AI_CHAT-TC15..TC17`: mapping/default/selection RAM, gateway delayed-arm/final
  contract và Android reaction-speed re-smoke PASS; iOS vẫn theo `AI_CHAT-TC14`.
- `AI_CHAT-TC18`: concrete gateway test cho `listenFor = 180.000 ms`, final/
  endpointing kết thúc sớm; input 3.000 ký tự accepted, 6.001 rejected và
  response >2.000 rejected. Source, expanded 90/90 tests, analyze 10 item/0
  issue, format 21 file/0 changed và Android build/install đã PASS;
  >60-second device continuity smoke vẫn pending.
