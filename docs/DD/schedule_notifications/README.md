# DD — Thông báo lịch trình

| Attribute | Value |
|---|---|
| Module Code | SCHEDULE_NOTIFICATIONS |
| BD Module | M09 |
| Version | v1.3 |
| Status | Approved - DD docs complete |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-07-13 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M09, 13, Appendix A UC-04 |
| Approved Addendum | docs/BD/wellness_rewards/BD_BioAI_Daily_Proof_Wellness_Rewards_v1.0.md (BD-BIOAI-WELLNESS-REWARDS-001) |

## Purpose
Lên lịch nhắc theo plan/item và xử lý thao tác hoàn thành/bỏ qua từ thông báo.

## Documents in This Module
- [Overall](./Overall.md)
- [Feature List](./List_Features.md)
- [Function List](./Function_List.md)
- [Views](./Views.md)
- [Import and File Mapping](./Import_File.md)
- [Diagrams](./diagrams/README.md)
- [Assets](./assets/README.md)
- [Change History](./history/CHANGELOG.md)
- [Implementation Delta 2026-07-13](./Implementation_Delta_2026-07-13.md)

## Traceability Summary
- SCHEDULE_NOTIFICATIONS-F01: Lên lịch thông báo
- SCHEDULE_NOTIFICATIONS-F02: Xử lý action từ thông báo
- Delta 2026-07-13: hành động hoàn thành mở đúng nhiệm vụ để chụp ảnh, không hoàn thành nền.

## Dependent Modules
- PERSONAL_SCHEDULE_AI: source plan items.
- DASHBOARD_SCHEDULE: update completion events.
- FAMILYPLUS: subject and privacy boundary.

## Answered Questions
| ID | Question | Decision | Status |
|---|---|---|---|
| Q-16 | Which timezone is authoritative? | Use Vietnam timezone, Asia/Ho_Chi_Minh. | Answered - User decision 2026-06-30 |
| Q-15 | How does FamilyPlus member visibility work? | FamilyPlus has up to 5 members. Every joined member in the package can view all information of every other member in the package. | Answered - User decision 2026-06-30 |

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
