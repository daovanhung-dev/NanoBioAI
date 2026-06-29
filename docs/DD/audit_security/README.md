# DD — Audit, bảo mật & hỗ trợ

| Attribute | Value |
|---|---|
| Module Code | AUDIT_SECURITY |
| BD Module | M19 |
| Version | v1.0 |
| Status | Draft - selected policy implementation-ready |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-29 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 11.8, 14, 15, 16.3 AC-20/AC-21/AC-24, Appendix A UC-23 |

## Purpose
Kiểm soát quyền nhiều lớp, audit log, hỗ trợ/vi phạm và bảo vệ dữ liệu nhạy cảm.

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
- AUDIT_SECURITY-F01: Ghi audit bắt buộc
- AUDIT_SECURITY-F02: Kiểm soát quyền và hỗ trợ rủi ro

## Dependent Modules
- All modules M01-M18: emit audit/security events.
- Supabase/trusted backend planned for RLS and role enforcement.

## Open Questions
| ID | Question | Impact | Status |
|---|---|---|---|
| Q-12 | Admin có bao nhiêu nhóm quyền? | Permission matrix and UI. | Open |
| Q-13 | Admin có được điều chỉnh thủ công Điểm Sale và cần hai người duyệt không? | Audit and separation of duties. | Open |
| Q-18 | Sale xem được định danh nào của khách hay chỉ số liệu tổng hợp? | Privacy and Sale dashboard. | Open |

## Product Decisions Applied (2026-06-29)
- Q-12: Admin active has full audited operational CRUD capability through Admin RPC/backend, not direct Flutter writes to every Supabase table.
- Q-13: Manual Sale point adjustment is allowed and requires exactly one Admin approval with reason/idempotency/audit.
- Q-18: Customer visibility is limited to basic profile/contact/status summaries; health data, AI content, secrets, and raw payment payloads stay hidden.

## Approval Status
| Role | Approver | Status | Date |
|---|---|---|---|
| BA/PO | Product Owner | Pending |  |
| Tech Lead | Tech Lead | Pending |  |
| QA Lead | QA Lead | Pending |  |

## Validation Notes
- Runtime code was not changed in this DD creation pass.
- Physical schema, RLS, endpoint, payment provider, and UI mockups remain Draft unless explicitly specified by BD.
