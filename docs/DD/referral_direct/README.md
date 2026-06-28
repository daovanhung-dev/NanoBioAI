# DD — Sale & mã giới thiệu trực tiếp

| Attribute | Value |
|---|---|
| Module Code | REFERRAL_DIRECT |
| BD Module | M12 |
| Version | v1.0 |
| Status | Draft |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 7/M12, 15, 16.2 AC-09/AC-10/AC-14, Appendix A UC-12..UC-14 |

## Purpose
Đăng ký Sale, cấp mã giới thiệu và tạo quan hệ Sale -> khách trực tiếp duy nhất.

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
- REFERRAL_DIRECT-F01: Đăng ký và duyệt Sale
- REFERRAL_DIRECT-F02: Gắn mã giới thiệu trực tiếp

## Dependent Modules
- AUTH_PROFILE_SYNC: Member and customer identity.
- PAYMENT_MEMBERSHIP: later payment source.
- SALE_POINTS: point credit after approval.
- AUDIT_SECURITY: fraud/audit.

## Open Questions
| ID | Question | Impact | Status |
|---|---|---|---|
| Q-01 | Ai được trở thành Sale: tất cả Member, chỉ Member mua gói, hay cần hồ sơ/duyệt? | Sale registration and Admin approval flow. | Open |
| Q-08 | Mã giới thiệu nhập ở bước nào và Admin có được sửa hậu kiểm không? | Referral locking and anti-fraud. | Open |
| Q-09 | Tiêu chí phát hiện tự giới thiệu/tài khoản trùng là gì? | Fraud checks and rejection rules. | Open |
| Q-10 | Sale suspended/closed thì khách cũ có còn phát sinh điểm không? | Sale state machine and disputes. | Open |
| Q-18 | Sale xem được định danh nào của khách hay chỉ số liệu tổng hợp? | Privacy and Sale dashboard. | Open |

## Approval Status
| Role | Approver | Status | Date |
|---|---|---|---|
| BA/PO | Product Owner | Pending |  |
| Tech Lead | Tech Lead | Pending |  |
| QA Lead | QA Lead | Pending |  |

## Validation Notes
- Runtime code was not changed in this DD creation pass.
- Physical schema, RLS, endpoint, payment provider, and UI mockups remain Draft unless explicitly specified by BD.
