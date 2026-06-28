# DD — Xác thực, hồ sơ và đồng bộ Guest

| Attribute | Value |
|---|---|
| Module Code | AUTH_PROFILE_SYNC |
| BD Module | M05 |
| Version | v1.0 |
| Status | Draft |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-28 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 6/M05, 13, Appendix A UC-05 |

## Purpose
Đăng ký/đăng nhập, liên kết dữ liệu Guest local với tài khoản và dựng quyền ban đầu.

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
- AUTH_PROFILE_SYNC-F01: Đăng ký/đăng nhập và dựng quyền
- AUTH_PROFILE_SYNC-F02: Đồng bộ dữ liệu Guest

## Dependent Modules
- ONBOARDING_PROFILE: dữ liệu Guest.
- MEMBERSHIP_QUOTA: entitlement.
- REFERRAL_DIRECT: mã giới thiệu.
- AUDIT_SECURITY: auth/security logs.

## Open Questions
| ID | Question | Impact | Status |
|---|---|---|---|
| Q-08 | Mã giới thiệu nhập ở bước nào và Admin có được sửa hậu kiểm không? | Referral locking and anti-fraud. | Open |
| Q-16 | Múi giờ chuẩn cho reset quota, thời hạn gói, báo cáo và duyệt payment là gì? | Quota, entitlement, reporting and approval windows. | Open |

## Approval Status
| Role | Approver | Status | Date |
|---|---|---|---|
| BA/PO | Product Owner | Pending |  |
| Tech Lead | Tech Lead | Pending |  |
| QA Lead | QA Lead | Pending |  |

## Validation Notes
- Runtime code was not changed in this DD creation pass.
- Physical schema, RLS, endpoint, payment provider, and UI mockups remain Draft unless explicitly specified by BD.
