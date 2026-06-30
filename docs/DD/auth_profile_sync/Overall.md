# Overall — AUTH_PROFILE_SYNC / Xác thực, hồ sơ và đồng bộ Guest

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | AUTH_PROFILE_SYNC |
| BD Module | M05 |
| Version | v1.0 |
| Status | Approved - DD docs complete |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M05, 13, Appendix A UC-05 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
| Release Scope | Project DD baseline for M01-M19 |

## 2. Business Goal
Module này đảm bảo auth qua Supabase hoặc phương án phê duyệt, đồng bộ không mất dữ liệu và dựng quyền từ nhiều trục trạng thái.

## 3. Module Scope

### In Scope
- Đăng ký/đăng nhập.
- Liên kết dữ liệu Guest -> Member.
- Đọc gói hiện hành, trạng thái Sale/Admin.
- Gắn mã giới thiệu theo policy.

### Out of Scope
- Payment approval.
- Commission calculation.
- Physical Supabase schema/RLS chi tiết.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| Guest, Member | Use module features according to BD sections 3, 5, and BD sections 6/M05, 13, Appendix A UC-05. | Must not bypass entitlement, ownership, family consent, Sale/Admin scope, or audit rules. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must follow accepted product decisions. |
| Admin/Super Admin | Operate only where BD grants admin responsibility. | Backend/API must reject missing permission; UI hiding is not sufficient. |

## 5. Primary Entities/Data

| Entity ID | Entity | Purpose | Important Attributes | Relationships |
|---|---|---|---|---|
| AUTH_PROFILE_SYNC-E-app_user | App User | Hồ sơ app liên kết auth | auth_user_id, account status, package status, sale status | Owns profile and entitlements |
| AUTH_PROFILE_SYNC-E-guest_sync | Guest Sync Snapshot | Dữ liệu chuyển local-cloud | local key, sync status, conflict policy | Links Guest Profile to App User |

## 6. States and State Transitions

| Entity / Group | States | Notes |
|---|---|---|
| App User | guest, free_active, plus_active, familyplus_active, suspended, cancelled | Source: BD Appendix B and module sections. |

## 7. Business Rules

| ID | Rule | Applied At | Criticality |
|---|---|---|---|
| AUTH_PROFILE_SYNC-BR01 | Không dùng một trường duy nhất để suy ra toàn bộ quyền. | Auth, profile sync, effective access build | Mandatory |
| AUTH_PROFILE_SYNC-BR02 | Gắn mã giới thiệu sau thanh toán đầu tiên bị chặn trừ Admin đặc biệt có audit. | Auth, profile sync, effective access build | Mandatory |

## 8. Overall Operational Flow

1. Actor enters the module through the planned view or event listed in Views.md.
2. System validates authentication, entitlement, role, ownership, family scope, Sale status, or Admin permission as applicable.
3. System loads only the data needed for Xác thực, hồ sơ và đồng bộ Guest.
4. Feature function applies module business rules and cross-cutting rules from BD sections 14 and 15.
5. Successful writes use transaction/idempotency and audit where required.
6. UI/API returns a safe business result and never exposes raw stack trace, DB/API wording, secret, payment evidence, or unnecessary health data.

## 9. Integrations and Dependencies

| Dependency | Type | Purpose | Failure Behavior |
|---|---|---|---|
| Auth/Profile | Internal/Supabase planned | Identify actor and ownership. | Block action or request login. |
| Membership/Entitlement | Internal/trusted backend planned | Apply Free/Plus/FamilyPlus access and quotas. | Keep previous state; do not grant paid access. |
| Audit/Security | Cross-cutting | Trace sensitive changes. | Sensitive writes must fail or be queued safely if audit cannot be recorded. |
| Module-specific dependencies | Internal | ONBOARDING_PROFILE: dữ liệu Guest., MEMBERSHIP_QUOTA: entitlement., REFERRAL_DIRECT: mã giới thiệu., AUDIT_SECURITY: auth/security logs. | Follow dependency owner DD and record conflict as an implementation issue or accepted exception. |

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
| AUTH_PROFILE_SYNC-RISK01 | Implementation evidence backlog | Runtime/sandbox evidence, final wireframes, and production acceptance remain outside DD completeness. | Implementation must produce evidence before production release. | Tracked |
| AUTH_PROFILE_SYNC-ASSUMPTION01 | Assumption | BD v2.0 plus user decisions from 2026-06-30 are the source of truth; legacy conflicting Sale/Admin logic is not implementation source. | Implementation must migrate or reject old behavior such as Sale tree, tier-2 commission, or 5 percent rules. | Active |
| AUTH_PROFILE_SYNC-Q-08 | Answered decision | When can referral code be entered? | Referral code is accepted only during registration. Any post-registration correction requires audited Super Admin override. | Accepted - User decision 2026-06-30 |
| AUTH_PROFILE_SYNC-Q-16 | Answered decision | Which timezone is authoritative? | Use Vietnam timezone, Asia/Ho_Chi_Minh. | Accepted - User decision 2026-06-30 |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| AUTH_PROFILE_SYNC-ADR01 | Approve this module DD as docs-complete and track runtime/sandbox evidence separately. | The user requested DD docs 100 percent without changing runtime code or claiming sandbox evidence. | Accepted |
| AUTH_PROFILE_SYNC-ADR02 | Keep accepted product decisions as the module business contract. | Q-01..Q-18 are closed by user decision and recorded in the DD registry. | Accepted |

## 13. Traceability Matrix

| BD/Requirement | Feature | Function | View | API | Test |
|---|---|---|---|---|---|
| BD M05 luồng đăng ký/đăng nhập | AUTH_PROFILE_SYNC-F01 | AUTH_PROFILE_SYNC-FN01 | AUTH_PROFILE_SYNC-V01 | AUTH_PROFILE_SYNC-API01 | AUTH_PROFILE_SYNC-TC01 |
| BD M05 Guest -> Member | AUTH_PROFILE_SYNC-F02 | AUTH_PROFILE_SYNC-FN02 | AUTH_PROFILE_SYNC-V02 | AUTH_PROFILE_SYNC-API02 | AUTH_PROFILE_SYNC-TC02 |

## 14. Approval Checklist

- [x] Scope and out-of-scope reviewed for DD docs completeness.
- [x] Business rules reviewed for DD docs completeness.
- [x] UI states reviewed for DD docs completeness.
- [x] API/schema/RLS contracts documented for implementation planning.
- [x] Product decisions answered or accepted as explicit implementation policy.

## 15. Accepted Product Decision Contract

| ID | Accepted Policy | Implementation Contract | Source |
|---|---|---|---|
| Q-08 | Referral code is accepted only during registration. Any post-registration correction requires audited Super Admin override. | Registration attach RPC is single-use and locked after account creation; override stores actor, reason, old/new referral, and audit id. | User decision 2026-06-30 |
| Q-16 | Use Vietnam timezone, Asia/Ho_Chi_Minh. | Quota reset, reporting windows, payment hold, refund/cancel window, schedule/day boundaries, and audit display use Asia/Ho_Chi_Minh. | User decision 2026-06-30 |

### Implementation Evidence Backlog

| Evidence Area | Required evidence before production acceptance | DD blocker? |
|---|---|---|
| Runtime/test/sandbox | Guest merge/profile sync edge cases and Supabase evidence. | No - tracked outside DD completeness |
| Coding progress | Update only when code, tests, SQL/RPC, or sandbox evidence changes. | No |
| Production acceptance | Requires implementation workflow evidence and worklog command output. | No |
