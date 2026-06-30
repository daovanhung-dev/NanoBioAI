# CHANGELOG — AUDIT_SECURITY / Audit, bảo mật & hỗ trợ

## [v1.1] - 2026-06-30
### Changed
- Recorded accepted product decisions Q-12, Q-13, Q-18 in README, Overall, Import_File, and checklist traceability.
- Reclassified prior question rows as answered decisions; remaining gaps are implementation evidence, sandbox/RLS/API verification, or planned assets.

### Decisions
- Q-12: All Admin groups exist: Super Admin, Finance Admin, Support Admin, and Content Admin.
- Q-13: Admin has broad operational power, but only Super Admin can edit sensitive data, perform full-data edits, or make manual Sale point adjustments. Each action requires reason, idempotency, and audit.
- Q-18: Sale may see customer phone number and basic profile information for customer care, but cannot see health data, AI data, secrets, or raw payment payloads.

### Validation
- Docs-only change; runtime code was not changed.

## [v1.0] - 2026-06-28
### Added
- Initial DD created from docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), scope BD sections 11.8, 14, 15, 16.3 AC-20/AC-21/AC-24, Appendix A UC-23.
- Created README, Overall, List_Features, Function_List, Views, Import_File, diagrams README, assets README, and changelog.

### Impact
- Affected module: M19 / AUDIT_SECURITY.
- Migration required: No runtime migration in this docs-only pass.
- Regression test required: Yes when implementation starts; see module test checklist and BD section 17.2.

### Historical Decisions - answered 2026-06-30
- Q-12: Admin có bao nhiêu nhóm quyền?
- Q-13: Admin có được điều chỉnh thủ công Điểm Sale và cần hai người duyệt không?
- Q-18: Sale xem được định danh nào của khách hay chỉ số liệu tổng hợp?