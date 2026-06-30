# DD — Gói thành viên & quota

| Attribute | Value |
|---|---|
| Module Code | MEMBERSHIP_QUOTA |
| BD Module | M06 |
| Version | v1.0 |
| Status | Draft - contracts updated, sandbox evidence pending |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M06, 13, 16.1 AC-04..AC-08, Appendix A UC-06 |

## Purpose
Quản lý Free/Plus/FamilyPlus, entitlement và giới hạn dùng AI Chat/tạo lịch trình.

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
- MEMBERSHIP_QUOTA-F01: Dựng quyền hiệu lực
- MEMBERSHIP_QUOTA-F02: Kiểm soát quota Free

## Dependent Modules
- AUTH_PROFILE_SYNC: user/session.
- PAYMENT_MEMBERSHIP: source payment approved.
- AI_CHAT and PERSONAL_SCHEDULE_AI: quota consumers.

## Answered Questions
| ID | Question | Decision | Status |
|---|---|---|---|
| Q-04 | How do package periods and renewals work? | Plus and FamilyPlus support monthly and yearly plans. Early renewal extends from current expiry; late renewal starts from Admin approval time; pending payment never grants rights. | Answered - User decision 2026-06-30 |
| Q-16 | Which timezone is authoritative? | Use Vietnam timezone, Asia/Ho_Chi_Minh. | Answered - User decision 2026-06-30 |

## Approval Status
| Role | Approver | Status | Date |
|---|---|---|---|
| BA/PO | Product Owner | Pending |  |
| Tech Lead | Tech Lead | Pending |  |
| QA Lead | QA Lead | Pending |  |

## Validation Notes
- Runtime code was not changed in this DD creation pass.
- Physical schema, RLS, endpoint, payment provider, and UI mockups remain Draft unless explicitly specified by BD.
- Product decisions Q-04, Q-16 were answered on 2026-06-30; remaining Draft items are implementation evidence, sandbox/RLS/API verification, or planned assets, not PO blockers.
