# Overall — RECONCILIATION / Tính toán & đối soát

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | RECONCILIATION |
| BD Module | M17 |
| Version | v1.0 |
| Status | Draft - contracts updated, sandbox evidence pending |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD section 12.1, 14.4, 15, Appendix A UC-22 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
| Release Scope | Project DD baseline for M01-M19 |

## 2. Business Goal
Module này bảo đảm dữ liệu nguồn và dữ liệu tổng hợp nhất quán, xử lý sai lệch bằng adjustment có audit thay vì sửa mất lịch sử.

## 3. Module Scope

### In Scope
- Reconcile payment-entitlement.
- Reconcile referral-commission-points.
- Reconcile quota and AI request.
- Generate discrepancy list for Admin.

### Out of Scope
- Final accounting/tax process.
- Manual hidden correction without audit.
- Production scheduler config.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| Admin, System | Use module features according to BD sections 3, 5, and BD section 12.1, 14.4, 15, Appendix A UC-22. | Must not bypass entitlement, ownership, family consent, Sale/Admin scope, or audit rules. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must follow accepted product decisions. |
| Admin/Super Admin | Operate only where BD grants admin responsibility. | Backend/API must reject missing permission; UI hiding is not sufficient. |

## 5. Primary Entities/Data

| Entity ID | Entity | Purpose | Important Attributes | Relationships |
|---|---|---|---|---|
| RECONCILIATION-E-reconciliation_run | Reconciliation Run | Kỳ đối soát | period, scope, status, actor | Has discrepancies |
| RECONCILIATION-E-discrepancy | Discrepancy | Sai lệch cần xử lý | source entity, expected, actual, status | May create adjustment |

## 6. States and State Transitions

| Entity / Group | States | Notes |
|---|---|---|
| Reconciliation Run | created, running, completed, failed, reviewed, adjusted | Source: BD Appendix B and module sections. |

## 7. Business Rules

| ID | Rule | Applied At | Criticality |
|---|---|---|---|
| RECONCILIATION-BR01 | Job tính commission chạy lại không được tạo/cộng điểm trùng. | Reconciliation job and discrepancy resolution | Mandatory |
| RECONCILIATION-BR02 | Xử lý sai lệch tạo adjustment/reversal, không xóa hoặc sửa mất lịch sử. | Reconciliation job and discrepancy resolution | Mandatory |

## 8. Overall Operational Flow

1. Actor enters the module through the planned view or event listed in Views.md.
2. System validates authentication, entitlement, role, ownership, family scope, Sale status, or Admin permission as applicable.
3. System loads only the data needed for Tính toán & đối soát.
4. Feature function applies module business rules and cross-cutting rules from BD sections 14 and 15.
5. Successful writes use transaction/idempotency and audit where required.
6. UI/API returns a safe business result and never exposes raw stack trace, DB/API wording, secret, payment evidence, or unnecessary health data.

## 9. Integrations and Dependencies

