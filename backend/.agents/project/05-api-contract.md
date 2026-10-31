# API Contract

- Base path: `/api/v1`; readiness/liveness are `/health/ready` and `/health/live`.
- Success envelope: `success`, `businessCode`, `message`, `data`, `meta`, `traceId`.
- Error envelope has the same fields and always `data: null`.
- Accept a valid UUID `X-Trace-Id`, otherwise generate one; return it in the header and envelope.
- Use bearer access tokens on protected routes and document them in OpenAPI.
- Use resource/action paths, typed request schemas, explicit pagination bounds, and allowlisted sorts.
- FamilyPlus routes use `/family-plus/context`, `/family-plus/group`, and
  `/family-plus/members`; enforce an active plan and owner-scoped subjects.
- Sleep safety routes under `/sleep-safety` use authenticated owner-scoped
  contact, preference, session, event and dispatch contracts. Session/event
  sync rejects cross-user ownership and event/session mismatches.
- Never return ORM objects, credentials, password hashes, provider secrets, or private file paths.
- `POST /ai/generate` requires a FastAPI bearer access token and active account. It accepts 1–8 `user`/`assistant` text messages, ending in `user`, with a 16 KiB request-body cap. The server controls the Nabi system instruction, model, provider URL, and inference options.
- `POST /ai/generate/stream` streams bounded NDJSON deltas under the same auth, account and provider controls. AI success data contains `text`, `model`, and optional provider token counts. Text routes are disabled unless `OLLAMA_ENABLED=true`; provider context overflow maps to 413, timeout to 504, unavailability to 503, malformed provider responses to `502 AI_PROVIDER_FAILURE`, and output truncation to `502 AI_RESPONSE_TRUNCATED` without partial text. Errors never include raw provider payloads.
- `POST /food/scan/analyze` accepts one validated image and uses the separately configured vision model when `OLLAMA_VISION_ENABLED=true`; otherwise it returns 503 `FEATURE_NOT_ENABLED`. Flutter AI requests require a backend session and never fall back to local inference. Nabi ESP speech recognition and offline TTS remain on-device, while generated replies use the authenticated AI API. Six source-less functions have no route.
- HTTP status must match error/success semantics. Unexpected errors are safe and include only a trace ID.
