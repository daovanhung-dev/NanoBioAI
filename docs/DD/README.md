# Design Documents - BioAI / NanoBio Project

| Attribute | Value |
|---|---|
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md |
| BD Code | BD-BIOAI-PRODUCT-FLOW-002 |
| BD Version | 2.0 |
| Advanced Health Source BD | docs/BD/advanced_health/BD_BioAI_Advanced_Health_Features_v1.0.md (`BD-BIOAI-ADVANCED-HEALTH-001`) |
| Daily Proof and Wellness Rewards Addendum | docs/BD/wellness_rewards/BD_BioAI_Daily_Proof_Wellness_Rewards_v1.0.md (`BD-BIOAI-WELLNESS-REWARDS-001`) |
| Nabi Companion Notification BD | docs/BD/notification_Nabi/BD_thong_bao_nut_noi_Nabi.md (`BD-NABI-NOTIFICATION-001`) |
| DD Baseline Date | 2026-06-28 |
| Source-truth Baseline | `25018e8` |
| Last Updated | 2026-08-24 |
| Lifecycle | Current |
| DD decision | M01-M19/M30 Approved; M20-M29 Draft without module DD |
| Implementation | Partial aggregate; see module matrix |
| Verification | Static-verified; Runtime-unverified; Sandbox-unverified |

## Purpose
This folder contains split module DDs for M01-M19 and M30. `Approved` records a
business/DD decision only; it does not mean runtime complete. The matrix below
is the current source-derived status. M20-M29 have a reachable catalog/access
placeholder but no module DD or business implementation. M30 has SQLite,
engine/repository/controller and Supabase source, but no app-shell trigger or
presentation wiring, so it is `Source-only`.

## Status Contract

- Lifecycle describes how the document is used: `Current`, `Historical`,
  `Generated`, `Reference`, `Source`, or `Binary`.
- Implementation describes reachable code: `Implemented`, `Partial`,
  `Placeholder`, `Source-only`, `Absent`, or `N/A`.
- Verification describes evidence: `Static-verified`, `Runtime-unverified`,
  `Sandbox-unverified`, or `Historical`.
- Static source/config evidence never substitutes for device, provider,
  production, or Supabase sandbox acceptance.

## Stitch Green Wellness Readiness — 2026-08-08

The [Wave 0 DD readiness and evidence pack](../refactor/stitch_nanobio_design_system/DD_READINESS.md) records pending decisions. It is a Draft gate document, not an Approved module DD or addendum. M20-M29 remain `Placeholder`; the shell is real reachable code but is not health-data/AI business behavior.

## Module Map

