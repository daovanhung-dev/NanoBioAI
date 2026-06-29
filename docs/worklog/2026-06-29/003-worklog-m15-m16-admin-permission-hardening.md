Commit de xuat: feat(admin): harden permission states

# Worklog - M15/M16 Admin Permission Hardening

## Thoi gian

- Ngay: 2026-06-29
- Timezone: Asia/Saigon (+07:00)

## Pham vi

- Loai task: coding + tests + checklist.
- Module chinh: M15 `ADMIN_DASHBOARD`, M16 `ADMIN_OPS`.
- Yeu cau goc: implement safe coding slice cho Admin permission/error-state hardening theo `docs/checklist/checklist_task_coding.md`.

## Da lam

- Them Admin permission helpers trong domain: wildcard, section permission, mutation permission, `canAccessSection`, `canRunMutation`.
- Map section theo RPC hien co: dashboard `dashboard.read`, users `users.write`, payments `payments.write`, sales/saleConversions `sales.write`, reports `reports.write`, audit `audit.read`, plans/config list `config.write`.
- Admin controller khong goi list/mutation RPC khi active Admin thieu permission; state tra ve `deniedPermission` va safe message.
- Admin UI filter navigation shortcuts/actions theo permission va hien permission-denied panel khi route truc tiep vao section khong du quyen.
- Them controller tests voi fake repository va mo rong model/docs contract tests cho role/permission matrix draft.
- Cap nhat checklist M15/M16: coding progress giu 60 vi Q-12/Q-18 va sandbox verification chua dong.

## File code/docs da sua

- `lib/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart` - sua - permission helpers.
- `lib/app_versions/admin/features/admin_panel/presentation/controllers/admin_controller.dart` - sua - permission guard/error state.
- `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_shell_page.dart` - sua - UI filtering va denied state.
- `test/app_versions/admin/admin_models_test.dart` - sua - role-style permission coverage.
- `test/app_versions/admin/admin_controller_test.dart` - tao - controller permission guard tests.
- `test/docs/supabase_admin_contract_test.dart`, `test/docs/supabase_config_contract_test.dart` - sua - draft role matrix contract coverage.
- `docs/checklist/checklist_complete_DD.md`, `docs/checklist/checklist_task_coding.md` - sua - progress va blockers.

## Commands

- `dart format lib\app_versions\admin\features\admin_panel\domain\entities\admin_models.dart lib\app_versions\admin\features\admin_panel\presentation\controllers\admin_controller.dart lib\app_versions\admin\features\admin_panel\presentation\pages\admin_shell_page.dart test\app_versions\admin\admin_models_test.dart test\app_versions\admin\admin_controller_test.dart test\docs\supabase_admin_contract_test.dart test\docs\supabase_config_contract_test.dart`: PASS.
- `flutter analyze lib/main_admin.dart lib/app_versions/admin test/app_versions/admin test/docs/supabase_admin_contract_test.dart test/docs/supabase_config_contract_test.dart`: PASS.
- `flutter test test/app_versions/admin test/docs/supabase_admin_contract_test.dart test/docs/supabase_config_contract_test.dart`: PASS.

## Loi/Rui ro

- Chua chot Q-12 role matrix va Q-18 privacy; khong claim DD ready/production-ready.
- `plans.write` vs `config.write` dang la matrix gap: SQL upsert co nhanh `plans.write`, list config/plans dung `config.write`, va seed role chua gan `plans.write`.
- Chua chay Supabase sandbox/staging SQL/RPC/RLS/audit smoke; khong chay `config.sql` trong phien nay vi la destructive sandbox rebuild script.

## Ty le hoan thanh

- Hoan thanh: repo-level Admin permission/error-state hardening va targeted tests.
- Dang do: policy approval, sandbox verification, audit evidence per operation.
