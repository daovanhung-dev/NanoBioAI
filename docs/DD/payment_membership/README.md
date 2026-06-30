# DD — Thanh toán, xác minh và quyền gói

| Attribute | Value |
|---|---|
| Module Code | PAYMENT_MEMBERSHIP |
| BD Module | M13 |
| Version | v1.0 |
| Status | Approved - DD docs complete |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
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

## Answered Questions
| ID | Question | Decision | Status |
|---|---|---|---|
| Q-03 | What is the 10 percent commission base? | Commission is calculated from the listed package price. | Answered - User decision 2026-06-30 |
| Q-04 | How do package periods and renewals work? | Plus and FamilyPlus support monthly and yearly plans. Early renewal extends from current expiry; late renewal starts from Admin approval time; pending payment never grants rights. | Answered - User decision 2026-06-30 |
| Q-05 | How are refund, cancel, and chargeback handled after points are credited? | Refund/cancel is allowed only within 24 hours after purchase. Points are reversed immediately in that window. Because conversion is also locked for 24 hours, there is no converted-then-reversed case. | Answered - User decision 2026-06-30 |
| Q-11 | How is FamilyPlus commission calculated? | FamilyPlus commission is calculated only on the package owner portion. | Answered - User decision 2026-06-30 |
| Q-17 | Can webhook/trusted recorder approve payments automatically? | All payments and transfers are manually reviewed and manually approved by Admin. Trusted recorder may only create pending evidence; only Admin approval creates payment_approved. | Answered - User decision 2026-06-30 |

## Approval Status
| Role | Approver | Status | Date |
|---|---|---|---|
| BA/PO | Product Owner | Approved by DD acceptance pass | 2026-06-30 |
| Tech Lead | Tech Lead | Approved by DD acceptance pass | 2026-06-30 |
| QA Lead | QA Lead | Approved by DD acceptance pass | 2026-06-30 |

## Validation Notes
- DD docs complete: all product questions are answered and documented as implementation policy.
- Runtime, sandbox/RLS/API smoke, and production acceptance evidence are tracked in the Implementation Evidence Backlog, not as DD blockers.
- Runtime code, SQL, Supabase config, and tests were not changed in this DD docs 100 percent pass.
