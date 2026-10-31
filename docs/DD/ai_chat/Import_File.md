# Import File — AI_CHAT / AI Chat

> Runtime update 2026-10-30: AI calls use `BackendAiTextClient` and the
> authenticated NanoBio API. The setup gate, `llamadart`, and local text/vision
> inference were removed. Voice capture/speech recognition/TTS remain on-device;
> generated replies use the backend. Older design assumptions in narrative
> sections are historical; the dependency, API and configuration tables below
> describe the current runtime contract.

## 0. Dependency Rules

1. Presentation -> Provider/Controller -> Use case/Service -> Repository -> Datasource/API/DAO.
2. Presentation must not import SQLite DAO, Supabase raw client, or payment/referral backend directly.
3. Domain/use-case code must not import UI widgets or BuildContext.
4. Shared utilities must not contain module-specific business logic.
5. Secrets, service-role keys, payment evidence, and raw health data must not be hard-coded or committed.

## 1. Package / External Dependency Registry

| ID | Package / Service | Version / Plan | Source | Purpose | Owner | Security Note |
|---|---|---|---|---|---|---|
| AI_CHAT-DEP01 | NanoBio self-hosted backend | Current runtime API | `lib/core/network/backend_api_client.dart` | Authenticated AI generation, streaming, Food Scan, entitlement/quota services | Backend/Tech Lead | No service credential or HTTP fallback in Flutter. |
| AI_CHAT-DEP02 | Flutter/Riverpod/GoRouter | Existing stack | .codex/AGENTS.md | Presentation, state, navigation | App team | Keep layer boundaries. |
| AI_CHAT-DEP03 | `speech_to_text` | 7.4.0 | Existing `pubspec.lock` | Nhận dạng từng câu; hard cap `listenFor` 180.000 ms; `changePauseFor` 200/500/1.000/2.000 ms sau partial non-empty đầu tiên | App team | Không dùng làm continuous always-on recorder; OS có thể final/stop trước hard cap; threshold không phải Gemini latency. |
| AI_CHAT-DEP04 | `flutter_tts` | 4.2.5 | Existing `pubspec.lock` | TTS tiếng Việt với completion await | App team | Mic phải tắt trong khi TTS phát. |
| AI_CHAT-DEP05 | `AiTextClient` / `BackendAiTextClient` | NanoBio self-hosted API | `lib/app_versions/v1/services/ai/ai_text_client.dart`, `lib/core/network/backend_ai_text_client.dart` | Gọi text, JSON, stream và vision AI qua backend có xác thực | App/Backend team | Không gửi yêu cầu ẩn danh; không fallback sang model local. |
| AI_CHAT-DEP06 | `BackendApiClient` | Existing API client | `lib/core/network/backend_api_client.dart` | Session, HTTPS transport, refresh, timeout and response mapping | Backend team | Không dùng HTTP fallback. |

## 2. File Map and Internal Contract

| File Path | Layer | Responsibility | Allowed Imports | Forbidden Imports | Public Export | Feature / Function |
|---|---|---|---|---|---|---|
| planned:lib/app_versions/v2/features/ai_chat/presentation/ | Presentation | Render views and dispatch user actions | Providers, view models, theme tokens, router | DAO, raw Supabase/payment clients, storage models | Screens/widgets | AI_CHAT-Vxx |
| planned:lib/app_versions/v2/features/ai_chat/application/ | Use case / Service | Orchestrate validation, authorization, business rules | Domain entities, repository interfaces, policies | Widgets, BuildContext, raw SQL/API client | execute(command, actorContext) | AI_CHAT-FNxx |
| planned:lib/app_versions/v2/features/ai_chat/domain/ | Domain | Entity and policy contracts | Pure Dart/value objects | UI, persistence implementation | Entities/policies | AI_CHAT-E-* |
| planned:lib/app_versions/v2/features/ai_chat/data/ | Repository/Datasource | Persist/integrate with local/trusted backend | Datasource/API/DAO contracts, mappers | UI widgets/controllers | Repository implementation | AI_CHAT-FNxx |
| planned:test/ | Test | Unit/integration/widget tests | Public contracts and fakes at correct layer | Production secrets or real payment/webhook payloads | Test fixtures | AI_CHAT-TCxx |
| `lib/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_access_gate.dart` | Presentation | Auth + exact-user paid gate; không mount page/controller khi fail | Access providers, router, theme | STT/TTS/datasource trực tiếp | `AiVoiceAccessGate` | AI_CHAT-F03/V03 |
| `lib/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_page.dart` | Presentation | UI Voice tối giản + dropdown reaction speed | Controller/provider, theme, router | Supabase/Gemini/STT/TTS implementation | `AiVoicePage` | AI_CHAT-V03 |
| `lib/app_versions/v1/features/ai_voice/presentation/controllers/ai_voice_controller.dart` | Controller | Sequential state machine + lifecycle generation guard + RAM reaction-speed selection | Repository + STT/TTS gateway contracts | Raw Supabase/Gemini client | Controller API | AI_CHAT-FN03 |
| `lib/app_versions/v1/features/ai_voice/domain/repositories/ai_voice_repository.dart` | Domain | Turn/reset contract | Pure domain entities | Flutter widgets/API client | Repository interface | AI_CHAT-FN03 |
| `lib/app_versions/v1/features/ai_voice/data/repositories/ai_voice_repository_impl.dart` | Repository | Bounded 12-message RAM history; user/history item tối đa 6.000 ký tự | Datasource + domain contract | UI/controller | Repository impl | AI_CHAT-FN03 |
| `lib/app_versions/v1/features/ai_voice/data/datasources/voice_chat_turn_datasource.dart` | Datasource | Gọi backend qua `BackendAiTextClient`, validate/map result/errors/timeout; response tối đa 2.000 ký tự | Shared AI contract + backend client | UI/TTS/STT | Datasource | AI_CHAT-API03 |
| `lib/app_versions/v1/features/ai_voice/data/gateways/speech_to_text_gateway.dart` | Device gateway | One-shot recognition; 180.000 ms hard cap; delayed-arm selected silence threshold after first non-empty partial | `speech_to_text` | Gemini/Supabase | STT gateway | AI_CHAT-FN03 |
| `lib/app_versions/v1/features/ai_voice/data/gateways/flutter_tts_gateway.dart` | Device gateway | Await Vietnamese speech completion | `flutter_tts` | Gemini/Supabase | TTS gateway | AI_CHAT-FN03 |
| `test/app_versions/v1/features/ai_voice/` | Test | Controller/repository/gate/route/plugin/datasource/reaction-speed/listen-duration contracts with fakes | Public contracts | Real Gemini/key/transcript fixtures | Test suites | AI_CHAT-TC03..TC18 |

