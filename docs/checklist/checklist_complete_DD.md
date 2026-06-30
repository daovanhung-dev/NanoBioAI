# Checklist Complete DD

Commit de xuat: docs(checklist): danh dau DD docs M01-M19 hoan thanh 100 phan tram

## Metadata

| Field | Value |
|---|---|
| Nguon | `docs/DD/README.md` va cac module `docs/DD/<module>/` |
| Pham vi | BioAI / NanoBio DD v2.0 M01-M19 |
| Loai tru | Module template folder, khong tinh vao M01-M19. |
| Ngay cap nhat | 2026-06-30 |
| Muc dich | Theo doi DD docs completeness rieng voi coding progress va implementation evidence backlog. |

## Rubric phan tram

`DD completeness %`:

| % | Dieu kien |
|---:|---|
| 0 | Chua co DD module. |
| 20 | Co folder DD module nhung thieu file baseline hoac thieu mapping. |
| 40 | Co du baseline DD nhung con open questions hoac thieu contract/API/schema/RLS/test traceability trong tai lieu. |
| 60 | Contract/API/schema/RLS da co mot phan nhung chua du de coding khong can hoi lai. |
| 80 | Product decisions, acceptance criteria, API/schema/RLS va test traceability da du cho targeted coding. |
| 100 | DD docs approved: status Approved, Open Q = 0, rule/API/schema/RLS/test traceability documented, approval checklist docs pass. |

`Coding progress %`: chi doi khi co bang chung code runtime, test, SQL/RPC, sandbox hoac acceptance thuc te.

## Tong hop M01-M19

