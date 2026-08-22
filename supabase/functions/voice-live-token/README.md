# `voice-live-token` Edge Function

> **Trạng thái 2026-08-23:** Flutter Voice runtime hiện dùng Gemini Live
> trực tiếp và không gọi Function này. File được giữ lại như một phương án
> server-side cũ để tránh xóa WIP/khả năng chuyển lại sau này; không cần deploy
> nó để direct mode hoạt động.

This function validates the caller's Supabase JWT, confirms that the caller
has an active `plus` or `family_plus` plan through `effective_user_access`,
then mints a short-lived Gemini Live AuthToken. Voice sessions do not consume
or commit an `ai_chat_message` quota event.

The AuthToken locks only `model`, `generationConfig`, and `systemInstruction`
with `fieldMask: model,generationConfig,systemInstruction`; the Flutter setup
continues to provide VAD, transcription, and session-resumption settings. The
function returns the AuthToken `name` credential and never sends
`GEMINI_API_KEY`, audio, or transcript data to Flutter.

Deploy with the project linked to a disposable sandbox/staging environment:

```bash
export SUPABASE_ACCESS_TOKEN=...
export SUPABASE_PROJECT_REF=...
supabase secrets set --project-ref "$SUPABASE_PROJECT_REF" \
  GEMINI_API_KEY=... \
  GEMINI_LIVE_MODEL=gemini-3.1-flash-live-preview
supabase functions deploy voice-live-token --project-ref "$SUPABASE_PROJECT_REF"
deno test --allow-net supabase/functions/voice-live-token/handler_test.ts
```

`SUPABASE_URL` and `SUPABASE_ANON_KEY` are supplied by the Edge runtime. Keep
`verify_jwt = true` in `supabase/config.toml`; do not deploy this function with
JWT verification disabled. The function must remain server-side so the Gemini
API key is never included in the app. "Unlimited" means no NanoBio voice-turn
quota for paid members; Gemini service availability and technical session
limits still apply.
