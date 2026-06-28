Commit de xuat: feat(admin): tao Admin app surface va Supabase draft

# Worklog - Admin App Surface Va Supabase Admin

## Thoi gian

- Ngay: 2026-06-28
- Bat dau: 08:27
- Ket thuc: 08:27
- Timezone: Asia/Saigon (+07:00)

## Pham vi

- Loai task: coding + Supabase schema draft + test/docs
- Module chinh: Admin app, Supabase Admin, Sale direct-only
- Yeu cau goc: Tao Admin co cau truc rieng nhu v1/v2/v3 va tao SQL Supabase Admin trong `docs/supabase`.

## Da lam

- Tao `lib/main_admin.dart` va `lib/app_versions/admin/` gom app, router, Clean Architecture feature Admin panel.
- Tao Admin dashboard shell voi route `/admin/*`, navigation rail, login, dashboard metrics, section lists va dialog reason bat buoc cho mutation.
- Tao datasource/repository/provider/controller goi Supabase RPC, khong goi raw Supabase client tu widget/controller.
- Tao `docs/supabase/11-admin-access-dashboard.sql` voi Admin roles, permissions, audit, config/report tables va RPC Admin.
- Chuyen Sale/Supabase commission sang direct-only 10%, bo second-level/5% trong runtime, SQL draft va acceptance docs.
- Cap nhat architecture test, Admin/Supabase contract tests va Sale calculator tests.

## File code/docs da sua

- `lib/main_admin.dart` - tao - Admin entrypoint rieng.
- `lib/app_versions/admin/` - tao - Admin app/router/feature Clean Architecture.
- `lib/sale_referral/` va `lib/services/supabase/sale/` - sua - Sale direct-only 10%.
- `docs/supabase/05-sale-referral-commission.sql` - sua - commission direct-only.
- `docs/supabase/11-admin-access-dashboard.sql` - tao - Admin SQL/RPC draft.
- `docs/supabase/*.md`, `docs/supabase/07-seed-reference-data.sql`, `docs/supabase/10-mobile-sync-and-sale-rpc.sql` - sua - Admin/direct-only docs.
- `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md` - sua - them Admin source/Supabase draft route.
- `test/app_versions/admin/admin_models_test.dart` - tao - Admin domain mapper test.
- `test/docs/supabase_admin_contract_test.dart` - tao - SQL/direct-only contract test.
- `test/architecture_version_boundary_test.dart` - sua - Admin boundary checks.

## Tai lieu lien quan

- `.codex/workflows/coding.md`
- `.codex/workflows/supabase-schema.md`
- `.codex/domains/access-membership-referral.md`
- `docs/DD/admin_dashboard/`
- `docs/DD/admin_operations/`
- `docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md`

## Commands

- `dart format ...`: PASS - formatted touched Dart files.
- `flutter analyze lib/main_admin.dart lib/app_versions/admin lib/sale_referral lib/services/supabase/sale test/app_versions/admin test/docs/supabase_admin_contract_test.dart test/sale_referral/domain/services/sale_commission_calculator_test.dart test/architecture_version_boundary_test.dart`: PASS.
- `flutter test test/app_versions/admin/admin_models_test.dart test/docs/supabase_admin_contract_test.dart test/sale_referral/domain/services/sale_commission_calculator_test.dart test/architecture_version_boundary_test.dart`: PASS.
- `git diff --check`: PASS - CRLF warnings only.
- `powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1`: FAIL - repo-wide `dart format --set-exit-if-changed .` found/rewrote 22 pre-existing unformatted files outside task before analyze/test could run; those formatter-only changes were reverted.

## Loi/Rui ro

- Da fix: Sale runtime/Supabase draft khong con second-level/5%.
- Chua fix: Supabase SQL chua chay tren sandbox/staging; chi la draft review.
- Can kiem tra tiep: Full `codex_quick_check` after repo-wide formatting is handled; Edge Function/payment provider thuc te chua co trong repo.

## Ty le hoan thanh

- Hoan thanh: Admin app scaffold/runtime RPC contract, SQL draft, direct-only Sale migration draft, targeted validation.
- Dang do: Sandbox/staging Supabase verification va provider webhook production.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - co runtime, SQL draft, tests va context update.
- Muc do hoan thanh task: cao voi pham vi repo; chua claim production migration.
- Bang chung kiem chung: targeted analyze/test PASS, `git diff --check` PASS; quick check blocked by repo-wide format drift outside task.
- Diem ton token/chua toi uu: patch file co encoding mojibake ton nhieu buoc; lan sau nen rewrite cac docs nho bi mojibake som hon.
- Cach toi uu cho phien sau: doc/ghep DD Admin Ops + Supabase direct-only truoc, sau do tach patch runtime va docs thanh cac cum nho.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
