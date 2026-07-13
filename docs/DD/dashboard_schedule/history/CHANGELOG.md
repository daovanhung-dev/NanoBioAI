# CHANGELOG — DASHBOARD_SCHEDULE / Dashboard & Thực hiện lịch trình

## [v1.3] - 2026-07-13
### Changed
- Added Approved addendum `BD-BIOAI-WELLNESS-REWARDS-001` and implementation delta for the 30-minute window, camera proof, private local/cloud evidence, undo and server-authoritative `+10 Điểm chăm sóc` flow.
- Kept DD status Approved and separated source-ready/targeted-test evidence from sandbox and real-device acceptance.

### Validation
- Docs delta only in this changelog; runtime and Supabase evidence is referenced, not reclassified as deployed production evidence.

## [v1.2] - 2026-06-30
### Changed
- Marked DASHBOARD_SCHEDULE DD docs as `Approved - DD docs complete`.
- Separated runtime/test/sandbox evidence into the Implementation Evidence Backlog.
- Converted unchecked DD requirement lists into documented acceptance/evidence requirement tables without claiming tests were executed.

### Validation
- Docs-only change; runtime code, SQL, Supabase config, and tests were not changed.

## [v1.1] - 2026-06-30
### Changed
- Recorded accepted product decisions Q-15 in README, Overall, Import_File, and checklist traceability.
- Reclassified prior question rows as answered decisions; remaining gaps are implementation evidence, sandbox/RLS/API verification, or planned assets.

### Decisions
- Q-15: FamilyPlus has up to 5 members. Every joined member in the package can view all information of every other member in the package.

### Validation
- Docs-only change; runtime code was not changed.

## [v1.0] - 2026-06-28
### Added
- Initial DD created from docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), scope BD sections 6/M03, 13, Appendix A UC-09.
- Created README, Overall, List_Features, Function_List, Views, Import_File, diagrams README, assets README, and changelog.

### Impact
- Affected module: M03 / DASHBOARD_SCHEDULE.
- Migration required: No runtime migration in this docs-only pass.
- Regression test required: Yes when implementation starts; see module test checklist and BD section 17.2.

### Historical Decisions - answered 2026-06-30
- Q-15: Số thành viên FamilyPlus tối đa, quyền xem/sửa và consent theo tuổi/quan hệ?
