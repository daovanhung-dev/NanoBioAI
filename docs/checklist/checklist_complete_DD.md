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
| M01 `ONBOARDING_PROFILE` | Approved - DD docs complete | 0 | 100 | 60 | V1 onboarding local hardening and tests exist; DD docs have accepted health and FamilyPlus visibility policy. | Supabase/profile sync, subject-aware FamilyPlus reads, consent/audit smoke evidence. | Verify profile sync and FamilyPlus subject read/write evidence in implementation phase. |
| M02 `PERSONAL_SCHEDULE_AI` | Approved - DD docs complete | 0 | 100 | 80 | Local request ledger, guest guard, idempotency, quota gateway, and targeted tests exist; DD docs have timezone policy. | M06 trusted quota backend/RPC, FamilyPlus subject ownership, Asia/Ho_Chi_Minh quota boundary evidence. | Wire production quota commit and verify day-boundary behavior with M06/M11. |
| M03 `DASHBOARD_SCHEDULE` | Approved - DD docs complete | 0 | 100 | 40 | Dashboard, timeline, lifestyle completion, and tests exist; DD docs have FamilyPlus visibility policy. | Subject-aware dashboard mapping, cross-member traceability, and acceptance evidence. | Map current widgets to DD views and add subject-aware dashboard tests. |
| M04 `BASIC_HEALTH_CALC` | Approved - DD docs complete | 0 | 100 | 40 | BMI/nutrition constants and local calculator pieces exist; DD docs have formula source policy. | Formula version config, disclaimer copy, and production tests. | Promote formulas into tested services with source/version/disclaimer traceability. |
| M05 `AUTH_PROFILE_SYNC` | Approved - DD docs complete | 0 | 100 | 60 | V2 auth, Supabase auth datasource, account security, and cloud sync tests exist; DD docs have referral attach timing and timezone. | Guest merge/profile sync edge cases and Supabase evidence. | Verify registration-only referral attach, guest merge, and profile sync across devices. |
| M06 `MEMBERSHIP_QUOTA` | Approved - DD docs complete | 0 | 100 | 60 | SQL drafts and quota placeholders exist; DD docs have package lifecycle and timezone. | Trusted quota write, effective access service, reset policy, and sandbox/RLS evidence. | Implement/verify entitlement and quota RPC guards for AI chat and schedule. |
| M07 `AI_CHAT` | Approved - DD docs complete | 0 | 100 | 40 | V1 AI chat UI/service/repository exist; DD docs have timezone and quota dependency contract. | M06 quota gate before production AI calls. | Add quota check, safe blocked state, and tests for Free limit and paid bypass. |
| M08 `HEALTH_SCORE_HABITS` | Approved - DD docs complete | 0 | 100 | 40 | Local v2 health scoring draft, providers, route, and tests exist; DD docs have formula and FamilyPlus visibility policy. | Official score formula version, ledger/backend contract, and sandbox evidence. | Replace local draft with versioned wellness formula and add subject-aware ledger/RLS tests. |
| M09 `SCHEDULE_NOTIFICATIONS` | Approved - DD docs complete | 0 | 100 | 40 | Local notification scheduling, lifecycle, action handler, and tests exist; DD docs have timezone and FamilyPlus visibility. | Subject-aware notification and cross-device sync evidence. | Add subject metadata contracts and tests for permission denied, refresh, and package member visibility. |
| M10 `ADVANCED_TRACKING_GOALS` | Approved - DD docs complete | 0 | 100 | 10 | V3 advanced tracking remains a planned implementation slice; DD docs have formulas and FamilyPlus visibility policy. | First paid tracking metric, storage, UI slice, repository, and tests. | Choose one paid metric slice and add repository, UI, and tests using accepted formula/subject policy. |
| M11 `FAMILYPLUS` | Approved - DD docs complete | 0 | 100 | 60 | FamilyPlus SQL draft and placeholders exist; DD docs have max 5, full member visibility, and owner-only commission. | Invite/remove lifecycle, repository/UI slice, and RLS isolation evidence. | Verify member lifecycle and two-family isolation in sandbox. |
| M12 `REFERRAL_DIRECT` | Approved - DD docs complete | 0 | 100 | 80 | Sale direct-only runtime and tests are repo-ready; DD docs have Sale eligibility, referral lock, fraud policy, inactive Sale behavior, and privacy. | Supabase RPC/RLS sandbox evidence and anti-fraud smoke cases. | Smoke Sale request, Admin approval/suspend, referral attach, fraud hold, and privacy DTOs. |
| M13 `PAYMENT_MEMBERSHIP` | Approved - DD docs complete | 0 | 100 | 60 | Payment/membership SQL drafts and Admin review RPC draft exist; DD docs have commission base, package lifecycle, refund window, owner-only FamilyPlus commission, and manual approval. | Sandbox payment approval, entitlement activation, idempotency, and provider evidence. | Test manual payment approval, no pending-rights grant, 24h cancel/refund, and entitlement extension. |
| M14 `SALE_POINTS` | Approved - DD docs complete | 0 | 100 | 80 | Sale ledger/conversion request, Admin queue, SQL contracts, and tests are repo-ready; DD docs have commission and payout policy. | Sandbox conversion queue, payout audit, and reconciliation edge evidence. | Verify 24h hold, minimum conversion, manual payout, Super Admin adjustment, suspended Sale, and FamilyPlus owner-only cases. |
| M15 `ADMIN_DASHBOARD` | Approved - DD docs complete | 0 | 100 | 85 | Admin dashboard runtime has full active-Admin access policy, reconciliation route, target section, timezone default, and privacy-limited summaries. | Admin SQL/RPC/RLS and audit-safe metric evidence. | Verify Admin roles, dashboard metrics, drill-down target sections, and privacy DTOs in sandbox. |
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
| M01 `ONBOARDING_PROFILE` | Supabase/profile sync, subject-aware FamilyPlus reads, consent/audit smoke evidence. |
| M02 `PERSONAL_SCHEDULE_AI` | M06 trusted quota backend/RPC, FamilyPlus subject ownership, Asia/Ho_Chi_Minh quota boundary evidence. |
| M03 `DASHBOARD_SCHEDULE` | Subject-aware dashboard mapping, cross-member traceability, and acceptance evidence. |
| M04 `BASIC_HEALTH_CALC` | Formula version config, disclaimer copy, and production tests. |
| M05 `AUTH_PROFILE_SYNC` | Guest merge/profile sync edge cases and Supabase evidence. |
| M06 `MEMBERSHIP_QUOTA` | Trusted quota write, effective access service, reset policy, and sandbox/RLS evidence. |
| M07 `AI_CHAT` | M06 quota gate before production AI calls. |
| M08 `HEALTH_SCORE_HABITS` | Official score formula version, ledger/backend contract, and sandbox evidence. |
| M09 `SCHEDULE_NOTIFICATIONS` | Subject-aware notification and cross-device sync evidence. |
| M10 `ADVANCED_TRACKING_GOALS` | First paid tracking metric, storage, UI slice, repository, and tests. |
| M11 `FAMILYPLUS` | Invite/remove lifecycle, repository/UI slice, and RLS isolation evidence. |
| M12 `REFERRAL_DIRECT` | Supabase RPC/RLS sandbox evidence and anti-fraud smoke cases. |
| M13 `PAYMENT_MEMBERSHIP` | Sandbox payment approval, entitlement activation, idempotency, and provider evidence. |
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
