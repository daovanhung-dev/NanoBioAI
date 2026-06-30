# DD — Theo dõi nâng cao & mục tiêu

| Attribute | Value |
|---|---|
| Module Code | ADVANCED_TRACKING_GOALS |
| BD Module | M10 |
| Version | v1.0 |
| Status | Draft - contracts updated, paid slice pending |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M10, 16.1 AC-06, Appendix A UC-10 |

## Purpose
Hỗ trợ Plus/FamilyPlus chọn mục tiêu nâng cao và theo dõi lộ trình theo mục tiêu.

## Documents in This Module
- [Overall](./Overall.md)
- [Feature List](./List_Features.md)
- [Function List](./Function_List.md)
- [Views](./Views.md)
- [Import and File Mapping](./Import_File.md)
- [Diagrams](./diagrams/README.md)
- [Assets](./assets/README.md)
- [Change History](./history/CHANGELOG.md)

## Traceability Summary
- ADVANCED_TRACKING_GOALS-F01: Chọn mục tiêu nâng cao
- ADVANCED_TRACKING_GOALS-F02: Theo dõi lộ trình mục tiêu

## Dependent Modules
- MEMBERSHIP_QUOTA: Plus/FamilyPlus entitlement.
- HEALTH_SCORE_HABITS: progress data.
- PERSONAL_SCHEDULE_AI: schedule adjustments.

## Answered Questions
| ID | Question | Decision | Status |
|---|---|---|---|
| Q-14 | Which health formulas are used? | Use reference wellness formulas only, not diagnosis: BMI by CDC, BMR/RMR by Mifflin-St Jeor, TDEE by activity factor, hydration by National Academies DRI, sleep/activity by CDC. M08 health score is versioned and separate from daily local score. | Answered - User decision 2026-06-30 |
| Q-15 | How does FamilyPlus member visibility work? | FamilyPlus has up to 5 members. Every joined member in the package can view all information of every other member in the package. | Answered - User decision 2026-06-30 |

## Approval Status
| Role | Approver | Status | Date |
|---|---|---|---|
| BA/PO | Product Owner | Pending |  |
| Tech Lead | Tech Lead | Pending |  |
| QA Lead | QA Lead | Pending |  |

## Validation Notes
- Runtime code was not changed in this DD creation pass.
- Physical schema, RLS, endpoint, payment provider, and UI mockups remain Draft unless explicitly specified by BD.
- Product decisions Q-14, Q-15 were answered on 2026-06-30; remaining Draft items are implementation evidence, sandbox/RLS/API verification, or planned assets, not PO blockers.
