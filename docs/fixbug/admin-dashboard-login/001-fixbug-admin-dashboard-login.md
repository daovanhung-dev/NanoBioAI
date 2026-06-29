Commit de xuat: fix(admin): sua dashboard admin khong tai sau login

# Fixbug - Admin Dashboard Login Blocker

## Mo ta

- Sau khi dang nhap thanh cong bang tai khoan Admin hop le, app vao
  `/admin/dashboard` nhung hien man hinh "Chua tai duoc khu quan tri".
- UI roi vao nhanh `AsyncValue.error`, khac voi nhanh tai khoan khong co quyen
  Admin.

## Nguyen nhan

- `AdminController` tai dashboard theo thu tu:
  1. goi `get_my_admin_session`;
  2. neu session la Admin hop le, goi `get_admin_dashboard_summary`.
- RPC `get_admin_dashboard_summary` la PL/pgSQL `returns table (... status
  text, ...)`.
- Trong than function, cac dieu kien metric dung `where status = ...`,
  `created_at`, `amount_cents`, `available_at` khong qualify bang alias bang.
- PostgreSQL co the xem `status` la output column cua function thay vi cot bang
  nguon, lam RPC dashboard nem loi sau khi session Admin da hop le.

## Cach sua

- Giu nguyen RPC signature `get_admin_dashboard_summary(timestamptz,
  timestamptz, text, text)`.
- Cap nhat `docs/supabase/11-admin-access-dashboard.sql` va
  `docs/supabase/config.sql`:
  - `public.payment_events pe`: dung `pe.status`, `pe.created_at`.
  - `public.sale_profiles sp`: dung `sp.status`.
  - `public.commission_records cr`: dung `cr.status`, `cr.amount_cents`,
    `cr.available_at`, `cr.created_at`.
- Khong doi Flutter controller/router/login UI vi loi nam o RPC dashboard.

## Kiem chung

- `flutter test test/app_versions/admin test/docs/supabase_admin_contract_test.dart test/docs/supabase_config_contract_test.dart`: PASS.
- `git diff --check`: PASS.
- `powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1`:
  FAIL tai buoc `dart format --set-exit-if-changed .` vi formatter phat hien
  drift ngoai pham vi trong cac file onboarding/splash va untracked
  `lib/app_versions/admin/core/admin_logger.dart`.

## Luu y trien khai

- Can ap dung SQL function da cap nhat vao Supabase local/dev/staging dang chay.
  Chi sua repo file khong tu dong thay doi database dang active.
- Sau khi apply SQL, kiem tra:
  - Tai khoan Admin hop le vao duoc dashboard.
  - Tai khoan da dang nhap nhung khong co role Admin van thay man hinh khong co
    quyen Admin.