| Dependency | Type | Purpose | Failure Behavior |
|---|---|---|---|
| Auth/Profile | Internal/Supabase planned | Identify actor and ownership. | Block action or request login. |
| Membership/Entitlement | Internal/trusted backend planned | Apply Free/Plus/FamilyPlus access and quotas. | Keep previous state; do not grant paid access. |
| Audit/Security | Cross-cutting | Trace sensitive changes. | Sensitive writes must fail or be queued safely if audit cannot be recorded. |
| Module-specific dependencies | Internal | PAYMENT_MEMBERSHIP, SALE_POINTS, MEMBERSHIP_QUOTA, HEALTH_SCORE_HABITS., AUDIT_SECURITY: audit corrections., REPORTING: reporting consumers. | Follow dependency owner DD and record conflict as an implementation issue or accepted exception. |

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
| RECONCILIATION-RISK01 | Risk | API/schema/RLS sandbox evidence and final UI assets may still lag the DD contract. | Coding must keep acceptance evidence and sandbox proof before production release. | Open |
| RECONCILIATION-ASSUMPTION01 | Assumption | BD v2.0 plus user decisions from 2026-06-30 are the source of truth; legacy conflicting Sale/Admin logic is not implementation source. | Implementation must migrate or reject old behavior such as Sale tree, tier-2 commission, or 5 percent rules. | Active |
| RECONCILIATION-Q-05 | Answered decision | How are refund, cancel, and chargeback handled after points are credited? | Refund/cancel is allowed only within 24 hours after purchase. Points are reversed immediately in that window. Because conversion is also locked for 24 hours, there is no converted-then-reversed case. | Accepted - User decision 2026-06-30 |
| RECONCILIATION-Q-10 | Answered decision | Do suspended or closed Sale accounts continue receiving points? | Suspended or closed Sale accounts receive no new points from old customers. | Accepted - User decision 2026-06-30 |
| RECONCILIATION-Q-13 | Answered decision | Who can edit sensitive data and Sale points? | Admin has broad operational power, but only Super Admin can edit sensitive data, perform full-data edits, or make manual Sale point adjustments. Each action requires reason, idempotency, and audit. | Accepted - User decision 2026-06-30 |
| RECONCILIATION-Q-17 | Answered decision | Can webhook/trusted recorder approve payments automatically? | All payments and transfers are manually reviewed and manually approved by Admin. Trusted recorder may only create pending evidence; only Admin approval creates payment_approved. | Accepted - User decision 2026-06-30 |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| RECONCILIATION-ADR01 | Keep implementation gated by documented API/schema/RLS/audit evidence where the checklist still marks sandbox pending. | Product decisions are answered, but several modules still require Supabase or runtime verification before production acceptance. | Accepted |
| RECONCILIATION-ADR02 | Apply accepted product decisions Q-05, Q-10, Q-13, Q-17 as the module business contract. | User decisions from 2026-06-30 close the BD Q-01..Q-18 blocker set for this module. | Accepted |

## 13. Traceability Matrix

| BD/Requirement | Feature | Function | View | API | Test |
|---|---|---|---|---|---|
| BD section 12.1, UC-22 | RECONCILIATION-F01 | RECONCILIATION-FN01 | RECONCILIATION-V01 | RECONCILIATION-API01 | RECONCILIATION-TC01 |
| BD section 12.1 luồng đối soát | RECONCILIATION-F02 | RECONCILIATION-FN02 | RECONCILIATION-V02 | RECONCILIATION-API02 | RECONCILIATION-TC02 |

## 14. Approval Checklist

- [ ] Scope and out-of-scope reviewed by BA/PO.
- [ ] Business rules reviewed by Tech Lead.
- [ ] UI states reviewed by UI/UX and QA.
- [ ] API/schema/RLS contracts added before coding.
- [x] Product decisions Q-05, Q-10, Q-13, Q-17 answered or accepted as explicit implementation policy on 2026-06-30.

## 15. Accepted Product Decision Contract

| ID | Accepted Policy | Implementation Contract | Source |
|---|---|---|---|
| Q-05 | Refund/cancel is allowed only within 24 hours after purchase. Points are reversed immediately in that window. Because conversion is also locked for 24 hours, there is no converted-then-reversed case. | Refund/cancel RPC requires approved payment age <= 24 hours, creates reversal ledger, and blocks conversion while payment is inside the hold window. | User decision 2026-06-30 |
| Q-10 | Suspended or closed Sale accounts receive no new points from old customers. | Commission creation checks Sale status at payment approval time and rejects inactive/suspended/closed Sale with audit-safe reason. | User decision 2026-06-30 |
| Q-13 | Admin has broad operational power, but only Super Admin can edit sensitive data, perform full-data edits, or make manual Sale point adjustments. Each action requires reason, idempotency, and audit. | Sensitive mutation RPCs require Super Admin, reason, idempotency_key, before/after summary, and audit row; no two-person approval is required in this DD. | User decision 2026-06-30 |
| Q-17 | All payments and transfers are manually reviewed and manually approved by Admin. Trusted recorder may only create pending evidence; only Admin approval creates payment_approved. | Payment write path separates evidence capture from approval; payment_approved requires Admin actor, reason/reference, idempotency, and audit. | User decision 2026-06-30 |

### Remaining Evidence Gate
- DD readiness for this module is 60 percent in `docs/checklist/checklist_complete_DD.md`.
- Coding progress changes only when runtime code, tests, or sandbox evidence are added.
