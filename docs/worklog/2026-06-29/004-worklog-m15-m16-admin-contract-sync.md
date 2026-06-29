Commit de xuat: feat(admin): dong bo permission contract admin

# Worklog - M15/M16 Admin Contract Sync

## Thoi gian

- Ngay: 2026-06-29
- Bat dau: 14:02
- Ket thuc: 14:03
- Timezone: Asia/Saigon

## Pham vi

- Loai task: coding
- Module chinh: M15 `ADMIN_DASHBOARD`, M16 `ADMIN_OPS`
- Yeu cau goc: Doc AGENTS.md de lay context va hoan thanh cac chuc nang lien quan module admin.

## Da lam

- Doc context bat buoc: root `AGENTS.md`, `.codex/AGENTS.md`, project map, learned skills, workflow `coding`, task-skill `coding`, domain access/membership/referral, open risks, Supabase README/config/admin SQL, DD/checklist Admin.
- Dong bo permission contract Admin app:
  - `plans` dung `plans.write` thay vi `config.write`.
  - `config` tiep tuc dung `config.write`.
  - Them RPC `admin_list_plan_config_versions` cho plan-scoped config list.
  - Chan dashboard/audit bi goi nhu mutation RPC.
- Dong bo `docs/supabase/config.sql` voi `docs/supabase/12-sale-module-update.sql`: Sale conversion queue dung `sales.write` thay vi stale `payments.write`.
- Bo sung targeted tests cho plan/config permission split, Sale conversion RPC, va read-only mutation guard.
- Cap nhat checklist DD/coding de ghi ro phan da xong va blocker con lai: Q-12/Q-18, Supabase sandbox/RLS/RPC/audit evidence.

## File code/docs da sua

- `lib/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart` - sua - map `plans` sang `plans.write`, them read-only mutation guard.
- `lib/app_versions/admin/features/admin_panel/data/datasources/admin_supabase_datasource.dart` - sua - map `plans` sang `admin_list_plan_config_versions`, chan mutation RPC cho dashboard/audit.
- `test/app_versions/admin/admin_models_test.dart` - sua - them contract tests.
- `docs/supabase/11-admin-access-dashboard.sql` - sua - them plan-scoped list RPC va grant.
- `docs/supabase/config.sql` - sua - dong bo single-file rebuild voi Admin/Sale SQL contract.
- `docs/checklist/checklist_complete_DD.md` - sua - cap nhat M15/M16 progress/evidence.
- `docs/checklist/checklist_task_coding.md` - sua - cap nhat next task va note phien coding.
- `.codex/history/` va `.codex/task-skills/` - generated update - refresh tu worklog moi.

## Tai lieu lien quan

- `.codex/workflows/coding.md`
- `.codex/task-skills/coding.md`
- `.codex/domains/access-membership-referral.md`
- `docs/DD/admin_dashboard/README.md`
- `docs/DD/admin_operations/README.md`
- `docs/supabase/11-admin-access-dashboard.sql`
- `docs/supabase/12-sale-module-update.sql`
- `docs/supabase/config.sql`

## Commands

- `dart format lib/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart lib/app_versions/admin/features/admin_panel/data/datasources/admin_supabase_datasource.dart test/app_versions/admin/admin_models_test.dart`: PASS
- `flutter test test/app_versions/admin`: PASS
- `flutter analyze lib/app_versions/admin test/app_versions/admin`: PASS
- `rg -n "admin_list_plan_config_versions|admin_list_sale_point_conversions|admin_review_sale_point_conversion|sale_point_conversions_select_own|payments\.write|sales\.write|plans\.write|config\.write" docs/supabase/11-admin-access-dashboard.sql docs/supabase/12-sale-module-update.sql docs/supabase/config.sql lib/app_versions/admin test/app_versions/admin`: PASS
- `git diff --check`: PASS
- `powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1`: FAIL - dung o `dart format --set-exit-if-changed .` vi 7 file v1 onboarding/splash ngoai pham vi chua format; cac thay doi format ngoai pham vi do validation tao ra da duoc restore.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS

## Loi/Rui ro

- Da fix:
  - `plans.write` khong con bi map nham sang `config.write` tren client.
  - Plan list co RPC rieng `admin_list_plan_config_versions` dung `plans.write`.
  - Dashboard/audit khong con co mutation RPC mapping.
  - `config.sql` rebuild khong con stale `payments.write` cho Sale conversion queue; da dong bo `sales.write`.
- Chua fix:
  - Chua chot Admin role matrix Q-12 va privacy Q-18.
  - Chua verify Supabase sandbox/RLS/RPC/audit rows.
  - Chua chay duoc quick check full do global format drift ngoai pham vi.
- Can kiem tra tiep:
  - Chay Supabase local/sandbox smoke cho Admin user A/B/role scopes.
  - Kiem tra audit row cho payment, sale profile, sale conversion, config/plan, report export mutations.

## Ty le hoan thanh

- Hoan thanh: Code-side Admin permission/RPC contract sync va targeted validation.
- Dang do: DD acceptance/Admin production readiness van bi chan boi open product questions va sandbox evidence.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - thay doi scoped vao Admin contract, co tests va dong bo `config.sql`.
- Muc do hoan thanh task: hoan thanh phan code co the lam an toan; khong claim full DD acceptance vi Q-12/Q-18 va sandbox con mo.
- Bang chung kiem chung: targeted Admin tests/analyze pass, SQL/Dart `rg` contract check pass, `git diff --check` pass.
- Diem ton token/chua toi uu: quick check toan repo tao format side-effect ngoai pham vi; lan sau nen chay targeted format check truoc khi quick check hoac biet truoc repo co global format drift.
- Cach toi uu cho phien sau: bat dau tu M15/M16 checklist + `docs/supabase/08-acceptance-checks.md`, sau do chay Supabase sandbox smoke neu moi truong san sang.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