| BD | Module DD | DD decision | Implementation | Verification | Reachable/source evidence |
|---|---|---|---|---|---|
| M01 | [Onboarding and health profile](./onboarding_profile/README.md) | Approved | Implemented | Static-verified; Runtime-unverified; Sandbox-unverified | V1 onboarding route/controller/repository plus `main.dart` completion callback; 9-step catalog |
| M02 | [Personal schedule AI](./personal_schedule_ai/README.md) | Approved | Implemented | Static-verified; Runtime-unverified; Sandbox-unverified | `GeneratedPlanService`, onboarding first plan and dashboard additional-plan action |
| M03 | [Dashboard and schedule execution](./dashboard_schedule/README.md) | Approved | Implemented | Static-verified; Runtime-unverified; Sandbox-unverified | V1 dashboard/lifestyle schedule, completion/proof and wellness-reward gateways |
| M04 | [Basic health calculators](./basic_health_calculators/README.md) | Approved | Partial | Static-verified; Runtime-unverified | `/body-metrics` and versioned formula engine are reachable; DD Admin formula-version management is not end-to-end |
| M05 | [Auth, profile sync, and guest merge](./auth_profile_sync/README.md) | Approved | Implemented | Static-verified; Runtime-unverified; Sandbox-unverified | V2 auth routes/controller, reactive gate and cloud-sync flow |
| M06 | [Membership and quota](./membership_quota/README.md) | Approved | Implemented | Static-verified; Runtime-unverified; Sandbox-unverified | Effective-access providers and trusted quota gateways/RPC source |
| M07 | [AI Chat](./ai_chat/README.md) | Approved | Implemented | Static-verified; Runtime-unverified; Sandbox-unverified | Auth-protected text/voice routes, controllers and REST/STT/TTS sources |
| M08 | [Health score and habits](./health_score_habits/README.md) | Approved | Implemented | Static-verified; Runtime-unverified; Sandbox-unverified | V2 health-score route/providers/repository and ledger SQL source |
| M09 | [Schedule notifications](./schedule_notifications/README.md) | Approved | Implemented | Static-verified; Runtime-unverified; Sandbox-unverified | Notification bootstrap, scheduler, lifecycle refresh and action handler |
| M10 | [Advanced tracking and goals](./advanced_tracking_goals/README.md) | Approved | Partial | Static-verified; Runtime-unverified; Sandbox-unverified | Reachable V3 advanced-hydration goal/roadmap slice; broader multi-goal/plan adjustment in BD is absent |
| M11 | [FamilyPlus](./familyplus/README.md) | Approved | Implemented | Static-verified; Runtime-unverified; Sandbox-unverified | V3 FamilyPlus route/page/repository and family RPC source |
| M12 | [Sale and direct referral](./referral_direct/README.md) | Approved | Implemented | Static-verified; Runtime-unverified; Sandbox-unverified | Protected Sale route, registration/referral repository and RPC source |
| M13 | [Payment, verification, and entitlement](./payment_membership/README.md) | Approved | Implemented | Static-verified; Runtime-unverified; Sandbox-unverified | Membership payment route, VietQR request/confirm and Admin review source |
| M14 | [Sale points and conversion](./sale_points/README.md) | Approved | Implemented | Static-verified; Runtime-unverified; Sandbox-unverified | Sale wallet/conversion UI/repository and Admin conversion RPC source |
| M15 | [Admin dashboard](./admin_dashboard/README.md) | Approved | Implemented | Static-verified; Runtime-unverified; Sandbox-unverified | Admin surface/router, safe summary metrics and permissioned drill-down sections |
| M16 | [Admin operations](./admin_operations/README.md) | Approved | Implemented | Static-verified; Runtime-unverified; Sandbox-unverified | Admin user/payment/Sale/plan/config operations and mutation RPC mapping |
| M17 | [Reconciliation](./reconciliation/README.md) | Approved | Partial | Static-verified; Runtime-unverified; Sandbox-unverified | Reachable Admin reconciliation run/status flow; source only detects a limited discrepancy class and has no scheduled runner |
| M18 | [Statistics and reporting](./reporting/README.md) | Approved | Partial | Static-verified; Runtime-unverified; Sandbox-unverified | Reachable report catalog/export-request flow; no report file producer/download path |
| M19 | [Audit, security, and support](./audit_security/README.md) | Approved | Partial | Static-verified; Runtime-unverified; Sandbox-unverified | Auth/access/RLS/audit event surface exists; full support/ticket, retention and response scope is not end-to-end |
| M30 | [Nabi companion notifications](./nabi_companion_notifications/README.md) | Approved | Source-only | Static-verified; Runtime-unverified; Sandbox-unverified | SQLite v15/current v20 tables, catalog/engine/local repository/controller and Supabase RPC/RLS source; no app-shell trigger/presentation wiring |

## Approved Cross-Module Delta - 2026-07-13

The following implementation deltas trace `BD-BIOAI-WELLNESS-REWARDS-001` to the existing Approved module contracts:

| Module | Delta | Main contract |
|---|---|---|
| M03 | [Dashboard and schedule execution](./dashboard_schedule/Implementation_Delta_2026-07-13.md) | 30-minute execution window, camera proof, local/cloud reconciliation and proof gallery |
| M08 | [Health score and habits](./health_score_habits/Implementation_Delta_2026-07-13.md) | Separate Wellness Point wallet, pending/available/expiry/FEFO and voucher experience |
| M09 | [Schedule notifications](./schedule_notifications/Implementation_Delta_2026-07-13.md) | Notification opens the exact item for camera capture; no background completion |
| M15 | [Admin dashboard](./admin_dashboard/Implementation_Delta_2026-07-13.md) | Wellness reward inventory, transaction and rollout observability |
| M16 | [Admin operations](./admin_operations/Implementation_Delta_2026-07-13.md) | Offer/code administration, atomic cancel/refund and audit contract |

The addendum is the higher-priority source for conflicts limited to this feature. It does not replace unrelated rules in the product-flow baseline.

## Planned DD Backlog — M20-M29

| BD | Planned Module DD | Module Code | DD decision | Implementation | Verification |
|---|---|---|---|---|---|
| M20 | Not created | BLOOD_PRESSURE_TRACKING | Draft | Placeholder | Static-verified; Runtime-unverified |
| M21 | Not created | HEART_OXYGEN_TRACKING | Draft | Placeholder | Static-verified; Runtime-unverified |
| M22 | Not created | MEDICATION_ADHERENCE | Draft | Placeholder | Static-verified; Runtime-unverified |
| M23 | Not created | GLUCOSE_TRACKING | Draft | Placeholder | Static-verified; Runtime-unverified |
| M24 | Not created | SYMPTOM_PAIN_JOURNAL | Draft | Placeholder | Static-verified; Runtime-unverified |
| M25 | Not created | WOMENS_CYCLE_HEALTH | Draft | Placeholder | Static-verified; Runtime-unverified |
| M26 | Not created | RESPIRATORY_ALLERGY_TRACKING | Draft | Placeholder | Static-verified; Runtime-unverified |
| M27 | Not created | LAB_RESULT_TRACKING | Draft | Placeholder | Static-verified; Runtime-unverified |
| M28 | Not created | PREVENTIVE_CARE | Draft | Placeholder | Static-verified; Runtime-unverified |
| M29 | Not created | AI_HEALTH_TRENDS | Draft | Placeholder | Static-verified; Runtime-unverified |

