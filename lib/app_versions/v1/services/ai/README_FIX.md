# NanoBio AI Chat — release transport

Lifecycle: `Current source note`. Production Flutter code sends bounded AI
requests to the `nabi-ai-generate` Supabase Edge Function. The Gemini provider
credential is an Edge Function secret and is not read from Flutter runtime
configuration or Android `BuildConfig`.

`GeminiRestClient` remains a transport seam for unit tests and explicitly
injected local tooling. It is not constructed by the production providers.
`AIChatService`, NaBi Care, Sleep Analysis and Food Scan use
`NabiAiBackendClient` unless a test supplies an explicit fake/client.

If the backend is unavailable or the function returns an invalid response, the
app fails closed with user-safe copy or a deterministic local fallback where
that feature's contract permits it. No client-side Gemini key, provider secret,
or unrestricted provider endpoint is bundled in the release artifact.

## Backend transport contract

- Function: `supabase/functions/nabi-ai-generate/index.ts`
- Authentication: Supabase session JWT, verified in the Edge runtime.
- Provider authentication: `GEMINI_API_KEY` Edge Function secret only.
- Request limits: bounded body, content count, prompt length, and response length.
- Tests: `supabase/functions/nabi-ai-generate/handler_test.ts` plus Flutter fake
  transport tests; deployed runtime evidence remains a release gate.

Do not add a `GEMINI_API_KEY` asset, Gradle property, Dart define in a release
profile, or native `BuildConfig` field. If local development needs a provider
credential, keep it outside the repository and use only an explicit test or
backend environment.
