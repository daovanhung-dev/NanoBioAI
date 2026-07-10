Commit de xuat: fix(auth): khong chan dang nhap khi dong bo cloud loi

# Fixbug - Auth login sync failure

## Tom tat

- Log local cho thay Auth sign-in tra ve 200 cho cac tai khoan seed, nhung
  REST/RPC sau dang nhap tra ve 503 khi PostgREST container khong chay.
- App dang coi loi dong bo cloud sau Auth nhu loi dang nhap, lam nguoi dung
  thay "khong the dang nhap" du sign-in da thanh cong.
- Seed `auth.users` con phu thuoc viec sua thu cong cac cot token null, co
  the lam Auth login fail sau rebuild Supabase moi.

## Nguyen nhan

- `AuthController` await `_syncAfterAuth` trong cac flow build/refresh/sign-in
  va rethrow loi tu cloud sync/RPC.
- Dev seed chen user Auth ma chua dam bao cac cot token text cua Supabase Auth
  khong null trong moi truong local/sandbox hien tai.
- Admin login chua tach ro truong hop Auth thanh cong nhung tai khoan khong co
  role Admin hoat dong.

## Cach sua

- Doi post-auth sync trong `AuthController` thanh best-effort: log warning/error
  nhung khong rethrow, de Auth sign-in thanh cong khong bi bien thanh loi login.
- Them translator loi Supabase Auth dung chung cho v2 auth va admin login, voi
  thong diep nguoi dung bang tieng Viet.
- Admin login kiem tra `get_my_admin_session` ngay sau Auth sign-in; neu khong
  co quyen Admin thi sign out va hien thong bao dung nguyen nhan.
- Cap nhat `docs/supabase/config.sql` va seed dev membership de set/coalesce cac
  cot token Auth ve chuoi rong, kem guard `DEV_AUTH_SEED_TOKEN_COLUMNS_NULL`.

## Kiem chung

- Supabase local: apply `docs/supabase/config.sql` thanh cong.
- SQL local: so user co token Auth null = 0.
- Local REST/Auth:
  - `dev.free@nanobio.local`: LOGIN_OK, PROFILE_OK.
  - `dev.plus@nanobio.local`: LOGIN_OK, PROFILE_OK.
  - `dev.family@nanobio.local`: LOGIN_OK, PROFILE_OK.
  - `dev.admin@nanobio.local`: LOGIN_OK, PROFILE_OK, ADMIN_RPC_OK.
- Regression test: `auth_controller_sync_failure_test.dart` dam bao sync/RPC loi
  khong lam `signInWithEmail` fail khi Auth da thanh cong.

## Luu y

- Loi 503 trong log local den tu viec chay Supabase stack thieu PostgREST trong
  lan kiem tra dau; day la loi ha tang local, nhung app van can xu ly mem de
  khong khoa dang nhap khi dong bo sau Auth gap su co.
