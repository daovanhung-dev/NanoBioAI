# Domain - AI Service / Meal / Exercise / Chat

## Source

- `lib/app_versions/v1/services/ai/`
- `lib/app_versions/v1/features/meal_plan/`
- `lib/app_versions/v1/features/ai_chat/`
- Normalizers in `lifestyle_schedule` and `daily_health_tracking`.
- Tests: `test/services/ai/`, meal/schedule/task tests.

## Rules

- Production AI uses the provider-neutral `AiTextClient` contract with
  `LocalAiTextClient` backed by the app-owned `lib/core/ai_local/` runtime. Do
  not add provider keys or route prompts/images to an AI service.
- Native user builds require an explicitly selected and downloaded text model.
  Food Scan downloads its local vision model and projector on first use. Web AI
  must fail with a clear unsupported-platform message.
- Plan generation may use the validated local catalog fallback when local
  inference fails. AI Chat must not fabricate a fallback response.
- Budget prompts using the selected model's context and tokenizer. Keep recent
  chat history only; shortlist schedule candidates while preserving the full
  local catalog for normalization and safety validation.
- Supabase remains in use for auth, sync, data, and existing quota flows. Do not
  edit or deploy the retained AI Edge Functions as part of app-local inference.
- Never trust AI output blindly; validate schema, type, range, and Vietnamese user-facing text.
- Tests must not call a remote AI service or download large model assets.
- Handle download resume/cancel, checksum mismatch, storage errors, unsupported
  platform, timeout, quota, invalid JSON, context overflow, and model load
  failure safely.
- Do not let AI chat history/context grow without bounds.
- Log only safe summaries: stage, status, counts, error type; no raw prompt/response or secrets.
- Guest/free/Plus generation and chat quota must follow access rules.

## Search

```powershell
rg "LocalAiTextClient|AiTextClient|context|timeout|retry|fallback|AIService|AIChatService|quota" lib/app_versions/v1/services/ai lib/app_versions/v1/features test
rg "validator|normalizer|catalog|Vietnamese|json|schema|trace" lib/app_versions/v1/services/ai lib/app_versions/v1/features test
```
