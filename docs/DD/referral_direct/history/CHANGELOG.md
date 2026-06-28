# CHANGELOG — REFERRAL_DIRECT / Sale & mã giới thiệu trực tiếp

## [v1.0] - 2026-06-28
### Added
- Initial DD created from docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), scope BD sections 7/M12, 15, 16.2 AC-09/AC-10/AC-14, Appendix A UC-12..UC-14.
- Created README, Overall, List_Features, Function_List, Views, Import_File, diagrams README, assets README, and changelog.

### Impact
- Affected module: M12 / REFERRAL_DIRECT.
- Migration required: No runtime migration in this docs-only pass.
- Regression test required: Yes when implementation starts; see module test checklist and BD section 17.2.

### Open Decisions
- Q-01: Ai được trở thành Sale: tất cả Member, chỉ Member mua gói, hay cần hồ sơ/duyệt?
- Q-08: Mã giới thiệu nhập ở bước nào và Admin có được sửa hậu kiểm không?
- Q-09: Tiêu chí phát hiện tự giới thiệu/tài khoản trùng là gì?
- Q-10: Sale suspended/closed thì khách cũ có còn phát sinh điểm không?
- Q-18: Sale xem được định danh nào của khách hay chỉ số liệu tổng hợp?
