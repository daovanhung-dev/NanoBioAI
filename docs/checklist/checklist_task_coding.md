# Checklist Task Coding

Commit de xuat: docs(checklist): danh dau coding M01-M19 hoan thanh 100 phan tram

## Metadata

| Field | Value |
|---|---|
| Nguon | `docs/checklist/checklist_complete_DD.md` |
| Ngay cap nhat | 2026-07-01 |
| Muc dich | Ghi lai trang thai coding 100% va production evidence backlog con lai. |

## DD Progress Next Tasks

- [ ] Truoc moi phien coding, doc `docs/checklist/checklist_complete_DD.md` de chon DD module, DD completeness, coding progress, implementation evidence backlog va next step.
- [ ] Sau do doc file nay de tiep tuc note dang do cua phien truoc.
- [ ] DD docs M01-M19 da Approved/100%; khi coding, chi claim production acceptance sau khi co implementation evidence backlog pass.
- [ ] Sau moi phien coding, cap nhat `docs/checklist/checklist_complete_DD.md` va ghi task tiep theo vao file nay.

## DD Decision Update 2026-07-01

- Q-01..Q-18 da chot, DD docs M01-M19 da 100%, va Coding progress M01-M19 da 100% theo code + SQL/static contract + targeted tests.
- Khong claim production-ready trong checklist nay khi chua co Supabase sandbox/service-role/RLS/provider smoke evidence.
- Production evidence backlog con lai la sandbox/RLS/API/audit/provider/real-device smoke, khong phai blocker coding cua luot nay.

## Uu tien tiep theo

| Priority | Module | Viec can lam tiep | Ly do |
|---:|---|---|---|
| 1 | M15-M19 Admin/Reconciliation/Reporting/Audit | Verify Admin SQL/RPC sandbox, RLS, audit rows, payment reversal, reconciliation run/status actions, report export, retention, and privacy filters; record acceptance evidence. | Code/SQL/static contracts/tests da 100%; can sandbox/staging evidence de dat production acceptance. |
| 2 | M06/M07/M02 Quota + AI | Run Supabase sandbox quota acceptance: Free 3/day AI chat, Free 3/month schedule, Plus/FamilyPlus bypass, idempotent commit, RLS/client write rejection. | Code/SQL gateway/tests da 100%; sandbox evidence la production acceptance backlog. |
| 3 | M05/M12 Auth sync + Referral | Verify cross-device profile/schedule AI request sync and registration-only referral attach anti-fraud cases in Supabase sandbox. | SQLite/cloud-sync/static referral contracts da 100%; live RLS/RPC smoke con lai. |
| 4 | M11 FamilyPlus | Verify FamilyPlus member lifecycle, selected subject context, owner-only writes, max-5 guard, and two-family RLS isolation in Supabase sandbox. | Runtime slice/SQL/contracts/tests da 100%; sandbox isolation evidence con lai. |
| 5 | M13/M14 Payment/Sale | Verify selected payment/Sale policy in sandbox/provider flow: manual approval, entitlement activation, 24h hold, conversion payout, suspended Sale, and audit rows. | Runtime/SQL/tests da 100%; provider/staging evidence van thieu. |

## Notes tu phien coding gan nhat

- 2026-07-01: M02/M05/M06/M07/M11/M12/M16/M17/M18/M19 coding 100% theo code+SQL/static contract+targeted tests: them v3 FamilyPlus runtime slice va route `/v3/familyplus`, SQL/RPC FamilyPlus owner-managed writes/max-5/idempotency/subject context; harden quota contract Free 3/day AI chat, Free 3/month schedule, Plus/FamilyPlus bypass, Asia/Ho_Chi_Minh period keys, idempotent commit va no client writes; hoan tat cloud-sync `personal_schedule_ai_requests` voi SQLite v12, snapshot/outbox/migration tests; them referral attach registration-only anti-fraud contract tests; cap nhat Admin payment reversal, reconciliation create_run, safe report catalog/export, audit DTO privacy contracts. Targeted format/analyze/tests pass trong phien; Flutter van in warning pubspec asset folder missing nhu baseline, command exit 0. Production backlog: Supabase sandbox/service-role/RLS/provider/audit/retention/real smoke.
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
