# Overall — SALE_POINTS / Điểm Sale & quy đổi

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | SALE_POINTS |
| BD Module | M14 |
| Version | v1.0 |
| Status | Draft - contracts updated, sandbox evidence pending |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 7.5..7.10, 9, 12.1, 14.4, 16.2 AC-11..AC-18, Appendix A UC-17..UC-19 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
| Release Scope | Project DD baseline for M01-M19 |

## 2. Business Goal
Module này dùng ledger thay vì chỉ số dư, không cộng điểm trước payment_approved và đảm bảo retry không nhân đôi điểm.

## 3. Module Scope

### In Scope
- Tính 10% sau payment_approved.
- Tạo Sale Commission Ledger duy nhất theo payment.
- Tính balance từ ledger.
- Sale yêu cầu conversion và Admin duyệt/chi trả.

### Out of Scope
- Payment approval source.
- Tax/contract/payout method final.
- Indirect commission.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| Sale, Admin, System | Use module features according to BD sections 3, 5, and BD sections 7.5..7.10, 9, 12.1, 14.4, 16.2 AC-11..AC-18, Appendix A UC-17..UC-19. | Must not bypass entitlement, ownership, family consent, Sale/Admin scope, or audit rules. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must follow accepted product decisions. |
| Admin/Super Admin | Operate only where BD grants admin responsibility. | Backend/API must reject missing permission; UI hiding is not sufficient. |

## 5. Primary Entities/Data

| Entity ID | Entity | Purpose | Important Attributes | Relationships |
|---|---|---|---|---|
| SALE_POINTS-E-sale_commission_ledger | Sale Commission Ledger | Ledger hoa hồng/Điểm Sale | payment, sale, rate 10%, base amount, points, status | Unique per payment |
| SALE_POINTS-E-sale_point_balance | Sale Point Balance | Số dư tính toán | available, held, converted, reversed | Derived from ledger |
| SALE_POINTS-E-sale_point_conversion | Sale Point Conversion | Yêu cầu đổi điểm | sale, points, rate, money, status, payout info | Reviewed by Admin |

## 6. States and State Transitions

| Entity / Group | States | Notes |
|---|---|---|
| Commission / Conversion | pending_payment_verification, payment_approved, commission_calculating, points_credited, points_reversed; Conversion: requested, pending_review, approved, paid, rejected, cancelled | Source: BD Appendix B and module sections. |

## 7. Business Rules

| ID | Rule | Applied At | Criticality |
|---|---|---|---|
| SALE_POINTS-BR01 | Mỗi payment_transaction_id chỉ tạo tối đa một Sale Commission Ledger chính. | Commission job, conversion request, reversal/adjustment | Mandatory |
| SALE_POINTS-BR02 | Chỉ điểm points_credited và chưa giữ/đảo mới được quy đổi. | Commission job, conversion request, reversal/adjustment | Mandatory |

## 8. Overall Operational Flow

1. Actor enters the module through the planned view or event listed in Views.md.
2. System validates authentication, entitlement, role, ownership, family scope, Sale status, or Admin permission as applicable.
3. System loads only the data needed for Điểm Sale & quy đổi.
4. Feature function applies module business rules and cross-cutting rules from BD sections 14 and 15.
5. Successful writes use transaction/idempotency and audit where required.
6. UI/API returns a safe business result and never exposes raw stack trace, DB/API wording, secret, payment evidence, or unnecessary health data.

## 9. Integrations and Dependencies

| Dependency | Type | Purpose | Failure Behavior |
|---|---|---|---|
| Auth/Profile | Internal/Supabase planned | Identify actor and ownership. | Block action or request login. |
| Membership/Entitlement | Internal/trusted backend planned | Apply Free/Plus/FamilyPlus access and quotas. | Keep previous state; do not grant paid access. |
| Audit/Security | Cross-cutting | Trace sensitive changes. | Sensitive writes must fail or be queued safely if audit cannot be recorded. |
| Module-specific dependencies | Internal | PAYMENT_MEMBERSHIP: payment_approved event., REFERRAL_DIRECT: valid relationship., ADMIN_OPS: conversion approval., AUDIT_SECURITY: ledger/audit. | Follow dependency owner DD and record conflict as an implementation issue or accepted exception. |

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
| SALE_POINTS-RISK01 | Risk | API/schema/RLS sandbox evidence and final UI assets may still lag the DD contract. | Coding must keep acceptance evidence and sandbox proof before production release. | Open |
| SALE_POINTS-ASSUMPTION01 | Assumption | BD v2.0 plus user decisions from 2026-06-30 are the source of truth; legacy conflicting Sale/Admin logic is not implementation source. | Implementation must migrate or reject old behavior such as Sale tree, tier-2 commission, or 5 percent rules. | Active |
| SALE_POINTS-Q-02 | Answered decision | When is a referral counted as successful? | A referral is successful when the referred customer payment is manually approved. Points are credited immediately after approval, but conversion is locked for 24 hours. | Accepted - User decision 2026-06-30 |
| SALE_POINTS-Q-03 | Answered decision | What is the 10 percent commission base? | Commission is calculated from the listed package price. | Accepted - User decision 2026-06-30 |
| SALE_POINTS-Q-05 | Answered decision | How are refund, cancel, and chargeback handled after points are credited? | Refund/cancel is allowed only within 24 hours after purchase. Points are reversed immediately in that window. Because conversion is also locked for 24 hours, there is no converted-then-reversed case. | Accepted - User decision 2026-06-30 |
| SALE_POINTS-Q-06 | Answered decision | What is the point-to-money conversion rate and minimum payout? | 1 point = 1 VND. Minimum conversion is 500,000 VND. Rate and minimum are Admin-configurable and versioned over time. | Accepted - User decision 2026-06-30 |
| SALE_POINTS-Q-07 | Answered decision | How does Sale payout work? | Sale submits bank info and a conversion request. Admin transfers manually, then approves and deducts points. | Accepted - User decision 2026-06-30 |
| SALE_POINTS-Q-10 | Answered decision | Do suspended or closed Sale accounts continue receiving points? | Suspended or closed Sale accounts receive no new points from old customers. | Accepted - User decision 2026-06-30 |
| SALE_POINTS-Q-11 | Answered decision | How is FamilyPlus commission calculated? | FamilyPlus commission is calculated only on the package owner portion. | Accepted - User decision 2026-06-30 |
| SALE_POINTS-Q-13 | Answered decision | Who can edit sensitive data and Sale points? | Admin has broad operational power, but only Super Admin can edit sensitive data, perform full-data edits, or make manual Sale point adjustments. Each action requires reason, idempotency, and audit. | Accepted - User decision 2026-06-30 |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| SALE_POINTS-ADR01 | Keep implementation gated by documented API/schema/RLS/audit evidence where the checklist still marks sandbox pending. | Product decisions are answered, but several modules still require Supabase or runtime verification before production acceptance. | Accepted |
| SALE_POINTS-ADR02 | Apply accepted product decisions Q-02, Q-03, Q-05, Q-06, Q-07, Q-10, Q-11, Q-13 as the module business contract. | User decisions from 2026-06-30 close the BD Q-01..Q-18 blocker set for this module. | Accepted |

