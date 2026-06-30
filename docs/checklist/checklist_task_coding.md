# Checklist Task Coding

Commit de xuat: docs(checklist): khoi tao task coding theo DD progress

## Metadata

| Field | Value |
|---|---|
| Nguon | `docs/checklist/checklist_complete_DD.md` |
| Ngay cap nhat | 2026-06-30 |
| Muc dich | Ghi lai cong viec coding tiep theo tu tien do DD module cua phien truoc. |

## DD Progress Next Tasks

- [ ] Truoc moi phien coding, doc `docs/checklist/checklist_complete_DD.md` de chon DD module, DD completeness, coding progress, implementation evidence backlog va next step.
- [ ] Sau do doc file nay de tiep tuc note dang do cua phien truoc.
- [ ] DD docs M01-M19 da Approved/100%; khi coding, chi claim production acceptance sau khi co implementation evidence backlog pass.
- [ ] Sau moi phien coding, cap nhat `docs/checklist/checklist_complete_DD.md` va ghi task tiep theo vao file nay.

## DD Decision Update 2026-06-30

- Q-01..Q-18 da chot va DD docs M01-M19 da 100%; implementation evidence moi la backlog coding/test.
- M01, M03, M04, M08, M09, M10, M13, M14, M15 da co code+test evidence theo acceptance coding; tiep theo uu tien sandbox/RLS/API/audit evidence va production smoke.
- Coding progress chi tang khi co code/test/SQL/sandbox evidence moi.

## Uu tien tiep theo

| Priority | Module | Viec can lam tiep | Ly do |
|---:|---|---|---|
| 1 | M15-M19 Admin | Verify Admin SQL/RPC sandbox, RLS, audit rows, 24h hold, reconciliation, point adjustment, and privacy filters; record acceptance evidence. | Q-05/Q-10/Q-12/Q-13/Q-16/Q-17/Q-18 da chot va runtime/SQL/tests da update; can sandbox/staging evidence de dat acceptance. |
| 2 | M12/M14 Sale | Repo-ready da co; tiep theo verify Sale RPC/RLS sandbox va ghi acceptance evidence cho request Sale/referral/conversion queue. | Sale direct-only co app/Admin/SQL contract/tests, nhung chua production-ready khi sandbox va financial policies da chot; sandbox evidence can lam. |
| 3 | M06/M07 Quota + AI Chat | Run Supabase sandbox quota acceptance: Free 3/day AI chat, Free 3/month schedule, Plus/FamilyPlus bypass, idempotent commit, RLS/client write rejection. | Code/SQL gateway da wire; sandbox evidence la blocker de dat production acceptance. |
| 4 | M01/M02/M03 Guest flow | M01 local-first user-data sync da harden; tiep theo doi chieu M03 dashboard state, Supabase sandbox sync, va FamilyPlus contract. | V1 runtime local da tien len; cloud sync sandbox/RLS, subject/consent va dashboard state can implementation/sandbox evidence. |
| 5 | M13/M17 Payment/Reconciliation | Verify selected payment/reconciliation policy in sandbox, then finish provider/chargeback-specific contracts not covered by current local draft. | Q-05/Q-10/Q-13/Q-17 da chot cho selected policy; provider/staging evidence van thieu. |

## Notes tu phien coding gan nhat

