# DD — Thông báo lịch trình

| Attribute | Value |
|---|---|
| Module Code | SCHEDULE_NOTIFICATIONS |
| BD Module | M09 |
| Version | v1.0 |
| Status | Draft |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M09, 13, Appendix A UC-04 |

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

## Traceability Summary
- SCHEDULE_NOTIFICATIONS-F01: Lên lịch thông báo
- SCHEDULE_NOTIFICATIONS-F02: Xử lý action từ thông báo

## Dependent Modules
- PERSONAL_SCHEDULE_AI: source plan items.
- DASHBOARD_SCHEDULE: update completion events.
- FAMILYPLUS: subject and privacy boundary.

## Open Questions
| ID | Question | Impact | Status |
|---|---|---|---|
| Q-16 | Múi giờ chuẩn cho reset quota, thời hạn gói, báo cáo và duyệt payment là gì? | Quota, entitlement, reporting and approval windows. | Open |
| Q-15 | Số thành viên FamilyPlus tối đa, quyền xem/sửa và consent theo tuổi/quan hệ? | Family data model and privacy. | Open |

## Approval Status
| Role | Approver | Status | Date |
|---|---|---|---|
| BA/PO | Product Owner | Pending |  |
| Tech Lead | Tech Lead | Pending |  |
| QA Lead | QA Lead | Pending |  |

## Validation Notes
- Runtime code was not changed in this DD creation pass.
- Physical schema, RLS, endpoint, payment provider, and UI mockups remain Draft unless explicitly specified by BD.
