Commit de xuat: docs(supabase): bo sung fixture Sale A local sandbox

# Worklog - Sale A sandbox seed

## Thoi gian

- Ngay: 2026-07-28
- Bat dau: Trong phien Codex hien tai
- Ket thuc: Trong phien Codex hien tai
- Timezone: Asia/Saigon

## Pham vi

- Loai task: Supabase schema/seed fixture va smoke test
- Module chinh: Sale/referral, M12 va M14
- Yeu cau goc: Bo sung seed data Sale de Sale A co du lieu Tong quan va Khach hang.

## Da lam

- Them ba persona khach hang truc tiep cua Sale A: da kha dung, dang cho kha dung va chua chuyen doi.
- Them Auth identity, profile, phone, birth year, subscription, referral va payment fixture cho cac persona moi.
- De payment trigger tao commission 10% truc tiep; chuyen ba commission cua khach Ready sang `approved` va giu commission khach Pending o trang thai cho kha dung.
- Can bang fixture Sale A: 4 khach truc tiep, 4 payment thanh cong, 199000 diem dang giu, 3097000 diem duyet, 2500000 diem dang quy doi va 597000 diem kha dung.
- Giu chuoi A -> B -> C direct-only: payment cua C chi tao commission cho B, khong tao commission upstream cho A.
- Mo rong smoke SQL de dang nhap gia lap Sale A va kiem tra Sale state, payout profile, dashboard, customer list, ledger va conversion history.
- Mirror module 19 vao `config.sql` va cap nhat account matrix.

## File code/docs da sua

- `docs/supabase/19-dev-sandbox-comprehensive-seed.sql` - them fixture Sale A va commission history.
- `docs/supabase/config.sql` - mirror chinh xac fixture canonical trong rebuild entrypoint.
- `docs/supabase/19-dev-sandbox-accounts.md` - bo sung ba tai khoan khach hang Sale A.
- `test/docs/fixtures/supabase_comprehensive_seed_smoke.sql` - kiem tra Sale A qua RPC trong transaction rollback.

## Tai lieu lien quan

- `docs/supabase/12-sale-module-update.sql`
- `docs/supabase/05-sale-referral-commission.sql`
- `docs/supabase/20-dev-sandbox-demo-profile.sql`

## Commands

- `flutter test test/docs/supabase_comprehensive_seed_contract_test.dart`: PASS - module 19 mirror, account matrix va smoke fixture contract deu pass.
- `flutter test test/docs/supabase_config_contract_test.dart test/docs/supabase_dev_seed_membership_test.dart test/docs/supabase_admin_contract_test.dart`: PASS - 33 test pass.
- `git diff --check`: PASS - khong co whitespace error.
- `docker ps --format '{{.Names}}'`: SKIPPED - Docker daemon khong chay, nen chua the rebuild Supabase va chay smoke SQL thuc te.

## Loi/Rui ro

- Da fix: Sale A co du lieu co y nghia cho cac man Tong quan, Khach hang, So diem va Quy doi.
- Chua fix: Khong co bang chung runtime Supabase trong phien do Docker daemon khong san sang.
- Can kiem tra tiep: Rebuild local/sandbox bang `config.sql`, sau do chay smoke SQL va demo profile neu can kiem thu nut quy doi.

## Ty le hoan thanh

- Hoan thanh: Seed fixture, mirror config, tai lieu va contract/smoke coverage.
- Dang do: Live local/sandbox execution phu thuoc Docker daemon.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - fixture dung RPC va payment trigger hien co, khong hard-code du lieu o Flutter.
- Muc do hoan thanh task: Hoan thanh trong pham vi local/sandbox.
- Bang chung kiem chung: Hai lenh Flutter test deu pass; mirror config duoc contract test xac nhan.
- Diem ton token/chua toi uu: Can doc fixture Auth va commission trigger de dam bao cac tong dashboard chinh xac.
- Cach toi uu cho phien sau: Khoi dong Docker truoc khi thay doi fixture de chay smoke SQL thuc te trong cung phien.
- Task-skill can doc lan sau: `.codex/task-skills/supabase-schema.md`
