# Checklist Complete DD

Commit de xuat: docs(checklist): cap nhat DD readiness sau khi chot Q-01..Q-18

## Metadata

| Field | Value |
|---|---|
| Nguon | `docs/DD/README.md` va cac module `docs/DD/<module>/` |
| Pham vi | BioAI / NanoBio DD v2.0 M01-M19 |
| Loai tru | Module template folder, khong tinh vao M01-M19. |
| Ngay cap nhat | 2026-06-30 |
| Muc dich | Theo doi DD readiness va coding progress sau khi Q-01..Q-18 da duoc ghi thanh accepted product decisions. |

## Rubric phan tram

`DD readiness %`:

| % | Dieu kien |
|---:|---|
| 0 | Chua co DD module. |
| 20 | Co folder DD module nhung thieu file baseline hoac thieu mapping. |
| 40 | Co du baseline DD nhung con Status Draft, open questions, hoac thieu contract/API/schema/RLS cu the. |
| 60 | Contract/API/schema/RLS du ro de coding phan khong bi blocker, nhung con Supabase sandbox/RLS/API/audit evidence hoac paid slice. |
| 80 | Ready/approved cho targeted coding; product decisions, acceptance criteria va test traceability da chot. |
| 100 | Implemented va accepted theo DD voi runtime/test/sandbox evidence. |

`Coding progress %`: chi doi khi co bang chung code runtime, test, SQL/RPC, sandbox hoac acceptance thuc te.

## Tong hop M01-M19

