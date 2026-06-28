# Overall — AI_CHAT / AI Chat

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | AI_CHAT |
| BD Module | M07 |
| Version | v1.0 |
| Status | Draft |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M07, 16.1 AC-03/AC-04/AC-06, Appendix A UC-07 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
| Release Scope | Project DD baseline for M01-M19 |

## 2. Business Goal
Module này đảm bảo AI Chat chỉ mở cho tài khoản có quyền, không gọi AI khi quota bị chặn và không lưu/log raw sensitive response trong DD.

## 3. Module Scope

### In Scope
- Gate AI Chat theo đăng nhập/gói.
- Quota Free 3 lượt/ngày.
- Plus/FamilyPlus không bị quota Free.
- Xử lý lỗi AI an toàn.

### Out of Scope
- Prompt/response thật.
- Medical diagnosis.
- Model/provider tuning chi tiết.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| Free, Plus, FamilyPlus | Use module features according to BD sections 3, 5, and BD sections 6/M07, 16.1 AC-03/AC-04/AC-06, Appendix A UC-07. | Must not bypass entitlement, ownership, family consent, Sale/Admin scope, or audit rules. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must not invent product decisions. |
| Admin/Super Admin | Operate only where BD grants admin responsibility. | Backend/API must reject missing permission; UI hiding is not sufficient. |

## 5. Primary Entities/Data

| Entity ID | Entity | Purpose | Important Attributes | Relationships |
|---|---|---|---|---|
| AI_CHAT-E-ai_request | AI Request | Theo dõi request chat | request_id, user, status, quota impact | Uses quota ledger |
| AI_CHAT-E-chat_message | Chat Message | Tin nhắn chat nếu lưu | owner, role, content summary, created_at | Subject to privacy policy |

## 6. States and State Transitions

| Entity / Group | States | Notes |
|---|---|---|
| AI Request | created, validating, sent, succeeded, failed, quota_blocked | Source: BD Appendix B and module sections. |

## 7. Business Rules

| ID | Rule | Applied At | Criticality |
|---|---|---|---|
| AI_CHAT-BR01 | Guest không được mở AI Chat. | AI chat gate and quota consumption | Mandatory |
| AI_CHAT-BR02 | Free bị chặn ở lượt hỏi thứ 4 trong ngày; Plus/FamilyPlus không bị quota Free. | AI chat gate and quota consumption | Mandatory |

## 8. Overall Operational Flow

1. Actor enters the module through the planned view or event listed in Views.md.
2. System validates authentication, entitlement, role, ownership, family scope, Sale status, or Admin permission as applicable.
3. System loads only the data needed for AI Chat.
4. Feature function applies module business rules and cross-cutting rules from BD sections 14 and 15.
5. Successful writes use transaction/idempotency and audit where required.
6. UI/API returns a safe business result and never exposes raw stack trace, DB/API wording, secret, payment evidence, or unnecessary health data.

## 9. Integrations and Dependencies

| Dependency | Type | Purpose | Failure Behavior |
|---|---|---|---|
| Auth/Profile | Internal/Supabase planned | Identify actor and ownership. | Block action or request login. |
| Membership/Entitlement | Internal/trusted backend planned | Apply Free/Plus/FamilyPlus access and quotas. | Keep previous state; do not grant paid access. |
| Audit/Security | Cross-cutting | Trace sensitive changes. | Sensitive writes must fail or be queued safely if audit cannot be recorded. |
| Module-specific dependencies | Internal | MEMBERSHIP_QUOTA: access/quota., AUTH_PROFILE_SYNC: session., AUDIT_SECURITY: safe logging. | Follow dependency owner DD and record conflict as OPEN QUESTION. |

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
| AI_CHAT-RISK01 | Risk | Physical schema/API/RLS and final UI wireframes are not provided in BD. | Implementation may diverge if coding starts before detailed contracts. | Open |
| AI_CHAT-ASSUMPTION01 | Assumption | This DD uses BD v2.0 as source of truth and treats conflicting legacy Sale logic as blocked. | Legacy behavior must be reviewed before coding. | Active |
| AI_CHAT-Q-16 | Open question | Múi giờ chuẩn cho reset quota, thời hạn gói, báo cáo và duyệt payment là gì? | Quota, entitlement, reporting and approval windows. | Open |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| AI_CHAT-ADR01 | Keep this module DD in Draft until PO/Tech Lead closes related open questions and implementation contracts. | BD v2.0 contains Q-01..Q-18 and explicit DD-before-coding gates. | Accepted |

## 13. Traceability Matrix

| BD/Requirement | Feature | Function | View | API | Test |
|---|---|---|---|---|---|
| BD M07 luồng, AC-03/AC-06 | AI_CHAT-F01 | AI_CHAT-FN01 | AI_CHAT-V01 | AI_CHAT-API01 | AI_CHAT-TC01 |
| BD M07 rules, AC-04 | AI_CHAT-F02 | AI_CHAT-FN02 | AI_CHAT-V02 | AI_CHAT-API02 | AI_CHAT-TC02 |

## 14. Approval Checklist

- [ ] Scope and out-of-scope reviewed by BA/PO.
- [ ] Business rules reviewed by Tech Lead.
- [ ] UI states reviewed by UI/UX and QA.
- [ ] API/schema/RLS contracts added before coding.
- [ ] Open questions resolved or accepted as explicit implementation assumptions.
