# Overall — ADVANCED_TRACKING_GOALS / Theo dõi nâng cao & mục tiêu

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | ADVANCED_TRACKING_GOALS |
| BD Module | M10 |
| Version | v1.0 |
| Status | Approved - DD docs complete |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M10, 16.1 AC-06, Appendix A UC-10 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
| Release Scope | Project DD baseline for M01-M19 |

## 2. Business Goal
Module này giữ advanced tracking là planned paid capability, chỉ mở khi entitlement Plus/FamilyPlus hợp lệ và DD chi tiết đủ Ready.

## 3. Module Scope

### In Scope
- Chọn mục tiêu nâng cao.
- Theo dõi lộ trình mục tiêu.
- Liên kết lịch trình/health score theo quyền.
- State Draft until detailed BD/UI is approved.

### Out of Scope
- Free/Guest access.
- Clinical treatment roadmap.
- Final goal catalog without PO approval.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| Plus, FamilyPlus | Use module features according to BD sections 3, 5, and BD sections 6/M10, 16.1 AC-06, Appendix A UC-10. | Must not bypass entitlement, ownership, family consent, Sale/Admin scope, or audit rules. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must follow accepted product decisions. |
| Admin/Super Admin | Operate only where BD grants admin responsibility. | Backend/API must reject missing permission; UI hiding is not sufficient. |

## 5. Primary Entities/Data

| Entity ID | Entity | Purpose | Important Attributes | Relationships |
|---|---|---|---|---|
| ADVANCED_TRACKING_GOALS-E-goal | Advanced Goal | Mục tiêu nâng cao | subject, type, status, start/end | Links plan and progress |
| ADVANCED_TRACKING_GOALS-E-roadmap_step | Roadmap Step | Mốc lộ trình | goal, order, status, target | Tracked over time |

## 6. States and State Transitions

| Entity / Group | States | Notes |
|---|---|---|
| Goal Roadmap | draft, active, paused, completed, archived | Source: BD Appendix B and module sections. |

## 7. Business Rules

| ID | Rule | Applied At | Criticality |
|---|---|---|---|
| ADVANCED_TRACKING_GOALS-BR01 | Guest/Free không được dùng mục tiêu nâng cao. | Paid feature gate and goal tracking | Mandatory |
| ADVANCED_TRACKING_GOALS-BR02 | Goal catalog and behavior remain Draft until PO approves detailed product design. | Paid feature gate and goal tracking | Mandatory |

## 8. Overall Operational Flow

1. Actor enters the module through the planned view or event listed in Views.md.
2. System validates authentication, entitlement, role, ownership, family scope, Sale status, or Admin permission as applicable.
3. System loads only the data needed for Theo dõi nâng cao & mục tiêu.
4. Feature function applies module business rules and cross-cutting rules from BD sections 14 and 15.
5. Successful writes use transaction/idempotency and audit where required.
6. UI/API returns a safe business result and never exposes raw stack trace, DB/API wording, secret, payment evidence, or unnecessary health data.

## 9. Integrations and Dependencies

