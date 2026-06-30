# Overall — ADMIN_DASHBOARD / Admin View / Dashboard

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | ADMIN_DASHBOARD |
| BD Module | M15 |
| Version | v1.0 |
| Status | Approved - DD docs complete |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 11.1/11.2, 12.2, 16.3 AC-19, Appendix A UC-20 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
| Release Scope | Project DD baseline for M01-M19 |

## 2. Business Goal
Module này cho Admin xem chỉ số tổng hợp, drill-down đúng quyền và không xem dữ liệu sức khỏe nhạy cảm nếu không có scope.

## 3. Module Scope

### In Scope
- Tổng quan user, onboarding, gói, doanh thu, payment, Sale, FamilyPlus, vận hành.
- Lọc thời gian/phạm vi.
- Drill-down sang module quản trị.
- Audit hành động từ dashboard.

### Out of Scope
- Full admin CRUD operations.
- Export detailed reports.
- Raw health data exposure.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| Admin | Use module features according to BD sections 3, 5, and BD sections 11.1/11.2, 12.2, 16.3 AC-19, Appendix A UC-20. | Must not bypass entitlement, ownership, family consent, Sale/Admin scope, or audit rules. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must follow accepted product decisions. |
| Admin/Super Admin | Operate only where BD grants admin responsibility. | Backend/API must reject missing permission; UI hiding is not sufficient. |

## 5. Primary Entities/Data

| Entity ID | Entity | Purpose | Important Attributes | Relationships |
|---|---|---|---|---|
| ADMIN_DASHBOARD-E-dashboard_metric | Dashboard Metric | Chỉ số tổng hợp | metric key, period, value, scope | Derived from reporting |
| ADMIN_DASHBOARD-E-admin_scope | Admin Scope | Phạm vi quyền xem | role, permission, scope | Limits metrics |

## 6. States and State Transitions

| Entity / Group | States | Notes |
|---|---|---|
| Admin Dashboard | loading, ready, partial_error, forbidden | Source: BD Appendix B and module sections. |

## 7. Business Rules

| ID | Rule | Applied At | Criticality |
|---|---|---|---|
| ADMIN_DASHBOARD-BR01 | Admin chỉ thấy chỉ số trong phạm vi permission. | Dashboard read and drill-down | Mandatory |
| ADMIN_DASHBOARD-BR02 | Dashboard không mặc định hiển thị dữ liệu sức khỏe nhạy cảm hoặc payment raw. | Dashboard read and drill-down | Mandatory |

## 8. Overall Operational Flow

1. Actor enters the module through the planned view or event listed in Views.md.
2. System validates authentication, entitlement, role, ownership, family scope, Sale status, or Admin permission as applicable.
3. System loads only the data needed for Admin View / Dashboard.
4. Feature function applies module business rules and cross-cutting rules from BD sections 14 and 15.
5. Successful writes use transaction/idempotency and audit where required.
6. UI/API returns a safe business result and never exposes raw stack trace, DB/API wording, secret, payment evidence, or unnecessary health data.

## 9. Integrations and Dependencies

| Dependency | Type | Purpose | Failure Behavior |
|---|---|---|---|
| Auth/Profile | Internal/Supabase planned | Identify actor and ownership. | Block action or request login. |
| Membership/Entitlement | Internal/trusted backend planned | Apply Free/Plus/FamilyPlus access and quotas. | Keep previous state; do not grant paid access. |
| Audit/Security | Cross-cutting | Trace sensitive changes. | Sensitive writes must fail or be queued safely if audit cannot be recorded. |
| Module-specific dependencies | Internal | ADMIN_OPS: quản lý module detail., REPORTING: aggregates., AUDIT_SECURITY: permission and audit. | Follow dependency owner DD and record conflict as an implementation issue or accepted exception. |

## 10. Non-Functional Requirements

