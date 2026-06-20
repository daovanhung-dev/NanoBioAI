Commit de xuat: feat(auth): hoan thanh authentication v2 theo BD/DD

# Authentication V2

## Muc tieu

- Trien khai module authentication theo `BD-AUTH-001` va DD authentication `00-16`.
- Dung Supabase Auth va `public.users.onboarding_status` lam nguon dieu huong chinh.
- Giu SQLite la cache/local data cho dashboard, AI plan va notification hien co.

## Pham vi

- Bao gom: dang ky, dang nhap, verify email, forgot/reset password, AuthGate, profile bootstrap missing state, onboarding cloud lifecycle, logout/delete account repository contract.
- Khong bao gom: chay SQL truc tiep len Supabase production, tao Edge Function server-side, OAuth social login, 2FA.

## Luong hoat dong

1. App v2 mo `AuthGate`.
2. AuthGate doc session Supabase, email verification va `public.users.onboarding_status`.
3. Chua login thi vao login/register.
4. Chua verify email thi vao verify email.
5. Profile bootstrap thieu thi hien man hinh ho tro/retry.
6. `not_started`/`in_progress` thi vao onboarding.
7. `completed` thi vao menu/dashboard v1.

## Du lieu va luu tru

- Nguon doc route: Supabase Auth + `public.users`.
- Onboarding cloud-first: update `users`, `health_profiles`, `lifestyle_habits`, replace/upsert collection rows co du lieu that, sau do set completed.
- Mirror local: SQLite ghi bang auth UUID de dashboard/AI/notification hien tai tiep tuc doc dung user.
- Database SQL: dung scripts trong `docs/DD/authentication/database/`, khong chay tu Flutter.

## UI/UX

- Them page v2 cho login, register, verify email, forgot password, reset password va auth callback.
- Copy tieng Viet co dau, giong Nami, khong hien thuat ngu database/trigger/RLS cho user.
- Verify email co cooldown gui lai 60 giay.

## Files

- `lib/app_versions/v2/features/auth/` - module auth v2 domain/data/providers/pages.
- `lib/app_versions/v2/router/` - route AuthGate va auth pages.
- `lib/services/supabase/auth/` - service dung chung cho current auth user va onboarding cloud profile.
- `lib/app_versions/v1/features/onboarding/` - save cloud-first roi mirror SQLite.
- `lib/app_versions/v1/features/dashboard/` va `daily_health_tracking` - doc SQLite theo auth UUID neu co.
- `.env.example`, Android/iOS config - deep link `nanobio://auth/callback`.

## Kiem chung

- `dart format --set-exit-if-changed .`: PASS.
- `flutter test test\architecture_preservation_property_test.dart test\app_versions\v2\features\auth test\architecture_version_boundary_test.dart test\widget_test.dart test\features\dashboard test\features\daily_health_tracking`: PASS - 63 tests.
- `flutter analyze`: FAIL do 289 warning/info nen hien co cua repo; loc theo file auth/onboarding/dashboard vua sua khong co issue.
- `.codex\tool\codex_quick_check.ps1` voi `-ExecutionPolicy Bypass`: log co 1 full-suite test fail doc lap o `test/features/features_hub/features_hub_page_test.dart` do khong tim thay text `AI Coach`.

## Lien ket

- Worklog: `../../worklog/2026-06-20/002-worklog-authentication-v2.md`
- Test: `../../test/authentication/001-test-authentication-v2.md`

## Rui ro

- Can deploy/chay SQL Supabase theo `docs/DD/authentication/database/README.md` truoc khi test manual tren moi truong that.
- Xoa tai khoan phu thuoc Edge Function `delete-account` duoc deploy rieng, Flutter khong chua service-role key.
- Full suite hien con fail ngoai scope auth o `features_hub_page_test`; targeted auth/onboarding/dashboard regression da pass.
