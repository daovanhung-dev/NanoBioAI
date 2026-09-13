Commit de xuat: feat(supabase): tu dong chuyen membership het han ve free

# Worklog - Membership expiration reconciliation

## Thoi gian

- Ngay: 2026-09-13
- Bat dau: 20:30
- Ket thuc: 20:55
- Timezone: Asia/Ho_Chi_Minh (UTC+07:00)

## Pham vi

- Loai task: Implement feature tren canonical Supabase schema va tai lieu van hanh.
- Module chinh: M06/M13 membership, quota va access reconciliation.
- Yeu cau goc: Khi subscription het han, tu dong danh dau `expired` va dong bo nguoi dung ve `free`; cap lai goi moi phai khoi phuc dung plan.

## Da lam

- Bat buoc extension `pg_cron`; canonical rebuild fail-fast neu scheduler khong co.
- Tao `public.expire_membership_subscriptions()` bang `security definer`, tra ve so dong vua het han, chi xu ly `trialing`/`active`/`past_due` co `ends_at <= now()`.
- Giu nguyen `ends_at`, subscription vinh vien va `canceled`; thao tac idempotent va kich hoat trigger dong bo membership hien co.
- Revoke quyen client, chi grant execute cho `service_role`; owner/cron van thuc thi duoc.
- Dang ky job `nanobio-expire-memberships` moi 5 phut, unschedule moi job cung ten truoc khi tao lai, va fail-fast assertion cho extension/function/quyen/job active.
- Cap nhat README, checklist, static contract test va smoke fixture rollback-only.
- Khong thay doi seed root Admin, payment flow, RPC cap goi, RPC dieu chinh thoi han hay logic `current_plan_for_user()`/`effective_user_access`.

## File code/docs da sua

- `docs/supabase/01_build_system.sql` - them extension, function het han, pg_cron registration va assertions.
- `docs/supabase/README.md` - ghi ro dependency, chu ky toi da 5 phut, quyen va cach kiem tra job.
- `docs/checklist/checklist_task_coding.md` - them handoff verification cho M06/M13.
- `docs/checklist/checklist_complete_DD.md` - cap nhat boundary/evidence cua membership.
- `test/docs/supabase_membership_expiration_contract_test.dart` - static contract test.
- `test/docs/fixtures/supabase_membership_expiration_smoke.sql` - smoke rollback-only cho expiry, plan peer, permanent, canceled va cap lai goi.
- `docs/worklog/2026-09-13/010-worklog-membership-expiration.md` - worklog phien nay.

## Tai lieu lien quan

- `.codex/workflows/supabase-schema.md`
- `.codex/task-skills/supabase-schema.md`
- `.codex/domains/access-membership-referral.md`
- `docs/supabase/README.md`
- `test/docs/fixtures/supabase_membership_expiration_smoke.sql`

## Commands

- `git diff --check`: PASS.
- Targeted `grep` contract checks cho function, filter, privilege, pg_cron, schedule va smoke tokens: PASS.
- `dart test test/docs/supabase_membership_expiration_contract_test.dart`: SKIPPED - executable `dart` khong co trong moi truong.
- `flutter test test/docs/supabase_membership_expiration_contract_test.dart`: SKIPPED - executable `flutter` khong co trong moi truong.
- `pg_isready` PASS nhung `psql` read-only probe SKIPPED - local PostgreSQL tu choi peer auth cho `postgres` va role mac dinh `daovanhung` khong ton tai; chua xac dinh duoc database disposable co `pg_cron`.
- Apply canonical SQL va runtime smoke: SKIPPED - khong co Supabase local/container disposable; khong chay rebuild tren staging/production.
- `pwsh ... validate_codex_integrity.ps1`: FAIL baseline - thieu `docs/audit/source_truth_manifest.json` va stale paths trong history/task-skill; khong phat sinh tu feature nay.

## Loi/Rui ro

- Da fix: cron rebuild idempotent theo ten; scheduler va privilege boundary duoc fail-fast assertion; smoke fixture rollback-only de khong de lai du lieu test.
- Chua fix: chua co runtime evidence tren sandbox co `pg_cron`; open risk `NB-RISK-001` van con hieu luc.
- Can kiem tra tiep: apply `01_build_system.sql` voi `psql -v ON_ERROR_STOP=1`, chay smoke fixture, kiem tra `cron.job`, va chay Dart contract test khi toolchain/sandbox san sang.

## Ty le hoan thanh

- Hoan thanh: implementation SQL canonical, scheduler contract, docs/checklist, static contract test, rollback smoke fixture va diff validation.
- Dang do: runtime Supabase/pg_cron smoke va Dart/Flutter test do thieu moi truong; chua claim production readiness.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - da bao ve ca access hieu luc tuc thoi va dong bo cac cot luu, giu nguyen lich su, quyen client va kha nang cap lai goi.
- Muc do hoan thanh task: hoan tat implementation trong pham vi; runtime acceptance con pending theo dung risk boundary.
- Bang chung kiem chung: `git diff --check` va targeted static contract checks PASS; Dart/Flutter va Supabase runtime SKIPPED do thieu toolchain/database disposable.
- Diem ton token/chua toi uu: phai doc nhieu context Supabase de tranh thay doi sai trigger/permission; `rg` khong co trong image nen dung `grep` fallback.
- Cach toi uu cho phien sau: chuan bi sandbox co `pg_cron`, role postgres/service-role va Flutter toolchain; chay integration fixture rollback thay cho static-only verification.
- Task-skill can doc lan sau: `.codex/task-skills/supabase-schema.md`
