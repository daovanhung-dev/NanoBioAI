Commit de xuat: docs(worklog): ghi nhan phien fix env tracked bundled

# Worklog - Fix env tracked and bundled

## Thoi gian

- Ngay: 2026-07-10
- Bat dau: 14:20
- Ket thuc: 14:35
- Timezone: Asia/Saigon

## Pham vi

- Loai task: bugfix
- Module chinh: config/env, app entrypoints, auth/AI env readers
- Yeu cau goc: Tim va fix no ky thuat/bug an trong toan du an; xu ly debt P0 `.env` tracked va bundled.

## Da lam

- Xac minh `.env` dang tracked va `pubspec.yaml` co asset `- .env` ma khong doc noi dung `.env`.
- Them `lib/core/config/app_env.dart` de doc config tu `--dart-define` truoc, dotenv optional fallback sau.
- Cap nhat app entrypoints, auth config, onboarding dev check, Dio provider, AI service va AI chat service sang `AppEnv`.
- Xoa `.env` khoi Flutter assets va `git rm --cached -- .env` de giu file local nhung xoa tracking.
- Cap nhat `.env.example`, checklist, issue/todo/fixbug docs.

## File code/docs da sua

- `.env` - untrack - xoa khoi git index, khong xoa local file.
- `.env.example` - sua - chuyen thanh template `--dart-define`.
- `pubspec.yaml` - sua - bo asset `.env`.
- `lib/core/config/app_env.dart` - tao - helper config safe.
- `lib/main.dart`, `lib/main_v2.dart`, `lib/main_admin.dart` - sua - init Supabase tu `AppEnv`.
- `lib/core/network/dio_provider.dart` - sua - base URL tu `AppEnv`.
- `lib/services/supabase/auth/account_security_service.dart` - sua - delete-account function tu `AppEnv`.
- `lib/app_versions/v2/features/auth/providers/auth_dependencies.dart` - sua - email confirmation flag tu `AppEnv`.
- `lib/app_versions/v2/features/auth/data/datasources/supabase_auth_remote_datasource.dart` - sua - auth redirect/delete env tu `AppEnv`.
- `lib/app_versions/v1/features/onboarding/providers/onboarding_provider.dart` - sua - AI dev check flag tu `AppEnv`.
- `lib/app_versions/v1/services/ai/ai_service.dart` - sua - Gemini env tu `AppEnv`.
- `lib/app_versions/v1/services/ai/ai_chat_service.dart` - sua - Gemini chat env tu `AppEnv`.
- `test/core/config/app_env_test.dart` - tao - tests fallback/optional/missing config.
- `docs/issues/env-tracked-and-bundled/001-issue-env-tracked-and-bundled.md` - tao.
- `docs/todo/env-tracked-and-bundled/001-todo-env-tracked-and-bundled.md` - tao.
- `docs/fixbug/env-tracked-and-bundled/001-fixbug-env-tracked-and-bundled.md` - tao.
- `docs/checklist/checklist_technical_debt.md` - sua - danh dau debt P0 fixed.

## Tai lieu lien quan

- `docs/checklist/checklist_technical_debt.md`
- `.codex/domains/access-membership-referral.md`
- `.codex/domains/onboarding.md`

## Commands

- `git ls-files -- .env`: PASS - khong con output sau fix.
- `git check-ignore -v .env`: PASS - `.env` duoc ignore.
- `flutter test test/core/config/app_env_test.dart test/services/ai/ai_service_test.dart test/app_versions/v2/features/auth/auth_validators_test.dart test/services/supabase/auth/supabase_auth_error_translator_test.dart`: PASS.
- `dart analyze ...`: PASS - targeted env/auth/AI files.

## Loi/Rui ro

- Da fix: `.env` khong con tracked va khong con la Flutter asset.
- Chua fix: Chua rotate key; neu `.env` tung co key that trong lich su git, can rotate ngoai repo.
- Can kiem tra tiep: Full app run can duoc truyen `SUPABASE_URL` va `SUPABASE_ANON_KEY` bang `--dart-define`.

## Ty le hoan thanh

- Hoan thanh: Debt P0 env tracking/asset packaging.
- Dang do: Objective toan du an van con cac debt P1/P2 trong checklist.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - xu ly debt P0 khong doc/in secret va co test.
- Muc do hoan thanh task: hoan thanh mot debt P0 trong objective lon.
- Bang chung kiem chung: git metadata, targeted tests/analyze PASS.
- Diem ton token/chua toi uu: Doc diff AI service dai; lan sau dung `rg` va `Select-String` hep hon.
- Cach toi uu cho phien sau: Tiep tuc theo checklist, uu tien analyzer warnings co tac dong release.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