## 3. API / Datasource Dependencies

| ID | API / Datasource | Method / Event | Request | Response | Used By |
|---|---|---|---|---|---|
| AI_CHAT-API01 | `POST /api/v1/ai/generate` | Authenticated NanoBio backend | Bounded `messages`, `system_instruction`, response format/schema and generation limits | Sanitized text/JSON response or typed backend error | AI_CHAT-FN01/FN02 |
| AI_CHAT-API02 | `POST /api/v1/ai/generate/stream` | Authenticated NanoBio backend | Bounded messages and generation limits | Server-streamed text deltas, completion or typed backend error | AI_CHAT-FN03 |
| AI_CHAT-API03 | `BackendAiTextClient.generateText` with one image attachment | `POST /api/v1/food/scan/analyze` | Authenticated sanitized image bytes, MIME type, prompt and minimum analysis context | Backend vision result or typed auth/quota/membership/network/model error; no local vision fallback | AI_CHAT-FN04 |
| AI_CHAT-API-AUDIT | Audit/event integration | Event after successful sensitive write | correlation_id, actor_id, action, entity_ref, reason, idempotency_key | audit_id, recorded_at, immutable action summary | Functions with side effects |

## 4. Entity / Model Dependencies

| Entity / Model | Intended File | Source | Used At |
|---|---|---|---|
| AI_CHAT-E-ai_request | planned:lib/app_versions/v2/features/ai_chat/domain/ | AI Request | Features/functions/views in this module |
| AI_CHAT-E-chat_message | planned:lib/app_versions/v2/features/ai_chat/domain/ | Chat Message | Features/functions/views in this module |
| AI_CHAT-E-voice_session | Voice repository RAM state | Runtime memory only | AI_CHAT-F03/FN03/V03; never persisted |

## 5. Constants, Config and Feature Flags

| ID | Name | Source | Default | Who Can Change | Used By |
|---|---|---|---|---|---|
| AI_CHAT-CFG01 | Module enablement / rollout flag | Planned remote config or backend config | Disabled until release enabled; DD docs approved | Product Owner / Tech Lead | All features |
| AI_CHAT-CFG02 | Module-specific thresholds or policy | System Configuration entity or Admin managed policy version | Versioned default from accepted DD decisions; disabled only when feature flag is off | Super Admin/Admin role allowed by M16 with audit | Business rules |
| AI_CHAT-CFG03 | Text/vision model selection | NanoBio backend configuration | Server selects the configured Ollama model; Flutter does not download or select a text/vision model | Backend operator | AI_CHAT-API03/04 |
| AI_CHAT-CFG04 | Model context and tokenizer | NanoBio backend runtime | Server owns model/tokenizer context; Flutter sends bounded requests and handles typed size/context errors | Backend operator | AI_CHAT-API03/04 |
| AI_CHAT-CFG05 | Voice reaction speed | `AiVoiceState` RAM | Bình thường 1.000 ms; choices 200/500/1.000/2.000 ms | Plus/FamilyPlus user khi session đã dừng | AI_CHAT-FN03/V03; không SQLite/Supabase/env |

## 6. Documented Dependency Requirements

| ID | Requirement | DD docs status | Implementation evidence |
|---|---|---|---|
| AI_CHAT-IMP-EV01 | File map is updated when code is implemented. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-IMP-EV02 | No reverse layer imports. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-IMP-EV03 | No secrets or production payloads in source/tests/docs. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-IMP-EV04 | API/schema/RLS contracts are documented before coding. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-IMP-EV05 | Tests cover permission, business rule, duplicate/retry, and dependency failure. | Documented | Required in implementation/test phase; not executed in this DD docs pass |
| AI_CHAT-IMP-EV06 | Voice path follows Presentation -> Controller -> Repository -> Datasource -> authenticated NanoBio backend AI; platform STT and TTS remain on-device. | Implemented | Backend client tests and release APK signature/build PASS; live HTTPS/device AI acceptance is pending because port 443 is unreachable |
| AI_CHAT-IMP-EV07 | Old Gemini Live protocol/gateway/custom PCM/native channel/token path has no remaining runtime reference. | Documented | Baseline cleanup/static scan PASS |
| AI_CHAT-IMP-EV08 | `RECORD_AUDIO`, speech-recognition/TTS declarations and iOS usage strings remain; Live-only audio permissions are removed only after reference scan. | Documented | Android reaction-speed build/device PASS; iOS pending |
| AI_CHAT-IMP-EV09 | Reaction-speed mapping/default/RAM lifecycle, dropdown lock while active, delayed arm after first non-empty partial and final-result behavior are tested. | Documented | PASS — expanded 86/86 tests + Android device smoke |
