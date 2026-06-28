# DD — Tính toán sức khỏe cơ bản

| Attribute | Value |
|---|---|
| Module Code | BASIC_HEALTH_CALC |
| BD Module | M04 |
| Version | v1.0 |
| Status | Draft |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M04, 18.2 Q-14, Appendix A UC-03 |

## Purpose
Cung cấp công cụ tính toán sức khỏe cơ bản theo dữ liệu người dùng nhập hoặc hồ sơ đã lưu.

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
- BASIC_HEALTH_CALC-F01: Chạy công cụ tính toán cơ bản
- BASIC_HEALTH_CALC-F02: Quản lý version công thức

## Dependent Modules
- ONBOARDING_PROFILE: input cơ bản.
- ADMIN_OPS: quản lý version công thức nếu PO cho phép.
- AUDIT_SECURITY: audit thay đổi công thức.

## Open Questions
| ID | Question | Impact | Status |
|---|---|---|---|
| Q-14 | Danh sách module tính toán sức khỏe và công thức nào đã được phê duyệt? | Health calculator and health score responsibility. | Open |

## Approval Status
| Role | Approver | Status | Date |
|---|---|---|---|
| BA/PO | Product Owner | Pending |  |
| Tech Lead | Tech Lead | Pending |  |
| QA Lead | QA Lead | Pending |  |

## Validation Notes
- Runtime code was not changed in this DD creation pass.
- Physical schema, RLS, endpoint, payment provider, and UI mockups remain Draft unless explicitly specified by BD.
