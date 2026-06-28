# Overall — ADMIN_OPS / Admin quản lý hệ thống

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | ADMIN_OPS |
| BD Module | M16 |
| Version | v1.0 |
| Status | Draft |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 11.3..11.7, 16.3 AC-20..AC-24, Appendix A UC-21 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
| Release Scope | Project DD baseline for M01-M19 |

## 2. Business Goal
Module này chuẩn hóa admin operations theo permission, lý do, timestamp, idempotency và audit bắt buộc.

## 3. Module Scope

### In Scope
- Quản lý user/profile trong scope.
- Quản lý gói/giá/entitlement config version hóa.
- Quản lý Sale/mã giới thiệu.
- Quản lý payment/conversion/support finance.
- Quản lý content/notification templates.

### Out of Scope
- Super Admin policy final if Q-12 not answered.
- Two-person approval final if Q-13 not answered.
- Raw health data edits without policy.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| Admin, Super Admin | Use module features according to BD sections 3, 5, and BD sections 11.3..11.7, 16.3 AC-20..AC-24, Appendix A UC-21. | Must not bypass entitlement, ownership, family consent, Sale/Admin scope, or audit rules. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must not invent product decisions. |
| Admin/Super Admin | Operate only where BD grants admin responsibility. | Backend/API must reject missing permission; UI hiding is not sufficient. |

## 5. Primary Entities/Data

| Entity ID | Entity | Purpose | Important Attributes | Relationships |
|---|---|---|---|---|
| ADMIN_OPS-E-admin_role_permission | Admin Role/Permission | Phân quyền quản trị | role, permission, scope | Controls admin actions |
| ADMIN_OPS-E-system_configuration | System Configuration | Cấu hình version hóa | key, value, effective time, approval/audit | Used by packages, Sale, points |
| ADMIN_OPS-E-admin_action | Admin Action | Thao tác quản trị | actor, action, target, reason, status | Writes audit |

## 6. States and State Transitions

| Entity / Group | States | Notes |
|---|---|---|
| Admin Action | initiated, confirmed, failed, rolled_back | Source: BD Appendix B and module sections. |

## 7. Business Rules

| ID | Rule | Applied At | Criticality |
|---|---|---|---|
| ADMIN_OPS-BR01 | Admin operations quan trọng phải có lý do, timestamp, actor và audit. | Admin mutations and configuration changes | Mandatory |
| ADMIN_OPS-BR02 | Không sửa trực tiếp bản ghi tài chính đã chốt; dùng adjustment/reversal. | Admin mutations and configuration changes | Mandatory |

## 8. Overall Operational Flow

1. Actor enters the module through the planned view or event listed in Views.md.
2. System validates authentication, entitlement, role, ownership, family scope, Sale status, or Admin permission as applicable.
3. System loads only the data needed for Admin quản lý hệ thống.
4. Feature function applies module business rules and cross-cutting rules from BD sections 14 and 15.
5. Successful writes use transaction/idempotency and audit where required.
6. UI/API returns a safe business result and never exposes raw stack trace, DB/API wording, secret, payment evidence, or unnecessary health data.

## 9. Integrations and Dependencies

| Dependency | Type | Purpose | Failure Behavior |
|---|---|---|---|
| Auth/Profile | Internal/Supabase planned | Identify actor and ownership. | Block action or request login. |
| Membership/Entitlement | Internal/trusted backend planned | Apply Free/Plus/FamilyPlus access and quotas. | Keep previous state; do not grant paid access. |
| Audit/Security | Cross-cutting | Trace sensitive changes. | Sensitive writes must fail or be queued safely if audit cannot be recorded. |
| Module-specific dependencies | Internal | AUDIT_SECURITY: audit/permissions., PAYMENT_MEMBERSHIP: payment ops., REFERRAL_DIRECT: Sale ops., SALE_POINTS: conversion/adjustment. | Follow dependency owner DD and record conflict as OPEN QUESTION. |

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
| ADMIN_OPS-RISK01 | Risk | Physical schema/API/RLS and final UI wireframes are not provided in BD. | Implementation may diverge if coding starts before detailed contracts. | Open |
| ADMIN_OPS-ASSUMPTION01 | Assumption | This DD uses BD v2.0 as source of truth and treats conflicting legacy Sale logic as blocked. | Legacy behavior must be reviewed before coding. | Active |
| ADMIN_OPS-Q-12 | Open question | Admin có bao nhiêu nhóm quyền? | Permission matrix and UI. | Open |
| ADMIN_OPS-Q-13 | Open question | Admin có được điều chỉnh thủ công Điểm Sale và cần hai người duyệt không? | Audit and separation of duties. | Open |
| ADMIN_OPS-Q-17 | Open question | Payment phải duyệt thủ công toàn bộ hay webhook tự động có thể tạo payment_approved? | Payment architecture and operations. | Open |
| ADMIN_OPS-Q-18 | Open question | Sale xem được định danh nào của khách hay chỉ số liệu tổng hợp? | Privacy and Sale dashboard. | Open |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| ADMIN_OPS-ADR01 | Keep this module DD in Draft until PO/Tech Lead closes related open questions and implementation contracts. | BD v2.0 contains Q-01..Q-18 and explicit DD-before-coding gates. | Accepted |

## 13. Traceability Matrix

| BD/Requirement | Feature | Function | View | API | Test |
|---|---|---|---|---|---|
| BD sections 11.3..11.5, UC-21 | ADMIN_OPS-F01 | ADMIN_OPS-FN01 | ADMIN_OPS-V01 | ADMIN_OPS-API01 | ADMIN_OPS-TC01 |
| BD section 11.6, AC-20..AC-23 | ADMIN_OPS-F02 | ADMIN_OPS-FN02 | ADMIN_OPS-V02 | ADMIN_OPS-API02 | ADMIN_OPS-TC02 |

## 14. Approval Checklist

- [ ] Scope and out-of-scope reviewed by BA/PO.
- [ ] Business rules reviewed by Tech Lead.
- [ ] UI states reviewed by UI/UX and QA.
- [ ] API/schema/RLS contracts added before coding.
- [ ] Open questions resolved or accepted as explicit implementation assumptions.