| Module | DD status | Open Q | DD readiness % | Coding progress % | Tien do hien tai | Blocker chinh | Buoc tiep theo |
|---|---|---:|---:|---:|---|---|---|
| M01 `ONBOARDING_PROFILE` | In Review - product decisions answered | 0 | 80 | 60 | V1 onboarding local hardening and tests exist; DD now has accepted health and FamilyPlus visibility policy. | Supabase/profile sync and sandbox/RLS evidence remain before production cloud behavior. | Document and verify profile sync, subject-aware FamilyPlus reads, and consent/audit cases in sandbox. |
| M02 `PERSONAL_SCHEDULE_AI` | Draft - contracts updated, sandbox evidence pending | 0 | 60 | 80 | Local request ledger, guest guard, idempotency, quota gateway, and targeted tests exist; timezone policy is accepted. | M06 trusted quota backend/RPC and FamilyPlus subject ownership still need sandbox evidence. | Wire production quota commit and verify Asia/Ho_Chi_Minh day boundaries with M06/M11. |
| M03 `DASHBOARD_SCHEDULE` | In Review - product decisions answered | 0 | 80 | 40 | Dashboard, timeline, lifestyle completion, and tests exist; FamilyPlus visibility policy is accepted. | Detailed dashboard state mapping and cross-member traceability need acceptance evidence. | Map DD views/functions to current widgets and add subject-aware dashboard tests. |
| M04 `BASIC_HEALTH_CALC` | In Review - product decisions answered | 0 | 80 | 40 | BMI/nutrition constants and local calculator pieces exist; formula source policy is accepted. | Formula version config, disclaimer copy, and production tests remain. | Promote formula contracts into tested services with source/version/disclaimer traceability. |
| M05 `AUTH_PROFILE_SYNC` | Draft - contracts updated, sandbox evidence pending | 0 | 60 | 60 | V2 auth, Supabase auth datasource, account security, and cloud sync tests exist; referral attach timing and timezone are accepted. | Guest merge/profile sync edge cases and Supabase evidence remain. | Verify registration-only referral attach, guest merge, and profile sync across devices. |
| M06 `MEMBERSHIP_QUOTA` | Draft - contracts updated, sandbox evidence pending | 0 | 60 | 60 | SQL drafts and quota placeholders exist; package lifecycle and timezone are accepted. | Trusted quota write, effective access service, and reset policy need sandbox evidence. | Implement/verify entitlement and quota RPC guards for AI chat and schedule. |
| M07 `AI_CHAT` | In Review - product decisions answered | 0 | 80 | 40 | V1 AI chat UI/service/repository exist; timezone policy is accepted. | M06 quota gate must be wired before production AI calls. | Add quota check, safe blocked state, and tests for Free limit and paid bypass. |
| M08 `HEALTH_SCORE_HABITS` | In Review - product decisions answered | 0 | 80 | 40 | Local v2 health scoring draft, providers, route, and tests exist; formula and FamilyPlus visibility policy are accepted. | Official score formula version, ledger/backend contract, and sandbox evidence remain. | Replace local draft with versioned wellness formula and add subject-aware ledger/RLS tests. |
| M09 `SCHEDULE_NOTIFICATIONS` | In Review - product decisions answered | 0 | 80 | 40 | Local notification scheduling, lifecycle, action handler, and tests exist; timezone and FamilyPlus visibility are accepted. | Subject-aware notification and cross-device sync contracts need evidence. | Add subject metadata contracts and tests for permission denied, refresh, and package member visibility. |
| M10 `ADVANCED_TRACKING_GOALS` | Draft - contracts updated, paid slice pending | 0 | 60 | 10 | V3 advanced tracking is still a planned placeholder; formulas and FamilyPlus visibility are accepted. | First paid tracking metric, storage, and UI slice are not implemented. | Choose one paid metric slice and add repository, UI, and tests using accepted formula/subject policy. |
| M11 `FAMILYPLUS` | Draft - contracts updated, sandbox evidence pending | 0 | 60 | 60 | FamilyPlus SQL draft and placeholders exist; max 5, full member visibility, and owner-only commission are accepted. | Invite/remove lifecycle, repository/UI slice, and RLS isolation evidence remain. | Verify member lifecycle and two-family isolation in sandbox. |
| M12 `REFERRAL_DIRECT` | Draft - contracts updated, sandbox evidence pending | 0 | 60 | 80 | Sale direct-only runtime and tests are repo-ready; Sale eligibility, referral lock, fraud policy, inactive Sale behavior, and privacy are accepted. | Supabase RPC/RLS sandbox evidence and anti-fraud smoke cases remain. | Smoke user Sale request, Admin approval/suspend, referral attach, fraud hold, and Sale customer privacy DTOs. |
| M13 `PAYMENT_MEMBERSHIP` | Draft - contracts updated, sandbox evidence pending | 0 | 60 | 60 | Payment/membership SQL drafts and Admin review RPC draft exist; commission base, package lifecycle, refund window, owner-only FamilyPlus commission, and manual approval are accepted. | Sandbox payment approval, entitlement activation, and provider evidence remain. | Test idempotent manual payment approval, no pending-rights grant, 24h cancel/refund, and entitlement extension. |
| M14 `SALE_POINTS` | Draft - contracts updated, sandbox evidence pending | 0 | 60 | 80 | Sale ledger/conversion request, Admin queue, SQL contracts, and tests are repo-ready; commission and payout policy are accepted. | Sandbox conversion queue, payout audit, and reconciliation edge evidence remain. | Verify 24h hold, minimum conversion, manual payout, Super Admin adjustment, suspended Sale, and owner-only FamilyPlus cases. |
| M15 `ADMIN_DASHBOARD` | Draft - contracts updated, sandbox evidence pending | 0 | 60 | 85 | Admin dashboard runtime has full active-Admin access policy, reconciliation route, target section, timezone default, and privacy-limited summaries. | Admin SQL/RPC/RLS and audit-safe metric evidence remain. | Verify Admin roles, dashboard metrics, drill-down target sections, and privacy DTOs in sandbox. |
| M16 `ADMIN_OPS` | Draft - contracts updated, sandbox evidence pending | 0 | 60 | 85 | Admin ops covers users, payments, sales, sale conversions, reconciliation, plans, reports, audit, config, manual payment approval, and audited point adjustment. | Sandbox mutation/RLS/audit evidence remains. | Run every mutation RPC with role checks, reason/idempotency, audit row, and client write rejection. |
| M17 `RECONCILIATION` | Draft - contracts updated, sandbox evidence pending | 0 | 60 | 65 | Reconciliation UI/RPC mapping exists; 24h hold, no new points for suspended/closed Sale, Super Admin adjustment, and no ledger overwrite are accepted. | Provider/staging discrepancy data and sandbox edge cases remain. | Test pending payment mismatch, refund/cancel, held points, suspended Sale, and manual approval evidence. |
| M18 `REPORTING` | Draft - contracts updated, sandbox evidence pending | 0 | 60 | 70 | Report export policy aligns to Admin groups, Vietnam timezone, audit, and basic customer-summary privacy. | Report catalog, retention, and sandbox export evidence remain. | Verify export request audit, privacy filters, no raw payloads, and timezone windowing. |
| M19 `AUDIT_SECURITY` | Draft - contracts updated, sandbox evidence pending | 0 | 60 | 75 | Audit/security contracts cover Admin groups, Super Admin sensitive edits, point adjustment, reconciliation classify, and no raw sensitive payload exposure. | Security response, retention, sandbox audit rows, and no-raw-payload evidence remain. | Verify audit rows for payment, Sale, reconciliation, point adjustment, and Admin list privacy. |

