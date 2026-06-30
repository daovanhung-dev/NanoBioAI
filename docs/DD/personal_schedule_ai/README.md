# DD — AI Lịch trình cá nhân

| Attribute | Value |
|---|---|
| Module Code | PERSONAL_SCHEDULE_AI |
| BD Module | M02 |
| Version | v1.0 |
| Status | Draft - contracts updated, sandbox evidence pending |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M02, 13, 16.1 AC-01/AC-02/AC-05/AC-06, Appendix A UC-02/UC-08 |

## Purpose
Sinh hoặc thay đổi lịch trình cá nhân gồm thực đơn, bài tập và mốc hoạt động dựa trên hồ sơ onboarding và quyền gói.

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
- PERSONAL_SCHEDULE_AI-F01: Sinh lịch trình đầu tiên cho Guest
- PERSONAL_SCHEDULE_AI-F02: Tạo lịch trình mới cho Member

## Dependent Modules
- ONBOARDING_PROFILE: input cá nhân hóa.
- MEMBERSHIP_QUOTA: kiểm tra quota/gói.
- SCHEDULE_NOTIFICATIONS: nhận lịch để tạo nhắc.

## Answered Questions
| ID | Question | Decision | Status |
|---|---|---|---|
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
- Product decisions Q-16 were answered on 2026-06-30; remaining Draft items are implementation evidence, sandbox/RLS/API verification, or planned assets, not PO blockers.
