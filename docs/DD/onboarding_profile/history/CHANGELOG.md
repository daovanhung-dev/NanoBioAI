# CHANGELOG — ONBOARDING_PROFILE / Onboarding & Hồ sơ sức khỏe

## [v1.3] - 2026-07-15
### Changed
- Added the required versioned daily-routine profile, onboarding/legacy-user confirmation gate, source files and tests in the logbug 14-7-26 implementation delta.

### Validation
- Runtime tests are linked from the delta; sandbox sync/RLS evidence remains pending.

## [v1.2] - 2026-06-30
### Changed
- Marked ONBOARDING_PROFILE DD docs as `Approved - DD docs complete`.
- Separated runtime/test/sandbox evidence into the Implementation Evidence Backlog.
- Converted unchecked DD requirement lists into documented acceptance/evidence requirement tables without claiming tests were executed.

### Validation
- Docs-only change; runtime code, SQL, Supabase config, and tests were not changed.

## [v1.1] - 2026-06-30
### Changed
- Recorded accepted product decisions Q-14, Q-15 in README, Overall, Import_File, and checklist traceability.
- Reclassified prior question rows as answered decisions; remaining gaps are implementation evidence, sandbox/RLS/API verification, or planned assets.

### Decisions
- Q-14: Use reference wellness formulas only, not diagnosis: BMI by CDC, BMR/RMR by Mifflin-St Jeor, TDEE by activity factor, hydration by National Academies DRI, sleep/activity by CDC. M08 health score is versioned and separate from daily local score.
- Q-15: FamilyPlus has up to 5 members. Every joined member in the package can view all information of every other member in the package.

### Validation
- Docs-only change; runtime code was not changed.

## [v1.0] - 2026-06-28
### Added
- Initial DD created from docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), scope BD sections 6/M01, 13, 16.1 AC-01, Appendix A UC-01.
- Created README, Overall, List_Features, Function_List, Views, Import_File, diagrams README, assets README, and changelog.

### Impact
- Affected module: M01 / ONBOARDING_PROFILE.
- Migration required: No runtime migration in this docs-only pass.
- Regression test required: Yes when implementation starts; see module test checklist and BD section 17.2.

### Historical Decisions - answered 2026-06-30
- Q-14: Danh sách module tính toán sức khỏe và công thức nào đã được phê duyệt?
- Q-15: Số thành viên FamilyPlus tối đa, quyền xem/sửa và consent theo tuổi/quan hệ?
