# Overall — BASIC_HEALTH_CALC / Tính toán sức khỏe cơ bản

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | BASIC_HEALTH_CALC |
| BD Module | M04 |
| Version | v1.0 |
| Status | In Review - product decisions answered |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M04, 18.2 Q-14, Appendix A UC-03 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
| Release Scope | Project DD baseline for M01-M19 |

## 2. Business Goal
Module này tách công cụ tính toán cơ bản khỏi chẩn đoán y tế và giữ công thức ở trạng thái version hóa/chờ phê duyệt.

## 3. Module Scope

### In Scope
- Nhập dữ liệu và tính toán chỉ số cơ bản được phê duyệt.
- Hiển thị kết quả với copy an toàn.
- Quản lý version công thức khi có phê duyệt.

### Out of Scope
- Chẩn đoán, điều trị, khuyến nghị y tế chuyên sâu.
- Admin tự sửa công thức production không có version.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| Guest, Member | Use module features according to BD sections 3, 5, and BD sections 6/M04, 18.2 Q-14, Appendix A UC-03. | Must not bypass entitlement, ownership, family consent, Sale/Admin scope, or audit rules. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must follow accepted product decisions. |
| Admin/Super Admin | Operate only where BD grants admin responsibility. | Backend/API must reject missing permission; UI hiding is not sufficient. |

## 5. Primary Entities/Data

| Entity ID | Entity | Purpose | Important Attributes | Relationships |
|---|---|---|---|---|
| BASIC_HEALTH_CALC-E-calculator_input | Calculator Input | Dữ liệu tính toán | height, weight, age group, goal fields | May derive from onboarding |
| BASIC_HEALTH_CALC-E-formula_version | Formula Version | Version công thức | code, version, status, effective_from | Managed by admin if approved |

## 6. States and State Transitions

| Entity / Group | States | Notes |
|---|---|---|
| Calculator Formula | draft, approved, active, deprecated | Source: BD Appendix B and module sections. |

## 7. Business Rules

| ID | Rule | Applied At | Criticality |
|---|---|---|---|
| BASIC_HEALTH_CALC-BR01 | Chỉ dùng công thức đã được phê duyệt/version hóa. | Calculator run and formula versioning | Mandatory |
| BASIC_HEALTH_CALC-BR02 | Kết quả không được trình bày như chẩn đoán hoặc điều trị. | Calculator run and formula versioning | Mandatory |

## 8. Overall Operational Flow

1. Actor enters the module through the planned view or event listed in Views.md.
2. System validates authentication, entitlement, role, ownership, family scope, Sale status, or Admin permission as applicable.
3. System loads only the data needed for Tính toán sức khỏe cơ bản.
4. Feature function applies module business rules and cross-cutting rules from BD sections 14 and 15.
5. Successful writes use transaction/idempotency and audit where required.
6. UI/API returns a safe business result and never exposes raw stack trace, DB/API wording, secret, payment evidence, or unnecessary health data.

## 9. Integrations and Dependencies

| Dependency | Type | Purpose | Failure Behavior |
|---|---|---|---|
| Auth/Profile | Internal/Supabase planned | Identify actor and ownership. | Block action or request login. |
| Membership/Entitlement | Internal/trusted backend planned | Apply Free/Plus/FamilyPlus access and quotas. | Keep previous state; do not grant paid access. |
| Audit/Security | Cross-cutting | Trace sensitive changes. | Sensitive writes must fail or be queued safely if audit cannot be recorded. |
| Module-specific dependencies | Internal | ONBOARDING_PROFILE: input cơ bản., ADMIN_OPS: quản lý version công thức nếu PO cho phép., AUDIT_SECURITY: audit thay đổi công thức. | Follow dependency owner DD and record conflict as an implementation issue or accepted exception. |

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
| BASIC_HEALTH_CALC-RISK01 | Risk | API/schema/RLS sandbox evidence and final UI assets may still lag the DD contract. | Coding must keep acceptance evidence and sandbox proof before production release. | Open |
| BASIC_HEALTH_CALC-ASSUMPTION01 | Assumption | BD v2.0 plus user decisions from 2026-06-30 are the source of truth; legacy conflicting Sale/Admin logic is not implementation source. | Implementation must migrate or reject old behavior such as Sale tree, tier-2 commission, or 5 percent rules. | Active |
| BASIC_HEALTH_CALC-Q-14 | Answered decision | Which health formulas are used? | Use reference wellness formulas only, not diagnosis: BMI by CDC, BMR/RMR by Mifflin-St Jeor, TDEE by activity factor, hydration by National Academies DRI, sleep/activity by CDC. M08 health score is versioned and separate from daily local score. | Accepted - User decision 2026-06-30 |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| BASIC_HEALTH_CALC-ADR01 | Keep implementation gated by documented API/schema/RLS/audit evidence where the checklist still marks sandbox pending. | Product decisions are answered, but several modules still require Supabase or runtime verification before production acceptance. | Accepted |
| BASIC_HEALTH_CALC-ADR02 | Apply accepted product decisions Q-14 as the module business contract. | User decisions from 2026-06-30 close the BD Q-01..Q-18 blocker set for this module. | Accepted |

## 13. Traceability Matrix

| BD/Requirement | Feature | Function | View | API | Test |
|---|---|---|---|---|---|
| BD M04 luồng, UC-03 | BASIC_HEALTH_CALC-F01 | BASIC_HEALTH_CALC-FN01 | BASIC_HEALTH_CALC-V01 | BASIC_HEALTH_CALC-API01 | BASIC_HEALTH_CALC-TC01 |
| BD M04 lưu ý, Q-14 | BASIC_HEALTH_CALC-F02 | BASIC_HEALTH_CALC-FN02 | BASIC_HEALTH_CALC-V02 | BASIC_HEALTH_CALC-API02 | BASIC_HEALTH_CALC-TC02 |

## 14. Approval Checklist

- [ ] Scope and out-of-scope reviewed by BA/PO.
- [ ] Business rules reviewed by Tech Lead.
- [ ] UI states reviewed by UI/UX and QA.
- [ ] API/schema/RLS contracts added before coding.
- [x] Product decisions Q-14 answered or accepted as explicit implementation policy on 2026-06-30.

## 15. Accepted Product Decision Contract

| ID | Accepted Policy | Implementation Contract | Source |
|---|---|---|---|
| Q-14 | Use reference wellness formulas only, not diagnosis: BMI by CDC, BMR/RMR by Mifflin-St Jeor, TDEE by activity factor, hydration by National Academies DRI, sleep/activity by CDC. M08 health score is versioned and separate from daily local score. | Health formula versions, inputs, outputs, source links, disclaimer copy, and skip/missing-data policy are stored as versioned config before production use. | User decision 2026-06-30 |
| Q-14 sources | Health formulas are wellness references only and are not diagnosis or medical advice. | CDC BMI: https://www.cdc.gov/bmi/about/index.html<br>CDC BMI categories: https://www.cdc.gov/bmi/adult-calculator/bmi-categories.html<br>Mifflin-St Jeor PubMed: https://pubmed.ncbi.nlm.nih.gov/2305711/<br>National Academies water DRI: https://www.nationalacademies.org/read/10925/chapter/6<br>CDC physical activity: https://www.cdc.gov/physical-activity-basics/guidelines/adults.html<br>CDC sleep: https://www.cdc.gov/sleep/about/index.html | User decision 2026-06-30 plus cited public references |

### Remaining Evidence Gate
- DD readiness for this module is 80 percent in `docs/checklist/checklist_complete_DD.md`.
- Coding progress changes only when runtime code, tests, or sandbox evidence are added.
