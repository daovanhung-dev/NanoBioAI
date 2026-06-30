# DD — Tính toán & đối soát

| Attribute | Value |
|---|---|
| Module Code | RECONCILIATION |
| BD Module | M17 |
| Version | v1.0 |
| Status | Draft - contracts updated, sandbox evidence pending |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
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

## Answered Questions
| ID | Question | Decision | Status |
|---|---|---|---|
| Q-05 | How are refund, cancel, and chargeback handled after points are credited? | Refund/cancel is allowed only within 24 hours after purchase. Points are reversed immediately in that window. Because conversion is also locked for 24 hours, there is no converted-then-reversed case. | Answered - User decision 2026-06-30 |
| Q-10 | Do suspended or closed Sale accounts continue receiving points? | Suspended or closed Sale accounts receive no new points from old customers. | Answered - User decision 2026-06-30 |
| Q-13 | Who can edit sensitive data and Sale points? | Admin has broad operational power, but only Super Admin can edit sensitive data, perform full-data edits, or make manual Sale point adjustments. Each action requires reason, idempotency, and audit. | Answered - User decision 2026-06-30 |
| Q-17 | Can webhook/trusted recorder approve payments automatically? | All payments and transfers are manually reviewed and manually approved by Admin. Trusted recorder may only create pending evidence; only Admin approval creates payment_approved. | Answered - User decision 2026-06-30 |

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
- Product decisions Q-05, Q-10, Q-13, Q-17 were answered on 2026-06-30; remaining Draft items are implementation evidence, sandbox/RLS/API verification, or planned assets, not PO blockers.
