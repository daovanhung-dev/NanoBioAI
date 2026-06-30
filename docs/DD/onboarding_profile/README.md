# DD — Onboarding & Hồ sơ sức khỏe

| Attribute | Value |
|---|---|
| Module Code | ONBOARDING_PROFILE |
| BD Module | M01 |
| Version | v1.0 |
| Status | In Review - product decisions answered |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M01, 13, 16.1 AC-01, Appendix A UC-01 |

## Purpose
Thu thập dữ liệu đầu vào tối thiểu để cá nhân hóa lịch trình AI, công cụ tính toán và hồ sơ sức khỏe.

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
- ONBOARDING_PROFILE-F01: Thu thập dữ liệu onboarding
- ONBOARDING_PROFILE-F02: Xác nhận hoàn tất onboarding

## Dependent Modules
- PERSONAL_SCHEDULE_AI: dùng hồ sơ để sinh lịch trình đầu tiên.
- AUTH_PROFILE_SYNC: đồng bộ Guest -> Member.
- FAMILYPLUS: subject_member_id khi onboarding cho thành viên gia đình.

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
