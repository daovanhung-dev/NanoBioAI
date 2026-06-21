Commit de xuat: docs(auth): tao checklist DD authentication v2

# Checklist DD Authentication V2

Cap nhat gan nhat: 2026-06-21 sau phien toi uu auth theo luong he thong.

## Cach doc trang thai

- `[x] Done`: da co code/tai lieu/test muc tieu trong scope Flutter.
- `[~] Partial`: da lam mot phan, con thieu UI/test/manual verify/ops.
- `[ ] Pending`: chua lam trong codebase hien tai.
- `[M] Manual`: phu thuoc Supabase SQL, Dashboard, email link, RLS, Edge Function hoac moi truong that.

## Tong quan theo phase

| Phase | DD | Trang thai | Da hoan thanh | Con lai |
|---|---|---:|---|---|
| A. Database foundation | `03`, `database/*` | [M] | Da doc DD/SQL, khong chay SQL trong coding, app khong tu chen baseline profile sau sign-up. | Chay SQL theo `database/README.md`, verify integrity query 0 row, RLS smoke 2 tai khoan, backfill user cu neu co. |
| B. Auth data/domain layer | `04`, `08`, `11`, `12`, `14` | [x] | Co commands/results/errors, `AuthRepository`, Supabase datasource, route-state resolver, validators, error mapping duplicate/neutral, last-login best-effort, delete qua Edge Function, contract tests khong lo service-role. | Co the bo sung fake Supabase datasource coverage sau neu can chi tiet hon. |
| C. Presentation/routing | `07`, `08`, `11`, `14` | [x] | Co login/register/verify/forgot/reset/callback pages, AuthGate v2, deep link native, route theo Supabase session + email + onboarding status. Production `main.dart` chay `BioAIV2App/v2Router`; Splash giu guest flow nhung chuyen session hien co vao AuthGate; auth route dung constants chung. | Manual test email verification/recovery link tren Supabase that. |
| D. Onboarding/profile integration | `09`, `10` | [x] | Onboarding mark `in_progress`, save cloud-first, set `completed` + timestamp, mirror SQLite bang auth UUID, local readers doc theo current auth UUID, co profile edit sau onboarding cloud-first + local mirror. | Can manual Supabase/RLS verify. |
| E. Settings/account safety | `10`, `11`, `12` | [~] | Co UI doi mat khau/logout/request delete, confirm dialogs, route ve AuthGate, central user-scoped cache invalidation, Flutter khong lo service-role key. | Edge Function server-side/JWT/cascade delete va auth-user-change runtime smoke can manual verify. |

## Checklist theo DD module

### `02_MODULE_OVERVIEW.md` - Module Authentication

- [x] Dung Supabase Auth lam identity, khong luu password trong public DB.
- [x] Dung `public.users.onboarding_status` lam route truth de vao onboarding/dashboard.
- [x] Co hop dong `AuthRepository` va datasource tach Supabase Auth.
- [x] AuthGate chan Dashboard neu chua login, chua verify email, profile bootstrap thieu, hoac onboarding chua completed.
- [x] Settings/profile co update profile, doi mat khau, logout, request delete account va route ve AuthGate v2.

### `03_DATA_MODEL_RLS_AND_MIGRATIONS.md` - Database/RLS/Migration

- [x] Flutter khong chay SQL production va khong dung service-role key.
- [x] Flutter doc/ghi theo current auth UUID, khong tin local latest user khi co session.
- [x] Onboarding save ghi `users`, `health_profiles`, `lifestyle_habits`, collections va survey answers theo user hien hanh.
- [M] Chua deploy/verify SQL lifecycle fields, trigger bootstrap, RLS/grants trong moi truong Supabase that.
- [M] Chua chay `002_verify_auth_profile_integrity.sql` va RLS smoke 2 account.

### `04_FEATURE_REGISTRATION.md` - FR-01 Dang ky

- [x] Co `RegisterCommand`, `RegistrationResult`, validator email/password/confirm/name/terms.
- [x] Datasource goi Supabase `signUp`, truyen metadata an toan, khong tu insert baseline profile tu Flutter.
- [x] UI register co loading/error/success route verify/AuthGate.
- [x] Duplicate email/network co mapping than thien; rate-limit van phu thuoc Supabase/manual verify.
- [M] Baseline rows sau sign-up phu thuoc trigger Supabase, can manual verify.

### `05_FEATURE_PROFILE_BOOTSTRAP.md` - FR-02 Bootstrap profile

- [x] AuthGate doc profile hien hanh va co state `profileBootstrapUnavailable` khi thieu baseline row.
- [x] Flutter khong client-insert de sua loi thieu baseline profile.
- [M] Trigger bootstrap, constraint unique, revoke insert va integrity query chua duoc chay trong coding.

### `06_FEATURE_MANUAL_ACCOUNT_CREATION.md` - FR-03 Tao account thu cong

- [x] App xu ly account thu cong dung cach neu Supabase trigger tao baseline rows.
- [x] App hien support/retry neu profile row chua san sang.
- [M] Quy trinh tao account trong Supabase Dashboard va verify TC-AUTH-07 la manual ops, chua thuc hien trong code.