Coding gate for M20-M29: only the UI catalog shell and shared development placeholder described by AHF-BR-001..006 are approved. Do not create DD folders or implement health-data/AI behavior until each module DD is approved.

## Reading Order
1. Read this file first.
2. Read the module README.md.
3. Read Overall.md before List_Features.md, Function_List.md, Views.md, and Import_File.md.
4. For coding, follow accepted decisions in the module contract and keep implementation evidence current in the backlog checklist.

## Cross-Project Critical Rules
- Guest is a closed allowlist: only BD-listed V1 features are available before login.
- Package entitlement and Sale/Admin role are independent axes.
- Sale is direct referral only: no Sale tree, no tier-2 commission, and no 5 percent legacy rate.
- Only active Plus or FamilyPlus members can become active Sale.
- Referral code is accepted only during registration unless Super Admin performs an audited override.
- Payment and payout are manual: trusted recorder can create pending evidence, but Admin approval creates payment_approved or payout approval.
- Pending payment never grants rights; only payment_approved activates entitlement and commission.
- Commission is 10 percent of listed price; FamilyPlus commission uses owner portion only.
- Points are credited after approved payment, held from conversion for 24 hours, and convert at 1 point = 1 VND with minimum 500,000 VND unless Admin changes versioned config.
- Schedule completion is allowed only in `[start_time, start_time + 30 minutes]` in `Asia/Ho_Chi_Minh`; invalid time data fails closed, and eligible online completion requires private camera proof.
- Wellness Points are a third, account-scoped point system: they are separate from Health Points and Sale Points, award `+10` per eligible completion, become available at window end, expire under the applicable versioned policy, and are spent FEFO.
- Guest/offline completion may retain local proof but never creates redeemable Wellness Points. Keep the wellness-rewards rollout flag disabled until migration, private Storage, RLS, concurrency, inventory, and cancellation paths pass sandbox acceptance.
- Refund/cancel is allowed only within 24 hours after purchase and reverses points immediately.
- Suspended or closed Sale accounts receive no new points from old customers.
- FamilyPlus supports up to 5 members; joined members can view all information of each other in the package.
- Vietnam timezone `Asia/Ho_Chi_Minh` is authoritative for quotas, reports, holds, refunds, schedules, and audit display.
- Admin groups are Super Admin, Finance Admin, Support Admin, and Content Admin; only Super Admin can edit sensitive/all data or manually adjust Sale points.
- Sale customer views may include phone and basic profile data for care, but never health data, AI data, secrets, or raw payment payloads.
- Payment, entitlement, commission ledger, conversion, adjustment, quota, family access, and audit writes must be idempotent and traceable.
- No DD file should contain secrets, production PII, raw health records, raw payment evidence, or raw webhook payloads.

## Accepted Decision Registry

