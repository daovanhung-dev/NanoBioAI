# Overall — FAMILYPLUS / FamilyPlus

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | FAMILYPLUS |
| BD Module | M11 |
| Version | v1.0 |
| Status | Approved - DD docs complete |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 10/M11, 13, 14.2, 16.1 AC-06, Appendix A UC-11 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
| Release Scope | Project DD baseline for M01-M19 |

## 2. Business Goal
Module này đảm bảo dữ liệu gia đình tách theo subject_member_id, không cho Sale/Admin xem dữ liệu sức khỏe ngoài scope.

## 3. Module Scope

### In Scope
- Tạo nhóm gia đình.
- Thêm/xóa/thay đổi vai trò thành viên.
- Onboarding/lịch trình riêng theo subject.
- Consent/phân quyền dữ liệu.

### Out of Scope
- Chốt số thành viên tối đa khi PO chưa trả lời.
- Quyền consent theo tuổi/quan hệ cuối cùng.
- Sale/referral access to family health data.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| FamilyPlus owner, Family member | Use module features according to BD sections 3, 5, and BD sections 10/M11, 13, 14.2, 16.1 AC-06, Appendix A UC-11. | Must not bypass entitlement, ownership, family consent, Sale/Admin scope, or audit rules. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must follow accepted product decisions. |
| Admin/Super Admin | Operate only where BD grants admin responsibility. | Backend/API must reject missing permission; UI hiding is not sufficient. |

## 5. Primary Entities/Data

| Entity ID | Entity | Purpose | Important Attributes | Relationships |
|---|---|---|---|---|
| FAMILYPLUS-E-family_group | Family Group | Nhóm FamilyPlus | owner, status, member quota | Has family members |
| FAMILYPLUS-E-family_member | Family Member | Một người trong Family | subject_member_id, role, consent, status | Owns health/schedule data |

## 6. States and State Transitions

| Entity / Group | States | Notes |
|---|---|---|
| Family Group / Family Member | pending_invite, active, removed, expired_access, consent_revoked | Source: BD Appendix B and module sections. |

## 7. Business Rules

| ID | Rule | Applied At | Criticality |
|---|---|---|---|
| FAMILYPLUS-BR01 | Mỗi dữ liệu sức khỏe/lịch trình phải có subject_member_id rõ ràng. | Family member management and data access | Mandatory |
| FAMILYPLUS-BR02 | Chủ gói không mặc định có toàn quyền xem mọi dữ liệu nếu chính sách đồng ý không cho phép. | Family member management and data access | Mandatory |

## 8. Overall Operational Flow

1. Actor enters the module through the planned view or event listed in Views.md.
2. System validates authentication, entitlement, role, ownership, family scope, Sale status, or Admin permission as applicable.
3. System loads only the data needed for FamilyPlus.
4. Feature function applies module business rules and cross-cutting rules from BD sections 14 and 15.
5. Successful writes use transaction/idempotency and audit where required.
6. UI/API returns a safe business result and never exposes raw stack trace, DB/API wording, secret, payment evidence, or unnecessary health data.

## 9. Integrations and Dependencies

| Dependency | Type | Purpose | Failure Behavior |
|---|---|---|---|
| Auth/Profile | Internal/Supabase planned | Identify actor and ownership. | Block action or request login. |
| Membership/Entitlement | Internal/trusted backend planned | Apply Free/Plus/FamilyPlus access and quotas. | Keep previous state; do not grant paid access. |
| Audit/Security | Cross-cutting | Trace sensitive changes. | Sensitive writes must fail or be queued safely if audit cannot be recorded. |
| Module-specific dependencies | Internal | MEMBERSHIP_QUOTA: FamilyPlus entitlement., ONBOARDING_PROFILE and PERSONAL_SCHEDULE_AI: subject-specific flows., AUDIT_SECURITY: privacy/audit. | Follow dependency owner DD and record conflict as an implementation issue or accepted exception. |

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
| FAMILYPLUS-RISK01 | Implementation evidence backlog | Runtime/sandbox evidence, final wireframes, and production acceptance remain outside DD completeness. | Implementation must produce evidence before production release. | Tracked |
| FAMILYPLUS-ASSUMPTION01 | Assumption | BD v2.0 plus user decisions from 2026-06-30 are the source of truth; legacy conflicting Sale/Admin logic is not implementation source. | Implementation must migrate or reject old behavior such as Sale tree, tier-2 commission, or 5 percent rules. | Active |
| FAMILYPLUS-Q-15 | Answered decision | How does FamilyPlus member visibility work? | FamilyPlus has up to 5 members. Every joined member in the package can view all information of every other member in the package. | Accepted - User decision 2026-06-30 |
| FAMILYPLUS-Q-11 | Answered decision | How is FamilyPlus commission calculated? | FamilyPlus commission is calculated only on the package owner portion. | Accepted - User decision 2026-06-30 |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| FAMILYPLUS-ADR01 | Approve this module DD as docs-complete and track runtime/sandbox evidence separately. | The user requested DD docs 100 percent without changing runtime code or claiming sandbox evidence. | Accepted |
| FAMILYPLUS-ADR02 | Keep accepted product decisions as the module business contract. | Q-01..Q-18 are closed by user decision and recorded in the DD registry. | Accepted |

## 13. Traceability Matrix

| BD/Requirement | Feature | Function | View | API | Test |
|---|---|---|---|---|---|
| BD M11 chức năng, UC-11 | FAMILYPLUS-F01 | FAMILYPLUS-FN01 | FAMILYPLUS-V01 | FAMILYPLUS-API01 | FAMILYPLUS-TC01 |
| BD M11 luồng thêm thành viên | FAMILYPLUS-F02 | FAMILYPLUS-FN02 | FAMILYPLUS-V02 | FAMILYPLUS-API02 | FAMILYPLUS-TC02 |

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
| Q-11 | FamilyPlus commission is calculated only on the package owner portion. | Payment line items separate owner portion from dependent member portions; commission uses owner portion only. | User decision 2026-06-30 |

### Implementation Evidence Backlog

| Evidence Area | Required evidence before production acceptance | DD blocker? |
|---|---|---|
| Runtime/test/sandbox | Invite/remove lifecycle, repository/UI slice, and RLS isolation evidence. | No - tracked outside DD completeness |
| Coding progress | Update only when code, tests, SQL/RPC, or sandbox evidence changes. | No |
| Production acceptance | Requires implementation workflow evidence and worklog command output. | No |
