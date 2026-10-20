# NanoBioAI local inference

## Runtime contract

Production feature services depend on the provider-neutral `AiTextClient` in
`ai_text_client.dart`. The production implementation is `LocalAiTextClient`,
backed by the app-owned runtime in `lib/core/ai_local/`; it does not import or
depend on the standalone `ai_local` application.

Native user builds require a selected and installed text model before entering
the user app. The selection is persisted locally and loaded on the next start.
Food Scan installs its vision model and projector on first use. Downloaded
assets are resumed when possible and SHA-256 checked before installation.
Inference failures stay local and do not fall through to a remote AI service.

The web implementation reports `unsupported_platform`. Web routes that do not
need AI remain available. AI features must show this state instead of sending
requests to an Edge Function.

## Supabase boundary

Supabase remains in use for authentication, data, cloud sync, and existing
quota workflows. The NanoBioAI app no longer invokes the
`nabi-ai-generate` or `food-scan-analyze` AI functions. Their source, deployed
secrets, and deployment state are outside this app migration and remain
untouched.

## Model and prompt limits

Prompt construction uses the selected local model's context size and tokenizer
when the client exposes context estimation. Chat history is pruned to the
recent messages that fit. Meal and exercise catalog prompts use eligible code
shortlists; the existing catalog normalizers remain authoritative and reject
unknown codes, duplicates, or unsafe structure. A context failure never
triggers remote inference.

## Configuration

The app uses public Supabase configuration for existing account and data flows.
No AI API key or `GEMINI_*` setting is required by NanoBioAI.
