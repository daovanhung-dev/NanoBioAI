# CHANGELOG — SCHEDULE_NOTIFICATIONS / Thông báo lịch trình

## [v1.4] - 2026-07-15
### Changed
- Notifications now consume resolver-owned schedule times and the deep-link contract uses the inclusive completion boundary.

### Validation
- No notification mechanism change; real-device smoke remains pending.

## [v1.3] - 2026-07-13
### Changed
- Replaced background completion semantics with `Mở để chụp ảnh` navigation to the exact schedule item and shared M03 camera-proof use case.
- Preserved payload/subject validation and idempotency; skip remains a separate non-reward action when configured.

### Validation
- Targeted notification/lifestyle test evidence is recorded in the implementation delta; real-device delivery/action smoke remains open.

## [v1.2] - 2026-06-30
### Changed
- Marked SCHEDULE_NOTIFICATIONS DD docs as `Approved - DD docs complete`.
- Separated runtime/test/sandbox evidence into the Implementation Evidence Backlog.
- Converted unchecked DD requirement lists into documented acceptance/evidence requirement tables without claiming tests were executed.

### Validation
- Docs-only change; runtime code, SQL, Supabase config, and tests were not changed.

## [v1.1] - 2026-06-30
### Changed
- Recorded accepted product decisions Q-16, Q-15 in README, Overall, Import_File, and checklist traceability.
- Reclassified prior question rows as answered decisions; remaining gaps are implementation evidence, sandbox/RLS/API verification, or planned assets.

### Decisions
- Q-16: Use Vietnam timezone, Asia/Ho_Chi_Minh.
- Q-15: FamilyPlus has up to 5 members. Every joined member in the package can view all information of every other member in the package.

### Validation
- Docs-only change; runtime code was not changed.

## [v1.0] - 2026-06-28
### Added
- Initial DD created from docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), scope BD sections 6/M09, 13, Appendix A UC-04.
- Created README, Overall, List_Features, Function_List, Views, Import_File, diagrams README, assets README, and changelog.

### Impact
- Affected module: M09 / SCHEDULE_NOTIFICATIONS.
- Migration required: No runtime migration in this docs-only pass.
- Regression test required: Yes when implementation starts; see module test checklist and BD section 17.2.

### Historical Decisions - answered 2026-06-30
- Q-16: Múi giờ chuẩn cho reset quota, thời hạn gói, báo cáo và duyệt payment là gì?
- Q-15: Số thành viên FamilyPlus tối đa, quyền xem/sửa và consent theo tuổi/quan hệ?
