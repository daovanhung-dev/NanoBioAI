# Overall — REFERRAL_DIRECT / Sale & mã giới thiệu trực tiếp

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | REFERRAL_DIRECT |
| BD Module | M12 |
| Version | v1.0 |
| Status | Draft - contracts updated, sandbox evidence pending |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 7/M12, 15, 16.2 AC-09/AC-10/AC-14, Appendix A UC-12..UC-14 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
| Release Scope | Project DD baseline for M01-M19 |

## 2. Business Goal
Module này thay toàn bộ mô hình hoa hồng cây nhiều tầng bằng direct referral 1 tầng, không tạo tầng 2/5% hoặc cây Sale.

## 3. Module Scope

### In Scope
- Gửi yêu cầu trở thành Sale.
- Admin duyệt/từ chối Sale.
- Cấp/quản lý mã giới thiệu duy nhất.
- Gắn quan hệ trực tiếp Sale -> khách.

### Out of Scope
- Commission calculation/payment.
- Sale xem health data của khách.
- Multi-level referral tree.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| Member, Sale, Admin | Use module features according to BD sections 3, 5, and BD sections 7/M12, 15, 16.2 AC-09/AC-10/AC-14, Appendix A UC-12..UC-14. | Must not bypass entitlement, ownership, family consent, Sale/Admin scope, or audit rules. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must follow accepted product decisions. |
| Admin/Super Admin | Operate only where BD grants admin responsibility. | Backend/API must reject missing permission; UI hiding is not sufficient. |

## 5. Primary Entities/Data

| Entity ID | Entity | Purpose | Important Attributes | Relationships |
|---|---|---|---|---|
| REFERRAL_DIRECT-E-sale_profile | Sale Profile | Quyền Sale | status, code, activated_at, suspended_at | Owns referral code |
| REFERRAL_DIRECT-E-referral_relationship | Referral Relationship | Quan hệ Sale -> khách trực tiếp | sale_id, customer_id, referral_code, locked_at, status | Source for Sale points |

## 6. States and State Transitions

| Entity / Group | States | Notes |
|---|---|---|
| Sale Profile / Referral Relationship | Sale: none, pending_review, active, suspended, closed; Referral: pending, active, invalid, locked, reversed | Source: BD Appendix B and module sections. |

## 7. Business Rules

| ID | Rule | Applied At | Criticality |
|---|---|---|---|
| REFERRAL_DIRECT-BR01 | Không có hoa hồng tầng 2, tầng 3, cây Sale hoặc tỷ lệ 5%. | Sale registration, referral code validation, relationship locking | Mandatory |
| REFERRAL_DIRECT-BR02 | Khách chỉ được gắn tối đa một mã giới thiệu và mã chỉ hợp lệ khi Sale active. | Sale registration, referral code validation, relationship locking | Mandatory |

## 8. Overall Operational Flow

1. Actor enters the module through the planned view or event listed in Views.md.
2. System validates authentication, entitlement, role, ownership, family scope, Sale status, or Admin permission as applicable.
3. System loads only the data needed for Sale & mã giới thiệu trực tiếp.
4. Feature function applies module business rules and cross-cutting rules from BD sections 14 and 15.
5. Successful writes use transaction/idempotency and audit where required.
6. UI/API returns a safe business result and never exposes raw stack trace, DB/API wording, secret, payment evidence, or unnecessary health data.

## 9. Integrations and Dependencies

