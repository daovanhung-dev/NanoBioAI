# Overall — HEALTH_SCORE_HABITS / Điểm sức khỏe & thói quen

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | HEALTH_SCORE_HABITS |
| BD Module | M08 |
| Version | v1.0 |
| Status | In Review - product decisions answered |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M08, 9, 13, Appendix A UC-09 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
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
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must follow accepted product decisions. |
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
| Module-specific dependencies | Internal | DASHBOARD_SCHEDULE: completion events., FAMILYPLUS: subject boundary., BASIC_HEALTH_CALC: formula governance. | Follow dependency owner DD and record conflict as an implementation issue or accepted exception. |

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
| HEALTH_SCORE_HABITS-RISK01 | Risk | API/schema/RLS sandbox evidence and final UI assets may still lag the DD contract. | Coding must keep acceptance evidence and sandbox proof before production release. | Open |
| HEALTH_SCORE_HABITS-ASSUMPTION01 | Assumption | BD v2.0 plus user decisions from 2026-06-30 are the source of truth; legacy conflicting Sale/Admin logic is not implementation source. | Implementation must migrate or reject old behavior such as Sale tree, tier-2 commission, or 5 percent rules. | Active |
| HEALTH_SCORE_HABITS-Q-14 | Answered decision | Which health formulas are used? | Use reference wellness formulas only, not diagnosis: BMI by CDC, BMR/RMR by Mifflin-St Jeor, TDEE by activity factor, hydration by National Academies DRI, sleep/activity by CDC. M08 health score is versioned and separate from daily local score. | Accepted - User decision 2026-06-30 |
| HEALTH_SCORE_HABITS-Q-15 | Answered decision | How does FamilyPlus member visibility work? | FamilyPlus has up to 5 members. Every joined member in the package can view all information of every other member in the package. | Accepted - User decision 2026-06-30 |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| HEALTH_SCORE_HABITS-ADR01 | Keep implementation gated by documented API/schema/RLS/audit evidence where the checklist still marks sandbox pending. | Product decisions are answered, but several modules still require Supabase or runtime verification before production acceptance. | Accepted |
| HEALTH_SCORE_HABITS-ADR02 | Apply accepted product decisions Q-14, Q-15 as the module business contract. | User decisions from 2026-06-30 close the BD Q-01..Q-18 blocker set for this module. | Accepted |

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
- [x] Product decisions Q-14, Q-15 answered or accepted as explicit implementation policy on 2026-06-30.

## 15. Accepted Product Decision Contract

| ID | Accepted Policy | Implementation Contract | Source |
|---|---|---|---|
| Q-14 | Use reference wellness formulas only, not diagnosis: BMI by CDC, BMR/RMR by Mifflin-St Jeor, TDEE by activity factor, hydration by National Academies DRI, sleep/activity by CDC. M08 health score is versioned and separate from daily local score. | Health formula versions, inputs, outputs, source links, disclaimer copy, and skip/missing-data policy are stored as versioned config before production use. | User decision 2026-06-30 |
| Q-15 | FamilyPlus has up to 5 members. Every joined member in the package can view all information of every other member in the package. | Subject-aware reads allow package members to view package data; edits record actor, subject, reason when needed, and audit for sensitive changes. | User decision 2026-06-30 |
| Q-14 sources | Health formulas are wellness references only and are not diagnosis or medical advice. | CDC BMI: https://www.cdc.gov/bmi/about/index.html<br>CDC BMI categories: https://www.cdc.gov/bmi/adult-calculator/bmi-categories.html<br>Mifflin-St Jeor PubMed: https://pubmed.ncbi.nlm.nih.gov/2305711/<br>National Academies water DRI: https://www.nationalacademies.org/read/10925/chapter/6<br>CDC physical activity: https://www.cdc.gov/physical-activity-basics/guidelines/adults.html<br>CDC sleep: https://www.cdc.gov/sleep/about/index.html | User decision 2026-06-30 plus cited public references |

### Remaining Evidence Gate
- DD readiness for this module is 80 percent in `docs/checklist/checklist_complete_DD.md`.
- Coding progress changes only when runtime code, tests, or sandbox evidence are added.
