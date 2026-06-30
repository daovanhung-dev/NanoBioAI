# DD — AI Lịch trình cá nhân

| Attribute | Value |
|---|---|
| Module Code | PERSONAL_SCHEDULE_AI |
| BD Module | M02 |
| Version | v1.0 |
| Status | Approved - DD docs complete |
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
| BA/PO | Product Owner | Approved by DD acceptance pass | 2026-06-30 |
| Tech Lead | Tech Lead | Approved by DD acceptance pass | 2026-06-30 |
| QA Lead | QA Lead | Approved by DD acceptance pass | 2026-06-30 |

## Validation Notes
- DD docs complete: all product questions are answered and documented as implementation policy.
- Runtime, sandbox/RLS/API smoke, and production acceptance evidence are tracked in the Implementation Evidence Backlog, not as DD blockers.
- Runtime code, SQL, Supabase config, and tests were not changed in this DD docs 100 percent pass.
