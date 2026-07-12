# DD — Xác thực, hồ sơ và đồng bộ Guest

| Attribute | Value |
|---|---|
| Module Code | AUTH_PROFILE_SYNC |
| BD Module | M05 |
| Version | v1.3 |
| Status | Approved - DD docs complete |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-07-12 |
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
| BA/PO | Product Owner | Approved by DD acceptance pass | 2026-06-30 |
| Tech Lead | Tech Lead | Approved by DD acceptance pass | 2026-06-30 |
| QA Lead | QA Lead | Approved by DD acceptance pass | 2026-06-30 |

## Validation Notes
- DD docs complete: all product questions are answered and documented as implementation policy.
- Runtime, sandbox/RLS/API smoke, and production acceptance evidence are tracked in the Implementation Evidence Backlog, not as DD blockers.
- Runtime code, SQL, Supabase config, and tests were not changed in this DD docs 100 percent pass.

## Implementation Update 2026-07-12

- Guest Settings now exposes login/register actions, account-only controls are hidden without a session, and authenticated APK/AAB builds use a validated `--dart-define-from-file` launcher.
- Auth callback, Guest consent, push-before-pull, request ledger `request_id`, durable retry and Admin session isolation are implemented at source level.
- Migration `docs/supabase/15-auth-sync-completion.sql` replaces the signup trigger contract without destructive schema changes.
- Production acceptance remains pending Flutter compile/full tests, Supabase sandbox/RLS/atomic rollback and device evidence.