| Dependency | Type | Purpose | Failure Behavior |
|---|---|---|---|
| Auth/Profile | Internal/Supabase planned | Identify actor and ownership. | Block action or request login. |
| Membership/Entitlement | Internal/trusted backend planned | Apply Free/Plus/FamilyPlus access and quotas. | Keep previous state; do not grant paid access. |
| Audit/Security | Cross-cutting | Trace sensitive changes. | Sensitive writes must fail or be queued safely if audit cannot be recorded. |
| Module-specific dependencies | Internal | AUTH_PROFILE_SYNC: Member and customer identity., PAYMENT_MEMBERSHIP: later payment source., SALE_POINTS: point credit after approval., AUDIT_SECURITY: fraud/audit. | Follow dependency owner DD and record conflict as an implementation issue or accepted exception. |

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
| REFERRAL_DIRECT-RISK01 | Risk | API/schema/RLS sandbox evidence and final UI assets may still lag the DD contract. | Coding must keep acceptance evidence and sandbox proof before production release. | Open |
| REFERRAL_DIRECT-ASSUMPTION01 | Assumption | BD v2.0 plus user decisions from 2026-06-30 are the source of truth; legacy conflicting Sale/Admin logic is not implementation source. | Implementation must migrate or reject old behavior such as Sale tree, tier-2 commission, or 5 percent rules. | Active |
| REFERRAL_DIRECT-Q-01 | Answered decision | Who can become Sale? | Only members with Plus or higher active package can become Sale. | Accepted - User decision 2026-06-30 |
| REFERRAL_DIRECT-Q-08 | Answered decision | When can referral code be entered? | Referral code is accepted only during registration. Any post-registration correction requires audited Super Admin override. | Accepted - User decision 2026-06-30 |
| REFERRAL_DIRECT-Q-09 | Answered decision | What anti-fraud rules apply to referrals? | Use the strictest policy: hard-block same account, phone, email, payment, bank, device, or identity; hold suspicious IP/device/family/payment patterns for Admin review; only audited Super Admin override may release. | Accepted - User decision 2026-06-30 |
| REFERRAL_DIRECT-Q-10 | Answered decision | Do suspended or closed Sale accounts continue receiving points? | Suspended or closed Sale accounts receive no new points from old customers. | Accepted - User decision 2026-06-30 |
| REFERRAL_DIRECT-Q-18 | Answered decision | What customer information may Sale see? | Sale may see customer phone number and basic profile information for customer care, but cannot see health data, AI data, secrets, or raw payment payloads. | Accepted - User decision 2026-06-30 |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| REFERRAL_DIRECT-ADR01 | Keep implementation gated by documented API/schema/RLS/audit evidence where the checklist still marks sandbox pending. | Product decisions are answered, but several modules still require Supabase or runtime verification before production acceptance. | Accepted |
| REFERRAL_DIRECT-ADR02 | Apply accepted product decisions Q-01, Q-08, Q-09, Q-10, Q-18 as the module business contract. | User decisions from 2026-06-30 close the BD Q-01..Q-18 blocker set for this module. | Accepted |

## 13. Traceability Matrix

| BD/Requirement | Feature | Function | View | API | Test |
|---|---|---|---|---|---|
| BD sections 7.2, AC-09, UC-12/UC-13 | REFERRAL_DIRECT-F01 | REFERRAL_DIRECT-FN01 | REFERRAL_DIRECT-V01 | REFERRAL_DIRECT-API01 | REFERRAL_DIRECT-TC01 |
| BD sections 7.3/7.4, AC-10/AC-14, UC-14 | REFERRAL_DIRECT-F02 | REFERRAL_DIRECT-FN02 | REFERRAL_DIRECT-V02 | REFERRAL_DIRECT-API02 | REFERRAL_DIRECT-TC02 |

## 14. Approval Checklist

- [ ] Scope and out-of-scope reviewed by BA/PO.
- [ ] Business rules reviewed by Tech Lead.
- [ ] UI states reviewed by UI/UX and QA.
- [ ] API/schema/RLS contracts added before coding.
- [x] Product decisions Q-01, Q-08, Q-09, Q-10, Q-18 answered or accepted as explicit implementation policy on 2026-06-30.

## 15. Accepted Product Decision Contract

| ID | Accepted Policy | Implementation Contract | Source |
|---|---|---|---|
| Q-01 | Only members with Plus or higher active package can become Sale. | Sale registration and Admin approval must verify active Plus/FamilyPlus entitlement before status can become active. | User decision 2026-06-30 |
| Q-08 | Referral code is accepted only during registration. Any post-registration correction requires audited Super Admin override. | Registration attach RPC is single-use and locked after account creation; override stores actor, reason, old/new referral, and audit id. | User decision 2026-06-30 |
| Q-09 | Use the strictest policy: hard-block same account, phone, email, payment, bank, device, or identity; hold suspicious IP/device/family/payment patterns for Admin review; only audited Super Admin override may release. | Referral attach and payment commission checks run fraud rules before ledger writes and expose safe fraud review states, not raw signals. | User decision 2026-06-30 |
| Q-10 | Suspended or closed Sale accounts receive no new points from old customers. | Commission creation checks Sale status at payment approval time and rejects inactive/suspended/closed Sale with audit-safe reason. | User decision 2026-06-30 |
| Q-18 | Sale may see customer phone number and basic profile information for customer care, but cannot see health data, AI data, secrets, or raw payment payloads. | Sale customer views use privacy-limited DTOs and RLS/backend filters; no raw health, AI, secret, or payment evidence fields are returned. | User decision 2026-06-30 |

### Remaining Evidence Gate
- DD readiness for this module is 60 percent in `docs/checklist/checklist_complete_DD.md`.
- Coding progress changes only when runtime code, tests, or sandbox evidence are added.
