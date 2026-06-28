# Overall — BASIC_HEALTH_CALC / Tính toán sức khỏe cơ bản

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | BASIC_HEALTH_CALC |
| BD Module | M04 |
| Version | v1.0 |
| Status | Draft |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M04, 18.2 Q-14, Appendix A UC-03 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
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
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must not invent product decisions. |
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
| Module-specific dependencies | Internal | ONBOARDING_PROFILE: input cơ bản., ADMIN_OPS: quản lý version công thức nếu PO cho phép., AUDIT_SECURITY: audit thay đổi công thức. | Follow dependency owner DD and record conflict as OPEN QUESTION. |

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
| BASIC_HEALTH_CALC-RISK01 | Risk | Physical schema/API/RLS and final UI wireframes are not provided in BD. | Implementation may diverge if coding starts before detailed contracts. | Open |
| BASIC_HEALTH_CALC-ASSUMPTION01 | Assumption | This DD uses BD v2.0 as source of truth and treats conflicting legacy Sale logic as blocked. | Legacy behavior must be reviewed before coding. | Active |
| BASIC_HEALTH_CALC-Q-14 | Open question | Danh sách module tính toán sức khỏe và công thức nào đã được phê duyệt? | Health calculator and health score responsibility. | Open |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| BASIC_HEALTH_CALC-ADR01 | Keep this module DD in Draft until PO/Tech Lead closes related open questions and implementation contracts. | BD v2.0 contains Q-01..Q-18 and explicit DD-before-coding gates. | Accepted |

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
- [ ] Open questions resolved or accepted as explicit implementation assumptions.
