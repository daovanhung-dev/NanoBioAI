# CHANGELOG — RECONCILIATION / Tính toán & đối soát

## [v1.0] - 2026-06-28
### Added
- Initial DD created from docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), scope BD section 12.1, 14.4, 15, Appendix A UC-22.
- Created README, Overall, List_Features, Function_List, Views, Import_File, diagrams README, assets README, and changelog.

### Impact
- Affected module: M17 / RECONCILIATION.
- Migration required: No runtime migration in this docs-only pass.
- Regression test required: Yes when implementation starts; see module test checklist and BD section 17.2.

### Open Decisions
- Q-05: Hoàn/hủy/chargeback sau khi cộng điểm xử lý thế nào nếu Sale đã đổi điểm?
- Q-10: Sale suspended/closed thì khách cũ có còn phát sinh điểm không?
- Q-13: Admin có được điều chỉnh thủ công Điểm Sale và cần hai người duyệt không?
- Q-17: Payment phải duyệt thủ công toàn bộ hay webhook tự động có thể tạo payment_approved?