### `07_FEATURE_EMAIL_VERIFICATION.md` - FR-04 Verify email

- [x] Co page verify email, resend verification, cooldown 60 giay va quay lai AuthGate.
- [x] AuthRoute resolver chan user chua verify khi `AUTH_CONFIRM_EMAIL_REQUIRED=true`.
- [x] Co deep link `nanobio://auth/callback` trong env, Android, iOS va callback page recover session.
- [M] Chua manual test email template/allow-list/verification link tren Supabase that.

### `08_FEATURE_LOGIN_SESSION_AUTH_GATE.md` - FR-05/06 Login/session/AuthGate

- [x] Co `LoginCommand`, login page, invalid input validation, neutral auth error mapping.
- [x] AuthGate mapping: no session -> login, unverified -> verify, missing profile -> support, pending onboarding -> onboarding, completed -> menu/dashboard.
- [x] AuthGate doc them `public.users.subscription_tier` nhu snapshot tin cay toi thieu, default an toan `free`.
- [x] `last_login_at` best-effort, failure khong chan route.
- [x] Unit test route-state resolver cover cac state chinh.
- [x] Logout/delete clear Supabase session, local onboarding compatibility flag va user-scoped Riverpod providers/cache trung tam.

### `09_FEATURE_ONBOARDING_COMPLETION.md` - FR-07 Onboarding completion

- [x] Bat dau onboarding mark cloud `onboarding_status = in_progress` neu co Supabase session.
- [x] Save final cloud-first, set `completed` + timestamp sau khi payload du lieu duoc tao.
- [x] Optional collections duoc replace theo du lieu that, khong seed task/log gia.
- [x] Mirror SQLite bang auth UUID de dashboard/daily tracking doc tiep.
- [~] Co targeted regression/source contract cho lifecycle/profile/cache; chua co fake Supabase datasource unit test rieng cho tung TC-AUTH-18..22.

### `10_FEATURE_PROFILE_UPDATE.md` - FR-08 Profile update

- [x] Onboarding final save co update existing profile rows dung current auth UUID.
- [x] Co UI edit profile sau onboarding trong Profile/Settings flow, ghi cloud-first qua `AuthProfileService.updateProfile`.
- [x] Sau cloud save thanh cong, mirror SQLite bang auth UUID de dashboard/daily tracking tiep tuc doc dung user.
- [~] Stale session/missing session co safe failure copy trong UI va service throw typed auth failure; RLS failure can manual Supabase verify.

### `11_FEATURE_PASSWORD_RECOVERY_AND_CHANGE.md` - FR-09 Password recovery/change

- [x] Co forgot password page goi Supabase recovery voi redirect URL.
- [x] Co reset password page, validate confirm password, update password qua Supabase Auth.
- [x] Co auth callback recover session tu deep link.
- [x] Co UI doi mat khau trong Settings, validate confirm password va goi Supabase Auth update password.
- [M] Chua manual test recovery email/deep link tren Supabase that.

### `12_FEATURE_LOGOUT_AND_ACCOUNT_DELETION.md` - FR-10/11 Logout/delete

- [x] `AuthRepository.signOut()` clear Supabase session va local onboarding compatibility flag.
- [x] `requestAccountDeletion()` chi invoke Edge Function, khong goi Admin API/service-role trong Flutter.
- [x] Co UI Settings cho logout/delete account voi confirm dialogs va route ve `/v2/auth`.
- [x] Co helper central `invalidateUserScopedProviders` cho dashboard/daily/lifestyle/meal/nutrition/settings cache khi logout/delete/profile update.
- [M] Edge Function `delete-account`, server-side JWT validation va cascade delete chua verify trong moi truong that.

### `13_ERROR_HANDLING_AND_DATA_RECOVERY.md` - FR-12 Error/recovery

- [x] Co typed `AuthFailure`, generic/neutral user-facing copy, khong lo technical RLS/trigger/database tren UI.
- [x] Missing profile sau login vao support/retry state, khong client repair.
- [M] Backfill old users va incident checklist la manual database ops, chua thuc hien.

### `14_FLUTTER_LAYER_CONTRACTS.md` - Layer contracts

- [x] Co boundaries `domain/data/providers/presentation` trong `lib/app_versions/v2/features/auth`.
- [x] Co commands/results/states/errors theo contract.
- [x] Datasource dung Supabase Auth/PostgREST/Functions dung scope.
- [x] AuthGate la top-level route gate cua v2.
- [x] Auth UI goi `AuthController` provider mong cho login/register/resend/recovery/reset/callback; settings security actions dung shared service de khong tao phu thuoc v1 -> v2.

### `15_TEST_ACCEPTANCE_AND_TRACEABILITY.md` - Test/acceptance

- [x] Co unit tests cho route-state resolver va validators.
- [x] Co widget smoke tests cho login/register.
- [x] Targeted regression pass: auth v2, splash route decision, version boundary, settings/profile contract, onboarding/dashboard/daily tracking targeted tu phien truoc.
- [~] Chua co fake datasource/controller tests cho tat ca TC-AUTH-01..35, nhung da bo sung contract/unit tests cho code gaps TC-AUTH-04, 10, 13, 15, 24, 26, 31, 32, 34.
- [M] Chua co SQL integrity/RLS/manual Supabase verification.
- [~] `flutter analyze` con fail 287 warning/info nen cua repo; targeted auth/splash/version tests pass.

