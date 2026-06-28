Commit de xuat: feat(sale): coding module Sale full noi bo

# Worklog - Sale Module Full Noi Bo

## Thoi gian

- Ngay: 2026-06-28
- Bat dau: 15:01
- Ket thuc: 15:01
- Timezone: Asia/Saigon (+07:00)

## Pham vi

- Loai task: coding + Supabase schema draft + test/docs.
- Module chinh: `lib/sale_referral`, `lib/services/supabase/sale`,
  Supabase Sale SQL.
- Yeu cau goc: Implement plan "Coding Module Sale Full Noi Bo": direct-only
  10%, Sale pending Admin approval, referral code Register + Settings, Sale
  dashboard/ledger/conversion queue, Supabase SQL update trong `docs/supabase`.

## Da lam

- Refactor Sale runtime theo Clean Architecture: domain entities/services,
  repository contract, Supabase datasource, repository impl va Riverpod
  providers.
- Thay Sale shell thanh 4 tab: tong quan, khach truc tiep, ledger diem Sale,
  cong cu/quy doi.
- Cap nhat Sale registration de request chi tao pending; Admin approval moi mo
  active dashboard.
- Them attach referral code trong Register va Settings; Register chi attach
  khi Supabase tra session authenticated, Settings cho retry sau.
- Tao `docs/supabase/12-sale-module-update.sql` voi RPC/user/Admin contract:
  `attach_my_referral_code`, Sale dashboard/direct customers/ledger/conversion,
  conversion queue, Admin review conversion, Admin approve Sale cap code.
- Cap nhat Supabase README, RLS matrix va acceptance checks cho file SQL 12.
- Them test domain/repository/widget va cap nhat SQL contract test.

## File code/docs da sua

- `lib/sale_referral/` - sua/tao - Clean Architecture Sale runtime va UI.
- `lib/services/supabase/sale/` - sua - wrapper provider/service va Sale terms.
- `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart`
  - sua - entry nhap ma gioi thieu.
- `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` - sua
  - field ma gioi thieu optional trong Register.
- `docs/supabase/12-sale-module-update.sql` - tao - SQL update draft.
- `docs/supabase/README.md`, `06-rls-policy-matrix.md`,
  `08-acceptance-checks.md` - sua - run order/RLS/acceptance.
- `test/sale_referral/` va `test/docs/supabase_admin_contract_test.dart` -
  sua/tao - tests.

## Tai lieu lien quan

- `.codex/workflows/coding.md`
- `.codex/workflows/supabase-schema.md`
- `.codex/domains/access-membership-referral.md`
- `docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md`
- `docs/DD/referral_direct/`
- `docs/DD/sale_points/`
- `docs/DD/payment_membership/`

## Commands

- `dart format lib\sale_referral lib\services\supabase\sale ...`: PASS.
- `flutter analyze lib/sale_referral lib/services/supabase/sale lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart test/sale_referral test/docs/supabase_admin_contract_test.dart`: PASS.
- `flutter test test/sale_referral test/docs/supabase_admin_contract_test.dart test/architecture_version_boundary_test.dart`: PASS.
- `git diff --check`: PASS - CRLF warnings only.
- `rg -n "secondLevel|second-level|second_level|0\.0500|level = 2|5% tang 2|5% tầng 2" docs\supabase lib\sale_referral lib\services\supabase\sale test\sale_referral`: PASS - no matches.

## Loi/Rui ro

- Da fix: Sale client khong tu active sau khi chap nhan dieu le; khong ghi table
  payment/commission/conversion truc tiep tu Flutter.
- Da fix: Sale dashboard khong hien email, phone, payment evidence hay health
  data; chi hien ten khach va aggregate.
- Chua fix: SQL 12 chua chay tren Supabase sandbox/staging; chi la draft update.
- Chua fix: Payout provider, tax/invoice, bank transfer va webhook provider that
  nam ngoai pham vi task.
- Can kiem tra tiep: Chay SQL 12 tren staging, test RLS/RPC bang user A/B/Admin,
  va quyet dinh rollout conversion config `sale_point_conversion`.

## Ty le hoan thanh

- Hoan thanh: Runtime Sale full noi bo, SQL update draft, docs, tests targeted.
- Dang do: Supabase staging verification va provider/payout production.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - implementation co code, SQL draft, docs va tests.
- Muc do hoan thanh task: cao trong pham vi repo; khong claim production-ready.
- Bang chung kiem chung: targeted analyze/test PASS, `git diff --check` PASS,
  direct-only grep PASS.
- Diem ton token/chua toi uu: file UI auth/settings co mojibake nen patch theo
  anchor ky thuat ton them buoc.
- Cach toi uu cho phien sau: neu tiep tuc payment/points, chay SQL staging truoc
  roi moi them Admin UX cho conversion queue.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`,
  `.codex/task-skills/supabase-schema.md`.
