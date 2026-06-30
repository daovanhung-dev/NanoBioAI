# DD — Sale & mã giới thiệu trực tiếp

| Attribute | Value |
|---|---|
| Module Code | REFERRAL_DIRECT |
| BD Module | M12 |
| Version | v1.0 |
| Status | Approved - DD docs complete |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-06-30 |
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

## Answered Questions
| ID | Question | Decision | Status |
|---|---|---|---|
| Q-01 | Who can become Sale? | Only members with Plus or higher active package can become Sale. | Answered - User decision 2026-06-30 |
| Q-08 | When can referral code be entered? | Referral code is accepted only during registration. Any post-registration correction requires audited Super Admin override. | Answered - User decision 2026-06-30 |
| Q-09 | What anti-fraud rules apply to referrals? | Use the strictest policy: hard-block same account, phone, email, payment, bank, device, or identity; hold suspicious IP/device/family/payment patterns for Admin review; only audited Super Admin override may release. | Answered - User decision 2026-06-30 |
| Q-10 | Do suspended or closed Sale accounts continue receiving points? | Suspended or closed Sale accounts receive no new points from old customers. | Answered - User decision 2026-06-30 |
| Q-18 | What customer information may Sale see? | Sale may see customer phone number and basic profile information for customer care, but cannot see health data, AI data, secrets, or raw payment payloads. | Answered - User decision 2026-06-30 |

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
