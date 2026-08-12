# Worklog - M13 VietQR hardening closure

## Metadata

- Date: 2026-08-12
- Work type: coding / test / docs-dd / Supabase acceptance source
- Module: M13 `PAYMENT_MEMBERSHIP`
- Base commit inspected: `dfc9ea312e3988e39e26634cef6dc56914593037`
- Primary domain: Access / Membership / Referral
- Production rollout: out of scope

## Muc tieu

Đóng các gap còn lại của plan nâng cấp Plus/FamilyPlus qua VietQR: exact NB-only transfer content, trusted projection refresh sau approve, paid-gate audit, executable payment SQL acceptance source và đồng bộ M13 DD/checklist mà không tạo plan VIP hoặc client-side entitlement.

## Thay doi runtime

- Centralize payment plan normalization và exact transfer reference `^NB[0-9A-F]{12}$` tại `lib/core/membership/membership_upgrade_route.dart`.
- `MembershipPaymentRequest.transferMemoForPayment` chỉ trả canonical NB reference; legacy/free-form memo không được QR/copy.
- V2 router dùng shared normalizer, bỏ duplicate `_membershipPaymentPlanFromQuery`.
- Payment controller sau `succeeded`:
  1. invalidate `effectiveAccessProvider`;
  2. chạy existing authenticated cloud sync để pull `users.subscription_tier` từ Supabase;
  3. chỉ khi sync thành công mới invalidate `dashboardProvider`.
- Không set Plus/FamilyPlus từ request/UI/local state; Supabase vẫn là authority.

## Test source bo sung/cap nhat

- Exact NB normalizer: canonical/lowercase/invalid length/non-hex/wrong prefix.
- Paid gate static contract: AI Chat, schedule generation, health-module Plus, Advanced Tracking Plus, FamilyPlus.
- Payment model/widget/controller: exact QR/copy, fail-closed invalid reference, cancellation, 30s/resume poll, succeeded-only trusted access + local projection refresh, no duplicate refresh.
- New Supabase contract test validates migration + config + rollback smoke source.
- New `test/docs/fixtures/supabase_membership_payment_hardening_smoke.sql` covers owner/idempotency/open-request/direct writes/roles/pre-approval access/approve/reject/audit/renewal/switch/timezone/RLS/legacy missing expiry and always rolls back.
- True concurrent open-request race remains a two-session sandbox case because one SQL transaction cannot prove cross-session locking behavior.

## DD / acceptance docs

- M13 DD promoted to v1.4 and corrected from legacy “NB + payer name memo” to exact NB-only memo.
- Documented Finance/Super-only reviewer scope; Support/Content/Operations denied.
- Documented user cancel, one-open-request, finite month/year periods, same-plan renewal, immediate cross-plan switch, legacy missing-expiry fail-closed, and trusted projection refresh.
- Large project checklist/acceptance edits are applied by `patches/update_large_project_docs.py` to avoid replacing unrelated generated history.
- Supabase `23-membership-payment-hardening.sql` and matching `config.sql` already contain the hardening contract at base HEAD, so no duplicate backend migration is created in this closure patch.

## Kiem chung trong phien

### PASS - source/static checks available in runtime

- Exact NB regex centralized; old broad `[A-Z0-9]{1,23}` boundary removed from payment model.
- V2 duplicate plan parser removed and shared normalizer used.
- `succeeded` flow contains trusted-access invalidation + cloud sync + conditional Dashboard invalidation.
- SQL smoke contains transaction `begin`/`rollback` and all required acceptance sentinels.
- Overlay documentation no longer describes payer name as VietQR transfer memo.
- Python patch scripts compile successfully.
- `apply_patch.py` smoke-tested twice on a synthetic repository: first run updates M13/checklist/acceptance content, second run is idempotent; unrelated sentinel content remains intact.

### BLOCKED / not claimed

- `dart format`, `flutter analyze`, `flutter test`: Flutter/Dart executables are unavailable in the artifact runtime and the repository cannot be cloned because outbound GitHub DNS is blocked.
- GitHub branch creation: connector returned `403 Resource not accessible by integration`; no direct repo write was performed.
- Supabase SQL execution: no disposable Supabase/PostgreSQL target/CLI is available in this session.
- Two-session concurrency: requires two real authenticated DB sessions.
- VCB QR scan/manual reconciliation: requires bank-app UAT; no real transfer is performed by automation.

## Pham vi con lai truoc production acceptance

1. Apply the patch to a full checkout at the recorded base commit/current compatible main.
2. Run targeted Dart format/analyze/tests and architecture tests.
3. Rebuild/apply migration to disposable Supabase sandbox and run the M13 rollback smoke.
4. Run two-session concurrent create test.
5. Scan a generated QR in VCB and manually reconcile as Finance/Super Admin.
6. Record concrete command/UAT evidence and only then narrow/close the M13 portion of `NB-RISK-001`.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - patch keeps trusted access boundaries, closes documented contract drift and adds explicit executable acceptance source without fabricating external evidence.
- Muc do hoan thanh task: source-ready closure completed; external sandbox/VCB production acceptance remains intentionally unverified.
- Bang chung kiem chung: source inspection against live `main`, local static contract checks, exact file manifest; Flutter/Supabase/VCB execution blocked as recorded above.
- Diem ton token/chua toi uu: GitHub connector search index returned weak/no code search results, so several targeted files had to be fetched directly.
- Cach toi uu cho phien sau: work from a writable full checkout or Codex environment with GitHub/Supabase access, then run the existing targeted commands before broad validation.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md` and Supabase schema workflow for sandbox evidence.
