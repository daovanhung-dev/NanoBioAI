# Overall — SCHEDULE_NOTIFICATIONS / Thông báo lịch trình

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | SCHEDULE_NOTIFICATIONS |
| BD Module | M09 |
| Version | v1.0 |
| Status | Draft |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M09, 13, Appendix A UC-04 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
| Release Scope | Project DD baseline for M01-M19 |

## 2. Business Goal
Module này đảm bảo notification không lộ dữ liệu Family sai scope và action complete/skip cập nhật đúng plan item.

## 3. Module Scope

### In Scope
- Tạo notification schedule từ plan items.
- Nhắc theo timezone/config.
- Handle complete/skip action.
- Tách subject FamilyPlus.

### Out of Scope
- Template copy chi tiết.
- Vendor push config.
- Notification permission UX đầy đủ.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| Guest, Member, Family | Use module features according to BD sections 3, 5, and BD sections 6/M09, 13, Appendix A UC-04. | Must not bypass entitlement, ownership, family consent, Sale/Admin scope, or audit rules. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must not invent product decisions. |
| Admin/Super Admin | Operate only where BD grants admin responsibility. | Backend/API must reject missing permission; UI hiding is not sufficient. |

## 5. Primary Entities/Data

| Entity ID | Entity | Purpose | Important Attributes | Relationships |
|---|---|---|---|---|
| SCHEDULE_NOTIFICATIONS-E-notification_schedule | Notification Schedule | Lịch nhắc | plan/item, time, device, status | Linked to plan item |
| SCHEDULE_NOTIFICATIONS-E-notification_action | Notification Action | Action complete/skip | payload, actor, action, correlation id | Writes completion event |

## 6. States and State Transitions

| Entity / Group | States | Notes |
|---|---|---|
| Notification Schedule | scheduled, sent, failed, dismissed, action_completed, action_skipped | Source: BD Appendix B and module sections. |

## 7. Business Rules

| ID | Rule | Applied At | Criticality |
|---|---|---|---|
| SCHEDULE_NOTIFICATIONS-BR01 | FamilyPlus không gửi nhắc hoặc lộ dữ liệu thành viên khác trái quyền/consent. | Notification scheduling and action handling | Mandatory |
| SCHEDULE_NOTIFICATIONS-BR02 | Notification action phải idempotent để không tạo completion event trùng. | Notification scheduling and action handling | Mandatory |

## 8. Overall Operational Flow

1. Actor enters the module through the planned view or event listed in Views.md.
2. System validates authentication, entitlement, role, ownership, family scope, Sale status, or Admin permission as applicable.
3. System loads only the data needed for Thông báo lịch trình.
4. Feature function applies module business rules and cross-cutting rules from BD sections 14 and 15.
5. Successful writes use transaction/idempotency and audit where required.
6. UI/API returns a safe business result and never exposes raw stack trace, DB/API wording, secret, payment evidence, or unnecessary health data.

## 9. Integrations and Dependencies

| Dependency | Type | Purpose | Failure Behavior |
|---|---|---|---|
| Auth/Profile | Internal/Supabase planned | Identify actor and ownership. | Block action or request login. |
| Membership/Entitlement | Internal/trusted backend planned | Apply Free/Plus/FamilyPlus access and quotas. | Keep previous state; do not grant paid access. |
| Audit/Security | Cross-cutting | Trace sensitive changes. | Sensitive writes must fail or be queued safely if audit cannot be recorded. |
| Module-specific dependencies | Internal | PERSONAL_SCHEDULE_AI: source plan items., DASHBOARD_SCHEDULE: update completion events., FAMILYPLUS: subject and privacy boundary. | Follow dependency owner DD and record conflict as OPEN QUESTION. |

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
| SCHEDULE_NOTIFICATIONS-RISK01 | Risk | Physical schema/API/RLS and final UI wireframes are not provided in BD. | Implementation may diverge if coding starts before detailed contracts. | Open |
| SCHEDULE_NOTIFICATIONS-ASSUMPTION01 | Assumption | This DD uses BD v2.0 as source of truth and treats conflicting legacy Sale logic as blocked. | Legacy behavior must be reviewed before coding. | Active |
| SCHEDULE_NOTIFICATIONS-Q-16 | Open question | Múi giờ chuẩn cho reset quota, thời hạn gói, báo cáo và duyệt payment là gì? | Quota, entitlement, reporting and approval windows. | Open |
| SCHEDULE_NOTIFICATIONS-Q-15 | Open question | Số thành viên FamilyPlus tối đa, quyền xem/sửa và consent theo tuổi/quan hệ? | Family data model and privacy. | Open |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| SCHEDULE_NOTIFICATIONS-ADR01 | Keep this module DD in Draft until PO/Tech Lead closes related open questions and implementation contracts. | BD v2.0 contains Q-01..Q-18 and explicit DD-before-coding gates. | Accepted |

## 13. Traceability Matrix

| BD/Requirement | Feature | Function | View | API | Test |
|---|---|---|---|---|---|
| BD M09 luồng, UC-04 | SCHEDULE_NOTIFICATIONS-F01 | SCHEDULE_NOTIFICATIONS-FN01 | SCHEDULE_NOTIFICATIONS-V01 | SCHEDULE_NOTIFICATIONS-API01 | SCHEDULE_NOTIFICATIONS-TC01 |
| BD M09 quy tắc | SCHEDULE_NOTIFICATIONS-F02 | SCHEDULE_NOTIFICATIONS-FN02 | SCHEDULE_NOTIFICATIONS-V02 | SCHEDULE_NOTIFICATIONS-API02 | SCHEDULE_NOTIFICATIONS-TC02 |

## 14. Approval Checklist

- [ ] Scope and out-of-scope reviewed by BA/PO.
- [ ] Business rules reviewed by Tech Lead.
- [ ] UI states reviewed by UI/UX and QA.
- [ ] API/schema/RLS contracts added before coding.
- [ ] Open questions resolved or accepted as explicit implementation assumptions.
