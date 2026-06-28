# Overall — PAYMENT_MEMBERSHIP / Thanh toán, xác minh và quyền gói

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | PAYMENT_MEMBERSHIP |
| BD Module | M13 |
| Version | v1.0 |
| Status | Draft |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 8/M13, 14.4, 15, 16.1 AC-07/AC-08, 16.3 AC-20/AC-21, Appendix A UC-15/UC-16 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
| Release Scope | Project DD baseline for M01-M19 |

## 2. Business Goal
Module này đảm bảo payment pending không mở gói, Admin approval có lý do/audit, refund/cancel tạo adjustment thay vì sửa lịch sử.

## 3. Module Scope

### In Scope
- Tạo payment pending.
- Admin duyệt/từ chối payment.
- Kích hoạt/gia hạn entitlement sau approved.
- Refund/cancel/duplicate handling.

### Out of Scope
- Payment gateway cụ thể và webhook format.
- Payout Sale.
- Final refund/chargeback policy nếu PO chưa chốt.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| Member, Admin | Use module features according to BD sections 3, 5, and BD sections 8/M13, 14.4, 15, 16.1 AC-07/AC-08, 16.3 AC-20/AC-21, Appendix A UC-15/UC-16. | Must not bypass entitlement, ownership, family consent, Sale/Admin scope, or audit rules. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must not invent product decisions. |
| Admin/Super Admin | Operate only where BD grants admin responsibility. | Backend/API must reject missing permission; UI hiding is not sufficient. |

## 5. Primary Entities/Data

| Entity ID | Entity | Purpose | Important Attributes | Relationships |
|---|---|---|---|---|
| PAYMENT_MEMBERSHIP-E-payment_transaction | Payment Transaction | Giao dịch gói | user, plan, amount, status, transaction reference | Source for entitlement and commission |
| PAYMENT_MEMBERSHIP-E-payment_approval | Payment Approval | Lịch sử duyệt payment | payment, admin, decision, reason, time | Audit and entitlement source |
| PAYMENT_MEMBERSHIP-E-membership_entitlement | Membership Entitlement | Quyền gói | plan, start/end, source payment | Used by access gates |

## 6. States and State Transitions

| Entity / Group | States | Notes |
|---|---|---|
| Payment / Entitlement | Payment: created, pending_verification, approved, rejected, cancelled, refunded, chargeback_review; Entitlement: pending, active, expired, suspended, cancelled | Source: BD Appendix B and module sections. |

## 7. Business Rules

| ID | Rule | Applied At | Criticality |
|---|---|---|---|
| PAYMENT_MEMBERSHIP-BR01 | Không kích hoạt Plus/FamilyPlus chỉ vì khách tạo yêu cầu thanh toán. | Payment creation, approval, entitlement activation, refund/cancel | Mandatory |
| PAYMENT_MEMBERSHIP-BR02 | Chỉ payment_approved mới làm quyền gói hiệu lực và có thể kích hoạt Sale points. | Payment creation, approval, entitlement activation, refund/cancel | Mandatory |

## 8. Overall Operational Flow

1. Actor enters the module through the planned view or event listed in Views.md.
2. System validates authentication, entitlement, role, ownership, family scope, Sale status, or Admin permission as applicable.
3. System loads only the data needed for Thanh toán, xác minh và quyền gói.
4. Feature function applies module business rules and cross-cutting rules from BD sections 14 and 15.
5. Successful writes use transaction/idempotency and audit where required.
6. UI/API returns a safe business result and never exposes raw stack trace, DB/API wording, secret, payment evidence, or unnecessary health data.

## 9. Integrations and Dependencies

| Dependency | Type | Purpose | Failure Behavior |
|---|---|---|---|
| Auth/Profile | Internal/Supabase planned | Identify actor and ownership. | Block action or request login. |
| Membership/Entitlement | Internal/trusted backend planned | Apply Free/Plus/FamilyPlus access and quotas. | Keep previous state; do not grant paid access. |
| Audit/Security | Cross-cutting | Trace sensitive changes. | Sensitive writes must fail or be queued safely if audit cannot be recorded. |
| Module-specific dependencies | Internal | MEMBERSHIP_QUOTA: entitlement activation., REFERRAL_DIRECT: source referral., SALE_POINTS: points after approval., ADMIN_OPS/AUDIT_SECURITY: approval/audit. | Follow dependency owner DD and record conflict as OPEN QUESTION. |

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
| PAYMENT_MEMBERSHIP-RISK01 | Risk | Physical schema/API/RLS and final UI wireframes are not provided in BD. | Implementation may diverge if coding starts before detailed contracts. | Open |
| PAYMENT_MEMBERSHIP-ASSUMPTION01 | Assumption | This DD uses BD v2.0 as source of truth and treats conflicting legacy Sale logic as blocked. | Legacy behavior must be reviewed before coding. | Active |
| PAYMENT_MEMBERSHIP-Q-03 | Open question | 10% tính trên giá niêm yết hay số tiền thực thu sau giảm giá/voucher/thuế/phí? | Commission formula and reporting. | Open |
| PAYMENT_MEMBERSHIP-Q-04 | Open question | Các gói thanh toán theo tháng, năm hay một lần; gia hạn sớm/trễ xử lý ra sao? | Entitlement and recurring commission. | Open |
| PAYMENT_MEMBERSHIP-Q-05 | Open question | Hoàn/hủy/chargeback sau khi cộng điểm xử lý thế nào nếu Sale đã đổi điểm? | Ledger reversal and negative balance policy. | Open |
| PAYMENT_MEMBERSHIP-Q-11 | Open question | FamilyPlus payment tính 10% trên toàn gói hay chỉ phần chủ gói? | Commission base for FamilyPlus. | Open |
| PAYMENT_MEMBERSHIP-Q-17 | Open question | Payment phải duyệt thủ công toàn bộ hay webhook tự động có thể tạo payment_approved? | Payment architecture and operations. | Open |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| PAYMENT_MEMBERSHIP-ADR01 | Keep this module DD in Draft until PO/Tech Lead closes related open questions and implementation contracts. | BD v2.0 contains Q-01..Q-18 and explicit DD-before-coding gates. | Accepted |

## 13. Traceability Matrix

| BD/Requirement | Feature | Function | View | API | Test |
|---|---|---|---|---|---|
| BD sections 8.2, UC-15 | PAYMENT_MEMBERSHIP-F01 | PAYMENT_MEMBERSHIP-FN01 | PAYMENT_MEMBERSHIP-V01 | PAYMENT_MEMBERSHIP-API01 | PAYMENT_MEMBERSHIP-TC01 |
| BD sections 8.4, AC-07/AC-08/AC-20/AC-21, UC-16 | PAYMENT_MEMBERSHIP-F02 | PAYMENT_MEMBERSHIP-FN02 | PAYMENT_MEMBERSHIP-V02 | PAYMENT_MEMBERSHIP-API02 | PAYMENT_MEMBERSHIP-TC02 |

## 14. Approval Checklist

- [ ] Scope and out-of-scope reviewed by BA/PO.
- [ ] Business rules reviewed by Tech Lead.
- [ ] UI states reviewed by UI/UX and QA.
- [ ] API/schema/RLS contracts added before coding.
- [ ] Open questions resolved or accepted as explicit implementation assumptions.
