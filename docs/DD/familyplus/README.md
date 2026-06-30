# DD — FamilyPlus

| Attribute | Value |
|---|---|
| Module Code | FAMILYPLUS |
| BD Module | M11 |
| Version | v1.0 |
| Status | Draft - contracts updated, sandbox evidence pending |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 10/M11, 13, 14.2, 16.1 AC-06, Appendix A UC-11 |

## Purpose
Quản lý nhóm gia đình, thành viên, hồ sơ riêng, lịch trình riêng và quyền chia sẻ.

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
- FAMILYPLUS-F01: Quản lý nhóm gia đình
- FAMILYPLUS-F02: Theo dõi dữ liệu từng thành viên

## Dependent Modules
- MEMBERSHIP_QUOTA: FamilyPlus entitlement.
- ONBOARDING_PROFILE and PERSONAL_SCHEDULE_AI: subject-specific flows.
- AUDIT_SECURITY: privacy/audit.

## Answered Questions
| ID | Question | Decision | Status |
|---|---|---|---|
| Q-15 | How does FamilyPlus member visibility work? | FamilyPlus has up to 5 members. Every joined member in the package can view all information of every other member in the package. | Answered - User decision 2026-06-30 |
| Q-11 | How is FamilyPlus commission calculated? | FamilyPlus commission is calculated only on the package owner portion. | Answered - User decision 2026-06-30 |

## Approval Status
| Role | Approver | Status | Date |
|---|---|---|---|
| BA/PO | Product Owner | Pending |  |
| Tech Lead | Tech Lead | Pending |  |
| QA Lead | QA Lead | Pending |  |

## Validation Notes
- Runtime code was not changed in this DD creation pass.
- Physical schema, RLS, endpoint, payment provider, and UI mockups remain Draft unless explicitly specified by BD.
- Product decisions Q-15, Q-11 were answered on 2026-06-30; remaining Draft items are implementation evidence, sandbox/RLS/API verification, or planned assets, not PO blockers.
