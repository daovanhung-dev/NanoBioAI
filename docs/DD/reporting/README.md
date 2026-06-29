# DD — Thống kê & báo cáo

| Attribute | Value |
|---|---|
| Module Code | REPORTING |
| BD Module | M18 |
| Version | v1.0 |
| Status | Draft - selected policy implementation-ready |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-29 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD section 12.2, 14.2, 16.3 AC-23, Appendix A UC-24 |

## Purpose
Báo cáo sản phẩm, gói, Sale, payment, Family, vận hành và tuân thủ theo quyền.

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
- REPORTING-F01: Tạo báo cáo theo scope
- REPORTING-F02: Xuất báo cáo

## Dependent Modules
- ADMIN_DASHBOARD: summary display.
- RECONCILIATION: verified data.
- AUDIT_SECURITY: export log and permissions.

## Open Questions
| ID | Question | Impact | Status |
|---|---|---|---|
| Q-12 | Admin có bao nhiêu nhóm quyền? | Permission matrix and UI. | Open |
| Q-18 | Sale xem được định danh nào của khách hay chỉ số liệu tổng hợp? | Privacy and Sale dashboard. | Open |
| Q-16 | Múi giờ chuẩn cho reset quota, thời hạn gói, báo cáo và duyệt payment là gì? | Quota, entitlement, reporting and approval windows. | Open |

## Product Decisions Applied (2026-06-29)
- Q-12: Admin active has full audited operational CRUD capability through Admin RPC/backend, not direct Flutter writes to every Supabase table.
- Q-16: Time windows for reporting, package/payment approval and related Admin filters use `Asia/Ho_Chi_Minh`.
- Q-18: Reports/export surfaces may include customer basic profile/contact/status summaries only; health data, AI content, secrets, and raw payment payloads stay hidden.

## Approval Status
| Role | Approver | Status | Date |
|---|---|---|---|
| BA/PO | Product Owner | Pending |  |
| Tech Lead | Tech Lead | Pending |  |
| QA Lead | QA Lead | Pending |  |

## Validation Notes
- Runtime code was not changed in this DD creation pass.
- Physical schema, RLS, endpoint, payment provider, and UI mockups remain Draft unless explicitly specified by BD.
