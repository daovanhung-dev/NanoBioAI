# DD — Admin quản lý hệ thống

| Attribute | Value |
|---|---|
| Module Code | ADMIN_OPS |
| BD Module | M16 |
| Version | v1.0 |
| Status | Draft |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 11.3..11.7, 16.3 AC-20..AC-24, Appendix A UC-21 |

## Purpose
Quản trị người dùng, gói, Sale, payment, conversion, nội dung, cấu hình và vận hành sản phẩm.

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
- ADMIN_OPS-F01: Quản lý người dùng/gói/Sale/config
- ADMIN_OPS-F02: Quản lý tài chính hỗ trợ

## Dependent Modules
- AUDIT_SECURITY: audit/permissions.
- PAYMENT_MEMBERSHIP: payment ops.
- REFERRAL_DIRECT: Sale ops.
- SALE_POINTS: conversion/adjustment.

## Open Questions
| ID | Question | Impact | Status |
|---|---|---|---|
| Q-12 | Admin có bao nhiêu nhóm quyền? | Permission matrix and UI. | Open |
| Q-13 | Admin có được điều chỉnh thủ công Điểm Sale và cần hai người duyệt không? | Audit and separation of duties. | Open |
| Q-17 | Payment phải duyệt thủ công toàn bộ hay webhook tự động có thể tạo payment_approved? | Payment architecture and operations. | Open |
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
