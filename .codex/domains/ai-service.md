# Domain - AI Service / Meal / Exercise / Chat

## Source

- Shared client: `lib/core/network/backend_ai_text_client.dart`
- Core contract and orchestration: `lib/app_versions/v1/services/ai/`
- Specialized callers: body metrics, nutrition, sleep, fitness, Nabi Care,
  AI Voice, and Food Scan.
- Tests: `test/core/network/backend_ai_text_client_test.dart`,
  `test/services/ai/`, and feature-specific AI tests.

## Runtime rules

- All generative text, JSON plans, streaming chat, health analysis, voice
  responses, and Food Scan vision go through `BackendAiTextClient` to the
  authenticated NanoBio API. The app does not load, download, or run a local
  text/vision model.
- AI requests require a backend session. Guests can use non-AI app features;
  their AI actions must ask them to sign in and must not send anonymous API
  requests.
- Never fall back to local model inference when the API is unavailable, times
  out, rejects quota/membership, or returns malformed output. Show a typed
  unavailable/auth/quota result and keep retry available.
- Client API base URL is configured with `API_BASE_URL`; the release target is
  `https://42.118.174.147`. Do not use HTTP as a fallback.
- Food Scan sends its sanitized JPEG and the minimum context required for the
  requested analysis over HTTPS. User consent copy must disclose this before
  analysis. Sleep analysis sends a sanitized metric summary, not recordings,
  transcripts, or contact numbers. Fitness prompts exclude names and birth
  dates. Update feature notices when payload scope changes.
- Nabi ESP keeps local audio capture, Whisper speech recognition, ESP32
  transport, and offline TTS. Only generated assistant replies use the backend.
  This speech-recognition path is separate from the removed local text/vision
  model runtime.
- Keep deterministic calculations, local catalogs, schema validation, and
  safety normalizers local. They are not AI inference fallbacks.
- Validate model output schema, ranges, catalog IDs, and Vietnamese user-facing
  text. Do not log raw prompts, images, health payloads, responses, or tokens.
- AI tests use fake `BackendApiClient` transports and must not download model
  assets or make real AI requests.

## Backend contract

- Text and JSON generation: `POST /api/v1/ai/generate`.
- Streaming chat: `POST /api/v1/ai/generate/stream`.
- Image Food Scan: `POST /api/v1/food/scan/analyze`.
- Backend owns Ollama model selection, auth, membership/quota checks, rate
  limits, and safe provider error mapping. Current configured models are
  `qwen3:4b-instruct` for text and `qwen3-vl:4b` for vision.
- HTTPS API readiness is required for live acceptance. Source tests or a
  successful HTTP `:8080` health check do not prove the HTTPS route works.

## Search

```powershell
rg "BackendAiTextClient|AiTextClient|context|timeout|retry|AIService|AIChatService|quota" lib/app_versions/v1/services/ai lib/app_versions/v1/features test
rg "validator|normalizer|catalog|Vietnamese|json|schema|trace" lib/app_versions/v1/services/ai lib/app_versions/v1/features test
```
