# Design Documents — BioAI / NanoBio Project

| Attribute | Value |
|---|---|
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md |
| BD Code | BD-BIOAI-PRODUCT-FLOW-002 |
| BD Version | 2.0 |
| DD Baseline Date | 2026-06-28 |
| Status | Draft |

## Purpose
This folder contains split module DDs for the full BioAI / NanoBio product flow M01-M19. Each module follows the live DD module template and keeps traceability to BD headings, UC, AC, and open questions.

## Module Map

| BD | Module DD | Module Code | Status | Source |
|---|---|---|---|---|
| M01 | [Onboarding & Hồ sơ sức khỏe](./onboarding_profile/README.md) | ONBOARDING_PROFILE | Draft | BD sections 6/M01, 13, 16.1 AC-01, Appendix A UC-01 |
| M02 | [AI Lịch trình cá nhân](./personal_schedule_ai/README.md) | PERSONAL_SCHEDULE_AI | Draft | BD sections 6/M02, 13, 16.1 AC-01/AC-02/AC-05/AC-06, Appendix A UC-02/UC-08 |
| M03 | [Dashboard & Thực hiện lịch trình](./dashboard_schedule/README.md) | DASHBOARD_SCHEDULE | Draft | BD sections 6/M03, 13, Appendix A UC-09 |
| M04 | [Tính toán sức khỏe cơ bản](./basic_health_calculators/README.md) | BASIC_HEALTH_CALC | Draft | BD sections 6/M04, 18.2 Q-14, Appendix A UC-03 |
| M05 | [Xác thực, hồ sơ và đồng bộ Guest](./auth_profile_sync/README.md) | AUTH_PROFILE_SYNC | Draft | BD sections 6/M05, 13, Appendix A UC-05 |
| M06 | [Gói thành viên & quota](./membership_quota/README.md) | MEMBERSHIP_QUOTA | Draft | BD sections 6/M06, 13, 16.1 AC-04..AC-08, Appendix A UC-06 |
| M07 | [AI Chat](./ai_chat/README.md) | AI_CHAT | Draft | BD sections 6/M07, 16.1 AC-03/AC-04/AC-06, Appendix A UC-07 |
| M08 | [Điểm sức khỏe & thói quen](./health_score_habits/README.md) | HEALTH_SCORE_HABITS | Draft | BD sections 6/M08, 9, 13, Appendix A UC-09 |
| M09 | [Thông báo lịch trình](./schedule_notifications/README.md) | SCHEDULE_NOTIFICATIONS | Draft | BD sections 6/M09, 13, Appendix A UC-04 |
| M10 | [Theo dõi nâng cao & mục tiêu](./advanced_tracking_goals/README.md) | ADVANCED_TRACKING_GOALS | Draft | BD sections 6/M10, 16.1 AC-06, Appendix A UC-10 |
| M11 | [FamilyPlus](./familyplus/README.md) | FAMILYPLUS | Draft | BD sections 10/M11, 13, 14.2, 16.1 AC-06, Appendix A UC-11 |
| M12 | [Sale & mã giới thiệu trực tiếp](./referral_direct/README.md) | REFERRAL_DIRECT | Draft | BD sections 7/M12, 15, 16.2 AC-09/AC-10/AC-14, Appendix A UC-12..UC-14 |
| M13 | [Thanh toán, xác minh và quyền gói](./payment_membership/README.md) | PAYMENT_MEMBERSHIP | Draft | BD sections 8/M13, 14.4, 15, 16.1 AC-07/AC-08, 16.3 AC-20/AC-21, Appendix A UC-15/UC-16 |
| M14 | [Điểm Sale & quy đổi](./sale_points/README.md) | SALE_POINTS | Draft | BD sections 7.5..7.10, 9, 12.1, 14.4, 16.2 AC-11..AC-18, Appendix A UC-17..UC-19 |
| M15 | [Admin View / Dashboard](./admin_dashboard/README.md) | ADMIN_DASHBOARD | Draft | BD sections 11.1/11.2, 12.2, 16.3 AC-19, Appendix A UC-20 |
| M16 | [Admin quản lý hệ thống](./admin_operations/README.md) | ADMIN_OPS | Draft | BD sections 11.3..11.7, 16.3 AC-20..AC-24, Appendix A UC-21 |
| M17 | [Tính toán & đối soát](./reconciliation/README.md) | RECONCILIATION | Draft | BD section 12.1, 14.4, 15, Appendix A UC-22 |
| M18 | [Thống kê & báo cáo](./reporting/README.md) | REPORTING | Draft | BD section 12.2, 14.2, 16.3 AC-23, Appendix A UC-24 |
| M19 | [Audit, bảo mật & hỗ trợ](./audit_security/README.md) | AUDIT_SECURITY | Draft | BD sections 11.8, 14, 15, 16.3 AC-20/AC-21/AC-24, Appendix A UC-23 |

## Reading Order
1. Read this file first.
2. Read the module README.md.
3. Read Overall.md before List_Features.md, Function_List.md, Views.md, and Import_File.md.
4. For coding, do not implement Draft behavior until open product decisions and API/schema/RLS contracts are resolved.

## Cross-Project Critical Rules
- Guest is a closed allowlist: only BD-listed V1 features are available before login.
- Package entitlement and Sale/Admin role are independent axes.
- Sale is direct referral only: no level-2 commission, no 5% rate, and no Sale tree.
- Payment only creates pending rights until Admin or approved trusted process creates payment_approved.
- Sale points are credited only after a valid approved payment and an eligible direct referral.
- Payment, entitlement, commission ledger, conversion, adjustment, quota, family access, and audit writes must be idempotent and traceable.
- No DD file should contain secrets, production PII, raw health records, raw payment evidence, or raw webhook payloads.

## Open Questions
The BD defines Q-01..Q-18. Q-02..Q-10 and Q-17 remain coding blockers for payment, commission, Sale point conversion, and financial reconciliation.

| Question Range | Affected Modules |
|---|---|
| Q-01, Q-08, Q-09, Q-10, Q-18 | REFERRAL_DIRECT |
| Q-02..Q-07, Q-10, Q-11, Q-13 | SALE_POINTS |
| Q-03..Q-05, Q-11, Q-17 | PAYMENT_MEMBERSHIP |
| Q-12, Q-13, Q-18 | ADMIN_DASHBOARD, ADMIN_OPS, AUDIT_SECURITY |
| Q-14, Q-15, Q-16 | health, family, quota, reporting modules |

## Validation Notes
- Runtime code is out of scope for this DD creation pass.
- DD_Module_Template/ remains the source template and intentionally still contains placeholders.
- Generated module DDs must be validated excluding the template folder.
