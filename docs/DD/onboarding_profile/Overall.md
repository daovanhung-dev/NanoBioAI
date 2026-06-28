# Overall — ONBOARDING_PROFILE / Onboarding & Hồ sơ sức khỏe

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | ONBOARDING_PROFILE |
| BD Module | M01 |
| Version | v1.0 |
| Status | Draft |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M01, 13, 16.1 AC-01, Appendix A UC-01 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
| Release Scope | Project DD baseline for M01-M19 |

## 2. Business Goal
Module này đảm bảo Guest/Member có hồ sơ onboarding đủ dữ liệu, đúng subject và có thể chuyển sang sinh lịch trình đầu tiên mà không ghi đè dữ liệu FamilyPlus.

## 3. Module Scope

### In Scope
- Bước onboarding cho Guest/Member.
- Lưu hồ sơ đầu vào theo owner/subject.
- Đánh dấu trạng thái onboarding hoàn tất.
- Chuyển sang module AI lịch trình cá nhân.

### Out of Scope
- Chẩn đoán y tế hoặc khuyến nghị điều trị.
- Wireframe/copy chi tiết.
- Công thức tính toán sức khỏe chuyên môn.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| Guest, Member | Use module features according to BD sections 3, 5, and BD sections 6/M01, 13, 16.1 AC-01, Appendix A UC-01. | Must not bypass entitlement, ownership, family consent, Sale/Admin scope, or audit rules. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must not invent product decisions. |
| Admin/Super Admin | Operate only where BD grants admin responsibility. | Backend/API must reject missing permission; UI hiding is not sufficient. |

## 5. Primary Entities/Data

| Entity ID | Entity | Purpose | Important Attributes | Relationships |
|---|---|---|---|---|
| ONBOARDING_PROFILE-E-guest_profile | Guest Profile | Hồ sơ local trước đăng nhập | local key, first schedule flag, onboarding status | May sync to App User |
| ONBOARDING_PROFILE-E-onboarding_profile | Onboarding Profile | Dữ liệu cá nhân hóa | owner, subject, profile version, completion status | Used by Personal Plan and Health Calculator |

## 6. States and State Transitions

| Entity / Group | States | Notes |
|---|---|---|
| Onboarding | not_started, in_progress, completed | Source: BD Appendix B and module sections. |

## 7. Business Rules

| ID | Rule | Applied At | Criticality |
|---|---|---|---|
| ONBOARDING_PROFILE-BR01 | Onboarding phải có dữ liệu bắt buộc trước khi chuyển sang AI tạo lịch trình. | Onboarding steps, profile save, first schedule handoff | Mandatory |
| ONBOARDING_PROFILE-BR02 | FamilyPlus onboarding phải ghi đúng subject_member_id và không ghi đè hồ sơ người khác. | Onboarding steps, profile save, first schedule handoff | Mandatory |

## 8. Overall Operational Flow

1. Actor enters the module through the planned view or event listed in Views.md.
2. System validates authentication, entitlement, role, ownership, family scope, Sale status, or Admin permission as applicable.
3. System loads only the data needed for Onboarding & Hồ sơ sức khỏe.
4. Feature function applies module business rules and cross-cutting rules from BD sections 14 and 15.
5. Successful writes use transaction/idempotency and audit where required.
6. UI/API returns a safe business result and never exposes raw stack trace, DB/API wording, secret, payment evidence, or unnecessary health data.

## 9. Integrations and Dependencies

| Dependency | Type | Purpose | Failure Behavior |
|---|---|---|---|
| Auth/Profile | Internal/Supabase planned | Identify actor and ownership. | Block action or request login. |
| Membership/Entitlement | Internal/trusted backend planned | Apply Free/Plus/FamilyPlus access and quotas. | Keep previous state; do not grant paid access. |
| Audit/Security | Cross-cutting | Trace sensitive changes. | Sensitive writes must fail or be queued safely if audit cannot be recorded. |
| Module-specific dependencies | Internal | PERSONAL_SCHEDULE_AI: dùng hồ sơ để sinh lịch trình đầu tiên., AUTH_PROFILE_SYNC: đồng bộ Guest -> Member., FAMILYPLUS: subject_member_id khi onboarding cho thành viên gia đình. | Follow dependency owner DD and record conflict as OPEN QUESTION. |

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
| ONBOARDING_PROFILE-RISK01 | Risk | Physical schema/API/RLS and final UI wireframes are not provided in BD. | Implementation may diverge if coding starts before detailed contracts. | Open |
| ONBOARDING_PROFILE-ASSUMPTION01 | Assumption | This DD uses BD v2.0 as source of truth and treats conflicting legacy Sale logic as blocked. | Legacy behavior must be reviewed before coding. | Active |
| ONBOARDING_PROFILE-Q-14 | Open question | Danh sách module tính toán sức khỏe và công thức nào đã được phê duyệt? | Health calculator and health score responsibility. | Open |
| ONBOARDING_PROFILE-Q-15 | Open question | Số thành viên FamilyPlus tối đa, quyền xem/sửa và consent theo tuổi/quan hệ? | Family data model and privacy. | Open |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| ONBOARDING_PROFILE-ADR01 | Keep this module DD in Draft until PO/Tech Lead closes related open questions and implementation contracts. | BD v2.0 contains Q-01..Q-18 and explicit DD-before-coding gates. | Accepted |

## 13. Traceability Matrix

| BD/Requirement | Feature | Function | View | API | Test |
|---|---|---|---|---|---|
| BD M01, AC-01, UC-01 | ONBOARDING_PROFILE-F01 | ONBOARDING_PROFILE-FN01 | ONBOARDING_PROFILE-V01 | ONBOARDING_PROFILE-API01 | ONBOARDING_PROFILE-TC01 |
| BD M01 luồng chính, AC-01 | ONBOARDING_PROFILE-F02 | ONBOARDING_PROFILE-FN02 | ONBOARDING_PROFILE-V02 | ONBOARDING_PROFILE-API02 | ONBOARDING_PROFILE-TC02 |

## 14. Approval Checklist

- [ ] Scope and out-of-scope reviewed by BA/PO.
- [ ] Business rules reviewed by Tech Lead.
- [ ] UI states reviewed by UI/UX and QA.
- [ ] API/schema/RLS contracts added before coding.
- [ ] Open questions resolved or accepted as explicit implementation assumptions.
