# DD — Xác thực, hồ sơ và đồng bộ Guest

| Attribute | Value |
|---|---|
| Module Code | AUTH_PROFILE_SYNC |
| BD Module | M05 |
| Version | v1.0 |
| Status | Draft - contracts updated, sandbox evidence pending |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
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

## Answered Questions
| ID | Question | Decision | Status |
|---|---|---|---|
| Q-08 | When can referral code be entered? | Referral code is accepted only during registration. Any post-registration correction requires audited Super Admin override. | Answered - User decision 2026-06-30 |
| Q-16 | Which timezone is authoritative? | Use Vietnam timezone, Asia/Ho_Chi_Minh. | Answered - User decision 2026-06-30 |

## Approval Status
| Role | Approver | Status | Date |
|---|---|---|---|
| BA/PO | Product Owner | Pending |  |
| Tech Lead | Tech Lead | Pending |  |
| QA Lead | QA Lead | Pending |  |

## Validation Notes
- Runtime code was not changed in this DD creation pass.
- Physical schema, RLS, endpoint, payment provider, and UI mockups remain Draft unless explicitly specified by BD.
- Product decisions Q-08, Q-16 were answered on 2026-06-30; remaining Draft items are implementation evidence, sandbox/RLS/API verification, or planned assets, not PO blockers.
