# Overall — RECONCILIATION / Tính toán & đối soát

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | RECONCILIATION |
| BD Module | M17 |
| Version | v1.0 |
| Status | Draft |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD section 12.1, 14.4, 15, Appendix A UC-22 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
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
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must not invent product decisions. |
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
| Module-specific dependencies | Internal | PAYMENT_MEMBERSHIP, SALE_POINTS, MEMBERSHIP_QUOTA, HEALTH_SCORE_HABITS., AUDIT_SECURITY: audit corrections., REPORTING: reporting consumers. | Follow dependency owner DD and record conflict as OPEN QUESTION. |

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
| RECONCILIATION-RISK01 | Risk | Physical schema/API/RLS and final UI wireframes are not provided in BD. | Implementation may diverge if coding starts before detailed contracts. | Open |
| RECONCILIATION-ASSUMPTION01 | Assumption | This DD uses BD v2.0 as source of truth and treats conflicting legacy Sale logic as blocked. | Legacy behavior must be reviewed before coding. | Active |
| RECONCILIATION-Q-05 | Open question | Hoàn/hủy/chargeback sau khi cộng điểm xử lý thế nào nếu Sale đã đổi điểm? | Ledger reversal and negative balance policy. | Open |
| RECONCILIATION-Q-10 | Open question | Sale suspended/closed thì khách cũ có còn phát sinh điểm không? | Sale state machine and disputes. | Open |
| RECONCILIATION-Q-13 | Open question | Admin có được điều chỉnh thủ công Điểm Sale và cần hai người duyệt không? | Audit and separation of duties. | Open |
| RECONCILIATION-Q-17 | Open question | Payment phải duyệt thủ công toàn bộ hay webhook tự động có thể tạo payment_approved? | Payment architecture and operations. | Open |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| RECONCILIATION-ADR01 | Keep this module DD in Draft until PO/Tech Lead closes related open questions and implementation contracts. | BD v2.0 contains Q-01..Q-18 and explicit DD-before-coding gates. | Accepted |

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
- [ ] Open questions resolved or accepted as explicit implementation assumptions.
