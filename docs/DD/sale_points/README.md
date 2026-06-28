# DD — Điểm Sale & quy đổi

| Attribute | Value |
|---|---|
| Module Code | SALE_POINTS |
| BD Module | M14 |
| Version | v1.0 |
| Status | Draft |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 7.5..7.10, 9, 12.1, 14.4, 16.2 AC-11..AC-18, Appendix A UC-17..UC-19 |

## Purpose
Cộng Điểm Sale từ hoa hồng trực tiếp 10%, giữ ledger, xử lý reversal và quy đổi điểm.

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
- SALE_POINTS-F01: Cộng Điểm Sale sau payment approved
- SALE_POINTS-F02: Quy đổi Điểm Sale

## Dependent Modules
- PAYMENT_MEMBERSHIP: payment_approved event.
- REFERRAL_DIRECT: valid relationship.
- ADMIN_OPS: conversion approval.
- AUDIT_SECURITY: ledger/audit.

## Open Questions
| ID | Question | Impact | Status |
|---|---|---|---|
| Q-02 | Giới thiệu thành công có cần thêm điều kiện như qua thời gian hoàn tiền? | Timing of Sale point credit. | Open |
| Q-03 | 10% tính trên giá niêm yết hay số tiền thực thu sau giảm giá/voucher/thuế/phí? | Commission formula and reporting. | Open |
| Q-05 | Hoàn/hủy/chargeback sau khi cộng điểm xử lý thế nào nếu Sale đã đổi điểm? | Ledger reversal and negative balance policy. | Open |
| Q-06 | Tỷ lệ quy đổi Điểm Sale thành tiền, thay đổi theo thời gian, mức tối thiểu là gì? | Conversion configuration and UI. | Open |
| Q-07 | Sale nhận tiền bằng phương thức nào, chu kỳ chi trả, hồ sơ/tax/invoice nào? | Payout operations and evidence. | Open |
| Q-10 | Sale suspended/closed thì khách cũ có còn phát sinh điểm không? | Sale state machine and disputes. | Open |
| Q-11 | FamilyPlus payment tính 10% trên toàn gói hay chỉ phần chủ gói? | Commission base for FamilyPlus. | Open |
| Q-13 | Admin có được điều chỉnh thủ công Điểm Sale và cần hai người duyệt không? | Audit and separation of duties. | Open |

## Approval Status
| Role | Approver | Status | Date |
|---|---|---|---|
| BA/PO | Product Owner | Pending |  |
| Tech Lead | Tech Lead | Pending |  |
| QA Lead | QA Lead | Pending |  |

## Validation Notes
- Runtime code was not changed in this DD creation pass.
- Physical schema, RLS, endpoint, payment provider, and UI mockups remain Draft unless explicitly specified by BD.
