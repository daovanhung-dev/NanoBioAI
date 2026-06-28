# Overall — SALE_POINTS / Điểm Sale & quy đổi

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | SALE_POINTS |
| BD Module | M14 |
| Version | v1.0 |
| Status | Draft |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 7.5..7.10, 9, 12.1, 14.4, 16.2 AC-11..AC-18, Appendix A UC-17..UC-19 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
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
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must not invent product decisions. |
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
| Module-specific dependencies | Internal | PAYMENT_MEMBERSHIP: payment_approved event., REFERRAL_DIRECT: valid relationship., ADMIN_OPS: conversion approval., AUDIT_SECURITY: ledger/audit. | Follow dependency owner DD and record conflict as OPEN QUESTION. |

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
| SALE_POINTS-RISK01 | Risk | Physical schema/API/RLS and final UI wireframes are not provided in BD. | Implementation may diverge if coding starts before detailed contracts. | Open |
| SALE_POINTS-ASSUMPTION01 | Assumption | This DD uses BD v2.0 as source of truth and treats conflicting legacy Sale logic as blocked. | Legacy behavior must be reviewed before coding. | Active |
| SALE_POINTS-Q-02 | Open question | Giới thiệu thành công có cần thêm điều kiện như qua thời gian hoàn tiền? | Timing of Sale point credit. | Open |
| SALE_POINTS-Q-03 | Open question | 10% tính trên giá niêm yết hay số tiền thực thu sau giảm giá/voucher/thuế/phí? | Commission formula and reporting. | Open |
| SALE_POINTS-Q-05 | Open question | Hoàn/hủy/chargeback sau khi cộng điểm xử lý thế nào nếu Sale đã đổi điểm? | Ledger reversal and negative balance policy. | Open |
| SALE_POINTS-Q-06 | Open question | Tỷ lệ quy đổi Điểm Sale thành tiền, thay đổi theo thời gian, mức tối thiểu là gì? | Conversion configuration and UI. | Open |
| SALE_POINTS-Q-07 | Open question | Sale nhận tiền bằng phương thức nào, chu kỳ chi trả, hồ sơ/tax/invoice nào? | Payout operations and evidence. | Open |
| SALE_POINTS-Q-10 | Open question | Sale suspended/closed thì khách cũ có còn phát sinh điểm không? | Sale state machine and disputes. | Open |
| SALE_POINTS-Q-11 | Open question | FamilyPlus payment tính 10% trên toàn gói hay chỉ phần chủ gói? | Commission base for FamilyPlus. | Open |
| SALE_POINTS-Q-13 | Open question | Admin có được điều chỉnh thủ công Điểm Sale và cần hai người duyệt không? | Audit and separation of duties. | Open |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| SALE_POINTS-ADR01 | Keep this module DD in Draft until PO/Tech Lead closes related open questions and implementation contracts. | BD v2.0 contains Q-01..Q-18 and explicit DD-before-coding gates. | Accepted |

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
- [ ] Open questions resolved or accepted as explicit implementation assumptions.
