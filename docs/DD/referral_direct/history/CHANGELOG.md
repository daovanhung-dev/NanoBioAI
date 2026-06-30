# CHANGELOG — REFERRAL_DIRECT / Sale & mã giới thiệu trực tiếp

## [v1.2] - 2026-06-30
### Changed
- Marked REFERRAL_DIRECT DD docs as `Approved - DD docs complete`.
- Separated runtime/test/sandbox evidence into the Implementation Evidence Backlog.
- Converted unchecked DD requirement lists into documented acceptance/evidence requirement tables without claiming tests were executed.

### Validation
- Docs-only change; runtime code, SQL, Supabase config, and tests were not changed.

## [v1.1] - 2026-06-30
### Changed
- Recorded accepted product decisions Q-01, Q-08, Q-09, Q-10, Q-18 in README, Overall, Import_File, and checklist traceability.
- Reclassified prior question rows as answered decisions; remaining gaps are implementation evidence, sandbox/RLS/API verification, or planned assets.

### Decisions
- Q-01: Only members with Plus or higher active package can become Sale.
- Q-08: Referral code is accepted only during registration. Any post-registration correction requires audited Super Admin override.
- Q-09: Use the strictest policy: hard-block same account, phone, email, payment, bank, device, or identity; hold suspicious IP/device/family/payment patterns for Admin review; only audited Super Admin override may release.
- Q-10: Suspended or closed Sale accounts receive no new points from old customers.
- Q-18: Sale may see customer phone number and basic profile information for customer care, but cannot see health data, AI data, secrets, or raw payment payloads.

### Validation
- Docs-only change; runtime code was not changed.

## [v1.0] - 2026-06-28
### Added
- Initial DD created from docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), scope BD sections 7/M12, 15, 16.2 AC-09/AC-10/AC-14, Appendix A UC-12..UC-14.
- Created README, Overall, List_Features, Function_List, Views, Import_File, diagrams README, assets README, and changelog.

### Impact
- Affected module: M12 / REFERRAL_DIRECT.
- Migration required: No runtime migration in this docs-only pass.
- Regression test required: Yes when implementation starts; see module test checklist and BD section 17.2.

### Historical Decisions - answered 2026-06-30
- Q-01: Ai được trở thành Sale: tất cả Member, chỉ Member mua gói, hay cần hồ sơ/duyệt?
- Q-08: Mã giới thiệu nhập ở bước nào và Admin có được sửa hậu kiểm không?
- Q-09: Tiêu chí phát hiện tự giới thiệu/tài khoản trùng là gì?
- Q-10: Sale suspended/closed thì khách cũ có còn phát sinh điểm không?
- Q-18: Sale xem được định danh nào của khách hay chỉ số liệu tổng hợp?