| Category | Requirement |
|---|---|
| Security | Enforce UI, route, use-case/API, and database/RLS layers for sensitive data and paid/Sale/Admin access. |
| Data Integrity | Use unique business keys/idempotency for writes, especially payment, quota, point, family, notification, and admin actions. |
| Privacy | Minimize health, family, payment, and referral data exposure by role. |
| Observability | Log safe module status, correlation id, actor type, and audit-relevant changes only. |
| Resilience | Dependency failures must not create duplicate rights, duplicate points, incorrect quota, or partial financial state. |

## 11. Risks, Assumptions, and Decisions

| ID | Type | Content | Impact | Status |
|---|---|---|---|---|
| ADMIN_DASHBOARD-RISK01 | Implementation evidence backlog | Runtime/sandbox evidence, final wireframes, and production acceptance remain outside DD completeness. | Implementation must produce evidence before production release. | Tracked |
| ADMIN_DASHBOARD-ASSUMPTION01 | Assumption | BD v2.0 plus user decisions from 2026-06-30 are the source of truth; legacy conflicting Sale/Admin logic is not implementation source. | Implementation must migrate or reject old behavior such as Sale tree, tier-2 commission, or 5 percent rules. | Active |
| ADMIN_DASHBOARD-Q-12 | Answered decision | Which Admin groups exist? | All Admin groups exist: Super Admin, Finance Admin, Support Admin, and Content Admin. | Accepted - User decision 2026-06-30 |
| ADMIN_DASHBOARD-Q-18 | Answered decision | What customer information may Sale see? | Sale may see customer phone number and basic profile information for customer care, but cannot see health data, AI data, secrets, or raw payment payloads. | Accepted - User decision 2026-06-30 |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| ADMIN_DASHBOARD-ADR01 | Approve this module DD as docs-complete and track runtime/sandbox evidence separately. | The user requested DD docs 100 percent without changing runtime code or claiming sandbox evidence. | Accepted |
| ADMIN_DASHBOARD-ADR02 | Keep accepted product decisions as the module business contract. | Q-01..Q-18 are closed by user decision and recorded in the DD registry. | Accepted |

## 13. Traceability Matrix

| BD/Requirement | Feature | Function | View | API | Test |
|---|---|---|---|---|---|
| BD section 11.2, AC-19, UC-20 | ADMIN_DASHBOARD-F01 | ADMIN_DASHBOARD-FN01 | ADMIN_DASHBOARD-V01 | ADMIN_DASHBOARD-API01 | ADMIN_DASHBOARD-TC01 |
| BD section 11.2 workflow | ADMIN_DASHBOARD-F02 | ADMIN_DASHBOARD-FN02 | ADMIN_DASHBOARD-V02 | ADMIN_DASHBOARD-API02 | ADMIN_DASHBOARD-TC02 |

## 14. Approval Checklist

- [x] Scope and out-of-scope reviewed for DD docs completeness.
- [x] Business rules reviewed for DD docs completeness.
- [x] UI states reviewed for DD docs completeness.
- [x] API/schema/RLS contracts documented for implementation planning.
- [x] Product decisions answered or accepted as explicit implementation policy.

## 15. Accepted Product Decision Contract

| ID | Accepted Policy | Implementation Contract | Source |
|---|---|---|---|
| Q-12 | All Admin groups exist: Super Admin, Finance Admin, Support Admin, and Content Admin. | Admin permission model must expose these groups and map section/action permissions in UI, API, and RLS/backend policy. | User decision 2026-06-30 |
| Q-18 | Sale may see customer phone number and basic profile information for customer care, but cannot see health data, AI data, secrets, or raw payment payloads. | Sale customer views use privacy-limited DTOs and RLS/backend filters; no raw health, AI, secret, or payment evidence fields are returned. | User decision 2026-06-30 |

### Implementation Evidence Backlog

| Evidence Area | Required evidence before production acceptance | DD blocker? |
|---|---|---|
| Runtime/test/sandbox | Admin SQL/RPC/RLS and audit-safe metric evidence. | No - tracked outside DD completeness |
| Coding progress | Update only when code, tests, SQL/RPC, or sandbox evidence changes. | No |
| Production acceptance | Requires implementation workflow evidence and worklog command output. | No |
