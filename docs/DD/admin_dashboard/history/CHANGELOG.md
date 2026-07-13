# CHANGELOG — ADMIN_DASHBOARD / Admin View / Dashboard

## [v1.3] - 2026-07-13
### Changed
- Added the `Điểm chăm sóc` Admin section/route and the independent `wellness_rewards.read/write` permission boundary.
- Documented privacy-limited catalog, inventory aggregate and redemption drill-down behavior.

### Validation
- Client/Admin targeted evidence is referenced; Admin role/RLS sandbox smoke is still required.

## [v1.2] - 2026-06-30
### Changed
- Marked ADMIN_DASHBOARD DD docs as `Approved - DD docs complete`.
- Separated runtime/test/sandbox evidence into the Implementation Evidence Backlog.
- Converted unchecked DD requirement lists into documented acceptance/evidence requirement tables without claiming tests were executed.

### Validation
- Docs-only change; runtime code, SQL, Supabase config, and tests were not changed.

## [v1.1] - 2026-06-30
### Changed
- Recorded accepted product decisions Q-12, Q-18 in README, Overall, Import_File, and checklist traceability.
- Reclassified prior question rows as answered decisions; remaining gaps are implementation evidence, sandbox/RLS/API verification, or planned assets.

### Decisions
- Q-12: All Admin groups exist: Super Admin, Finance Admin, Support Admin, and Content Admin.
- Q-18: Sale may see customer phone number and basic profile information for customer care, but cannot see health data, AI data, secrets, or raw payment payloads.

### Validation
- Docs-only change; runtime code was not changed.

## [v1.0] - 2026-06-28
### Added
- Initial DD created from docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), scope BD sections 11.1/11.2, 12.2, 16.3 AC-19, Appendix A UC-20.
- Created README, Overall, List_Features, Function_List, Views, Import_File, diagrams README, assets README, and changelog.

### Impact
- Affected module: M15 / ADMIN_DASHBOARD.
- Migration required: No runtime migration in this docs-only pass.
- Regression test required: Yes when implementation starts; see module test checklist and BD section 17.2.

### Historical Decisions - answered 2026-06-30
- Q-12: Admin có bao nhiêu nhóm quyền?
- Q-18: Sale xem được định danh nào của khách hay chỉ số liệu tổng hợp?
