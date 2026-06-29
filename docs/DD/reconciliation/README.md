# DD — Tính toán & đối soát

| Attribute | Value |
|---|---|
| Module Code | RECONCILIATION |
| BD Module | M17 |
| Version | v1.0 |
| Status | Draft - selected policy implementation-ready |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-29 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD section 12.1, 14.4, 15, Appendix A UC-22 |

## Purpose
Đối chiếu dữ liệu gói, payment, commission, Điểm Sale, quota và điểm sức khỏe để phát hiện sai lệch.

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
- RECONCILIATION-F01: Chạy đối soát định kỳ
- RECONCILIATION-F02: Xử lý sai lệch

## Dependent Modules
- PAYMENT_MEMBERSHIP, SALE_POINTS, MEMBERSHIP_QUOTA, HEALTH_SCORE_HABITS.
- AUDIT_SECURITY: audit corrections.
- REPORTING: reporting consumers.

## Open Questions
| ID | Question | Impact | Status |
|---|---|---|---|
| Q-05 | Hoàn/hủy/chargeback sau khi cộng điểm xử lý thế nào nếu Sale đã đổi điểm? | Ledger reversal and negative balance policy. | Open |
| Q-10 | Sale suspended/closed thì khách cũ có còn phát sinh điểm không? | Sale state machine and disputes. | Open |
| Q-13 | Admin có được điều chỉnh thủ công Điểm Sale và cần hai người duyệt không? | Audit and separation of duties. | Open |
| Q-17 | Payment phải duyệt thủ công toàn bộ hay webhook tự động có thể tạo payment_approved? | Payment architecture and operations. | Open |

## Product Decisions Applied (2026-06-29)
- Q-05: No package refund/cancel is allowed after 24h from approval/effective time; Sale points become usable only after the same 24h hold.
- Q-10: Suspended/closed Sale accounts do not receive new points from later payments by existing referred customers.
- Q-13: Manual Sale point adjustment is allowed and requires exactly one Admin approval with reason/idempotency/audit.
- Q-17: Payment approval is mandatory manual; trusted recorder only creates pending payment evidence for Admin review.

## Approval Status
| Role | Approver | Status | Date |
|---|---|---|---|
| BA/PO | Product Owner | Pending |  |
| Tech Lead | Tech Lead | Pending |  |
| QA Lead | QA Lead | Pending |  |

## Validation Notes
- Runtime code was not changed in this DD creation pass.
- Physical schema, RLS, endpoint, payment provider, and UI mockups remain Draft unless explicitly specified by BD.