| Module | DD docs status | Open Q | DD completeness % | Coding progress % | DD docs evidence | Implementation evidence backlog | Next implementation evidence |
|---|---|---:|---:|---:|---|---|---|
| M01 `ONBOARDING_PROFILE` | Approved - DD docs complete | 0 | 100 | 100 | V1 onboarding local hardening, authenticated local-first completion, outbox marker, snapshot tests, and shared `SubjectAccessContext` subject override tests exist. | Supabase sandbox/RLS profile sync evidence and consent/audit smoke evidence remain production acceptance backlog. | Smoke authenticated onboarding/profile sync in Supabase sandbox and verify consent/audit evidence. |
| M02 `PERSONAL_SCHEDULE_AI` | Approved - DD docs complete | 0 | 100 | 85 | Local request ledger, guest guard, idempotency, quota gateway, targeted tests, trusted quota RPC wrappers, and Asia/Ho_Chi_Minh adapter alignment exist. | Supabase sandbox/RLS quota execution, FamilyPlus subject ownership, and month-boundary evidence. | Execute schedule quota check/commit RPCs in Supabase sandbox and verify month-boundary behavior with M06/M11. |
| M03 `DASHBOARD_SCHEDULE` | Approved - DD docs complete | 0 | 100 | 100 | Dashboard, timeline, lifestyle completion, subject-aware datasource mapping, and FamilyPlus/non-FamilyPlus tests exist. | Supabase sandbox cross-member visibility and RLS smoke remain production acceptance backlog. | Verify dashboard subject visibility and traceability in sandbox. |
| M04 `BASIC_HEALTH_CALC` | Approved - DD docs complete | 0 | 100 | 100 | Versioned BMI/BMR/RMR/TDEE/hydration calculator, route `/body-metrics`, hub tile, disclaimer UI, and unit/widget tests exist. | Clinical/formula source review and production copy approval remain production acceptance backlog. | Verify production copy/formula references with PO/clinical review before release. |
| M05 `AUTH_PROFILE_SYNC` | Approved - DD docs complete | 0 | 100 | 70 | V2 auth, Supabase auth datasource, account security, cloud sync tests, local-first profile write path, and outbox retry tests exist; DD docs have referral attach timing and timezone. | Guest merge/profile sync cross-device/sandbox evidence and registration-only referral attach edge cases. | Verify guest merge, profile sync across devices, and referral attach policy in Supabase sandbox. |
| M06 `MEMBERSHIP_QUOTA` | Approved - DD docs complete | 0 | 100 | 70 | SQL quota RPC contracts, v2 effective access read model, shared trusted quota gateway, Asia/Ho_Chi_Minh quota seed, and targeted contract/unit tests exist. | Supabase sandbox/RLS verification for quota counters/events, idempotency, reset policy, and client write rejection. | Run `docs/supabase/config.sql` in sandbox and execute quota acceptance checks for Free, Plus, and FamilyPlus accounts. |
| M07 `AI_CHAT` | Approved - DD docs complete | 0 | 100 | 65 | AI Chat repository now checks quota before AI, commits only after successful response, maps safe blocked states, and has targeted tests. | Sandbox proof that Free limit blocks after 3/day and Plus/FamilyPlus bypass via M06 RPC. | Smoke AI Chat with authenticated Free and paid sandbox users, verifying no AI call when quota is denied. |
| M08 `HEALTH_SCORE_HABITS` | Approved - DD docs complete | 0 | 100 | 100 | Official `m08_wellness_v1_2026_06` formula, Vietnamese UI/disclaimer, FamilyPlus subject access tests, Supabase `health_score_ledgers` contract/RLS, providers, route, and tests exist. | Supabase sandbox ledger/RLS smoke remains production acceptance backlog. | Verify health score ledger read/write policy and FamilyPlus visibility in sandbox. |
| M09 `SCHEDULE_NOTIFICATIONS` | Approved - DD docs complete | 0 | 100 | 100 | Subject-aware notification payload v2, subject-stable reminder IDs, idempotent action handling, source-owner mismatch protection, permission-denied/refresh/package-member tests, cloud-sync contract, and architecture tests pass. | Production real-device notification and Supabase sandbox cross-device smoke remain outside code+test acceptance. | Run real-device notification delivery/action smoke and Supabase sandbox sync before production release. |
| M10 `ADVANCED_TRACKING_GOALS` | Approved - DD docs complete | 0 | 100 | 100 | V3 hydration advanced tracking slice implemented with Plus/FamilyPlus access gate, `advanced_hydration` goal storage in `health_goals`, roadmap progress from `health_tracking_logs.water_ml`, v3 route/page/providers/repository/use cases, widget/provider/data/use-case tests, cloud-sync contract, and architecture tests pass. | Production paid-access sandbox and FamilyPlus subject/RLS smoke remain outside code+test acceptance. | Run sandbox Plus/FamilyPlus access and subject visibility smoke before production release. |
| M11 `FAMILYPLUS` | Approved - DD docs complete | 0 | 100 | 60 | FamilyPlus SQL draft and placeholders exist; DD docs have max 5, full member visibility, and owner-only commission. | Invite/remove lifecycle, repository/UI slice, and RLS isolation evidence. | Verify member lifecycle and two-family isolation in sandbox. |
| M12 `REFERRAL_DIRECT` | Approved - DD docs complete | 0 | 100 | 80 | Sale direct-only runtime and tests are repo-ready; DD docs have Sale eligibility, referral lock, fraud policy, inactive Sale behavior, and privacy. | Supabase RPC/RLS sandbox evidence and anti-fraud smoke cases. | Smoke Sale request, Admin approval/suspend, referral attach, fraud hold, and privacy DTOs. |
| M13 `PAYMENT_MEMBERSHIP` | Approved - DD docs complete | 0 | 100 | 100 | V2 payments feature, client-safe pending payment RPC `create_membership_payment_request`, idempotency, price config, no pending-rights grant, 24h reversal guard, and targeted tests exist. | Provider/sandbox payment approval, entitlement activation, and external payment evidence remain production acceptance backlog. | Test manual payment approval, provider callback, entitlement activation, and 24h cancel/refund in sandbox. |
| M14 `SALE_POINTS` | Approved - DD docs complete | 0 | 100 | 100 | Sale ledger/conversion request, Admin queue, SQL contracts, privacy-limited direct customer DTO/UI, minimum conversion 500000 VND, and tests are repo-ready. | Sandbox conversion queue, payout audit, and reconciliation edge evidence remain production acceptance backlog. | Verify 24h hold, minimum conversion, manual payout, Super Admin adjustment, suspended Sale, and FamilyPlus owner-only cases. |
| M15 `ADMIN_DASHBOARD` | Approved - DD docs complete | 0 | 100 | 100 | Admin dashboard runtime/SQL has support/content roles, operations legacy alias, expanded safe summary metrics, drill-down target sections, timezone default, and privacy-limited summaries. | Admin SQL/RPC/RLS and audit-safe metric evidence remain production acceptance backlog. | Verify Admin roles, dashboard metrics, drill-down target sections, and privacy DTOs in sandbox. |
| M16 `ADMIN_OPS` | Approved - DD docs complete | 0 | 100 | 85 | Admin ops covers users, payments, sales, sale conversions, reconciliation, plans, reports, audit, config, manual payment approval, and audited point adjustment. | Sandbox mutation/RLS/audit evidence. | Run mutation RPCs with role checks, reason/idempotency, audit rows, and client write rejection. |
| M17 `RECONCILIATION` | Approved - DD docs complete | 0 | 100 | 65 | Reconciliation UI/RPC mapping exists; DD docs have 24h hold, no new points for suspended/closed Sale, Super Admin adjustment, and no ledger overwrite. | Provider/staging discrepancy data and sandbox edge cases. | Test pending payment mismatch, refund/cancel, held points, suspended Sale, and manual approval evidence. |
| M18 `REPORTING` | Approved - DD docs complete | 0 | 100 | 70 | Report export policy aligns to Admin groups, Vietnam timezone, audit, and basic customer-summary privacy. | Report catalog, retention, and sandbox export evidence. | Verify export request audit, privacy filters, no raw payloads, and timezone windowing. |
| M19 `AUDIT_SECURITY` | Approved - DD docs complete | 0 | 100 | 75 | Audit/security contracts cover Admin groups, Super Admin sensitive edits, point adjustment, reconciliation classify, and no raw sensitive payload exposure. | Security response, retention, sandbox audit rows, and no-raw-payload evidence. | Verify audit rows for payment, Sale, reconciliation, point adjustment, and Admin list privacy. |

