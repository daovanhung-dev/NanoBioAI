# DD — Điểm Sale & quy đổi

| Attribute | Value |
|---|---|
| Module Code | SALE_POINTS |
| BD Module | M14 |
| Version | v1.0 |
| Status | Draft - contracts updated, sandbox evidence pending |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
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

## Answered Questions
| ID | Question | Decision | Status |
|---|---|---|---|
| Q-02 | When is a referral counted as successful? | A referral is successful when the referred customer payment is manually approved. Points are credited immediately after approval, but conversion is locked for 24 hours. | Answered - User decision 2026-06-30 |
| Q-03 | What is the 10 percent commission base? | Commission is calculated from the listed package price. | Answered - User decision 2026-06-30 |
| Q-05 | How are refund, cancel, and chargeback handled after points are credited? | Refund/cancel is allowed only within 24 hours after purchase. Points are reversed immediately in that window. Because conversion is also locked for 24 hours, there is no converted-then-reversed case. | Answered - User decision 2026-06-30 |
| Q-06 | What is the point-to-money conversion rate and minimum payout? | 1 point = 1 VND. Minimum conversion is 500,000 VND. Rate and minimum are Admin-configurable and versioned over time. | Answered - User decision 2026-06-30 |
| Q-07 | How does Sale payout work? | Sale submits bank info and a conversion request. Admin transfers manually, then approves and deducts points. | Answered - User decision 2026-06-30 |
| Q-10 | Do suspended or closed Sale accounts continue receiving points? | Suspended or closed Sale accounts receive no new points from old customers. | Answered - User decision 2026-06-30 |
| Q-11 | How is FamilyPlus commission calculated? | FamilyPlus commission is calculated only on the package owner portion. | Answered - User decision 2026-06-30 |
| Q-13 | Who can edit sensitive data and Sale points? | Admin has broad operational power, but only Super Admin can edit sensitive data, perform full-data edits, or make manual Sale point adjustments. Each action requires reason, idempotency, and audit. | Answered - User decision 2026-06-30 |

## Approval Status
| Role | Approver | Status | Date |
|---|---|---|---|
| BA/PO | Product Owner | Pending |  |
| Tech Lead | Tech Lead | Pending |  |
| QA Lead | QA Lead | Pending |  |

## Validation Notes
- Runtime code was not changed in this DD creation pass.
- Physical schema, RLS, endpoint, payment provider, and UI mockups remain Draft unless explicitly specified by BD.
- Product decisions Q-02, Q-03, Q-05, Q-06, Q-07, Q-10, Q-11, Q-13 were answered on 2026-06-30; remaining Draft items are implementation evidence, sandbox/RLS/API verification, or planned assets, not PO blockers.
