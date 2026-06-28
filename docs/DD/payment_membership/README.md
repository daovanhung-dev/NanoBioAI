# DD — Thanh toán, xác minh và quyền gói

| Attribute | Value |
|---|---|
| Module Code | PAYMENT_MEMBERSHIP |
| BD Module | M13 |
| Version | v1.0 |
| Status | Draft |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 8/M13, 14.4, 15, 16.1 AC-07/AC-08, 16.3 AC-20/AC-21, Appendix A UC-15/UC-16 |

## Purpose
Ghi nhận giao dịch mua/gia hạn, xác minh qua Admin và chỉ kích hoạt quyền sau payment_approved.

## Documents in This Module
- [Overall](./Overall.md)
- [Feature List](./List_Features.md)
- [Function List](./Function_List.md)
- [Views](./Views.md)
- [Import and File Mapping](./Import_File.md)
- [Diagrams](./diagrams/README.md)
- [Assets](./assets/README.md)
- [Change History](./history/CHANGELOG.md)

## Traceability Summary
- PAYMENT_MEMBERSHIP-F01: Tạo thanh toán mua/gia hạn gói
- PAYMENT_MEMBERSHIP-F02: Admin duyệt/từ chối payment

## Dependent Modules
- MEMBERSHIP_QUOTA: entitlement activation.
- REFERRAL_DIRECT: source referral.
- SALE_POINTS: points after approval.
- ADMIN_OPS/AUDIT_SECURITY: approval/audit.

## Open Questions
| ID | Question | Impact | Status |
|---|---|---|---|
| Q-03 | 10% tính trên giá niêm yết hay số tiền thực thu sau giảm giá/voucher/thuế/phí? | Commission formula and reporting. | Open |
| Q-04 | Các gói thanh toán theo tháng, năm hay một lần; gia hạn sớm/trễ xử lý ra sao? | Entitlement and recurring commission. | Open |
| Q-05 | Hoàn/hủy/chargeback sau khi cộng điểm xử lý thế nào nếu Sale đã đổi điểm? | Ledger reversal and negative balance policy. | Open |
| Q-11 | FamilyPlus payment tính 10% trên toàn gói hay chỉ phần chủ gói? | Commission base for FamilyPlus. | Open |
| Q-17 | Payment phải duyệt thủ công toàn bộ hay webhook tự động có thể tạo payment_approved? | Payment architecture and operations. | Open |

## Approval Status
| Role | Approver | Status | Date |
|---|---|---|---|
| BA/PO | Product Owner | Pending |  |
| Tech Lead | Tech Lead | Pending |  |
| QA Lead | QA Lead | Pending |  |

## Validation Notes
- Runtime code was not changed in this DD creation pass.
- Physical schema, RLS, endpoint, payment provider, and UI mockups remain Draft unless explicitly specified by BD.
