# Overall — AUDIT_SECURITY / Audit, bảo mật & hỗ trợ

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | AUDIT_SECURITY |
| BD Module | M19 |
| Version | v1.0 |
| Status | Draft |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 11.8, 14, 15, 16.3 AC-20/AC-21/AC-24, Appendix A UC-23 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
| Release Scope | Project DD baseline for M01-M19 |

## 2. Business Goal
Module này là cross-cutting control để mọi thay đổi tiền, điểm, quyền, gói, Sale, referral, family data hoặc config đều truy vết được.

## 3. Module Scope

### In Scope
- Audit log immutable for sensitive changes.
- Permission matrix and scope enforcement.
- Security events and suspicious activity.
- Support/ticket evidence metadata.

### Out of Scope
- Raw secret storage.
- Full incident response runbook.
- RLS physical policy SQL if not yet designed.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| Admin, Super Admin, System | Use module features according to BD sections 3, 5, and BD sections 11.8, 14, 15, 16.3 AC-20/AC-21/AC-24, Appendix A UC-23. | Must not bypass entitlement, ownership, family consent, Sale/Admin scope, or audit rules. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must not invent product decisions. |
| Admin/Super Admin | Operate only where BD grants admin responsibility. | Backend/API must reject missing permission; UI hiding is not sufficient. |

## 5. Primary Entities/Data

| Entity ID | Entity | Purpose | Important Attributes | Relationships |
|---|---|---|---|---|
| AUDIT_SECURITY-E-audit_log | Audit Log | Truy vết | actor, action, entity, before/after, reason, timestamp, correlation id | Written by all sensitive modules |
| AUDIT_SECURITY-E-security_event | Security Event | Sự kiện bảo mật/rủi ro | event type, actor, target, severity, status | May open support case |
| AUDIT_SECURITY-E-support_case | Support Case | Hỗ trợ/vi phạm | subject, reason, status, evidence summary | Linked to audit/security |

## 6. States and State Transitions

| Entity / Group | States | Notes |
|---|---|---|
| Audit / Security Event | recorded, reviewed, escalated, resolved, archived | Source: BD Appendix B and module sections. |

## 7. Business Rules

| ID | Rule | Applied At | Criticality |
|---|---|---|---|
| AUDIT_SECURITY-BR01 | UI hiding does not replace route/use-case/API/database permission checks. | All sensitive operations and data reads | Mandatory |
| AUDIT_SECURITY-BR02 | Sale and Admin must not see health/AI/family/payment data beyond explicit scope. | All sensitive operations and data reads | Mandatory |

## 8. Overall Operational Flow

1. Actor enters the module through the planned view or event listed in Views.md.
2. System validates authentication, entitlement, role, ownership, family scope, Sale status, or Admin permission as applicable.
3. System loads only the data needed for Audit, bảo mật & hỗ trợ.
4. Feature function applies module business rules and cross-cutting rules from BD sections 14 and 15.
5. Successful writes use transaction/idempotency and audit where required.
6. UI/API returns a safe business result and never exposes raw stack trace, DB/API wording, secret, payment evidence, or unnecessary health data.

## 9. Integrations and Dependencies

| Dependency | Type | Purpose | Failure Behavior |
|---|---|---|---|
| Auth/Profile | Internal/Supabase planned | Identify actor and ownership. | Block action or request login. |
| Membership/Entitlement | Internal/trusted backend planned | Apply Free/Plus/FamilyPlus access and quotas. | Keep previous state; do not grant paid access. |
| Audit/Security | Cross-cutting | Trace sensitive changes. | Sensitive writes must fail or be queued safely if audit cannot be recorded. |
| Module-specific dependencies | Internal | All modules M01-M18: emit audit/security events., Supabase/trusted backend planned for RLS and role enforcement. | Follow dependency owner DD and record conflict as OPEN QUESTION. |

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
| AUDIT_SECURITY-RISK01 | Risk | Physical schema/API/RLS and final UI wireframes are not provided in BD. | Implementation may diverge if coding starts before detailed contracts. | Open |
| AUDIT_SECURITY-ASSUMPTION01 | Assumption | This DD uses BD v2.0 as source of truth and treats conflicting legacy Sale logic as blocked. | Legacy behavior must be reviewed before coding. | Active |
| AUDIT_SECURITY-Q-12 | Open question | Admin có bao nhiêu nhóm quyền? | Permission matrix and UI. | Open |
| AUDIT_SECURITY-Q-13 | Open question | Admin có được điều chỉnh thủ công Điểm Sale và cần hai người duyệt không? | Audit and separation of duties. | Open |
| AUDIT_SECURITY-Q-18 | Open question | Sale xem được định danh nào của khách hay chỉ số liệu tổng hợp? | Privacy and Sale dashboard. | Open |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| AUDIT_SECURITY-ADR01 | Keep this module DD in Draft until PO/Tech Lead closes related open questions and implementation contracts. | BD v2.0 contains Q-01..Q-18 and explicit DD-before-coding gates. | Accepted |

## 13. Traceability Matrix

| BD/Requirement | Feature | Function | View | API | Test |
|---|---|---|---|---|---|
| BD sections 14.3, 11.8, UC-23 | AUDIT_SECURITY-F01 | AUDIT_SECURITY-FN01 | AUDIT_SECURITY-V01 | AUDIT_SECURITY-API01 | AUDIT_SECURITY-TC01 |
| BD sections 14.1/14.2/15, AC-20/AC-24 | AUDIT_SECURITY-F02 | AUDIT_SECURITY-FN02 | AUDIT_SECURITY-V02 | AUDIT_SECURITY-API02 | AUDIT_SECURITY-TC02 |

## 14. Approval Checklist

- [ ] Scope and out-of-scope reviewed by BA/PO.
- [ ] Business rules reviewed by Tech Lead.
- [ ] UI states reviewed by UI/UX and QA.
- [ ] API/schema/RLS contracts added before coding.
- [ ] Open questions resolved or accepted as explicit implementation assumptions.