## Traceability TC-AUTH

| TC | Trang thai | Ghi chu |
|---|---:|---|
| TC-AUTH-01 | [~] | Code sign-up/session route co, trigger baseline can manual verify. |
| TC-AUTH-02 | [~] | Code confirm-email-on route verify co, baseline rows can manual verify. |
| TC-AUTH-03 | [x] | Validator local input co unit test. |
| TC-AUTH-04 | [x] | Duplicate email co neutral mapping va code-level coverage qua repository/source contract. |
| TC-AUTH-05 | [M] | Trigger failure simulation phu thuoc Supabase SQL/ops. |
| TC-AUTH-06 | [M] | Idempotent bootstrap phu thuoc DB trigger/integrity query. |
| TC-AUTH-07 | [M] | Manual account creation tren Supabase Dashboard. |
| TC-AUTH-08 | [x] | Route resolver unverified -> verify route. |
| TC-AUTH-09 | [~] | Callback page co, manual verification link chua test. |
| TC-AUTH-10 | [~] | Resend cooldown UI co; rate-limit thuc te phu thuoc Supabase manual verify. |
| TC-AUTH-11 | [x] | Route resolver completed -> dashboard/menu. |
| TC-AUTH-12 | [x] | Route resolver pending -> onboarding. |
| TC-AUTH-13 | [x] | Neutral auth error mapping co trong repository va login flow; khong lo technical detail ra UI. |
| TC-AUTH-14 | [x] | AuthGate resolve tu current session/profile. |
| TC-AUTH-15 | [x] | No session -> login co; logout/delete clear session va invalidate user-scoped providers. |
| TC-AUTH-16 | [x] | Missing public profile -> support/retry, no client insert. |
| TC-AUTH-17 | [x] | `last_login_at` failure best-effort, route khong bi block. |
| TC-AUTH-18 | [~] | Mark `in_progress` co; chua fake Supabase unit test rieng. |
| TC-AUTH-19 | [~] | Pending route resume co; partial draft persistence chua mo rong rieng. |
| TC-AUTH-20 | [~] | Completed save co; can manual Supabase verify. |
| TC-AUTH-21 | [~] | V1 validation can chan save; cloud-specific invalid test chua co. |
| TC-AUTH-22 | [~] | Code replace optional collections co; chua unit test rieng. |
| TC-AUTH-23 | [M] | RLS two-account smoke chua chay. |
| TC-AUTH-24 | [x] | Onboarding/profile update existing cloud rows dung current auth UUID, mirror local sau cloud success. |
| TC-AUTH-25 | [x] | Password/email khong ghi public table; password flow dung Supabase Auth. |
| TC-AUTH-26 | [~] | Missing session update profile co safe failure copy; RLS/stale session real can manual Supabase verify. |
| TC-AUTH-27 | [x] | Forgot password page/repository co validation va generic sent state. |
| TC-AUTH-28 | [~] | Recovery callback/reset page co; manual deep link chua test. |
| TC-AUTH-29 | [x] | Confirm password validator co unit test. |
| TC-AUTH-30 | [x] | Password update dung Supabase Auth, khong ghi public password data. |
| TC-AUTH-31 | [x] | SignOut UI + service clear Supabase/local flag va invalidate user-scoped providers. |
| TC-AUTH-32 | [M] | Flutter chi invoke Edge Function; server-side Edge Function/JWT rejection chua verify. |
| TC-AUTH-33 | [M] | Cascade delete phu thuoc Edge Function + DB, chua verify. |
| TC-AUTH-34 | [x] | Flutter khong chua service-role/Admin API delete user. |
| TC-AUTH-35 | [M] | Backfill old users la manual database ops. |

## Tom tat hoan thanh

- Done code/test Flutter chinh: B, C, D code-level va phan lon E.
- Partial: A do manual database pending; E do Edge Function server-side/cascade manual pending; Test/traceability do analyzer nen va manual Supabase chua clean.
- Chua lam trong repo: fake Supabase datasource test chi tiet cho tung TC-AUTH, manual RLS/email/recovery/Edge Function/backfill.
- Manual pending: deploy SQL, integrity query, RLS two-account smoke, email/recovery link, Edge Function delete account.
- Khong lam trong scope nay: quota/entitlement Free/Plus/FamilyPlus day du; `subscription_tier` chi moi la hook doc tu Supabase.

## Lien ket

- Feature: [Authentication V2](001-feature-authentication-v2.md)
- Test: [Test Authentication V2](../../test/authentication/001-test-authentication-v2.md)
- Worklog coding: [Worklog Authentication V2](../../worklog/2026-06-20/002-worklog-authentication-v2.md)
- Worklog auth flow: [Worklog Auth System Flow](../../worklog/2026-06-21/003-worklog-auth-system-flow.md)
