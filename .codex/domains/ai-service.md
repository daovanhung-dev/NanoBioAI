# Domain - AI Service / Meal / Exercise / Chat

## Source

- `lib/app_versions/v1/services/ai/`
- `lib/app_versions/v1/features/meal_plan/`
- `lib/app_versions/v1/features/ai_chat/`
- Normalizers in `lifestyle_schedule` and `daily_health_tracking`.
- Tests: `test/services/ai/`, meal/schedule/task tests.

## Rules

- Never trust AI output blindly; validate schema, type, range, and Vietnamese user-facing text.
- Tests must not call Gemini.
- Handle missing dotenv/API key, timeout, quota, invalid JSON, and model failure safely.
- Do not let AI chat history/context grow without bounds.
- Log only safe summaries: stage, status, counts, error type; no raw prompt/response or secrets.
- Guest/free/Plus generation and chat quota must follow access rules.

## Search

```powershell
rg "Gemini|generateContent|timeout|retry|fallback|AIService|AIChatService|dotenv|ChatSession" lib/app_versions/v1/services/ai lib/app_versions/v1/features test
rg "validator|normalizer|catalog|Vietnamese|json|schema|trace" lib/app_versions/v1/services/ai lib/app_versions/v1/features test
```
