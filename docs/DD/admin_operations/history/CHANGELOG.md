# CHANGELOG — ADMIN_OPS / Admin quản lý hệ thống

## [v1.0] - 2026-06-28
### Added
- Initial DD created from docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), scope BD sections 11.3..11.7, 16.3 AC-20..AC-24, Appendix A UC-21.
- Created README, Overall, List_Features, Function_List, Views, Import_File, diagrams README, assets README, and changelog.

### Impact
- Affected module: M16 / ADMIN_OPS.
- Migration required: No runtime migration in this docs-only pass.
- Regression test required: Yes when implementation starts; see module test checklist and BD section 17.2.

### Open Decisions
- Q-12: Admin có bao nhiêu nhóm quyền?
- Q-13: Admin có được điều chỉnh thủ công Điểm Sale và cần hai người duyệt không?
- Q-17: Payment phải duyệt thủ công toàn bộ hay webhook tự động có thể tạo payment_approved?
- Q-18: Sale xem được định danh nào của khách hay chỉ số liệu tổng hợp?