| ID | Decision | Affected Modules | Source |
|---|---|---|---|
| Q-01 | Only members with Plus or higher active package can become Sale. | REFERRAL_DIRECT | User decision 2026-06-30 |
| Q-02 | A referral is successful when the referred customer payment is manually approved. Points are credited immediately after approval, but conversion is locked for 24 hours. | SALE_POINTS | User decision 2026-06-30 |
| Q-03 | Commission is calculated from the listed package price. | PAYMENT_MEMBERSHIP, SALE_POINTS | User decision 2026-06-30 |
| Q-04 | Plus and FamilyPlus support monthly and yearly plans. Early renewal extends from current expiry; late renewal starts from Admin approval time; pending payment never grants rights. | MEMBERSHIP_QUOTA, PAYMENT_MEMBERSHIP | User decision 2026-06-30 |
| Q-05 | Refund/cancel is allowed only within 24 hours after purchase. Points are reversed immediately in that window. Because conversion is also locked for 24 hours, there is no converted-then-reversed case. | PAYMENT_MEMBERSHIP, SALE_POINTS, RECONCILIATION | User decision 2026-06-30 |
| Q-06 | 1 point = 1 VND. Minimum conversion is 500,000 VND. Rate and minimum are Admin-configurable and versioned over time. | SALE_POINTS | User decision 2026-06-30 |
| Q-07 | Sale submits bank info and a conversion request. Admin transfers manually, then approves and deducts points. | SALE_POINTS | User decision 2026-06-30 |
| Q-08 | Referral code is accepted only during registration. Any post-registration correction requires audited Super Admin override. | AUTH_PROFILE_SYNC, REFERRAL_DIRECT | User decision 2026-06-30 |
| Q-09 | Use the strictest policy: hard-block same account, phone, email, payment, bank, device, or identity; hold suspicious IP/device/family/payment patterns for Admin review; only audited Super Admin override may release. | REFERRAL_DIRECT | User decision 2026-06-30 |
| Q-10 | Suspended or closed Sale accounts receive no new points from old customers. | REFERRAL_DIRECT, SALE_POINTS, RECONCILIATION | User decision 2026-06-30 |
| Q-11 | FamilyPlus commission is calculated only on the package owner portion. | FAMILYPLUS, PAYMENT_MEMBERSHIP, SALE_POINTS | User decision 2026-06-30 |
| Q-12 | All Admin groups exist: Super Admin, Finance Admin, Support Admin, and Content Admin. | ADMIN_DASHBOARD, ADMIN_OPS, REPORTING, AUDIT_SECURITY | User decision 2026-06-30 |
| Q-13 | Admin has broad operational power, but only Super Admin can edit sensitive data, perform full-data edits, or make manual Sale point adjustments. Each action requires reason, idempotency, and audit. | SALE_POINTS, ADMIN_OPS, RECONCILIATION, AUDIT_SECURITY | User decision 2026-06-30 |
| Q-14 | Use reference wellness formulas only, not diagnosis: BMI by CDC, BMR/RMR by Mifflin-St Jeor, TDEE by activity factor, hydration by National Academies DRI, sleep/activity by CDC. M08 health score is versioned and separate from daily local score. | ONBOARDING_PROFILE, BASIC_HEALTH_CALC, HEALTH_SCORE_HABITS, ADVANCED_TRACKING_GOALS | User decision 2026-06-30 |
| Q-15 | FamilyPlus has up to 5 members. Every joined member in the package can view all information of every other member in the package. | ONBOARDING_PROFILE, DASHBOARD_SCHEDULE, HEALTH_SCORE_HABITS, SCHEDULE_NOTIFICATIONS, ADVANCED_TRACKING_GOALS, FAMILYPLUS | User decision 2026-06-30 |
| Q-16 | Use Vietnam timezone, Asia/Ho_Chi_Minh. | PERSONAL_SCHEDULE_AI, AUTH_PROFILE_SYNC, MEMBERSHIP_QUOTA, AI_CHAT, SCHEDULE_NOTIFICATIONS, REPORTING | User decision 2026-06-30 |
| Q-17 | All payments and transfers are manually reviewed and manually approved by Admin. Trusted recorder may only create pending evidence; only Admin approval creates payment_approved. | PAYMENT_MEMBERSHIP, ADMIN_OPS, RECONCILIATION | User decision 2026-06-30 |
| Q-18 | Sale may see customer phone number and basic profile information for customer care, but cannot see health data, AI data, secrets, or raw payment payloads. | REFERRAL_DIRECT, ADMIN_DASHBOARD, ADMIN_OPS, REPORTING, AUDIT_SECURITY | User decision 2026-06-30 |

## Health Formula Reference Policy
- Health formulas are wellness references only and are not diagnosis or medical advice.
- M08 health score must be versioned and kept separate from the local daily score.
- CDC BMI: https://www.cdc.gov/bmi/about/index.html
- CDC BMI categories: https://www.cdc.gov/bmi/adult-calculator/bmi-categories.html
- Mifflin-St Jeor PubMed: https://pubmed.ncbi.nlm.nih.gov/2305711/
- National Academies water DRI: https://www.nationalacademies.org/read/10925/chapter/6
- CDC physical activity: https://www.cdc.gov/physical-activity-basics/guidelines/adults.html
- CDC sleep: https://www.cdc.gov/sleep/about/index.html

## Validation Notes
- This audit changed documentation only; it did not change runtime code, SQL, schema or RPC behavior.
- `DD_Module_Template/` remains the source template and intentionally still contains placeholders.
- M01-M19 DD decisions are Approved, but implementation status is independently recorded in the module matrix and must not be inferred from DD approval.
- The 2026-07-13 implementation deltas record exact source and targeted test evidence separately from DD completeness. The migration/config rebuild and local contract smoke are source-level evidence, not proof of deployment to a real Supabase project.
- Real Supabase sandbox bucket/RLS/API smoke and device camera/notification checks remain `Sandbox-unverified`/`Runtime-unverified`; they are not PASS.
