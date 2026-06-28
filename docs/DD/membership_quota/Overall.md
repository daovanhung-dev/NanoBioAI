# Overall — MEMBERSHIP_QUOTA / Gói thành viên & quota

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | MEMBERSHIP_QUOTA |
| BD Module | M06 |
| Version | v1.0 |
| Status | Draft |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M06, 13, 16.1 AC-04..AC-08, Appendix A UC-06 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
| Release Scope | Project DD baseline for M01-M19 |

## 2. Business Goal
Module này dựng quyền hiệu lực từ auth + gói + trạng thái gói + Sale/Admin axis và kiểm soát quota trusted backend.

## 3. Module Scope

### In Scope
- Dựng entitlement Free/Plus/FamilyPlus.
- Quota AI Chat 3/ngày và tạo lịch 3/tháng cho Free.
- Nâng quyền sau payment_approved.
- Version hóa gói/quota.

### Out of Scope
- Payment provider cụ thể.
- Sale role tự mở quota.
- Hard-code paid access trong Flutter.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| Member, Admin | Use module features according to BD sections 3, 5, and BD sections 6/M06, 13, 16.1 AC-04..AC-08, Appendix A UC-06. | Must not bypass entitlement, ownership, family consent, Sale/Admin scope, or audit rules. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must not invent product decisions. |
| Admin/Super Admin | Operate only where BD grants admin responsibility. | Backend/API must reject missing permission; UI hiding is not sufficient. |

## 5. Primary Entities/Data

| Entity ID | Entity | Purpose | Important Attributes | Relationships |
|---|---|---|---|---|
| MEMBERSHIP_QUOTA-E-membership_product | Membership Product | Cấu hình gói | plan code, price, quota, version, effective time | Creates entitlement |
| MEMBERSHIP_QUOTA-E-membership_entitlement | Membership Entitlement | Quyền gói | user, plan, start/end, source payment | Used by gates |
| MEMBERSHIP_QUOTA-E-usage_quota_ledger | Usage Quota Ledger | Lịch sử quota | quota type, period, request id, status | Used by AI and schedule |

## 6. States and State Transitions

| Entity / Group | States | Notes |
|---|---|---|
| Entitlement | pending, active, expired, suspended, cancelled | Source: BD Appendix B and module sections. |

## 7. Business Rules

| ID | Rule | Applied At | Criticality |
|---|---|---|---|
| MEMBERSHIP_QUOTA-BR01 | Chỉ payment_approved mới mở quyền Plus/FamilyPlus. | Access gate, quota check, payment activation | Mandatory |
| MEMBERSHIP_QUOTA-BR02 | Quota phải có dữ liệu nguồn, kỳ tính, request_id và audit để đối soát. | Access gate, quota check, payment activation | Mandatory |

## 8. Overall Operational Flow

1. Actor enters the module through the planned view or event listed in Views.md.
2. System validates authentication, entitlement, role, ownership, family scope, Sale status, or Admin permission as applicable.
3. System loads only the data needed for Gói thành viên & quota.
4. Feature function applies module business rules and cross-cutting rules from BD sections 14 and 15.
5. Successful writes use transaction/idempotency and audit where required.
6. UI/API returns a safe business result and never exposes raw stack trace, DB/API wording, secret, payment evidence, or unnecessary health data.

## 9. Integrations and Dependencies

| Dependency | Type | Purpose | Failure Behavior |
|---|---|---|---|
| Auth/Profile | Internal/Supabase planned | Identify actor and ownership. | Block action or request login. |
| Membership/Entitlement | Internal/trusted backend planned | Apply Free/Plus/FamilyPlus access and quotas. | Keep previous state; do not grant paid access. |
| Audit/Security | Cross-cutting | Trace sensitive changes. | Sensitive writes must fail or be queued safely if audit cannot be recorded. |
| Module-specific dependencies | Internal | AUTH_PROFILE_SYNC: user/session., PAYMENT_MEMBERSHIP: source payment approved., AI_CHAT and PERSONAL_SCHEDULE_AI: quota consumers. | Follow dependency owner DD and record conflict as OPEN QUESTION. |

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
| MEMBERSHIP_QUOTA-RISK01 | Risk | Physical schema/API/RLS and final UI wireframes are not provided in BD. | Implementation may diverge if coding starts before detailed contracts. | Open |
| MEMBERSHIP_QUOTA-ASSUMPTION01 | Assumption | This DD uses BD v2.0 as source of truth and treats conflicting legacy Sale logic as blocked. | Legacy behavior must be reviewed before coding. | Active |
| MEMBERSHIP_QUOTA-Q-04 | Open question | Các gói thanh toán theo tháng, năm hay một lần; gia hạn sớm/trễ xử lý ra sao? | Entitlement and recurring commission. | Open |
| MEMBERSHIP_QUOTA-Q-16 | Open question | Múi giờ chuẩn cho reset quota, thời hạn gói, báo cáo và duyệt payment là gì? | Quota, entitlement, reporting and approval windows. | Open |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| MEMBERSHIP_QUOTA-ADR01 | Keep this module DD in Draft until PO/Tech Lead closes related open questions and implementation contracts. | BD v2.0 contains Q-01..Q-18 and explicit DD-before-coding gates. | Accepted |

## 13. Traceability Matrix

| BD/Requirement | Feature | Function | View | API | Test |
|---|---|---|---|---|---|
| BD M06 luồng dựng quyền, AC-07/AC-08, UC-06 | MEMBERSHIP_QUOTA-F01 | MEMBERSHIP_QUOTA-FN01 | MEMBERSHIP_QUOTA-V01 | MEMBERSHIP_QUOTA-API01 | MEMBERSHIP_QUOTA-TC01 |
| BD M06 quota, AC-04/AC-05 | MEMBERSHIP_QUOTA-F02 | MEMBERSHIP_QUOTA-FN02 | MEMBERSHIP_QUOTA-V02 | MEMBERSHIP_QUOTA-API02 | MEMBERSHIP_QUOTA-TC02 |

## 14. Approval Checklist

- [ ] Scope and out-of-scope reviewed by BA/PO.
- [ ] Business rules reviewed by Tech Lead.
- [ ] UI states reviewed by UI/UX and QA.
- [ ] API/schema/RLS contracts added before coding.
- [ ] Open questions resolved or accepted as explicit implementation assumptions.
