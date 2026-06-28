# DD — Điểm sức khỏe & thói quen

| Attribute | Value |
|---|---|
| Module Code | HEALTH_SCORE_HABITS |
| BD Module | M08 |
| Version | v1.0 |
| Status | Draft |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M08, 9, 13, Appendix A UC-09 |

## Purpose
Tính điểm sức khỏe và tiến độ thói quen từ lịch sử thực hiện lịch trình, tách biệt hoàn toàn với Điểm Sale.

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
- HEALTH_SCORE_HABITS-F01: Tính điểm sức khỏe
- HEALTH_SCORE_HABITS-F02: Theo dõi thói quen

## Dependent Modules
- DASHBOARD_SCHEDULE: completion events.
- FAMILYPLUS: subject boundary.
- BASIC_HEALTH_CALC: formula governance.

## Open Questions
| ID | Question | Impact | Status |
|---|---|---|---|
| Q-14 | Danh sách module tính toán sức khỏe và công thức nào đã được phê duyệt? | Health calculator and health score responsibility. | Open |
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
