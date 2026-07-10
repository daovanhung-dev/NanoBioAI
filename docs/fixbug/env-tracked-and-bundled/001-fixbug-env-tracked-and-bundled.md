Commit de xuat: fix(config): bo env khoi tracking va asset bundle

# Fixbug - Env tracked and bundled

## Tom tat

- `.env` local dang bi track trong git va duoc khai bao trong `pubspec.yaml`
  assets.
- Day la debt P0 vi secret/config local co the vao VCS va app bundle.

## Cach sua

- Bo `.env` khoi git index bang `git rm --cached -- .env`; file van duoc giu
  local va tiep tuc bi `.gitignore` ignore.
- Xoa `- .env` khoi `pubspec.yaml`.
- Them `AppEnv` de doc config theo thu tu:
  1. `--dart-define`.
  2. dotenv optional fallback neu moi truong legacy co cung cap.
- Cap nhat `main.dart`, `main_v2.dart`, `main_admin.dart`, auth config,
  onboarding dev check, Dio provider, AI service va AI chat service sang
  `AppEnv`.
- Cap nhat `.env.example` thanh template ten bien cho `--dart-define`, khong
  khuyen khich bundle `.env`.

## Kiem chung

- `git ls-files -- .env`: PASS - khong con output.
- `git check-ignore -v .env`: PASS - `.env` duoc ignore boi `.gitignore`.
- `flutter test test/core/config/app_env_test.dart test/services/ai/ai_service_test.dart test/app_versions/v2/features/auth/auth_validators_test.dart test/services/supabase/auth/supabase_auth_error_translator_test.dart`: PASS.
- `dart analyze lib/core/config/app_env.dart lib/main.dart lib/main_v2.dart lib/main_admin.dart lib/core/network/dio_provider.dart lib/services/supabase/auth/account_security_service.dart lib/app_versions/v2/features/auth/providers/auth_dependencies.dart lib/app_versions/v2/features/auth/data/datasources/supabase_auth_remote_datasource.dart lib/app_versions/v1/features/onboarding/providers/onboarding_provider.dart lib/app_versions/v1/services/ai/ai_service.dart lib/app_versions/v1/services/ai/ai_chat_service.dart test/core/config/app_env_test.dart`: PASS.

## Luu y

- Neu `.env` tung chua key that trong lich su git, can rotate key ngoai repo.
- Runtime local can truyen gia tri bang `--dart-define`, IDE launch config
  local, hoac co che secret-safe tu pipeline.
