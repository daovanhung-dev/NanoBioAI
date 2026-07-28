Commit de xuat: docs(worklog): ghi nhan phien supabase comprehensive sandbox fixture

# Worklog - Supabase comprehensive sandbox fixture

## Thoi gian

- Ngay: 2026-07-28
- Bat dau: Phien lam viec hien tai
- Ket thuc: 2026-07-28 11:26 +07:00
- Timezone: Asia/Saigon

## Pham vi

- Loai task: Mo rong fixture Supabase local/sandbox, tai lieu va contract test.
- Module chinh: Auth, subscription/quota, FamilyPlus, Sale, Admin, Wellness/reward, Nabi va Storage proof.
- Yeu cau goc: Tao seed du lieu toan dien cho cac bang public, Auth, cac role/demo cohort va tai lieu tai khoan; giu lai bon tai khoan legacy.

## Da lam

- Tao module canonical `19-dev-sandbox-comprehensive-seed.sql`, mirror nguyen khoi vao `config.sql` ngay truoc `COMMIT`, va giu UUID/email cua bon tai khoan legacy.
- Tao cohort fixture cho Free, Plus, FamilyPlus, Sale graph direct-only, Admin role surfaces, Wellness/reward/voucher, Nabi va cloud-sync; them assertion rollback-only cho cac truong hop bi cam.
- Bo sung bucket private `sale-payout-proofs`, policy local/sandbox va script Storage API de tao proof fixture that.
- Tao profile demo opt-in de bat tam Wellness, Sale conversion va Nabi ma khong thay doi rollout mac dinh cua rebuild.
- Chuyen seed membership cu thanh no-op redirect de tranh hai executable seed contract, loai bo contract version cu con sot; them account matrix, acceptance/runbook va smoke/contract tests.
- Hoan thien ma tran reachable state sau ra soat: `initial_guest`/`member_new`, cac provenance quota, `admin_status=suspended`, tat ca Nabi category, config version state va lien ket marker Wellness voi request/quota tuong ung.
- Giu mot conversion `approved` rieng cho Storage runner va mot conversion `approved` retain de tuy chon mark-paid khong lam mat coverage lifecycle; runner chon UUID target co dinh.

## File code/docs da sua

- `docs/supabase/19-dev-sandbox-comprehensive-seed.sql` - tao fixture canonical.
- `docs/supabase/config.sql` - mirror fixture, bucket va policy rebuild.
- `docs/supabase/19-dev-sandbox-accounts.md` - tao ma tran tai khoan fixture local/sandbox.
- `docs/supabase/20-dev-sandbox-demo-profile.sql` - tao profile demo opt-in.
- `tools/supabase/Seed-StorageFixtures.ps1` - tao proof fixture qua Storage API/RLS.
- `docs/supabase/08-acceptance-checks.md`, `09-dev-seed-membership-test-accounts.sql`, `13-sale-payout-storage.md`, `16-schedule-proof-storage.md`, `README.md` - cap nhat contract, runbook va tai lieu tuong thich.
- `test/docs/supabase_comprehensive_seed_contract_test.dart`, `test/docs/supabase_storage_fixture_script_contract_test.dart`, `test/docs/fixtures/supabase_comprehensive_seed_smoke.sql`, `test/docs/supabase_dev_seed_membership_test.dart` - them/cap nhat contract va smoke test.
- `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_shell_page.dart` - dat upload proof Sale khong overwrite object da co.

## Tai lieu lien quan

- `docs/supabase/README.md`
- `docs/supabase/08-acceptance-checks.md`
- `docs/supabase/13-sale-payout-storage.md`
- `docs/supabase/16-schedule-proof-storage.md`

## Commands

- `flutter test test/docs`: PASS - 54 contract/document tests pass sau lan mo rong fixture cuoi.
- `dart format lib/app_versions/admin/features/admin_panel/presentation/pages/admin_shell_page.dart test/docs/...`: PASS - 4 file, khong co thay doi format.
- `flutter analyze lib/.../admin_shell_page.dart test/docs/...`: PASS - khong co issue.
- `.codex/tools/validate_codex_integrity.ps1`: PASS sau refresh history/worklog.
- `git diff --check`: PASS (chi co canh bao line-ending cua worktree Windows, khong co whitespace error).
- Rebuild Supabase va Storage smoke: SKIPPED - khong co Supabase disposable/local-sandbox da duoc xac nhan de chay thao tac destructive an toan.

## Loi/Rui ro

- Da fix: Dong bo canonical module voi block mirror cua `config.sql`; loai bo cum tu vi pham direct-only Sale contract trong comment; bo sung catalog, eligible future, lifecycle state va lien ket quota/Wellness sau static review.
- Chua xac minh runtime: Chua co bang chung runtime cho rebuild/Storage API do moi truong Supabase disposable chua san sang.
- Can kiem tra tiep: Khi co URL/CLI/Docker Supabase disposable, chay rebuild, profile demo, Storage runner va smoke SQL rollback-only.

## Ty le hoan thanh

- Hoan thanh: Thay doi source, tai lieu, fixture account matrix, Storage runner va contract test.
- Dang do: Runtime acceptance can moi truong Supabase disposable da duoc xac nhan; khong claim da chay destructive rebuild tren database chua ro nguon goc.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: Tot - co canonical source, mirror contract va kiem tra tinh cho cac invariant chinh.
- Muc do hoan thanh task: Hoan thanh phan implementation; runtime smoke duoc de ro la chua xac minh.
- Bang chung kiem chung: `flutter test test/docs` va targeted `flutter analyze` pass; fixture co smoke SQL rollback-only, mirror contract va contract cho Storage script.
- Diem ton token/chua toi uu: Mirror SQL lon can dong bo chinh xac; contract test duoc them de ngan drift ve sau.
- Cach toi uu cho phien sau: Cap URL/CLI Supabase disposable truoc khi bat dau de co the chay acceptance runtime ngay sau rebuild.
- Task-skill can doc lan sau: `.codex/task-skills/supabase.md`
