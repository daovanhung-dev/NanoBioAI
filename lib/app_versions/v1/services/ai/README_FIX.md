# NanoBioAI inference routing

Every in-app generative AI capability uses the authenticated NanoBio backend:
text/JSON generation, streaming chat, personalized health analysis, voice
responses, and Food Scan vision. `BackendAiTextClient` calls
`/api/v1/ai/generate`, `/api/v1/ai/generate/stream`, and
`/api/v1/food/scan/analyze`. The server owns Ollama model selection and
enforces authentication, membership, quota, and rate limits.

Guests can use app features that do not require AI. AI calls without a backend
session fail locally with a sign-in message and do not send anonymous requests.
Network/server failures never fall back to a local text or vision model.
Deterministic calculations, catalogs, validators, and local persistence remain
on-device.

Nabi ESP retains local microphone capture, Whisper speech recognition, ESP32
transport, and offline TTS; its generated reply now uses the authenticated
backend. The release API base is `https://42.118.174.147`; do not downgrade to
HTTP. Live acceptance depends on HTTPS readiness.
