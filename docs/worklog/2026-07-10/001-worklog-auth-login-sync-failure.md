Commit de xuat: docs(worklog): ghi nhan phien fix auth login sync failure

# Worklog - Fix auth login sync failure

## Thoi gian

- Ngay: 2026-07-10
- Bat dau: 13:00
- Ket thuc: 14:00
- Timezone: Asia/Saigon

## Pham vi

- Loai task: bugfix
- Module chinh: v2 authentication, admin login, Supabase dev seed
- Yeu cau goc: Doc log va fix bug khong the dang nhap.

## Da lam

- Doc log local va xac dinh Auth sign-in tra ve 200, nhung REST/RPC sau dang
  nhap tra 503 khi PostgREST container khong chay.
- Sua `AuthController` de dong bo cloud sau Auth la best-effort, khong rethrow
  loi sync/RPC vao flow dang nhap.
- Them `SupabaseAuthErrorTranslator` de gom nhom loi Auth va hien thong diep
  dang nhap cu the hon.
- Sua admin login de phan biet Auth sai, RPC quyen admin loi, va Auth thanh cong
  nhung khong co role Admin hoat dong.
- Cap nhat Supabase dev seed trong `config.sql` va
  `09-dev-seed-membership-test-accounts.sql` de cac cot token Auth khong null va
  co guard bat loi seed.
- Them/cap nhat regression tests cho translator, admin login, Auth sync failure
  va Supabase seed contract.
- Tao tai lieu fixbug `docs/fixbug/auth-login-sync-failure/001-fixbug-auth-login-sync-failure.md`.

## File code/docs da sua

- `lib/app_versions/v2/features/auth/presentation/controllers/auth_controller.dart` - sua - khong chan dang nhap khi sync cloud loi sau Auth.
- `lib/services/supabase/auth/supabase_auth_error_translator.dart` - tao - chuan hoa thong diep loi Supabase Auth.
- `lib/app_versions/v2/features/auth/data/repositories/supabase_auth_repository.dart` - sua - dung translator moi.
- `lib/app_versions/v2/features/auth/domain/entities/auth_failure.dart` - sua - them failure code can thiet.
- `lib/app_versions/admin/features/admin_panel/presentation/controllers/admin_controller.dart` - sua - kiem tra role Admin sau Auth sign-in.
- `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_login_page.dart` - sua - hien loi login cu the.
- `docs/supabase/config.sql` - sua - seed token Auth non-null va guard.
- `docs/supabase/09-dev-seed-membership-test-accounts.sql` - sua - seed token Auth non-null va guard.
- `test/app_versions/v2/features/auth/auth_controller_sync_failure_test.dart` - tao - regression sync failure khong chan dang nhap.
- `test/services/supabase/auth/supabase_auth_error_translator_test.dart` - tao - test map loi Auth.
- `test/app_versions/admin/admin_controller_test.dart` - sua - test Auth thanh cong nhung khong co role Admin.
- `test/docs/supabase_config_contract_test.dart` - sua - contract seed token va mobile sync hotfix hien tai.
- `test/docs/supabase_dev_seed_membership_test.dart` - sua - contract seed token.
- `docs/fixbug/auth-login-sync-failure/001-fixbug-auth-login-sync-failure.md` - tao - tom tat fixbug.

## Tai lieu lien quan

- `.codex/workflows/bugfix.md`
- `.codex/task-skills/bugfix.md`
- `.codex/domains/access-membership-referral.md`
- `docs/supabase/README.md`

## Commands

- `psql ... -f docs/supabase/config.sql`: PASS - apply local rebuild config.
- `select count(*) from auth.users where ... token is null`: PASS - ket qua 0.
- Local Auth/REST smoke qua Kong: PASS - 4 dev users login/profile OK, admin RPC OK.
- `flutter test test/docs/supabase_config_contract_test.dart test/docs/supabase_dev_seed_membership_test.dart`: PASS.
- `flutter test test/services/supabase/auth/supabase_auth_error_translator_test.dart test/app_versions/admin/admin_controller_test.dart test/app_versions/v2/features/auth/auth_pages_smoke_test.dart test/app_versions/v2/features/auth/auth_validators_test.dart`: PASS.
- `flutter test test/app_versions/v2/features/auth/auth_controller_sync_failure_test.dart`: PASS.
- `dart analyze ...`: PASS - targeted changed Dart/test files.
- `flutter test test/app_versions/v2/features/auth/auth_controller_sync_failure_test.dart test/app_versions/v2/features/auth/auth_pages_smoke_test.dart test/app_versions/v2/features/cloud_sync/authenticated_user_data_sync_repository_test.dart`: PASS.

## Loi/Rui ro

- Da fix: Auth success khong con bi bien thanh login failure khi post-auth sync/RPC loi; seed Supabase local khong can update thu cong token null.
- Chua fix: Khong thay doi ha tang Supabase neu PostgREST bi stop/exclude; app chi xu ly mem phan sync sau Auth.
- Can kiem tra tiep: Sandbox/staging Supabase theo risk NB-RISK-001 neu muon claim production-ready.

## Ty le hoan thanh

- Hoan thanh: Fix code, seed SQL, regression tests, local Supabase verification.
- Dang do: Chua chay full native build vi scope bugfix khong yeu cau.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - fix dung root cause tu log, co regression test va local REST/Auth smoke.
- Muc do hoan thanh task: hoan thanh bug dang nhap local/dev va thong diep loi lien quan.
- Bang chung kiem chung: SQL token count 0, 4 tai khoan dev LOGIN_OK/PROFILE_OK, admin RPC OK, targeted tests/analyze PASS.
- Diem ton token/chua toi uu: Mot so context Supabase va diff doc dai; lan sau nen doc router, workflow, domain truoc khi mo diff rong.
- Cach toi uu cho phien sau: Dung script smoke local co redact key ngay tu dau de tranh lap lai buoc lay key.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
