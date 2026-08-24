Commit de xuat: docs(supabase): gom rebuild local sandbox thanh hai script

# Worklog - Supabase two-script consolidation

## Thoi gian

- Ngay: 2026-08-24
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: Supabase schema/seed consolidation, tooling, contract test va docs.
- Module chinh: local/sandbox rebuild, membership/payment fixtures, Daily Health Hub, Storage runtime va M31 Sleep Safety.
- Yeu cau goc: chi giu hai file SQL `01_build_system.sql` va `02_seed_data.sql` trong `docs/supabase/`.

## Da lam

- Gop schema, RLS, RPC, Storage runtime, M31 rollout va fail-fast system checks vao `01_build_system.sql`.
- Gop destructive Auth reset, catalog 163 mon an, toan bo fixture, fail-fast seed checks va VietQR rollback smoke vao `02_seed_data.sql`.
- Dat runtime RPC manifest sau M31 va bao gom hai RPC SafetyContact ma Flutter goi truc tiep.
- Xoa numbered SQL/config generator cu; cap nhat tooling, contract test, README, DD/checklist va source-truth guidance sang hop dong hai script.
- Bao ve khu vuc meal catalog bang marker de tool dong bo khong xoa validation/rollback suffix.

## File code/docs da sua

- `docs/supabase/01_build_system.sql` - tao - system rebuild va assertion runtime.
- `docs/supabase/02_seed_data.sql` - tao - seed/fixture va assertion data.
- `docs/supabase/*.sql` cu va `config.sql` - xoa - bo contract numbered/generated.
- `tools/` va `test/docs/` - sua - dung hai source SQL va marker catalog moi.
- `.codex/`, `docs/README.md`, DD/checklist hien hanh, `SHA256SUMS.txt` - sua - dong bo huong dan va source truth.

## Commands

- `python3 tools/sync_meal_catalog_sql.py --check`: PASS.
- `python3 tools/validate_meal_sync.py`: PASS.
- `python3 tools/audit_supabase_runtime_contract.py`: PASS.
- `python3 .codex/tools/update_worklog_learning.py --check`: PASS sau khi refresh worklog.
- `python3 tools/validate_docs_source_truth.py`: BLOCKED - chi thieu `docs/audit/source_truth_manifest.json` da khong co tu HEAD.
- `git diff --check`: PASS.
- `dart` / `flutter` focused contract tests: SKIPPED - khong co tren PATH trong moi truong hien tai.
- Supabase local/sandbox execution: UNVERIFIED - khong co `psql`/Supabase CLI trong moi truong hien tai.

## Loi/Rui ro

- Da fix: drift giua numbered SQL va generated `config.sql`; entrypoint nay khong con ton tai.
- Da fix: meal catalog rewrite khong con xoa validation suffix.
- Chua fix: runtime/RLS/Edge Function can duoc chay tren local/sandbox disposable truoc khi coi la runtime verified.
- Chua fix: checksum goc `README.md` da stale tu HEAD, khong do thay doi cua phien nay.

## Ty le hoan thanh

- Hoan thanh: consolidation, tooling, contract/docs updates va static validation.
- Dang do: sandbox execution va Flutter test runtime evidence phu thuoc toolchain/moi truong ben ngoai.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - chi con hai script SQL co phan dinh ro rang va assertion fail-fast.
- Muc do hoan thanh task: hoan thanh pham vi repository; runtime sandbox chua xac minh.
- Bang chung kiem chung: structural checks, meal sync, runtime audit, source-truth/history checks va diff check.
- Diem ton token/chua toi uu: nhieu contract cu hard-code ten numbered/config nen can retarget rong.
- Cach toi uu cho phien sau: chay hai script tren Supabase disposable bang `ON_ERROR_STOP=1`, sau do ghi evidence RLS hai nguoi dung/family scope.
- Task-skill can doc lan sau: `.codex/task-skills/supabase-schema.md`
