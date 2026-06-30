# DD — Audit, bảo mật & hỗ trợ

| Attribute | Value |
|---|---|
| Module Code | AUDIT_SECURITY |
| BD Module | M19 |
| Version | v1.0 |
| Status | Draft - contracts updated, sandbox evidence pending |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
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

## Answered Questions
| ID | Question | Decision | Status |
|---|---|---|---|
| Q-12 | Which Admin groups exist? | All Admin groups exist: Super Admin, Finance Admin, Support Admin, and Content Admin. | Answered - User decision 2026-06-30 |
| Q-13 | Who can edit sensitive data and Sale points? | Admin has broad operational power, but only Super Admin can edit sensitive data, perform full-data edits, or make manual Sale point adjustments. Each action requires reason, idempotency, and audit. | Answered - User decision 2026-06-30 |
| Q-18 | What customer information may Sale see? | Sale may see customer phone number and basic profile information for customer care, but cannot see health data, AI data, secrets, or raw payment payloads. | Answered - User decision 2026-06-30 |

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
- Product decisions Q-12, Q-13, Q-18 were answered on 2026-06-30; remaining Draft items are implementation evidence, sandbox/RLS/API verification, or planned assets, not PO blockers.
