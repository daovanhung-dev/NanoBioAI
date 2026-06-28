Commit de xuat: feat(sale): hoan thien Sale repo-ready M12 M14

# Worklog - Sale Repo-Ready M12 M14

## Thoi gian

- Ngay: 2026-06-28
- Bat dau: trong phien Codex hien tai
- Ket thuc: 2026-06-28 21:01:19 +07:00
- Timezone: Asia/Saigon (+07:00)

## Pham vi

- Loai task: coding + test + docs-context
- Module chinh: M12 `REFERRAL_DIRECT`, M14 `SALE_POINTS`
- Yeu cau goc: Implement plan hoan thanh Sale repo-ready: Sale dashboard/ledger/conversion request, Admin conversion queue, Supabase/docs contract, tests, checklist/worklog.

## Da lam

- Xac nhan Sale/Admin baseline da co route/RPC cho Admin `saleConversions` va SQL 12 dung `sales.write`; bo sung tests de khoa contract nay.
- Don cleanup Sale UI sau khi local commission estimator da duoc go: bo parameter `emphasized` khong con dung trong `_EstimateLine`, giu Sale UI chi hien trusted RPC data.
- Mo rong Sale widget tests cho pending/suspended/closed state, active dashboard, conversion disabled/enabled, duplicate submit guard, failed retry giu cung idempotency key, va estimator local khong con hien.
- Mo rong repository tests cho conversion request mapping va idempotency key passthrough.
- Mo rong Admin tests cho `saleConversions` list/review RPC mapping, params `p_conversion_id`, action `mark_paid`, va route `/admin/sale-conversions`.
- Mo rong Supabase contract tests cho conversion review permission `sales.write`, admin conversion RPC, revoke direct client writes, va direct-only/no second-level markers.
- Cap nhat checklist M12/M14 len coding progress 80, giu DD readiness 40 va `Draft` vi sandbox/staging va financial open questions chua dong.
- Cap nhat RLS/acceptance docs de Admin conversion queue dung `sales.write`, khong ghi bang truc tiep tu Flutter.

## File code/docs da sua

- `lib/sale_referral/presentation/pages/sale_shell_page.dart` - sua - cleanup UI helper sau khi estimator local khong con dung.
- `test/sale_referral/presentation/sale_shell_page_test.dart` - sua - bo sung Sale UI state/conversion/idempotency coverage.
- `test/sale_referral/data/sale_repository_impl_test.dart` - sua - bo sung conversion/idempotency repository coverage.
- `test/app_versions/admin/admin_models_test.dart` - sua - bo sung Admin sale conversion queue route/RPC param coverage.
- `test/docs/supabase_admin_contract_test.dart` - sua - bo sung Supabase Sale conversion contract tests.
- `docs/supabase/06-rls-policy-matrix.md` - sua - ghi conversion queue doc theo `sales.write`.
- `docs/supabase/08-acceptance-checks.md` - sua - ghi acceptance conversion queue theo `sales.write`.
- `docs/checklist/checklist_complete_DD.md` - sua - cap nhat M12/M14 coding progress va next steps.
- `docs/checklist/checklist_task_coding.md` - sua - ghi note phien Sale repo-ready.
- `docs/worklog/2026-06-28/007-worklog-sale-repo-ready.md` - tao - ghi nhan phien.

## Tai lieu lien quan

- `docs/DD/referral_direct/`
- `docs/DD/sale_points/`
- `docs/supabase/12-sale-module-update.sql`
- `docs/checklist/checklist_complete_DD.md`
- `docs/checklist/checklist_task_coding.md`

## Commands

- `flutter analyze lib\sale_referral lib\services\supabase\sale lib\app_versions\admin test\sale_referral test\app_versions\admin test\docs\supabase_admin_contract_test.dart`: PASS - no issues found.
- `flutter test test/sale_referral test/app_versions/admin test/docs/supabase_admin_contract_test.dart`: PASS - all targeted Sale/Admin/docs tests passed.
- `rg -n "secondLevel|second-level|second_level|0\.0500|level = 2|5% tang 2|5% tầng 2|Uoc tinh diem Sale|Gia tri payment hop le|So payment truc tiep" docs\supabase lib\sale_referral lib\services\supabase\sale`: PASS - no runtime/docs matches.
- `git diff --check`: PASS - CRLF warnings only.

## Loi/Rui ro

- Da fix: Sale UI khong con helper parameter thua sau khi local estimator bi go; targeted analyze sach.
- Da fix: Tests khoa conversion request/idempotency retry va Admin sale-conversion RPC mapping.
- Chua fix: SQL 12 chua chay tren Supabase sandbox/staging; khong claim production-ready.
- Chua fix: Payout provider, tax/invoice, refund/chargeback, reconciliation policy va Q-02..Q-10/Q-13 van open theo DD.
- Can kiem tra tiep: Sandbox smoke user A/B/Admin cho request Sale, approve/reject/suspend, attach referral code, request/review conversion, RLS cross-user.

## Ty le hoan thanh

- Hoan thanh: Repo-ready cho M12/M14 trong pham vi app/Admin/RPC contract/tests/docs.
- Dang do: Production readiness bi chan boi sandbox evidence va financial/product open questions.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - targeted tests va docs/checklist trace ro trang thai repo-ready vs production-ready.
- Muc do hoan thanh task: hoan thanh theo assumption repo-ready.
- Bang chung kiem chung: targeted analyze/test PASS, grep guard PASS, diff-check PASS.
- Diem ton token/chua toi uu: mot so phan Admin/SQL da co san trong baseline nen can phan biet code delta voi verification evidence.
- Cach toi uu cho phien sau: chay Supabase sandbox verification truoc khi code them policy tai chinh.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`, `.codex/task-skills/supabase-schema.md`
