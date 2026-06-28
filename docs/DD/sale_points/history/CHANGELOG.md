# CHANGELOG — SALE_POINTS / Điểm Sale & quy đổi

## [v1.0] - 2026-06-28
### Added
- Initial DD created from docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), scope BD sections 7.5..7.10, 9, 12.1, 14.4, 16.2 AC-11..AC-18, Appendix A UC-17..UC-19.
- Created README, Overall, List_Features, Function_List, Views, Import_File, diagrams README, assets README, and changelog.

### Impact
- Affected module: M14 / SALE_POINTS.
- Migration required: No runtime migration in this docs-only pass.
- Regression test required: Yes when implementation starts; see module test checklist and BD section 17.2.

### Open Decisions
- Q-02: Giới thiệu thành công có cần thêm điều kiện như qua thời gian hoàn tiền?
- Q-03: 10% tính trên giá niêm yết hay số tiền thực thu sau giảm giá/voucher/thuế/phí?
- Q-05: Hoàn/hủy/chargeback sau khi cộng điểm xử lý thế nào nếu Sale đã đổi điểm?
- Q-06: Tỷ lệ quy đổi Điểm Sale thành tiền, thay đổi theo thời gian, mức tối thiểu là gì?
- Q-07: Sale nhận tiền bằng phương thức nào, chu kỳ chi trả, hồ sơ/tax/invoice nào?
- Q-10: Sale suspended/closed thì khách cũ có còn phát sinh điểm không?
- Q-11: FamilyPlus payment tính 10% trên toàn gói hay chỉ phần chủ gói?
- Q-13: Admin có được điều chỉnh thủ công Điểm Sale và cần hai người duyệt không?
