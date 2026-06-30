# CHANGELOG — REPORTING / Thống kê & báo cáo

## [v1.1] - 2026-06-30
### Changed
- Recorded accepted product decisions Q-12, Q-18, Q-16 in README, Overall, Import_File, and checklist traceability.
- Reclassified prior question rows as answered decisions; remaining gaps are implementation evidence, sandbox/RLS/API verification, or planned assets.

### Decisions
- Q-12: All Admin groups exist: Super Admin, Finance Admin, Support Admin, and Content Admin.
- Q-18: Sale may see customer phone number and basic profile information for customer care, but cannot see health data, AI data, secrets, or raw payment payloads.
- Q-16: Use Vietnam timezone, Asia/Ho_Chi_Minh.

### Validation
- Docs-only change; runtime code was not changed.

## [v1.0] - 2026-06-28
### Added
- Initial DD created from docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), scope BD section 12.2, 14.2, 16.3 AC-23, Appendix A UC-24.
- Created README, Overall, List_Features, Function_List, Views, Import_File, diagrams README, assets README, and changelog.

### Impact
- Affected module: M18 / REPORTING.
- Migration required: No runtime migration in this docs-only pass.
- Regression test required: Yes when implementation starts; see module test checklist and BD section 17.2.

### Historical Decisions - answered 2026-06-30
- Q-12: Admin có bao nhiêu nhóm quyền?
- Q-18: Sale xem được định danh nào của khách hay chỉ số liệu tổng hợp?
- Q-16: Múi giờ chuẩn cho reset quota, thời hạn gói, báo cáo và duyệt payment là gì?