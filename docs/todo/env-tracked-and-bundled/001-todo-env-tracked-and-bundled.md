Commit de xuat: docs(todo): lap todo fix env tracked bundled

# Todo - Fix env tracked and bundled

## Issue goc

- Issue: [Env tracked and bundled](../../issues/env-tracked-and-bundled/001-issue-env-tracked-and-bundled.md)
- Severity: blocker
- Trang thai: fixed 2026-07-10

## Muc tieu fix

- `.env` khong con tracked trong git.
- `.env` khong con nam trong Flutter assets.
- App co duong doc config khong can bundle file secret.

## Khong lam trong todo nay

- Khong doc, in, hoac ghi lai noi dung `.env`.
- Khong rotate key thay user; chi ghi can rotate neu key that tung bi commit.

## Checklist

1. [x] Xac minh `.env` dang tracked va asset bundle.
2. [x] Tao helper config dung `--dart-define` truoc, dotenv optional fallback sau.
3. [x] Cap nhat app entrypoints va service doc env qua helper.
4. [x] Xoa asset `- .env` khoi `pubspec.yaml`.
5. [x] `git rm --cached -- .env` de giu file local nhung xoa khoi tracking.
6. [x] Cap nhat `.env.example` thanh reference cho `--dart-define`.
7. [x] Them targeted tests/analyze.

## Verification

- `git ls-files -- .env`: PASS - khong con output.
- `git check-ignore -v .env`: PASS - `.env` duoc ignore.
- `flutter test test/core/config/app_env_test.dart test/services/ai/ai_service_test.dart test/app_versions/v2/features/auth/auth_validators_test.dart test/services/supabase/auth/supabase_auth_error_translator_test.dart`: PASS.
- `dart analyze ...`: PASS - targeted changed env/auth/AI files.
