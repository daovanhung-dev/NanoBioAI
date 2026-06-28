# DD — Dashboard & Thực hiện lịch trình

| Attribute | Value |
|---|---|
| Module Code | DASHBOARD_SCHEDULE |
| BD Module | M03 |
| Version | v1.0 |
| Status | Draft |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M03, 13, Appendix A UC-09 |

## Purpose
Hiển thị lịch trình hiện hành, cho phép đánh dấu hoàn thành/bỏ qua và theo dõi tiến độ theo đúng owner/subject.

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
- DASHBOARD_SCHEDULE-F01: Xem lịch trình hôm nay
- DASHBOARD_SCHEDULE-F02: Đánh dấu thực hiện lịch trình

## Dependent Modules
- PERSONAL_SCHEDULE_AI: nguồn Plan/Plan Item.
- HEALTH_SCORE_HABITS: dùng completion events.
- FAMILYPLUS: phân quyền subject.

## Open Questions
| ID | Question | Impact | Status |
|---|---|---|---|
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
