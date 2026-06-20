# Playbook - AI Service / Meal / Exercise / Chat

## Muc tieu

AI co the timeout, quota, hoac tra sai format nhung app khong crash. Text user-facing phai la tieng Viet co dau va da duoc validate/normalize.

## Doc truoc

- `lib/services/ai/`
- `lib/features/meal_plan/`
- `lib/features/ai_chat/`
- `.codex/playbooks/access_membership_referral.md` neu task cham AI chat quota, tao lich trinh theo tier, guest/free/Plus access, hoac membership gate.
- `lib/features/lifestyle_schedule/data/models/*normalizer*`
- `lib/features/daily_health_tracking/data/models/*normalizer*`
- Tests: `test/services/ai/`, `test/features/meal_plan/`, `test/features/lifestyle_schedule/`, `test/features/daily_health_tracking/`

## File can de y

- `lib/services/ai/ai_service.dart`
- `lib/services/ai/ai_chat_service.dart`
- `lib/services/ai/ai_json_parser.dart`
- `lib/services/ai/ai_json_prompt_builder.dart`
- `lib/services/ai/ai_vietnamese_text_validator.dart`
- `lib/services/ai/ai_trace_logger.dart`
- `lib/services/ai/prompts/meal_plan_prompt.dart`
- `lib/services/ai/prompts/exercise_tasks_prompt.dart`

## Quy tac

- Khong tin output AI tuyet doi; validate schema/type/range.
- AI chat phai xu ly dotenv/API key chua init an toan, khong crash khi test/unit khong load `.env`.
- Khong de chat history/context tang vo han; neu sua chat, kiem tra message count/token growth/fallback.
- Parser phai reject JSON sai schema thay vi crash.
- Neu AI tra id/code/text khong dau, map qua catalog/normalizer de lay tieng Viet co dau.
- Co fallback ro cho timeout, 503/quota, invalid JSON, missing fields.
- Guest chi duoc tao lich trinh AI 1 lan sau onboarding; free chat 3 cau/ngay va tao lich trinh 3 lan/thang; Plus planned mo gioi han theo membership gate.
- Unit/widget test khong goi Gemini that.
- Log AI chi ghi summary an toan: stage, status, count, error type; khong log API key/raw prompt/raw response dai.

## Tim nhanh

```bash
rg "Gemini|generateContent|timeout|retry|fallback|AIService|AIChatService|dotenv|ChatSession" lib/services/ai lib/features test
rg "validator|normalizer|catalog|Vietnamese|json|schema|trace" lib/services/ai lib/features test
```

## Test nen chay

- `flutter test test/services/ai`
- `flutter test test/features/meal_plan`
- Neu cham exercise/daily tasks: `flutter test test/features/lifestyle_schedule test/features/daily_health_tracking`
