# CHANGELOG — MEMBERSHIP_QUOTA / Gói thành viên & quota

## [v1.1] - 2026-06-30
### Changed
- Recorded accepted product decisions Q-04, Q-16 in README, Overall, Import_File, and checklist traceability.
- Reclassified prior question rows as answered decisions; remaining gaps are implementation evidence, sandbox/RLS/API verification, or planned assets.

### Decisions
- Q-04: Plus and FamilyPlus support monthly and yearly plans. Early renewal extends from current expiry; late renewal starts from Admin approval time; pending payment never grants rights.
- Q-16: Use Vietnam timezone, Asia/Ho_Chi_Minh.

### Validation
- Docs-only change; runtime code was not changed.

## [v1.0] - 2026-06-28
### Added
- Initial DD created from docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), scope BD sections 6/M06, 13, 16.1 AC-04..AC-08, Appendix A UC-06.
- Created README, Overall, List_Features, Function_List, Views, Import_File, diagrams README, assets README, and changelog.

### Impact
- Affected module: M06 / MEMBERSHIP_QUOTA.
- Migration required: No runtime migration in this docs-only pass.
- Regression test required: Yes when implementation starts; see module test checklist and BD section 17.2.

### Historical Decisions - answered 2026-06-30
- Q-04: Các gói thanh toán theo tháng, năm hay một lần; gia hạn sớm/trễ xử lý ra sao?
- Q-16: Múi giờ chuẩn cho reset quota, thời hạn gói, báo cáo và duyệt payment là gì?