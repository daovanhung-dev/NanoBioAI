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

1. Production entrypoint `main.dart` chay `BioAIV2App` voi `v2Router`.
2. Splash v1 van la `initialLocation`: neu co Supabase session thi vao `AuthGate`, neu chua co session thi di guest flow theo local onboarding flag.
3. AuthGate doc session Supabase, email verification, `public.users.onboarding_status` va `subscription_tier`.
4. Chua login thi vao login/register.
5. Chua verify email thi vao verify email.
6. Profile bootstrap thieu thi hien man hinh ho tro/retry.
7. `not_started`/`in_progress` thi vao onboarding.
8. `completed` thi vao menu/dashboard v1.

## Du lieu va luu tru

- Nguon doc route: Supabase Auth + `public.users`.
- `subscription_tier` duoc doc nhu snapshot/hook tin cay toi thieu, default an toan la `free`; chua mo quota/entitlement paid trong scope nay.
- Onboarding cloud-first: update `users`, `health_profiles`, `lifestyle_habits`, replace/upsert collection rows co du lieu that, sau do set completed.
- Mirror local: SQLite ghi bang auth UUID de dashboard/AI/notification hien tai tiep tuc doc dung user.
- Database SQL: dung scripts trong `docs/DD/authentication/database/`, khong chay tu Flutter.

## UI/UX

- Them page v2 cho login, register, verify email, forgot password, reset password va auth callback.
- Copy tieng Viet co dau, giong Nabi, khong hien thuat ngu database/trigger/RLS cho user.
- Verify email co cooldown gui lai 60 giay.

## Files

- `lib/app_versions/v2/features/auth/` - module auth v2 domain/data/providers/pages.
- `lib/app_versions/v2/router/` - route AuthGate va auth pages.
- `lib/services/supabase/auth/` - service dung chung cho current auth user va onboarding cloud profile.
- `lib/app_versions/v1/features/onboarding/` - save cloud-first roi mirror SQLite.
- `lib/app_versions/v1/features/dashboard/` va `daily_health_tracking` - doc SQLite theo auth UUID neu co.
- `.env.example`, Android/iOS config - deep link `nanobio://auth/callback`.
- `lib/core/constants/routes/auth_route_paths.dart` - route auth dung chung cho v1/v2.

## Kiem chung

- 2026-06-21: `dart format --set-exit-if-changed .`: PASS sau lan format cuoi.
- 2026-06-21: `flutter test test\app_versions\v2\features\auth test\app_versions\v1\features\splash test\architecture_version_boundary_test.dart`: PASS - 29 tests.
- 2026-06-21: `powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1`: PASS, script exit 0 va full suite pass 290 tests.
- 2026-06-21: `flutter analyze`: FAIL do 287 warning/info nen hien co cua repo.

## Lien ket

- Worklog: `../../worklog/2026-06-20/002-worklog-authentication-v2.md`
- Worklog cap nhat auth flow: `../../worklog/2026-06-21/003-worklog-auth-system-flow.md`
- Test: `../../test/authentication/001-test-authentication-v2.md`

## Rui ro

- Can deploy/chay SQL Supabase theo `docs/DD/authentication/database/README.md` truoc khi test manual tren moi truong that.
- Xoa tai khoan phu thuoc Edge Function `delete-account` duoc deploy rieng, Flutter khong chua service-role key.
- `subscription_tier` moi la hook doc tu Supabase, chua thay the DD entitlement/quota planned cho Free/Plus/FamilyPlus.