## 13. Traceability Matrix

| BD/Requirement | Feature | Function | View | API | Test |
|---|---|---|---|---|---|
| BD sections 7.5/7.6/12.1, AC-11..AC-16, UC-17 | SALE_POINTS-F01 | SALE_POINTS-FN01 | SALE_POINTS-V01 | SALE_POINTS-API01 | SALE_POINTS-TC01 |
| BD section 7.10, AC-17/AC-18, UC-18/UC-19 | SALE_POINTS-F02 | SALE_POINTS-FN02 | SALE_POINTS-V02 | SALE_POINTS-API02 | SALE_POINTS-TC02 |

## 14. Approval Checklist

- [ ] Scope and out-of-scope reviewed by BA/PO.
- [ ] Business rules reviewed by Tech Lead.
- [ ] UI states reviewed by UI/UX and QA.
- [ ] API/schema/RLS contracts added before coding.
- [x] Product decisions Q-02, Q-03, Q-05, Q-06, Q-07, Q-10, Q-11, Q-13 answered or accepted as explicit implementation policy on 2026-06-30.

## 15. Accepted Product Decision Contract

| ID | Accepted Policy | Implementation Contract | Source |
|---|---|---|---|
| Q-02 | A referral is successful when the referred customer payment is manually approved. Points are credited immediately after approval, but conversion is locked for 24 hours. | Payment approval emits one idempotent commission event; conversion eligibility checks approved_at plus 24 hours in Asia/Ho_Chi_Minh. | User decision 2026-06-30 |
| Q-03 | Commission is calculated from the listed package price. | Commission ledger stores listed_price, commission_rate_version, computed_points, payment_id, and immutable formula version. | User decision 2026-06-30 |
| Q-05 | Refund/cancel is allowed only within 24 hours after purchase. Points are reversed immediately in that window. Because conversion is also locked for 24 hours, there is no converted-then-reversed case. | Refund/cancel RPC requires approved payment age <= 24 hours, creates reversal ledger, and blocks conversion while payment is inside the hold window. | User decision 2026-06-30 |
| Q-06 | 1 point = 1 VND. Minimum conversion is 500,000 VND. Rate and minimum are Admin-configurable and versioned over time. | Conversion request reads active payout_config_version and persists rate, minimum, requested_points, requested_vnd, and idempotency key. | User decision 2026-06-30 |
| Q-07 | Sale submits bank info and a conversion request. Admin transfers manually, then approves and deducts points. | Payout lifecycle is requested -> admin_review -> manually_transferred -> approved/deducted or rejected, with audit and no automatic transfer integration. | User decision 2026-06-30 |
| Q-10 | Suspended or closed Sale accounts receive no new points from old customers. | Commission creation checks Sale status at payment approval time and rejects inactive/suspended/closed Sale with audit-safe reason. | User decision 2026-06-30 |
| Q-11 | FamilyPlus commission is calculated only on the package owner portion. | Payment line items separate owner portion from dependent member portions; commission uses owner portion only. | User decision 2026-06-30 |
| Q-13 | Admin has broad operational power, but only Super Admin can edit sensitive data, perform full-data edits, or make manual Sale point adjustments. Each action requires reason, idempotency, and audit. | Sensitive mutation RPCs require Super Admin, reason, idempotency_key, before/after summary, and audit row; no two-person approval is required in this DD. | User decision 2026-06-30 |

### Remaining Evidence Gate
- DD readiness for this module is 60 percent in `docs/checklist/checklist_complete_DD.md`.
- Coding progress changes only when runtime code, tests, or sandbox evidence are added.