| Dependency | Type | Purpose | Failure Behavior |
|---|---|---|---|
| Auth/Profile | Internal/Supabase planned | Identify actor and ownership. | Block action or request login. |
| Membership/Entitlement | Internal/trusted backend planned | Apply Free/Plus/FamilyPlus access and quotas. | Keep previous state; do not grant paid access. |
| Audit/Security | Cross-cutting | Trace sensitive changes. | Sensitive writes must fail or be queued safely if audit cannot be recorded. |
| Module-specific dependencies | Internal | MEMBERSHIP_QUOTA: Plus/FamilyPlus entitlement., HEALTH_SCORE_HABITS: progress data., PERSONAL_SCHEDULE_AI: schedule adjustments. | Follow dependency owner DD and record conflict as an implementation issue or accepted exception. |

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
| ADVANCED_TRACKING_GOALS-RISK01 | Implementation evidence backlog | Runtime/sandbox evidence, final wireframes, and production acceptance remain outside DD completeness. | Implementation must produce evidence before production release. | Tracked |
| ADVANCED_TRACKING_GOALS-ASSUMPTION01 | Assumption | BD v2.0 plus user decisions from 2026-06-30 are the source of truth; legacy conflicting Sale/Admin logic is not implementation source. | Implementation must migrate or reject old behavior such as Sale tree, tier-2 commission, or 5 percent rules. | Active |
| ADVANCED_TRACKING_GOALS-Q-14 | Answered decision | Which health formulas are used? | Use reference wellness formulas only, not diagnosis: BMI by CDC, BMR/RMR by Mifflin-St Jeor, TDEE by activity factor, hydration by National Academies DRI, sleep/activity by CDC. M08 health score is versioned and separate from daily local score. | Accepted - User decision 2026-06-30 |
| ADVANCED_TRACKING_GOALS-Q-15 | Answered decision | How does FamilyPlus member visibility work? | FamilyPlus has up to 5 members. Every joined member in the package can view all information of every other member in the package. | Accepted - User decision 2026-06-30 |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| ADVANCED_TRACKING_GOALS-ADR01 | Approve this module DD as docs-complete and track runtime/sandbox evidence separately. | The user requested DD docs 100 percent without changing runtime code or claiming sandbox evidence. | Accepted |
| ADVANCED_TRACKING_GOALS-ADR02 | Keep accepted product decisions as the module business contract. | Q-01..Q-18 are closed by user decision and recorded in the DD registry. | Accepted |

## 13. Traceability Matrix

| BD/Requirement | Feature | Function | View | API | Test |
|---|---|---|---|---|---|
| BD M10 chức năng, UC-10 | ADVANCED_TRACKING_GOALS-F01 | ADVANCED_TRACKING_GOALS-FN01 | ADVANCED_TRACKING_GOALS-V01 | ADVANCED_TRACKING_GOALS-API01 | ADVANCED_TRACKING_GOALS-TC01 |
| BD M10 luồng | ADVANCED_TRACKING_GOALS-F02 | ADVANCED_TRACKING_GOALS-FN02 | ADVANCED_TRACKING_GOALS-V02 | ADVANCED_TRACKING_GOALS-API02 | ADVANCED_TRACKING_GOALS-TC02 |

## 14. Approval Checklist

- [x] Scope and out-of-scope reviewed for DD docs completeness.
- [x] Business rules reviewed for DD docs completeness.
- [x] UI states reviewed for DD docs completeness.
- [x] API/schema/RLS contracts documented for implementation planning.
- [x] Product decisions answered or accepted as explicit implementation policy.

## 15. Accepted Product Decision Contract

| ID | Accepted Policy | Implementation Contract | Source |
|---|---|---|---|
| Q-14 | Use reference wellness formulas only, not diagnosis: BMI by CDC, BMR/RMR by Mifflin-St Jeor, TDEE by activity factor, hydration by National Academies DRI, sleep/activity by CDC. M08 health score is versioned and separate from daily local score. | Health formula versions, inputs, outputs, source links, disclaimer copy, and skip/missing-data policy are stored as versioned config before production use. | User decision 2026-06-30 |
| Q-15 | FamilyPlus has up to 5 members. Every joined member in the package can view all information of every other member in the package. | Subject-aware reads allow package members to view package data; edits record actor, subject, reason when needed, and audit for sensitive changes. | User decision 2026-06-30 |
| Q-14 sources | Health formulas are wellness references only and are not diagnosis or medical advice. | CDC BMI: https://www.cdc.gov/bmi/about/index.html<br>CDC BMI categories: https://www.cdc.gov/bmi/adult-calculator/bmi-categories.html<br>Mifflin-St Jeor PubMed: https://pubmed.ncbi.nlm.nih.gov/2305711/<br>National Academies water DRI: https://www.nationalacademies.org/read/10925/chapter/6<br>CDC physical activity: https://www.cdc.gov/physical-activity-basics/guidelines/adults.html<br>CDC sleep: https://www.cdc.gov/sleep/about/index.html | User decision 2026-06-30 plus cited public references |

### Implementation Evidence Backlog

| Evidence Area | Required evidence before production acceptance | DD blocker? |
|---|---|---|
| Runtime/test/sandbox | First paid tracking metric, storage, UI slice, repository, and tests. | No - tracked outside DD completeness |
| Coding progress | Update only when code, tests, SQL/RPC, or sandbox evidence changes. | No |
| Production acceptance | Requires implementation workflow evidence and worklog command output. | No |
