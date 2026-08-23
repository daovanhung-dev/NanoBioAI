Commit de xuat: feat(supabase): hoan thien runtime setup va Edge xoa tai khoan

# Worklog - Supabase runtime setup audit

## Thoi gian

- Ngay: 2026-08-23
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: supabase-schema
- Module chinh: Supabase runtime contract, Storage va Edge Function auth
- Yeu cau goc: Ra soat tat ca thanh phan Supabase ma app can va tao setup con thieu.

## Da lam

- Doi chieu tat ca diem goi Supabase trong Flutter voi `config.sql`: 61 RPC,
  29 bang/view duoc truy cap, 2 Storage bucket va 1 Edge Function bat buoc.
- Xac nhan rebuild khai bao 100 function, 0 procedure, 73 bang, 1 view, 26
  trigger va cac RLS policy; `94_validate_runtime_support.sql` doc catalog de
  in inventory thuc te sau khi chay SQL.
- Tao `06_schema_runtime_support.sql`: dua hai bucket minh chung ra khoi seed,
  upsert an toan va xac nhan/grant 61 RPC app-facing.
- Them Edge Function `delete-account` co JWT verification, xac nhan thao tac,
  xac thuc nguoi goi bang JWT va chi xoa dung tai khoan do tren server.
- Cap nhat Flutter gui co xac nhan khi yeu cau xoa tai khoan; them test Deno,
  Dart contract va tool audit de chan drift trong cac phien sau.
- Khong sua cac WIP Android/Voice dang co trong worktree.

## File code/docs da sua

- `docs/supabase/06_schema_runtime_support.sql` - tao Storage runtime va grant RPC.
- `docs/supabase/94_validate_runtime_support.sql` - smoke va inventory catalog rollback-only.
- `docs/supabase/config.sql` - generated rebuild entrypoint 01 den 06.
- `docs/supabase/README.md` - thu tu chay va deploy Edge Function.
- `supabase/functions/delete-account/` - Edge handler, runtime entrypoint, test va huong dan deploy.
- `supabase/config.toml` - bat JWT verification cho Edge Function moi.
- `tools/audit_supabase_runtime_contract.py` - audit app-to-Supabase contract.
- `lib/services/supabase/auth/account_security_service.dart` - gui xac nhan xoa tai khoan.

## Commands

- `python3 tools/build_supabase_rebuild_config.py`: PASS.
- `python3 tools/audit_supabase_runtime_contract.py`: PASS.
- `python3 -m py_compile ...`: PASS.
- `python3 tools/build_supabase_rebuild_config.py --check`: PASS.
- `python3 tools/sync_meal_catalog_sql.py --check`: PASS.
- `python3 tools/validate_meal_sync.py`: PASS.
- `sha256sum --check SHA256SUMS.txt`: PASS.
- `git diff --check`: PASS.
- `deno test --allow-net supabase/functions/delete-account/handler_test.ts`: SKIPPED - Deno khong co trong moi truong.
- `dart format` va Flutter test targeted: SKIPPED - Dart/Flutter khong co trong moi truong.
- `psql`/Supabase CLI smoke va deploy: SKIPPED - CLI khong co va khong co scope moi truong sandbox dang link.

## Loi/Rui ro

- Da fix: Storage bucket runtime khong con phu thuoc vao local fixture seed.
- Da fix: Flutter goi `delete-account` nay da co Edge Function JWT/server-side tuong ung.
- Chua fix: Chua co bang chung deploy hay smoke tren mot Supabase sandbox that.
- Can kiem tra tiep: Chay 01 den 06, 90 den 94 tren sandbox; deploy `delete-account`; chay Deno va Flutter targeted tests khi toolchain san sang.

## Ty le hoan thanh

- Hoan thanh: Audit, SQL setup, Edge source, regression contract va static validation.
- Dang do: Deploy/smoke tren Supabase sandbox that can quyen project va CLI.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: Tot - tach ro schema runtime, fixture va Edge runtime; khong sao chep secret.
- Muc do hoan thanh task: Hoan thanh phan repo; nghiem thu live con phu thuoc moi truong.
- Bang chung kiem chung: Audit app-to-schema, generated config, meal sync va whitespace deu PASS.
- Diem ton token/chua toi uu: Quet source rong de bao phu dynamic RPC Admin va cloud-sync.
- Cach toi uu cho phien sau: Chay `tools/audit_supabase_runtime_contract.py` truoc khi them datasource/Edge Function moi.
- Task-skill can doc lan sau: `.codex/task-skills/supabase-schema.md`
