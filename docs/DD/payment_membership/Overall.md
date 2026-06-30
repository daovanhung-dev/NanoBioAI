# Overall — PAYMENT_MEMBERSHIP / Thanh toán, xác minh và quyền gói

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | PAYMENT_MEMBERSHIP |
| BD Module | M13 |
| Version | v1.0 |
| Status | Draft - contracts updated, sandbox evidence pending |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 8/M13, 14.4, 15, 16.1 AC-07/AC-08, 16.3 AC-20/AC-21, Appendix A UC-15/UC-16 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
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
- Provider-specific chargeback integration details beyond the accepted 24h refund/cancel policy.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| Member, Admin | Use module features according to BD sections 3, 5, and BD sections 8/M13, 14.4, 15, 16.1 AC-07/AC-08, 16.3 AC-20/AC-21, Appendix A UC-15/UC-16. | Must not bypass entitlement, ownership, family consent, Sale/Admin scope, or audit rules. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must follow accepted product decisions. |
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
| Module-specific dependencies | Internal | MEMBERSHIP_QUOTA: entitlement activation., REFERRAL_DIRECT: source referral., SALE_POINTS: points after approval., ADMIN_OPS/AUDIT_SECURITY: approval/audit. | Follow dependency owner DD and record conflict as an implementation issue or accepted exception. |

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
| PAYMENT_MEMBERSHIP-RISK01 | Risk | API/schema/RLS sandbox evidence and final UI assets may still lag the DD contract. | Coding must keep acceptance evidence and sandbox proof before production release. | Open |
| PAYMENT_MEMBERSHIP-ASSUMPTION01 | Assumption | BD v2.0 plus user decisions from 2026-06-30 are the source of truth; legacy conflicting Sale/Admin logic is not implementation source. | Implementation must migrate or reject old behavior such as Sale tree, tier-2 commission, or 5 percent rules. | Active |
| PAYMENT_MEMBERSHIP-Q-03 | Answered decision | What is the 10 percent commission base? | Commission is calculated from the listed package price. | Accepted - User decision 2026-06-30 |
| PAYMENT_MEMBERSHIP-Q-04 | Answered decision | How do package periods and renewals work? | Plus and FamilyPlus support monthly and yearly plans. Early renewal extends from current expiry; late renewal starts from Admin approval time; pending payment never grants rights. | Accepted - User decision 2026-06-30 |
| PAYMENT_MEMBERSHIP-Q-05 | Answered decision | How are refund, cancel, and chargeback handled after points are credited? | Refund/cancel is allowed only within 24 hours after purchase. Points are reversed immediately in that window. Because conversion is also locked for 24 hours, there is no converted-then-reversed case. | Accepted - User decision 2026-06-30 |
| PAYMENT_MEMBERSHIP-Q-11 | Answered decision | How is FamilyPlus commission calculated? | FamilyPlus commission is calculated only on the package owner portion. | Accepted - User decision 2026-06-30 |
| PAYMENT_MEMBERSHIP-Q-17 | Answered decision | Can webhook/trusted recorder approve payments automatically? | All payments and transfers are manually reviewed and manually approved by Admin. Trusted recorder may only create pending evidence; only Admin approval creates payment_approved. | Accepted - User decision 2026-06-30 |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| PAYMENT_MEMBERSHIP-ADR01 | Keep implementation gated by documented API/schema/RLS/audit evidence where the checklist still marks sandbox pending. | Product decisions are answered, but several modules still require Supabase or runtime verification before production acceptance. | Accepted |
| PAYMENT_MEMBERSHIP-ADR02 | Apply accepted product decisions Q-03, Q-04, Q-05, Q-11, Q-17 as the module business contract. | User decisions from 2026-06-30 close the BD Q-01..Q-18 blocker set for this module. | Accepted |

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
- [x] Product decisions Q-03, Q-04, Q-05, Q-11, Q-17 answered or accepted as explicit implementation policy on 2026-06-30.

## 15. Accepted Product Decision Contract

| ID | Accepted Policy | Implementation Contract | Source |
|---|---|---|---|
| Q-03 | Commission is calculated from the listed package price. | Commission ledger stores listed_price, commission_rate_version, computed_points, payment_id, and immutable formula version. | User decision 2026-06-30 |
| Q-04 | Plus and FamilyPlus support monthly and yearly plans. Early renewal extends from current expiry; late renewal starts from Admin approval time; pending payment never grants rights. | Entitlement activation is created only by approved payment and calculates start/end from current active expiry or approval time. | User decision 2026-06-30 |
| Q-05 | Refund/cancel is allowed only within 24 hours after purchase. Points are reversed immediately in that window. Because conversion is also locked for 24 hours, there is no converted-then-reversed case. | Refund/cancel RPC requires approved payment age <= 24 hours, creates reversal ledger, and blocks conversion while payment is inside the hold window. | User decision 2026-06-30 |
| Q-11 | FamilyPlus commission is calculated only on the package owner portion. | Payment line items separate owner portion from dependent member portions; commission uses owner portion only. | User decision 2026-06-30 |
| Q-17 | All payments and transfers are manually reviewed and manually approved by Admin. Trusted recorder may only create pending evidence; only Admin approval creates payment_approved. | Payment write path separates evidence capture from approval; payment_approved requires Admin actor, reason/reference, idempotency, and audit. | User decision 2026-06-30 |

### Remaining Evidence Gate
- DD readiness for this module is 60 percent in `docs/checklist/checklist_complete_DD.md`.
- Coding progress changes only when runtime code, tests, or sandbox evidence are added.
