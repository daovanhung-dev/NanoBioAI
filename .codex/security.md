# Security

## Authentication
- Provider: **Supabase Auth** (email/password)
- Session management: handled by Supabase SDK (`supabase_flutter`)
- Token storage: Supabase SDK tự lưu session token (Keychain/SharedPreferences nội bộ)
- Current user check: `Supabase.instance.client.auth.currentUser`

## Route Protection
- `authGuard`: protect `/ai-chat`, `/nutrition`, `/profile` — redirect `/login` nếu chưa auth
- `guestGuard`: protect `/login` — redirect `/dashboard` nếu đã auth
- **⚠️ Dashboard guard bị comment out** — `/dashboard` accessible không cần login

## API Keys / Secrets
- Lưu trong `.env` file: `SUPABASE_ANON_KEY`, `GEMINI_API_KEY`
- Load qua `flutter_dotenv`
- **⚠️ `.env` không có trong `.gitignore`** — credentials đang bị commit vào repo
- `SUPABASE_ANON_KEY` là public anon key (thiết kế để public, nhưng cần RLS rules bên Supabase)

## Input Validation
- Onboarding: validation cơ bản (`canSave` check) — không có sanitization phức tạp
- Không có input validation cho XSS, SQL injection (SQLite dùng parameterized queries qua `sqflite` → an toàn với SQL injection)

## Data Storage
- Health data: **local SQLite** — không truyền lên server
- User auth: Supabase Cloud
- Không có encryption cho local database

## AI Prompt
- Prompt được build từ user data nhưng không expose sensitive fields như password/token
- Response từ AI được parse qua `jsonDecode` — không execute code từ AI

## Điểm cần chú ý khi mở rộng
1. Bật auth guard cho Dashboard trước khi release
2. Thêm `.env` vào `.gitignore` và dùng secret management
3. Cân nhắc encrypt SQLite (`sqlcipher`) nếu data nhạy cảm
4. Supabase RLS (Row Level Security) cần được cấu hình nếu dùng Supabase database
