Commit de xuat: feat(admin): hoan thien M15-M19 theo policy da chot

# Worklog - M15-M19 Admin Selected Policy

## Thoi gian

- Ngay: 2026-06-29
- Bat dau: 14:00
- Ket thuc: 14:46
- Timezone: Asia/Saigon

## Pham vi

- Loai task: coding + Supabase schema draft + tests + DD/checklist docs
- Module chinh: M15 ADMIN_DASHBOARD, M16 ADMIN_OPS, M17 RECONCILIATION, M18 REPORTING, M19 AUDIT_SECURITY
- Yeu cau goc: Implement revised plan theo Q-05/Q-10/Q-12/Q-13/Q-16/Q-17/Q-18 da duoc user chot.

## Da lam

- Admin runtime: them `reconciliation` section/route/nav/RPC mapping, dashboard metric drill-down, timezone default `Asia/Ho_Chi_Minh`, full active-Admin wildcard access policy, status-aware work queue actions, and manual point-adjustment RPC mapping.
- Supabase draft: cap nhat `11-admin-access-dashboard.sql` va `config.sql` cho full Admin roles, manual payment approval, 24h refund/cancel window, 24h Sale point hold, no-new-points cho Sale suspended/closed, audited point adjustment, and reconciliation run/list/classify RPCs.
- Sale SQL: cap nhat commission records `available_at` va conversion availability de Sale chi dung diem sau 24h.
- Docs/checklists: cap nhat DD M15-M19 selected-policy status/ADR, Supabase acceptance/RLS notes, DD progress checklist va coding next tasks.
- Tests: cap nhat Admin model/controller tests va Supabase SQL contract tests theo selected policy.

## File code/docs da sua

- `lib/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart` - sua - them reconciliation, timezone, target section, point permission/payload.
- `lib/app_versions/admin/features/admin_panel/data/datasources/admin_supabase_datasource.dart` - sua - them timezone param, reconciliation RPC, point-adjustment RPC.
- `lib/app_versions/admin/features/admin_panel/presentation/controllers/admin_controller.dart` - sua - dashboard dung `Asia/Ho_Chi_Minh`.
- `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_shell_page.dart` - sua - nav/action/status/drill-down UI.
- `lib/app_versions/admin/router/*` - sua - route `/admin/reconciliation`.
- `docs/supabase/05-sale-referral-commission.sql`, `11-admin-access-dashboard.sql`, `12-sale-module-update.sql`, `config.sql` - sua - Supabase selected policy draft/rebuild sync.
- `docs/supabase/06-rls-policy-matrix.md`, `08-acceptance-checks.md` - sua - acceptance/RLS policy notes.
- `docs/DD/admin_dashboard/`, `docs/DD/admin_operations/`, `docs/DD/reconciliation/`, `docs/DD/reporting/`, `docs/DD/audit_security/` - sua - selected-policy status/ADR notes.
- `docs/checklist/checklist_complete_DD.md`, `docs/checklist/checklist_create_DD.md`, `docs/checklist/checklist_task_coding.md` - sua - progress and next tasks.
- `test/app_versions/admin/*`, `test/docs/supabase_*_contract_test.dart` - sua - targeted coverage for policy changes.

## Tai lieu lien quan

- `docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md`
- `docs/supabase/README.md`
- `docs/checklist/checklist_complete_DD.md`
- `docs/checklist/checklist_task_coding.md`

## Commands

- `dart format ...`: PASS - formatted touched Dart/test files only.
- `dart analyze lib/main_admin.dart lib/app_versions/admin test/app_versions/admin test/docs/supabase_admin_contract_test.dart test/docs/supabase_config_contract_test.dart`: PASS - no issues found.
- `flutter test test/app_versions/admin test/docs/supabase_admin_contract_test.dart test/docs/supabase_config_contract_test.dart`: PASS - all 36 tests passed.
- `git diff --check`: PASS - no whitespace errors; Windows CRLF warnings only.

## Loi/Rui ro

- Da fix: Q-05/Q-10/Q-12/Q-13/Q-16/Q-17/Q-18 selected policy da duoc encode vao runtime, SQL draft, docs, and tests.
- Chua fix: chua chay Supabase sandbox/staging SQL/RPC/RLS/audit smoke; provider/chargeback-specific production contract van can evidence rieng.
- Can kiem tra tiep: run sandbox acceptance for payment approval, 24h hold, conversion reject under hold, refund/cancel >24h, suspended/closed Sale no-new-points, reconciliation adjustment, and audit row completeness.

## Ty le hoan thanh

- Hoan thanh: Local runtime/SQL draft/docs/tests for selected Admin M15-M19 policy.
- Dang do: Sandbox/staging verification and production migration review.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - code, SQL, docs, and tests were updated together and targeted checks pass.
- Muc do hoan thanh task: selected-policy implementation complete locally; not production-ready without sandbox evidence.
- Bang chung kiem chung: targeted analyze, targeted Flutter tests, and `git diff --check` all pass.
- Diem ton token/chua toi uu: SQL module/config mirroring consumed time; next session should use focused `rg` anchors and contract tests first.
- Cach toi uu cho phien sau: run sandbox SQL acceptance from the checklist before broad DD edits.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
