# Overall — PERSONAL_SCHEDULE_AI / AI Lịch trình cá nhân

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | PERSONAL_SCHEDULE_AI |
| BD Module | M02 |
| Version | v1.0 |
| Status | Draft |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M02, 13, 16.1 AC-01/AC-02/AC-05/AC-06, Appendix A UC-02/UC-08 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
| Release Scope | Project DD baseline for M01-M19 |

## 2. Business Goal
Module này kiểm soát việc gọi AI để tạo lịch trình đúng quota, idempotent và không trừ quota khi AI lỗi trước kết quả hợp lệ.

## 3. Module Scope

### In Scope
- Guest tạo lịch trình AI đầu tiên một lần.
- Member tạo lịch trình mới theo quota/gói.
- Lưu Personal Plan và Plan Item.
- Retry an toàn khi AI thất bại.

### Out of Scope
- Raw prompt/response AI trong DD.
- Chẩn đoán y tế.
- Rate limit kỹ thuật chi tiết ngoài BD.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| Guest, Member | Use module features according to BD sections 3, 5, and BD sections 6/M02, 13, 16.1 AC-01/AC-02/AC-05/AC-06, Appendix A UC-02/UC-08. | Must not bypass entitlement, ownership, family consent, Sale/Admin scope, or audit rules. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must not invent product decisions. |
| Admin/Super Admin | Operate only where BD grants admin responsibility. | Backend/API must reject missing permission; UI hiding is not sufficient. |

## 5. Primary Entities/Data

| Entity ID | Entity | Purpose | Important Attributes | Relationships |
|---|---|---|---|---|
| PERSONAL_SCHEDULE_AI-E-personal_plan | Personal Plan | Lịch trình AI | owner, subject, version, status, AI source | Has Plan Items |
| PERSONAL_SCHEDULE_AI-E-plan_item | Plan Item | Bữa ăn/bài tập/mốc lịch | plan id, time, type, status | Used by dashboard and notification |
| PERSONAL_SCHEDULE_AI-E-ai_request | AI Request | Theo dõi request/quota | request_id, type, status, quota impact | Linked to quota ledger |

## 6. States and State Transitions

| Entity / Group | States | Notes |
|---|---|---|
| Personal Plan | draft, generating, active, archived, failed | Source: BD Appendix B and module sections. |

## 7. Business Rules

| ID | Rule | Applied At | Criticality |
|---|---|---|---|
| PERSONAL_SCHEDULE_AI-BR01 | Guest chỉ được tạo lịch trình AI đầu tiên một lần. | Schedule generation, quota use, retry | Mandatory |
| PERSONAL_SCHEDULE_AI-BR02 | Nếu AI thất bại trước kết quả hợp lệ, không trừ quota và retry phải idempotent. | Schedule generation, quota use, retry | Mandatory |

## 8. Overall Operational Flow

1. Actor enters the module through the planned view or event listed in Views.md.
2. System validates authentication, entitlement, role, ownership, family scope, Sale status, or Admin permission as applicable.
3. System loads only the data needed for AI Lịch trình cá nhân.
4. Feature function applies module business rules and cross-cutting rules from BD sections 14 and 15.
5. Successful writes use transaction/idempotency and audit where required.
6. UI/API returns a safe business result and never exposes raw stack trace, DB/API wording, secret, payment evidence, or unnecessary health data.

## 9. Integrations and Dependencies

| Dependency | Type | Purpose | Failure Behavior |
|---|---|---|---|
| Auth/Profile | Internal/Supabase planned | Identify actor and ownership. | Block action or request login. |
| Membership/Entitlement | Internal/trusted backend planned | Apply Free/Plus/FamilyPlus access and quotas. | Keep previous state; do not grant paid access. |
| Audit/Security | Cross-cutting | Trace sensitive changes. | Sensitive writes must fail or be queued safely if audit cannot be recorded. |
| Module-specific dependencies | Internal | ONBOARDING_PROFILE: input cá nhân hóa., MEMBERSHIP_QUOTA: kiểm tra quota/gói., SCHEDULE_NOTIFICATIONS: nhận lịch để tạo nhắc. | Follow dependency owner DD and record conflict as OPEN QUESTION. |

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
| PERSONAL_SCHEDULE_AI-RISK01 | Risk | Physical schema/API/RLS and final UI wireframes are not provided in BD. | Implementation may diverge if coding starts before detailed contracts. | Open |
| PERSONAL_SCHEDULE_AI-ASSUMPTION01 | Assumption | This DD uses BD v2.0 as source of truth and treats conflicting legacy Sale logic as blocked. | Legacy behavior must be reviewed before coding. | Active |
| PERSONAL_SCHEDULE_AI-Q-16 | Open question | Múi giờ chuẩn cho reset quota, thời hạn gói, báo cáo và duyệt payment là gì? | Quota, entitlement, reporting and approval windows. | Open |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| PERSONAL_SCHEDULE_AI-ADR01 | Keep this module DD in Draft until PO/Tech Lead closes related open questions and implementation contracts. | BD v2.0 contains Q-01..Q-18 and explicit DD-before-coding gates. | Accepted |

## 13. Traceability Matrix

| BD/Requirement | Feature | Function | View | API | Test |
|---|---|---|---|---|---|
| BD M02 Guest flow, AC-01, AC-02, UC-02 | PERSONAL_SCHEDULE_AI-F01 | PERSONAL_SCHEDULE_AI-FN01 | PERSONAL_SCHEDULE_AI-V01 | PERSONAL_SCHEDULE_AI-API01 | PERSONAL_SCHEDULE_AI-TC01 |
| BD M02 Member flow, AC-05, AC-06, UC-08 | PERSONAL_SCHEDULE_AI-F02 | PERSONAL_SCHEDULE_AI-FN02 | PERSONAL_SCHEDULE_AI-V02 | PERSONAL_SCHEDULE_AI-API02 | PERSONAL_SCHEDULE_AI-TC02 |

## 14. Approval Checklist

- [ ] Scope and out-of-scope reviewed by BA/PO.
- [ ] Business rules reviewed by Tech Lead.
- [ ] UI states reviewed by UI/UX and QA.
- [ ] API/schema/RLS contracts added before coding.
- [ ] Open questions resolved or accepted as explicit implementation assumptions.