## Accepted Decision Coverage

| Decision group | Status | Notes |
|---|---|---|
| Q-01..Q-18 | Closed | Recorded in `docs/DD/README.md`, module README/Overall contracts, and changelogs on 2026-06-30. |
| Health formulas Q-14 | Accepted | Wellness-reference only; formulas/source links recorded; production must version config and disclaimer copy. |
| Sale/payment/payout | Accepted | Manual payment and payout approval, 24h conversion hold, 24h refund/cancel window, listed-price commission, owner-only FamilyPlus commission. |
| Admin/privacy | Accepted | Full Admin group model, Super Admin-only sensitive edits, Sale privacy-limited customer phone/basic info. |

## Chi tiet module va next steps

| Module | Bang chung hien co | Con thieu de dat DD 100% | Next steps chi tiet |
|---|---|---|---|
| M01 `ONBOARDING_PROFILE` | V1 onboarding local hardening and tests exist; DD now has accepted health and FamilyPlus visibility policy. | Supabase/profile sync and sandbox/RLS evidence remain before production cloud behavior. | Document and verify profile sync, subject-aware FamilyPlus reads, and consent/audit cases in sandbox. |
| M02 `PERSONAL_SCHEDULE_AI` | Local request ledger, guest guard, idempotency, quota gateway, and targeted tests exist; timezone policy is accepted. | M06 trusted quota backend/RPC and FamilyPlus subject ownership still need sandbox evidence. | Wire production quota commit and verify Asia/Ho_Chi_Minh day boundaries with M06/M11. |
| M03 `DASHBOARD_SCHEDULE` | Dashboard, timeline, lifestyle completion, and tests exist; FamilyPlus visibility policy is accepted. | Detailed dashboard state mapping and cross-member traceability need acceptance evidence. | Map DD views/functions to current widgets and add subject-aware dashboard tests. |
| M04 `BASIC_HEALTH_CALC` | BMI/nutrition constants and local calculator pieces exist; formula source policy is accepted. | Formula version config, disclaimer copy, and production tests remain. | Promote formula contracts into tested services with source/version/disclaimer traceability. |
| M05 `AUTH_PROFILE_SYNC` | V2 auth, Supabase auth datasource, account security, and cloud sync tests exist; referral attach timing and timezone are accepted. | Guest merge/profile sync edge cases and Supabase evidence remain. | Verify registration-only referral attach, guest merge, and profile sync across devices. |
| M06 `MEMBERSHIP_QUOTA` | SQL drafts and quota placeholders exist; package lifecycle and timezone are accepted. | Trusted quota write, effective access service, and reset policy need sandbox evidence. | Implement/verify entitlement and quota RPC guards for AI chat and schedule. |
| M07 `AI_CHAT` | V1 AI chat UI/service/repository exist; timezone policy is accepted. | M06 quota gate must be wired before production AI calls. | Add quota check, safe blocked state, and tests for Free limit and paid bypass. |
| M08 `HEALTH_SCORE_HABITS` | Local v2 health scoring draft, providers, route, and tests exist; formula and FamilyPlus visibility policy are accepted. | Official score formula version, ledger/backend contract, and sandbox evidence remain. | Replace local draft with versioned wellness formula and add subject-aware ledger/RLS tests. |
| M09 `SCHEDULE_NOTIFICATIONS` | Local notification scheduling, lifecycle, action handler, and tests exist; timezone and FamilyPlus visibility are accepted. | Subject-aware notification and cross-device sync contracts need evidence. | Add subject metadata contracts and tests for permission denied, refresh, and package member visibility. |
| M10 `ADVANCED_TRACKING_GOALS` | V3 advanced tracking is still a planned placeholder; formulas and FamilyPlus visibility are accepted. | First paid tracking metric, storage, and UI slice are not implemented. | Choose one paid metric slice and add repository, UI, and tests using accepted formula/subject policy. |
| M11 `FAMILYPLUS` | FamilyPlus SQL draft and placeholders exist; max 5, full member visibility, and owner-only commission are accepted. | Invite/remove lifecycle, repository/UI slice, and RLS isolation evidence remain. | Verify member lifecycle and two-family isolation in sandbox. |
| M12 `REFERRAL_DIRECT` | Sale direct-only runtime and tests are repo-ready; Sale eligibility, referral lock, fraud policy, inactive Sale behavior, and privacy are accepted. | Supabase RPC/RLS sandbox evidence and anti-fraud smoke cases remain. | Smoke user Sale request, Admin approval/suspend, referral attach, fraud hold, and Sale customer privacy DTOs. |
| M13 `PAYMENT_MEMBERSHIP` | Payment/membership SQL drafts and Admin review RPC draft exist; commission base, package lifecycle, refund window, owner-only FamilyPlus commission, and manual approval are accepted. | Sandbox payment approval, entitlement activation, and provider evidence remain. | Test idempotent manual payment approval, no pending-rights grant, 24h cancel/refund, and entitlement extension. |
| M14 `SALE_POINTS` | Sale ledger/conversion request, Admin queue, SQL contracts, and tests are repo-ready; commission and payout policy are accepted. | Sandbox conversion queue, payout audit, and reconciliation edge evidence remain. | Verify 24h hold, minimum conversion, manual payout, Super Admin adjustment, suspended Sale, and owner-only FamilyPlus cases. |
| M15 `ADMIN_DASHBOARD` | Admin dashboard runtime has full active-Admin access policy, reconciliation route, target section, timezone default, and privacy-limited summaries. | Admin SQL/RPC/RLS and audit-safe metric evidence remain. | Verify Admin roles, dashboard metrics, drill-down target sections, and privacy DTOs in sandbox. |
| M16 `ADMIN_OPS` | Admin ops covers users, payments, sales, sale conversions, reconciliation, plans, reports, audit, config, manual payment approval, and audited point adjustment. | Sandbox mutation/RLS/audit evidence remains. | Run every mutation RPC with role checks, reason/idempotency, audit row, and client write rejection. |
| M17 `RECONCILIATION` | Reconciliation UI/RPC mapping exists; 24h hold, no new points for suspended/closed Sale, Super Admin adjustment, and no ledger overwrite are accepted. | Provider/staging discrepancy data and sandbox edge cases remain. | Test pending payment mismatch, refund/cancel, held points, suspended Sale, and manual approval evidence. |
| M18 `REPORTING` | Report export policy aligns to Admin groups, Vietnam timezone, audit, and basic customer-summary privacy. | Report catalog, retention, and sandbox export evidence remain. | Verify export request audit, privacy filters, no raw payloads, and timezone windowing. |
| M19 `AUDIT_SECURITY` | Audit/security contracts cover Admin groups, Super Admin sensitive edits, point adjustment, reconciliation classify, and no raw sensitive payload exposure. | Security response, retention, sandbox audit rows, and no-raw-payload evidence remain. | Verify audit rows for payment, Sale, reconciliation, point adjustment, and Admin list privacy. |

## Quy tac Agent khi coding

- Truoc khi coding: doc file nay de xac dinh module, phan tram hien tai, blocker va next step.
- Sau do doc `docs/checklist/checklist_task_coding.md` de lay note cong viec tu phien truoc.
- Q-01..Q-18 khong con la PO blocker; khong invent rule khac neu conflict voi accepted decision registry.
- Neu module van 60% DD readiness, chi nang len 80/100 khi co sandbox/RLS/API/audit evidence hoac paid vertical slice theo blocker.
- Sau khi coding: cap nhat lai phan tram, bang chung, next steps trong file nay va ghi viec tiep theo vao `docs/checklist/checklist_task_coding.md`.
