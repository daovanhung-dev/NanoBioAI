# Overall — DASHBOARD_SCHEDULE / Dashboard & Thực hiện lịch trình

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | DASHBOARD_SCHEDULE |
| BD Module | M03 |
| Version | v1.0 |
| Status | Approved - DD docs complete |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M03, 13, Appendix A UC-09 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
| Release Scope | Project DD baseline for M01-M19 |

## 2. Business Goal
Module này đảm bảo dashboard đọc dữ liệu thật, không mock production, và completion event trở thành nguồn cho điểm sức khỏe.

## 3. Module Scope

### In Scope
- Hiển thị việc cần làm theo ngày.
- Đánh dấu hoàn thành/bỏ qua.
- Tách subject FamilyPlus.
- Cung cấp lịch sử cho health score.

### Out of Scope
- Công thức điểm sức khỏe.
- Thông báo push chi tiết.
- Advanced goal roadmap.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| Guest, Member, Family | Use module features according to BD sections 3, 5, and BD sections 6/M03, 13, Appendix A UC-09. | Must not bypass entitlement, ownership, family consent, Sale/Admin scope, or audit rules. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must follow accepted product decisions. |
| Admin/Super Admin | Operate only where BD grants admin responsibility. | Backend/API must reject missing permission; UI hiding is not sufficient. |

## 5. Primary Entities/Data

| Entity ID | Entity | Purpose | Important Attributes | Relationships |
|---|---|---|---|---|
| DASHBOARD_SCHEDULE-E-plan_item | Plan Item | Task lịch trình | status, due time, type | Belongs to Personal Plan |
| DASHBOARD_SCHEDULE-E-completion_event | Plan Completion Event | Lịch sử thực hiện | item, status, actor, time | Feeds Health Score |

## 6. States and State Transitions

| Entity / Group | States | Notes |
|---|---|---|
| Plan Item | pending, completed, skipped, expired | Source: BD Appendix B and module sections. |

## 7. Business Rules

| ID | Rule | Applied At | Criticality |
|---|---|---|---|
| DASHBOARD_SCHEDULE-BR01 | Dashboard phải đọc dữ liệu thật từ provider/repository, không dùng production mock data. | Dashboard read and completion write | Mandatory |
| DASHBOARD_SCHEDULE-BR02 | Không cho thao tác lịch trình của người khác ngoài FamilyPlus consent/scope. | Dashboard read and completion write | Mandatory |

## 8. Overall Operational Flow

1. Actor enters the module through the planned view or event listed in Views.md.
2. System validates authentication, entitlement, role, ownership, family scope, Sale status, or Admin permission as applicable.
3. System loads only the data needed for Dashboard & Thực hiện lịch trình.
4. Feature function applies module business rules and cross-cutting rules from BD sections 14 and 15.
5. Successful writes use transaction/idempotency and audit where required.
6. UI/API returns a safe business result and never exposes raw stack trace, DB/API wording, secret, payment evidence, or unnecessary health data.

## 9. Integrations and Dependencies

| Dependency | Type | Purpose | Failure Behavior |
|---|---|---|---|
| Auth/Profile | Internal/Supabase planned | Identify actor and ownership. | Block action or request login. |
| Membership/Entitlement | Internal/trusted backend planned | Apply Free/Plus/FamilyPlus access and quotas. | Keep previous state; do not grant paid access. |
| Audit/Security | Cross-cutting | Trace sensitive changes. | Sensitive writes must fail or be queued safely if audit cannot be recorded. |
| Module-specific dependencies | Internal | PERSONAL_SCHEDULE_AI: nguồn Plan/Plan Item., HEALTH_SCORE_HABITS: dùng completion events., FAMILYPLUS: phân quyền subject. | Follow dependency owner DD and record conflict as an implementation issue or accepted exception. |

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
| DASHBOARD_SCHEDULE-RISK01 | Implementation evidence backlog | Runtime/sandbox evidence, final wireframes, and production acceptance remain outside DD completeness. | Implementation must produce evidence before production release. | Tracked |
| DASHBOARD_SCHEDULE-ASSUMPTION01 | Assumption | BD v2.0 plus user decisions from 2026-06-30 are the source of truth; legacy conflicting Sale/Admin logic is not implementation source. | Implementation must migrate or reject old behavior such as Sale tree, tier-2 commission, or 5 percent rules. | Active |
| DASHBOARD_SCHEDULE-Q-15 | Answered decision | How does FamilyPlus member visibility work? | FamilyPlus has up to 5 members. Every joined member in the package can view all information of every other member in the package. | Accepted - User decision 2026-06-30 |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| DASHBOARD_SCHEDULE-ADR01 | Approve this module DD as docs-complete and track runtime/sandbox evidence separately. | The user requested DD docs 100 percent without changing runtime code or claiming sandbox evidence. | Accepted |
| DASHBOARD_SCHEDULE-ADR02 | Keep accepted product decisions as the module business contract. | Q-01..Q-18 are closed by user decision and recorded in the DD registry. | Accepted |

## 13. Traceability Matrix

| BD/Requirement | Feature | Function | View | API | Test |
|---|---|---|---|---|---|
| BD M03 chức năng | DASHBOARD_SCHEDULE-F01 | DASHBOARD_SCHEDULE-FN01 | DASHBOARD_SCHEDULE-V01 | DASHBOARD_SCHEDULE-API01 | DASHBOARD_SCHEDULE-TC01 |
| BD M03 luồng đánh dấu | DASHBOARD_SCHEDULE-F02 | DASHBOARD_SCHEDULE-FN02 | DASHBOARD_SCHEDULE-V02 | DASHBOARD_SCHEDULE-API02 | DASHBOARD_SCHEDULE-TC02 |

## 14. Approval Checklist

- [x] Scope and out-of-scope reviewed for DD docs completeness.
- [x] Business rules reviewed for DD docs completeness.
- [x] UI states reviewed for DD docs completeness.
- [x] API/schema/RLS contracts documented for implementation planning.
- [x] Product decisions answered or accepted as explicit implementation policy.

## 15. Accepted Product Decision Contract

| ID | Accepted Policy | Implementation Contract | Source |
|---|---|---|---|
| Q-15 | FamilyPlus has up to 5 members. Every joined member in the package can view all information of every other member in the package. | Subject-aware reads allow package members to view package data; edits record actor, subject, reason when needed, and audit for sensitive changes. | User decision 2026-06-30 |

### Implementation Evidence Backlog

| Evidence Area | Required evidence before production acceptance | DD blocker? |
|---|---|---|
| Runtime/test/sandbox | Subject-aware dashboard mapping, cross-member traceability, and acceptance evidence. | No - tracked outside DD completeness |
| Coding progress | Update only when code, tests, SQL/RPC, or sandbox evidence changes. | No |
| Production acceptance | Requires implementation workflow evidence and worklog command output. | No |
