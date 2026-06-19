# NanoBio AI Release Fix

Thay 2 file này vào:

- lib/services/ai/ai_service.dart
- lib/services/ai/ai_chat_service.dart

Sau đó sửa .env theo dạng không có dấu cách quanh dấu bằng:

SUPABASE_URL=https://...
SUPABASE_ANON_KEY=...
GEMINI_API_KEY=KEY_MOI_CUA_BAN
GEMINI_BASE_URL=https://generativelanguage.googleapis.com/v1beta
GEMINI_MODEL=gemini-3.5-flash
ONBOARDING_AI_DEV_CHECK_ENABLED=true

Build lại:

flutter clean
flutter pub get
flutter build apk --release --no-shrink

Nếu Windows báo lỗi symlink/plugin:
start ms-settings:developers
Bật Developer Mode rồi restart máy.