## Accepted Decision Coverage

| Decision group | DD docs status | Implementation note |
|---|---|---|
| Q-01..Q-18 | Closed and approved in DD docs | Recorded in `docs/DD/README.md`, module README/Overall contracts, and changelogs on 2026-06-30. |
| Health formulas Q-14 | Approved for DD docs | Wellness-reference only; production must keep version config and disclaimer copy. |
| Sale/payment/payout | Approved for DD docs | Manual payment/payout approval, 24h hold, 24h refund/cancel, listed-price commission, owner-only FamilyPlus commission. |
| Admin/privacy | Approved for DD docs | Full Admin group model, Super Admin-only sensitive edits, Sale privacy-limited phone/basic customer info. |

## Implementation Evidence Backlog

| Module | Required implementation evidence before production acceptance |
|---|---|
| M01 `ONBOARDING_PROFILE` | Supabase sandbox/RLS profile sync evidence and consent/audit smoke evidence. |
| M02 `PERSONAL_SCHEDULE_AI` | Supabase sandbox/RLS quota execution, FamilyPlus subject ownership, and month-boundary evidence. |
| M03 `DASHBOARD_SCHEDULE` | Supabase sandbox cross-member visibility and RLS smoke evidence. |
| M04 `BASIC_HEALTH_CALC` | Clinical/formula source review and production copy approval evidence. |
| M05 `AUTH_PROFILE_SYNC` | Guest merge/profile sync cross-device/sandbox evidence and registration-only referral attach edge cases. |
| M06 `MEMBERSHIP_QUOTA` | Supabase sandbox/RLS verification for quota counters/events, idempotency, reset policy, and client write rejection. |
| M07 `AI_CHAT` | Sandbox proof that Free limit blocks after 3/day and Plus/FamilyPlus bypass via M06 RPC. |
| M08 `HEALTH_SCORE_HABITS` | Supabase sandbox ledger/RLS smoke evidence. |
| M09 `SCHEDULE_NOTIFICATIONS` | Production real-device notification delivery/action smoke and Supabase sandbox cross-device sync evidence before release. |
| M10 `ADVANCED_TRACKING_GOALS` | Production Plus/FamilyPlus sandbox access, subject visibility/RLS, and hydration roadmap smoke before release. |
| M11 `FAMILYPLUS` | Invite/remove lifecycle, repository/UI slice, and RLS isolation evidence. |
| M12 `REFERRAL_DIRECT` | Supabase RPC/RLS sandbox evidence and anti-fraud smoke cases. |
| M13 `PAYMENT_MEMBERSHIP` | Provider/sandbox payment approval, entitlement activation, and external payment evidence. |
| M14 `SALE_POINTS` | Sandbox conversion queue, payout audit, and reconciliation edge evidence. |
| M15 `ADMIN_DASHBOARD` | Admin SQL/RPC/RLS and audit-safe metric evidence. |
| M16 `ADMIN_OPS` | Sandbox mutation/RLS/audit evidence. |
| M17 `RECONCILIATION` | Provider/staging discrepancy data and sandbox edge cases. |
| M18 `REPORTING` | Report catalog, retention, and sandbox export evidence. |
| M19 `AUDIT_SECURITY` | Security response, retention, sandbox audit rows, and no-raw-payload evidence. |

## Quy tac Agent khi coding

- Truoc khi coding: doc file nay de xac dinh DD module, coding progress hien tai, implementation evidence backlog va next step.
- Sau do doc `docs/checklist/checklist_task_coding.md` de lay note cong viec tu phien truoc.
- Q-01..Q-18 khong con la PO blocker; khong invent rule khac neu conflict voi accepted decision registry.
- DD completeness da la 100% cho M01-M19; chi tang coding progress khi co code/test/SQL/sandbox evidence moi.
- Runtime/sandbox/RLS/API/audit evidence phai ghi worklog va cap nhat backlog truoc khi claim production acceptance.
