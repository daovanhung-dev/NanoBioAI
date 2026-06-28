# DD — Admin View / Dashboard

| Attribute | Value |
|---|---|
| Module Code | ADMIN_DASHBOARD |
| BD Module | M15 |
| Version | v1.0 |
| Status | Draft |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 11.1/11.2, 12.2, 16.3 AC-19, Appendix A UC-20 |

## Purpose
Cung cấp dashboard vận hành toàn dự án theo quyền Admin và phạm vi dữ liệu.

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
- ADMIN_DASHBOARD-F01: Xem dashboard Admin
- ADMIN_DASHBOARD-F02: Drill-down theo quyền

## Dependent Modules
- ADMIN_OPS: quản lý module detail.
- REPORTING: aggregates.
- AUDIT_SECURITY: permission and audit.

## Open Questions
| ID | Question | Impact | Status |
|---|---|---|---|
| Q-12 | Admin có bao nhiêu nhóm quyền? | Permission matrix and UI. | Open |
| Q-18 | Sale xem được định danh nào của khách hay chỉ số liệu tổng hợp? | Privacy and Sale dashboard. | Open |

## Approval Status
| Role | Approver | Status | Date |
|---|---|---|---|
| BA/PO | Product Owner | Pending |  |
| Tech Lead | Tech Lead | Pending |  |
| QA Lead | QA Lead | Pending |  |

## Validation Notes
- Runtime code was not changed in this DD creation pass.
- Physical schema, RLS, endpoint, payment provider, and UI mockups remain Draft unless explicitly specified by BD.
