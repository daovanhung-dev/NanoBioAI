Commit de xuat: feat(sale): hoan thien policy Sale payout va referral

# Worklog - Sale Module Production Policy

## Thoi gian

- Ngay: 2026-06-29
- Bat dau: 15:05
- Ket thuc: 16:35
- Timezone: Asia/Saigon

## Pham vi

- Loai task: coding + Supabase schema draft + Admin UI + tests + docs
- Module chinh: M12 REFERRAL_DIRECT, M14 SALE_POINTS, Admin Sale conversion queue
- Yeu cau goc: Implement plan hoan thanh module Sale theo cac cau tra loi Q-01..Q-18 cua user.

## Da lam

- Supabase draft: them paid-plan eligibility cho request Sale, device hash anti-fraud, list-price/commission-base snapshot, payout profile, customer summary RPC, proof path, conversion profile guard va negative reversal adjustment khi refund/cancel/chargeback.
- Config rebuild: dong bo `docs/supabase/config.sql` voi cac module 05/11/12 da cap nhat.
- Flutter Sale: them device hash store, payout profile model/RPC, gate CCCD + ngan hang truoc dashboard, customer summary fields, 24h hold messaging, and attach-referral flow qua device hash.
- Flutter Admin: them metadata cho `AdminWorkItem`, proof path payload, private bucket upload attempt, QR rendering cho Sale conversion payout detail, and `qr_flutter` dependency.
- Docs/tests: them storage guide `13-sale-payout-storage.md`, cap nhat README/RLS/acceptance checks, contract tests va Sale/Admin tests.
- V1 settings: chan flow gan ma gioi thieu sau khi tao tai khoan; chi con thong bao rule "nhap khi dang ky".

## File code/docs da sua

- `docs/supabase/05-sale-referral-commission.sql`, `11-admin-access-dashboard.sql`, `12-sale-module-update.sql`, `config.sql` - sua - Sale payout/referral/payment policy va rebuild sync.
- `docs/supabase/06-rls-policy-matrix.md`, `08-acceptance-checks.md`, `README.md`, `13-sale-payout-storage.md` - sua/them - RLS, acceptance va storage proof runbook.
- `lib/sale_referral/**`, `lib/services/supabase/sale/**` - sua/them - model, repository, Supabase datasource, device hash, Sale UI gate.
- `lib/app_versions/admin/features/admin_panel/**` - sua - Admin conversion metadata, proof path va QR detail.
- `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart` - sua - tat attach referral sau signup.
- `pubspec.yaml`, `pubspec.lock` - sua - them `qr_flutter`.
- `test/sale_referral/**`, `test/app_versions/admin/admin_models_test.dart`, `test/docs/supabase_*_contract_test.dart` - sua - coverage cho contract moi.

## Tai lieu lien quan

- `docs/supabase/README.md`
- `docs/supabase/08-acceptance-checks.md`
- `docs/DD/referral_direct/Overall.md`
- `docs/DD/sale_points/Overall.md`

## Commands

- `flutter pub get`: PASS - cap nhat lockfile cho `qr_flutter`.
- `dart format ...`: PASS - formatted touched Dart/test files only.
- `dart analyze lib/sale_referral lib/services/supabase/sale lib/app_versions/admin/features/admin_panel lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart test/sale_referral test/app_versions/admin/admin_models_test.dart test/docs`: PASS - no issues found.
- `dart analyze lib/app_versions/admin/features/admin_panel`: PASS - no issues found sau khi them builder VietQR offline.
- `flutter test test/sale_referral/domain/sale_models_test.dart test/sale_referral/data/sale_repository_impl_test.dart test/sale_referral/presentation/sale_shell_page_test.dart test/app_versions/admin/admin_models_test.dart test/docs/supabase_admin_contract_test.dart test/docs/supabase_config_contract_test.dart`: PASS - all 48 tests passed.
- `flutter test test/app_versions/admin/admin_models_test.dart test/docs/supabase_admin_contract_test.dart test/docs/supabase_config_contract_test.dart`: PASS - all 34 tests passed sau fix reversal idempotency.
- `git diff --check`: PASS - no whitespace errors; Windows CRLF warnings only.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS - refreshed history/task-skills.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL - stale path co san trong `.codex/PROJECT_MAP.md` tro toi `docs/BD/authentication/BD_Authentication_Registration_Login_NanoBio.md`, nhung repo hien chi co `docs/BD/project_flow`.

## Loi/Rui ro

- Da fix: client/RPC contract da tach diem giao dich Sale, chan unpaid Sale registration, chan attach sau signup, yeu cau payout profile truoc dashboard/rut tien, va reverse diem bang adjustment am idempotent theo commission record.
- Chua fix: chua chay `docs/supabase/config.sql` tren Supabase sandbox/staging; chua tao bucket `sale-payout-proofs` that trong Supabase; QR VietQR da tao offline theo EMVCo/NAPAS best-effort nhung van can test scan voi ngan hang thuc te.
- Chua fix: `.codex/PROJECT_MAP.md` co stale path BD authentication ngoai pham vi task lam integrity check fail.
- Can kiem tra tiep: sandbox rebuild, RLS smoke, storage policy, manual payment approval, 24h hold, conversion before/after hold, proof upload, refund/chargeback reversal, suspended/closed no-new-points.

## Ty le hoan thanh

- Hoan thanh: Local Flutter/Admin/Supabase draft/docs/tests theo policy da chot.
- Dang do: Production-ready evidence tren sandbox/staging va cau hinh Storage bucket.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - contract SQL, Flutter wiring, Admin UI va tests duoc cap nhat cung luc.
- Muc do hoan thanh task: implementation local hoan tat theo plan, nhung khong claim production-ready vi thieu sandbox/storage evidence.
- Bang chung kiem chung: targeted analyze, targeted Flutter tests va `git diff --check` PASS; Codex integrity FAIL do stale path context ngoai pham vi task.
- Diem ton token/chua toi uu: dong bo `config.sql` ton nhieu thao tac vi module SQL lon; lan sau nen dung script section-sync co san.
- Cach toi uu cho phien sau: chay Supabase local/sandbox sớm de bat syntax/RLS thay vi chi dua vao contract tests.
- Task-skill can doc lan sau: `.codex/task-skills/supabase-schema.md`
