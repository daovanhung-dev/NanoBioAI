Commit de xuat: docs(supabase): chuan hoa bundle local sandbox va VietQR smoke

# Worklog - Numbered Supabase local/sandbox bundle

## Thoi gian

- Ngay: 2026-08-23
- Bat dau: 02:xx
- Ket thuc: 03:xx
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: supabase-schema
- Module chinh: local/sandbox rebuild, membership Plus fixture, VietQR payment request.
- Yeu cau goc: dat ten SQL theo thu tu chay, them fixture Plus local va thao tac tao/kiem tra ma giao dich VietQR.

## Da lam

- Doi ten bundle SQL thanh 01-05 cho rebuild/seed va 90-93 cho validation; README ghi ro thu tu, tinh huy du lieu va cach chay.
- Tao `config.sql` tu 01-05 bang generator xac dinh, kem `--check` de bat drift.
- Them fixture Plus local da xac nhan Auth, identity, subscription va assertion server-side cho plan/AI chat entitlement.
- Them `93_validate_membership_vietqr.sql`: tao request server-owned, kiem tra ma NB/reference-only, idempotency va one-open-request, sau do rollback.
- Dong bo meal SQL 163 recipes tu nguon Markdown; sua compatibility break giua `validate_meal_sync.py` va `build_seed`.
- Cap nhat cac runtime/tool/test/docs reference dang song sang bundle danh so; khong sua worklog lich su.

## File code/docs da sua

- `docs/supabase/` - bundle danh so, README, config generated va VietQR smoke.
- `tools/build_supabase_rebuild_config.py` - tao/kiem tra canonical config.
- `tools/sync_meal_catalog_sql.py`, `tools/validate_meal_sync.py` - dung seed danh so va API generator hien tai.
- `test/docs/` va payment contract tests - dung source SQL moi va them numbered-bundle contract.

## Commands

- `python3 -m py_compile ...`: PASS.
- `python3 tools/build_supabase_rebuild_config.py --check`: PASS.
- `python3 tools/sync_meal_catalog_sql.py --check`: PASS sau khi dong bo 163 recipes.
- `python3 tools/validate_meal_sync.py`: PASS (163 recipes / 64 topics / 11 chapters).
- Static numbered SQL/config/Plus/VietQR assertions: PASS.
- `git diff --check`: PASS.
- Dart/Flutter tests: SKIPPED - môi trường không có Dart hoặc Flutter.
- Supabase execution: SKIPPED - môi trường không có `psql` hoặc Supabase CLI.
- `.codex` integrity/history refresh: SKIPPED - môi trường không có PowerShell.

## Loi/Rui ro

- Da fix: validator meal goi signature cu cua generator, gay `TypeError` truoc khi kiem tra source fidelity.
- Chua fix: chua co bang chung thuc thi 01-05 va 90-93 tren database local/sandbox do thieu CLI/database runner.
- Can kiem tra tiep: chay full bundle tren Supabase local disposable, sau do login fixture Plus va mo payment UI de quet QR trong ung dung.

## Ty le hoan thanh

- Hoan thanh: source SQL, seed, config, documentation, static validation va regression contract.
- Dang do: database execution va Dart/Flutter test/device UAT phu thuoc toolchain local.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - rebuild co mot entrypoint generated va thu tu chay ro rang.
- Muc do hoan thanh task: da xong source-level; chua the thay bang chung runtime do toolchain thieu.
- Bang chung kiem chung: config drift check, meal fidelity, static SQL assertions va whitespace check deu PASS.
- Diem ton token/chua toi uu: cac contract test cu tro toi migration lich su khong con trong workspace, can route som ve source rebuild hien tai.
- Cach toi uu cho phien sau: cai Dart/Flutter va Supabase CLI truoc khi chay UAT, sau do dung README de rebuild sandbox duy nhat.
- Task-skill can doc lan sau: `.codex/task-skills/supabase-schema.md`
