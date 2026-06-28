# CHANGELOG — PAYMENT_MEMBERSHIP / Thanh toán, xác minh và quyền gói

## [v1.0] - 2026-06-28
### Added
- Initial DD created from docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), scope BD sections 8/M13, 14.4, 15, 16.1 AC-07/AC-08, 16.3 AC-20/AC-21, Appendix A UC-15/UC-16.
- Created README, Overall, List_Features, Function_List, Views, Import_File, diagrams README, assets README, and changelog.

### Impact
- Affected module: M13 / PAYMENT_MEMBERSHIP.
- Migration required: No runtime migration in this docs-only pass.
- Regression test required: Yes when implementation starts; see module test checklist and BD section 17.2.

### Open Decisions
- Q-03: 10% tính trên giá niêm yết hay số tiền thực thu sau giảm giá/voucher/thuế/phí?
- Q-04: Các gói thanh toán theo tháng, năm hay một lần; gia hạn sớm/trễ xử lý ra sao?
- Q-05: Hoàn/hủy/chargeback sau khi cộng điểm xử lý thế nào nếu Sale đã đổi điểm?
- Q-11: FamilyPlus payment tính 10% trên toàn gói hay chỉ phần chủ gói?
- Q-17: Payment phải duyệt thủ công toàn bộ hay webhook tự động có thể tạo payment_approved?
