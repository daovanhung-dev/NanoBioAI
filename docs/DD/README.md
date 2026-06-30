# Design Documents - BioAI / NanoBio Project

| Attribute | Value |
|---|---|
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md |
| BD Code | BD-BIOAI-PRODUCT-FLOW-002 |
| BD Version | 2.0 |
| DD Baseline Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
| Status | Approved - DD docs complete |

## Purpose
This folder contains split module DDs for the full BioAI / NanoBio product flow M01-M19. The 2026-06-30 pass records accepted decisions for BD Q-01..Q-18, approves DD docs for M01-M19, and moves runtime/sandbox evidence to a separate implementation backlog.

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
- Runtime, sandbox/RLS/API smoke, and production acceptance evidence remain in the implementation evidence backlog and do not reduce DD docs completeness.
