# CHANGELOG — AUTH_PROFILE_SYNC / Xác thực, hồ sơ và đồng bộ Guest

## [v1.1] - 2026-06-30
### Changed
- Recorded accepted product decisions Q-08, Q-16 in README, Overall, Import_File, and checklist traceability.
- Reclassified prior question rows as answered decisions; remaining gaps are implementation evidence, sandbox/RLS/API verification, or planned assets.

### Decisions
- Q-08: Referral code is accepted only during registration. Any post-registration correction requires audited Super Admin override.
- Q-16: Use Vietnam timezone, Asia/Ho_Chi_Minh.

### Validation
- Docs-only change; runtime code was not changed.

## [v1.0] - 2026-06-28
### Added
- Initial DD created from docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), scope BD sections 6/M05, 13, Appendix A UC-05.
- Created README, Overall, List_Features, Function_List, Views, Import_File, diagrams README, assets README, and changelog.

### Impact
- Affected module: M05 / AUTH_PROFILE_SYNC.
- Migration required: No runtime migration in this docs-only pass.
- Regression test required: Yes when implementation starts; see module test checklist and BD section 17.2.

### Historical Decisions - answered 2026-06-30
- Q-08: Mã giới thiệu nhập ở bước nào và Admin có được sửa hậu kiểm không?
- Q-16: Múi giờ chuẩn cho reset quota, thời hạn gói, báo cáo và duyệt payment là gì?