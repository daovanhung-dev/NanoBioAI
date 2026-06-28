# Overall — REPORTING / Thống kê & báo cáo

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | REPORTING |
| BD Module | M18 |
| Version | v1.0 |
| Status | Draft |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD section 12.2, 14.2, 16.3 AC-23, Appendix A UC-24 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
| Release Scope | Project DD baseline for M01-M19 |

## 2. Business Goal
Module này lấy báo cáo từ dữ liệu nguồn/ledger, không từ cache UI, và export phải có permission/audit.

## 3. Module Scope

### In Scope
- Report product, package, Sale, payment, Family, operations, audit.
- Filters by time/package/Sale/status/scope.
- Export CSV/Excel/PDF planned with audit.
- Use aggregate/anonymous data for health where possible.

### Out of Scope
- Final BI warehouse architecture.
- Raw sensitive data export without policy.
- Accounting statement format.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| Admin | Use module features according to BD sections 3, 5, and BD section 12.2, 14.2, 16.3 AC-23, Appendix A UC-24. | Must not bypass entitlement, ownership, family consent, Sale/Admin scope, or audit rules. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must not invent product decisions. |
| Admin/Super Admin | Operate only where BD grants admin responsibility. | Backend/API must reject missing permission; UI hiding is not sufficient. |

## 5. Primary Entities/Data

| Entity ID | Entity | Purpose | Important Attributes | Relationships |
|---|---|---|---|---|
| REPORTING-E-report_definition | Report Definition | Định nghĩa báo cáo | type, filters, scope, permissions | Used by dashboard/export |
| REPORTING-E-report_export | Report Export | Lịch sử xuất báo cáo | actor, format, filters, reason, timestamp | Writes audit |

## 6. States and State Transitions

| Entity / Group | States | Notes |
|---|---|---|
| Report / Export | draft, generating, ready, failed, exported | Source: BD Appendix B and module sections. |

## 7. Business Rules

| ID | Rule | Applied At | Criticality |
|---|---|---|---|
| REPORTING-BR01 | Export dữ liệu phải có permission, lý do nếu cần và audit. | Report generation and export | Mandatory |
| REPORTING-BR02 | Báo cáo tài chính lấy từ ledger/giao dịch nguồn, không chỉ từ UI cache. | Report generation and export | Mandatory |

## 8. Overall Operational Flow

1. Actor enters the module through the planned view or event listed in Views.md.
2. System validates authentication, entitlement, role, ownership, family scope, Sale status, or Admin permission as applicable.
3. System loads only the data needed for Thống kê & báo cáo.
4. Feature function applies module business rules and cross-cutting rules from BD sections 14 and 15.
5. Successful writes use transaction/idempotency and audit where required.
6. UI/API returns a safe business result and never exposes raw stack trace, DB/API wording, secret, payment evidence, or unnecessary health data.

## 9. Integrations and Dependencies

| Dependency | Type | Purpose | Failure Behavior |
|---|---|---|---|
| Auth/Profile | Internal/Supabase planned | Identify actor and ownership. | Block action or request login. |
| Membership/Entitlement | Internal/trusted backend planned | Apply Free/Plus/FamilyPlus access and quotas. | Keep previous state; do not grant paid access. |
| Audit/Security | Cross-cutting | Trace sensitive changes. | Sensitive writes must fail or be queued safely if audit cannot be recorded. |
| Module-specific dependencies | Internal | ADMIN_DASHBOARD: summary display., RECONCILIATION: verified data., AUDIT_SECURITY: export log and permissions. | Follow dependency owner DD and record conflict as OPEN QUESTION. |

## 10. Non-Functional Requirements

| Category | Requirement |
|---|---|
| Security | Enforce UI, route, use-case/API, and database/RLS layers for sensitive data and paid/Sale/Admin access. |
| Data Integrity | Use unique business keys/idempotency for writes, especially payment, quota, point, family, notification, and admin actions. |
| Privacy | Minimize health, family, payment, and referral data exposure by role. |
| Observability | Log safe module status, correlation id, actor type, and audit-relevant changes only. |
| Resilience | Dependency failures must not create duplicate rights, duplicate points, incorrect quota, or partial financial state. |

## 11. Risks, Assumptions, and Open Questions

| ID | Type | Content | Impact | Status |
|---|---|---|---|---|
| REPORTING-RISK01 | Risk | Physical schema/API/RLS and final UI wireframes are not provided in BD. | Implementation may diverge if coding starts before detailed contracts. | Open |
| REPORTING-ASSUMPTION01 | Assumption | This DD uses BD v2.0 as source of truth and treats conflicting legacy Sale logic as blocked. | Legacy behavior must be reviewed before coding. | Active |
| REPORTING-Q-12 | Open question | Admin có bao nhiêu nhóm quyền? | Permission matrix and UI. | Open |
| REPORTING-Q-18 | Open question | Sale xem được định danh nào của khách hay chỉ số liệu tổng hợp? | Privacy and Sale dashboard. | Open |
| REPORTING-Q-16 | Open question | Múi giờ chuẩn cho reset quota, thời hạn gói, báo cáo và duyệt payment là gì? | Quota, entitlement, reporting and approval windows. | Open |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| REPORTING-ADR01 | Keep this module DD in Draft until PO/Tech Lead closes related open questions and implementation contracts. | BD v2.0 contains Q-01..Q-18 and explicit DD-before-coding gates. | Accepted |

## 13. Traceability Matrix

| BD/Requirement | Feature | Function | View | API | Test |
|---|---|---|---|---|---|
| BD section 12.2 | REPORTING-F01 | REPORTING-FN01 | REPORTING-V01 | REPORTING-API01 | REPORTING-TC01 |
| BD section 12.2 rules, AC-23, UC-24 | REPORTING-F02 | REPORTING-FN02 | REPORTING-V02 | REPORTING-API02 | REPORTING-TC02 |

## 14. Approval Checklist

- [ ] Scope and out-of-scope reviewed by BA/PO.
- [ ] Business rules reviewed by Tech Lead.
- [ ] UI states reviewed by UI/UX and QA.
- [ ] API/schema/RLS contracts added before coding.
- [ ] Open questions resolved or accepted as explicit implementation assumptions.
