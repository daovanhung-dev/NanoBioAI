# DD — AI Chat

| Attribute | Value |
|---|---|
| Module Code | AI_CHAT |
| BD Module | M07 |
| Version | v1.0 |
| Status | In Review - product decisions answered |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M07, 16.1 AC-03/AC-04/AC-06, Appendix A UC-07 |

## Purpose
Cho phép Member hỏi đáp AI theo gói và quota, chặn Guest và vượt quota Free.

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
- AI_CHAT-F01: Mở AI Chat theo quyền
- AI_CHAT-F02: Gửi câu hỏi AI theo quota

## Dependent Modules
- MEMBERSHIP_QUOTA: access/quota.
- AUTH_PROFILE_SYNC: session.
- AUDIT_SECURITY: safe logging.

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
