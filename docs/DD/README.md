# Design Documents - BioAI / NanoBio Project

| Attribute | Value |
|---|---|
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md |
| BD Code | BD-BIOAI-PRODUCT-FLOW-002 |
| BD Version | 2.0 |
| Advanced Health Source BD | docs/BD/advanced_health/BD_BioAI_Advanced_Health_Features_v1.0.md (`BD-BIOAI-ADVANCED-HEALTH-001`) |
| Daily Proof and Wellness Rewards Addendum | docs/BD/wellness_rewards/BD_BioAI_Daily_Proof_Wellness_Rewards_v1.0.md (`BD-BIOAI-WELLNESS-REWARDS-001`) |
| DD Baseline Date | 2026-06-28 |
| Last Updated | 2026-07-13 |
| Status | M01-M19 Approved - DD docs complete; M20-M29 DD not started |

## Purpose
This folder contains split module DDs for the approved BioAI / NanoBio product-flow baseline M01-M19. The 2026-06-30 pass records accepted decisions for BD Q-01..Q-18, approves DD docs for M01-M19, and moves runtime/sandbox evidence to a separate implementation backlog. The Approved 2026-07-13 daily-proof and wellness-rewards addendum is traced through implementation deltas for M03, M08, M09, M15, and M16 without changing their Approved DD status. Advanced-health modules M20-M29 are registered below as a future DD backlog only; no DD folder has been created and the approved UI catalog shell does not change DD or business coding progress.

## Module Map

| BD | Module DD | Module Code | Status | Source |
|---|---|---|---|---|
| M01 | [Onboarding and health profile](./onboarding_profile/README.md) | ONBOARDING_PROFILE | Approved - DD docs complete | BD sections 6/M01, 13, 16.1 AC-01, Appendix A UC-01 |
| M02 | [Personal schedule AI](./personal_schedule_ai/README.md) | PERSONAL_SCHEDULE_AI | Approved - DD docs complete | BD sections 6/M02, 13, 16.1 AC-01/AC-02/AC-05/AC-06, Appendix A UC-02/UC-08 |
| M03 | [Dashboard and schedule execution](./dashboard_schedule/README.md) | DASHBOARD_SCHEDULE | Approved - DD docs complete | BD sections 6/M03, 13, Appendix A UC-09 |
| M04 | [Basic health calculators](./basic_health_calculators/README.md) | BASIC_HEALTH_CALC | Approved - DD docs complete | BD sections 6/M04, 18.2 Q-14, Appendix A UC-03 |
| M05 | [Auth, profile sync, and guest merge](./auth_profile_sync/README.md) | AUTH_PROFILE_SYNC | Approved - DD docs complete | BD sections 6/M05, 13, Appendix A UC-05 |
| M06 | [Membership and quota](./membership_quota/README.md) | MEMBERSHIP_QUOTA | Approved - DD docs complete | BD sections 6/M06, 13, 16.1 AC-04..AC-08, Appendix A UC-06 |
| M07 | [AI Chat](./ai_chat/README.md) | AI_CHAT | Approved - DD docs complete | BD sections 6/M07, 16.1 AC-03/AC-04/AC-06, Appendix A UC-07 |
| M08 | [Health score and habits](./health_score_habits/README.md) | HEALTH_SCORE_HABITS | Approved - DD docs complete | BD sections 6/M08, 9, 13, Appendix A UC-09 |
| M09 | [Schedule notifications](./schedule_notifications/README.md) | SCHEDULE_NOTIFICATIONS | Approved - DD docs complete | BD sections 6/M09, 13, Appendix A UC-04 |
| M10 | [Advanced tracking and goals](./advanced_tracking_goals/README.md) | ADVANCED_TRACKING_GOALS | Approved - DD docs complete | BD sections 6/M10, 16.1 AC-06, Appendix A UC-10 |
| M11 | [FamilyPlus](./familyplus/README.md) | FAMILYPLUS | Approved - DD docs complete | BD sections 10/M11, 13, 14.2, 16.1 AC-06, Appendix A UC-11 |
| M12 | [Sale and direct referral](./referral_direct/README.md) | REFERRAL_DIRECT | Approved - DD docs complete | BD sections 7/M12, 15, 16.2 AC-09/AC-10/AC-14, Appendix A UC-12..UC-14 |
| M13 | [Payment, verification, and entitlement](./payment_membership/README.md) | PAYMENT_MEMBERSHIP | Approved - DD docs complete | BD sections 8/M13, 14.4, 15, 16.1 AC-07/AC-08, 16.3 AC-20/AC-21, Appendix A UC-15/UC-16 |
| M14 | [Sale points and conversion](./sale_points/README.md) | SALE_POINTS | Approved - DD docs complete | BD sections 7.5..7.10, 9, 12.1, 14.4, 16.2 AC-11..AC-18, Appendix A UC-17..UC-19 |
| M15 | [Admin dashboard](./admin_dashboard/README.md) | ADMIN_DASHBOARD | Approved - DD docs complete | BD sections 11.1/11.2, 12.2, 16.3 AC-19, Appendix A UC-20 |
| M16 | [Admin operations](./admin_operations/README.md) | ADMIN_OPS | Approved - DD docs complete | BD sections 11.3..11.7, 16.3 AC-20..AC-24, Appendix A UC-21 |
| M17 | [Reconciliation](./reconciliation/README.md) | RECONCILIATION | Approved - DD docs complete | BD section 12.1, 14.4, 15, Appendix A UC-22 |
| M18 | [Statistics and reporting](./reporting/README.md) | REPORTING | Approved - DD docs complete | BD section 12.2, 14.2, 16.3 AC-23, Appendix A UC-24 |
| M19 | [Audit, security, and support](./audit_security/README.md) | AUDIT_SECURITY | Approved - DD docs complete | BD sections 11.8, 14, 15, 16.3 AC-20/AC-21/AC-24, Appendix A UC-23 |

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

