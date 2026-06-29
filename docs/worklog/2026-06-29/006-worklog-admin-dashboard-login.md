Commit de xuat: docs(worklog): ghi nhan phien admin dashboard login

# Worklog - Admin dashboard login blocker

## Thoi gian

- Ngay: 2026-06-29
- Bat dau: 19:14
- Ket thuc: 19:17
- Timezone: Asia/Saigon

## Pham vi

- Loai task: bugfix
- Module chinh: Admin dashboard / Supabase RPC
- Yeu cau goc: Sua loi dang nhap dung mat khau nhung khong vao duoc dashboard
  Admin, UI hien "Chua tai duoc khu quan tri".

## Da lam

- Xac nhan UI loi nam o nhanh `AsyncValue.error`, phu hop voi RPC dashboard
  nem loi sau khi session Admin hop le.
- Sua `get_admin_dashboard_summary` de qualify cot nguon bang alias bang.
- Them regression test cho SQL module va rebuild `config.sql`, ngan viec dua
  lai `where status ...` khong qualify trong function dashboard.
- Ghi tai lieu fixbug cho loi Admin dashboard login blocker.

## File code/docs da sua

- `docs/supabase/11-admin-access-dashboard.sql` - sua - qualify cot trong RPC
  dashboard summary.
- `docs/supabase/config.sql` - sua - dong bo rebuild Supabase entrypoint.
- `test/docs/supabase_admin_contract_test.dart` - sua - them contract test cho
  SQL module Admin.
- `test/docs/supabase_config_contract_test.dart` - sua - them contract test cho
  rebuild config.
- `docs/fixbug/admin-dashboard-login/001-fixbug-admin-dashboard-login.md` - tao
  - ghi root cause, cach sua va luu y trien khai.

## Tai lieu lien quan

- `.codex/workflows/bugfix.md`
- `.codex/domains/access-membership-referral.md`
- `docs/supabase/README.md`
- `docs/supabase/11-admin-access-dashboard.sql`
- `docs/supabase/config.sql`

## Commands

- `dart format test/docs/supabase_admin_contract_test.dart test/docs/supabase_config_contract_test.dart`: PASS.
- `flutter test test/app_versions/admin test/docs/supabase_admin_contract_test.dart test/docs/supabase_config_contract_test.dart`: PASS.
- `git diff --check`: PASS.
- `powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1`:
  FAIL - dung o `dart format --set-exit-if-changed .` do format drift ngoai
  pham vi; cac tracked file ngoai pham vi da duoc phuc hoi, untracked file
  co san khong co baseline de phuc hoi.

## Loi/Rui ro

- Da fix: `get_admin_dashboard_summary` khong con dung unqualified `status`
  filter trong metric dashboard.
- Chua fix: Supabase database dang active chua tu dong nhan thay doi SQL tu repo.
- Can kiem tra tiep: Apply SQL len local/dev Supabase va dang nhap bang tai
  khoan Admin that de smoke test UI.

## Ty le hoan thanh

- Hoan thanh: Sua SQL contract, test regression, fixbug doc.
- Dang do: Manual Supabase/UI validation sau khi apply SQL vao database active.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - thay doi hep vao RPC gay loi va co test chong hoi quy.
- Muc do hoan thanh task: hoan thanh phan repo; manual DB apply/validation con
  can moi truong Supabase active.
- Bang chung kiem chung: targeted Flutter/docs tests PASS; quick check FAIL do
  full-repo format drift ngoai pham vi; `git diff --check` PASS.
- Diem ton token/chua toi uu: quick check toan repo gay format drift ngoai pham
  vi; lan sau nen chay format check targeted truoc khi full quick check neu repo
  co untracked/dirty files.
- Cach toi uu cho phien sau: kiem tra `git status --short` va full-repo format
  drift truoc khi chay script co `dart format .`.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
