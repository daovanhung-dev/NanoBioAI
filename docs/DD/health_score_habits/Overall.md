# Overall — HEALTH_SCORE_HABITS / Điểm sức khỏe & thói quen

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | HEALTH_SCORE_HABITS |
| BD Module | M08 |
| Version | v1.0 |
| Status | Draft |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M08, 9, 13, Appendix A UC-09 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
| Release Scope | Project DD baseline for M01-M19 |

## 2. Business Goal
Module này giữ Health Score là điểm sức khỏe, không thể quy đổi tiền và không được dùng chung ledger với Điểm Sale.

## 3. Module Scope

### In Scope
- Tính điểm theo completion history.
- Version hóa công thức.
- Tách subject FamilyPlus.
- Hiển thị tiến độ/thói quen.

### Out of Scope
- Điểm Sale/hoa hồng.
- Chẩn đoán y tế.
- Công thức chưa được PO/chuyên môn phê duyệt.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| Free, Plus, FamilyPlus | Use module features according to BD sections 3, 5, and BD sections 6/M08, 9, 13, Appendix A UC-09. | Must not bypass entitlement, ownership, family consent, Sale/Admin scope, or audit rules. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must not invent product decisions. |
| Admin/Super Admin | Operate only where BD grants admin responsibility. | Backend/API must reject missing permission; UI hiding is not sufficient. |

## 5. Primary Entities/Data

| Entity ID | Entity | Purpose | Important Attributes | Relationships |
|---|---|---|---|---|
| HEALTH_SCORE_HABITS-E-health_score_ledger | Health Score Ledger | Điểm sức khỏe | subject, source event, formula version, score | Uses completion events |
| HEALTH_SCORE_HABITS-E-habit_progress | Habit Progress | Tiến độ thói quen | subject, period, score, status | Displayed on dashboard |

## 6. States and State Transitions

| Entity / Group | States | Notes |
|---|---|---|
| Health Score Ledger | calculated, adjusted, deprecated_formula | Source: BD Appendix B and module sections. |

## 7. Business Rules

| ID | Rule | Applied At | Criticality |
|---|---|---|---|
| HEALTH_SCORE_HABITS-BR01 | Điểm sức khỏe và Điểm Sale phải tách dữ liệu, tính toán và UI. | Health score calculation and display | Mandatory |
| HEALTH_SCORE_HABITS-BR02 | FamilyPlus phải tách điểm từng thành viên, không gộp nhầm vào chủ gói. | Health score calculation and display | Mandatory |

## 8. Overall Operational Flow

1. Actor enters the module through the planned view or event listed in Views.md.
2. System validates authentication, entitlement, role, ownership, family scope, Sale status, or Admin permission as applicable.
3. System loads only the data needed for Điểm sức khỏe & thói quen.
4. Feature function applies module business rules and cross-cutting rules from BD sections 14 and 15.
5. Successful writes use transaction/idempotency and audit where required.
6. UI/API returns a safe business result and never exposes raw stack trace, DB/API wording, secret, payment evidence, or unnecessary health data.

## 9. Integrations and Dependencies

| Dependency | Type | Purpose | Failure Behavior |
|---|---|---|---|
| Auth/Profile | Internal/Supabase planned | Identify actor and ownership. | Block action or request login. |
| Membership/Entitlement | Internal/trusted backend planned | Apply Free/Plus/FamilyPlus access and quotas. | Keep previous state; do not grant paid access. |
| Audit/Security | Cross-cutting | Trace sensitive changes. | Sensitive writes must fail or be queued safely if audit cannot be recorded. |
| Module-specific dependencies | Internal | DASHBOARD_SCHEDULE: completion events., FAMILYPLUS: subject boundary., BASIC_HEALTH_CALC: formula governance. | Follow dependency owner DD and record conflict as OPEN QUESTION. |

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
| HEALTH_SCORE_HABITS-RISK01 | Risk | Physical schema/API/RLS and final UI wireframes are not provided in BD. | Implementation may diverge if coding starts before detailed contracts. | Open |
| HEALTH_SCORE_HABITS-ASSUMPTION01 | Assumption | This DD uses BD v2.0 as source of truth and treats conflicting legacy Sale logic as blocked. | Legacy behavior must be reviewed before coding. | Active |
| HEALTH_SCORE_HABITS-Q-14 | Open question | Danh sách module tính toán sức khỏe và công thức nào đã được phê duyệt? | Health calculator and health score responsibility. | Open |
| HEALTH_SCORE_HABITS-Q-15 | Open question | Số thành viên FamilyPlus tối đa, quyền xem/sửa và consent theo tuổi/quan hệ? | Family data model and privacy. | Open |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| HEALTH_SCORE_HABITS-ADR01 | Keep this module DD in Draft until PO/Tech Lead closes related open questions and implementation contracts. | BD v2.0 contains Q-01..Q-18 and explicit DD-before-coding gates. | Accepted |

## 13. Traceability Matrix

| BD/Requirement | Feature | Function | View | API | Test |
|---|---|---|---|---|---|
| BD M08, section 9 | HEALTH_SCORE_HABITS-F01 | HEALTH_SCORE_HABITS-FN01 | HEALTH_SCORE_HABITS-V01 | HEALTH_SCORE_HABITS-API01 | HEALTH_SCORE_HABITS-TC01 |
| BD M08 luồng | HEALTH_SCORE_HABITS-F02 | HEALTH_SCORE_HABITS-FN02 | HEALTH_SCORE_HABITS-V02 | HEALTH_SCORE_HABITS-API02 | HEALTH_SCORE_HABITS-TC02 |

## 14. Approval Checklist

- [ ] Scope and out-of-scope reviewed by BA/PO.
- [ ] Business rules reviewed by Tech Lead.
- [ ] UI states reviewed by UI/UX and QA.
- [ ] API/schema/RLS contracts added before coding.
- [ ] Open questions resolved or accepted as explicit implementation assumptions.