| BD | Planned Module DD | Module Code | DD Status | Source |
|---|---|---|---|---|
| M20 | Not created | BLOOD_PRESSURE_TRACKING | Not started - source BD Draft | Advanced Health BD M20, UC-25, M20-BR01..03, M20-AC01..03 |
| M21 | Not created | HEART_OXYGEN_TRACKING | Not started - source BD Draft | Advanced Health BD M21, UC-26, M21-BR01..03, M21-AC01..03 |
| M22 | Not created | MEDICATION_ADHERENCE | Not started - source BD Draft | Advanced Health BD M22, UC-27, M22-BR01..03, M22-AC01..03 |
| M23 | Not created | GLUCOSE_TRACKING | Not started - source BD Draft | Advanced Health BD M23, UC-28, M23-BR01..03, M23-AC01..03 |
| M24 | Not created | SYMPTOM_PAIN_JOURNAL | Not started - source BD Draft | Advanced Health BD M24, UC-29, M24-BR01..03, M24-AC01..03 |
| M25 | Not created | WOMENS_CYCLE_HEALTH | Not started - source BD Draft | Advanced Health BD M25, UC-30, M25-BR01..03, M25-AC01..03 |
| M26 | Not created | RESPIRATORY_ALLERGY_TRACKING | Not started - source BD Draft | Advanced Health BD M26, UC-31, M26-BR01..03, M26-AC01..03 |
| M27 | Not created | LAB_RESULT_TRACKING | Not started - source BD Draft | Advanced Health BD M27, UC-32, M27-BR01..03, M27-AC01..03 |
| M28 | Not created | PREVENTIVE_CARE | Not started - source BD Draft | Advanced Health BD M28, UC-33, M28-BR01..03, M28-AC01..03 |
| M29 | Not created | AI_HEALTH_TRENDS | Not started - source BD Draft | Advanced Health BD M29, UC-34, M29-BR01..05, M29-AC01..04 |

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
- Schedule completion is allowed only in `[start_time, start_time + 30 minutes)` in `Asia/Ho_Chi_Minh`; invalid time data fails closed, and eligible online completion requires private camera proof.
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
- Runtime code, SQL, Supabase config, and tests are out of scope for this DD docs 100 percent pass.
- `DD_Module_Template/` remains the source template and intentionally still contains placeholders.
- M01-M19 DD docs are complete at the documentation layer: status Approved, Open Q = 0, and traceability/contracts are documented.
- The 2026-07-13 implementation deltas record exact source and targeted test evidence separately from DD completeness. The migration/config rebuild and local contract smoke are source-level evidence, not proof of deployment to a real Supabase project.
- Real Supabase sandbox bucket/RLS/API smoke, device camera/notification checks, full-root validation and production acceptance remain in the implementation evidence backlog and do not reduce DD docs completeness.