- 2026-06-30: M01/M03/M04/M08/M13/M14/M15 coding 100% theo code+test acceptance: them shared `SubjectAccessContext`, M01 onboarding va M03 dashboard subject-aware local paths/tests; M04 versioned BMI/BMR/RMR/TDEE/hydration calculator, route `/body-metrics`, hub tile, disclaimer va tests; M08 promoted `m08_wellness_v1_2026_06`, FamilyPlus subject tests, Vietnamese UI/disclaimer va `health_score_ledgers` SQL contract/RLS; M13 v2 payments feature + `create_membership_payment_request` pending/idempotent RPC, price config, no pending-rights grant, 24h reversal guard; M14 Sale direct customer privacy xoa `health_condition_summary`, conversion minimum 500000 VND; M15 support/content Admin roles, operations legacy alias, expanded safe dashboard metrics. Targeted analyze pass, focused tests pass 103 cases, M04/M08/M13 rerun pass 19 cases, architecture tests pass 24 cases. Flutter van in warning pubspec asset folder missing nhu baseline, command exit 0. Production backlog: Supabase sandbox/RLS/provider/payment/audit smoke.
- 2026-06-30: M09/M10 coding 100% theo code+test acceptance: M09 them payload v2 co subject/actor/correlation metadata, reminder ID co subject, action idempotent va chan subject/source-owner mismatch; M10 them v3 route `/v3/advanced-tracking`, hydration goal `advanced_hydration`, repository/datasource/use case/provider/page, Plus/FamilyPlus access gate va tests. Targeted analyze pass. Targeted tests pass 44 case cho notification, M10, cloud-sync contract va architecture boundary. Flutter van in warning pubspec asset folder missing do nhieu asset `.gitkeep` dang bi xoa san trong worktree, nhung targeted test command exit 0. Implementation evidence backlog production: real-device notification, Supabase sandbox cross-device sync, paid access va FamilyPlus subject/RLS smoke.
- 2026-06-30: M06/M07/M02 quota foundation da code/test: them shared `TrustedBackendUsageQuotaGateway`, v2 `EffectiveAccess` read model, SQL `check_usage_quota`/`commit_usage_quota` + schedule wrappers trong `03-membership-quota.sql` va `config.sql`, normalize quota timezone sang `Asia/Ho_Chi_Minh`, AI Chat check quota truoc AI va commit sau response. Targeted tests pass: usage quota gateway, AI Chat quota, Supabase config contract, generated-plan quota, architecture boundary. Implementation evidence backlog: chay Supabase sandbox/RLS cho quota counters/events, Free limit, paid bypass, idempotency, client write rejection.
- 2026-06-30: M01/M05 immediate user-data sync hardening da code/test: SQLite v11 backfill missing sync ids, onboarding current-user reader/local-first completion, `AuthProfileService` read-only, profile/onboarding contract tests updated, outbox retry va active snapshot tests pass. Quick check global format fail do 7 legacy files ngoai scope; targeted sync/onboarding/profile/daily/meal/lifestyle/notification tests pass. Implementation evidence backlog: Supabase sandbox/RLS/cross-device evidence va FamilyPlus subject-aware sync.
- 2026-06-28: M12/M14 Sale repo-ready: go local commission estimator khoi Sale UI, conversion request dung trusted RPC config/idempotency retry, them Admin `saleConversions` queue route/action mapping, SQL 12 dung `sales.write`, va targeted Sale/Admin/docs tests pass.
- 2026-06-28: M01 safe hardening da code/test local: sanitize onboarding logs, DB injection cho local datasource test, persistence/markCompleted/outbox tests, completion handoff va double-submit tests. Quick check fail o `flutter analyze` do analyzer issues toan cuc san co/ngoai pham vi; xem worklog 006.
- 2026-06-28: Khoi tao checklist task coding tu `checklist_complete_DD.md`; chua co runtime change trong phien nay.
- 2026-06-29: M02 runtime guard da code/test local: SQLite v10 request ledger + `guest_initial_plan_used`, `GeneratedPlanService` request/idempotency guard, member quota gateway truoc AI, dashboard append generation, safe quota/guest-used errors, targeted generated-plan/onboarding/migration/lifestyle tests pass. Implementation evidence backlog production: M06 trusted quota RPC/RLS sandbox, FamilyPlus subject/ownership; Q-16 timezone da chot Asia/Ho_Chi_Minh.
- 2026-06-29: M08 local draft da code/test: `lib/app_versions/v2/features/health_scoring/` co calculator version `m08_local_draft_2026_06`, SQLite read model, providers, route `/v2/health-score`, widget/provider/datasource/domain tests pass. Implementation evidence backlog official: accepted Q-14 formula policy va Q-15 FamilyPlus subject/consent implementation.
- 2026-06-29: M15/M16 Admin permission/error-state hardening da code/test: Admin domain co section/mutation permission helpers, controller khong goi section/mutation RPC khi thieu quyen, UI filter nav/action va hien denied state, Admin/docs targeted analyze/test pass. Implementation evidence backlog: `plans.write` vs `config.write`, sandbox SQL/RPC/audit evidence; Q-12/Q-18 da chot.
- 2026-06-29: M15/M16 Admin contract sync da code/test: `plans` dung `plans.write` + `admin_list_plan_config_versions`, `config` giu `config.write`, Sale conversion queue trong `config.sql` dong bo lai `sales.write` theo `12-sale-module-update.sql`, va dashboard/audit bi chan mutation RPC. Targeted Admin analyze/test pass; quick check dung o global dart format check do 7 file v1 ngoai pham vi chua format. Implementation evidence backlog: sandbox SQL/RPC/audit evidence; Q-12/Q-18 da chot.
- 2026-06-29: M15-M19 selected policy implementation da code/test local draft: Admin active full CRUD qua audited RPC/backend, reconciliation section/RPC mapping, dashboard timezone `Asia/Ho_Chi_Minh`, manual payment approval, 24h hold/refund-cancel window, no-new-points cho Sale suspended/closed, one-Admin point adjustment, DD/checklist/Supabase contracts updated. Implementation evidence backlog: sandbox/staging SQL/RPC/RLS/audit evidence.
