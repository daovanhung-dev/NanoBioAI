# Checklist Task Coding

Commit de xuat: docs(checklist): khoi tao task coding theo DD progress

## Metadata

| Field | Value |
|---|---|
| Nguon | `docs/checklist/checklist_complete_DD.md` |
| Ngay cap nhat | 2026-06-28 |
| Muc dich | Ghi lai cong viec coding tiep theo tu tien do DD module cua phien truoc. |

## DD Progress Next Tasks

- [ ] Truoc moi phien coding, doc `docs/checklist/checklist_complete_DD.md` de chon DD module, phan tram hien tai, blocker va next step.
- [ ] Sau do doc file nay de tiep tuc note dang do cua phien truoc.
- [ ] Neu module can code van `Draft`, chi code phan khong bi open question chan; neu blocker anh huong behavior thi cap nhat checklist thay vi invent rule.
- [ ] Sau moi phien coding, cap nhat `docs/checklist/checklist_complete_DD.md` va ghi task tiep theo vao file nay.

## Uu tien tiep theo

| Priority | Module | Viec can lam tiep | Ly do |
|---:|---|---|---|
| 1 | M15/M16 Admin | Chot role matrix Q-12/Q-18, resolve `plans.write` vs `config.write`, verify Admin SQL/RPC sandbox va ghi acceptance evidence. | Admin da co scaffold + SQL draft + permission/error-state tests; can policy + sandbox verification de tang tu 60 len 80. |
| 2 | M12/M14 Sale | Repo-ready da co; tiep theo verify Sale RPC/RLS sandbox va ghi acceptance evidence cho request Sale/referral/conversion queue. | Sale direct-only co app/Admin/SQL contract/tests, nhung chua production-ready khi sandbox va financial open questions chua dong. |
| 3 | M06/M07 Quota + AI Chat | Chot quota reset/trusted write va wire trusted quota backend cho AI chat; M02 runtime guard da co interface truoc AI nhung production adapter van blocked. | Quota la dependency production cho AI Chat va Personal Schedule. |
| 4 | M01/M02/M03 Guest flow | M02 runtime local da harden; tiep theo doi chieu M03 dashboard state va M01 cloud/FamilyPlus contract. | V1 runtime local da tien len, nhung cloud sync, subject/consent va dashboard state van bi open questions chan. |
| 5 | M13/M17 Payment/Reconciliation | Chot provider/refund/chargeback/reconciliation policy truoc khi code them. | Financial behavior bi chan boi Q-03..Q-10 va Q-17. |

## Notes tu phien coding gan nhat

- 2026-06-28: M12/M14 Sale repo-ready: go local commission estimator khoi Sale UI, conversion request dung trusted RPC config/idempotency retry, them Admin `saleConversions` queue route/action mapping, SQL 12 dung `sales.write`, va targeted Sale/Admin/docs tests pass.
- 2026-06-28: M01 safe hardening da code/test local: sanitize onboarding logs, DB injection cho local datasource test, persistence/markCompleted/outbox tests, completion handoff va double-submit tests. Quick check fail o `flutter analyze` do analyzer issues toan cuc san co/ngoai pham vi; xem worklog 006.
- 2026-06-28: Khoi tao checklist task coding tu `checklist_complete_DD.md`; chua co runtime change trong phien nay.
- 2026-06-29: M02 runtime guard da code/test local: SQLite v10 request ledger + `guest_initial_plan_used`, `GeneratedPlanService` request/idempotency guard, member quota gateway truoc AI, dashboard append generation, safe quota/guest-used errors, targeted generated-plan/onboarding/migration/lifestyle tests pass. Con blocker production: M06 trusted quota RPC/RLS sandbox, Q-16, FamilyPlus subject/ownership.
- 2026-06-29: M08 local draft da code/test: `lib/app_versions/v2/features/health_scoring/` co calculator version `m08_local_draft_2026_06`, SQLite read model, providers, route `/v2/health-score`, widget/provider/datasource/domain tests pass. Con blocker official: Q-14 formula/weights/skip-miss va Q-15 FamilyPlus subject/consent.
- 2026-06-29: M15/M16 Admin permission/error-state hardening da code/test: Admin domain co section/mutation permission helpers, controller khong goi section/mutation RPC khi thieu quyen, UI filter nav/action va hien denied state, Admin/docs targeted analyze/test pass. Con blocker: Q-12/Q-18, `plans.write` vs `config.write`, sandbox SQL/RPC/audit evidence.
