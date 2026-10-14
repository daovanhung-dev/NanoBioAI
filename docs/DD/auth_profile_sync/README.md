# DD — Xác thực, hồ sơ và đồng bộ Guest

| Attribute | Value |
|---|---|
| Module Code | AUTH_PROFILE_SYNC |
| BD Module | M05 |
| Version | v1.6 |
| Lifecycle | Current |
| DD decision | Approved |
| Implementation | Implemented |
| Verification | Focused-tests-pass; Hosted-migrations-functions-deployed; Production-API-signup-login-pass; Mobile-interaction-unverified |
| Source evidence | Members sign in with normalized phone/password through internal Auth aliases; Admin staff keep email login; members change passwords in Settings; Super Admin resets forgotten passwords to `12345678` |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-10-14 |
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
- The local/sandbox system build source `docs/supabase/01_build_system.sql`
  contains the final signup trigger contract.
- Production acceptance remains pending Flutter compile/full tests, Supabase sandbox/RLS/atomic rollback and device evidence.

## Implementation Update 2026-10-14 — Source stage before production smoke

- Member login/register now use normalized Vietnam phone plus password; legacy
  email stays as contact data and Admin staff keep email login. Supabase Phone
  Auth remains off: a server-side signup function creates a confirmed internal
  Auth alias derived from the normalized phone, then the app signs in using the
  same alias. The member only sees and enters a phone number.
- Members change their password directly in Settings. Forgot Password tells
  the member to contact Admin. A Super Admin verifies the registered phone,
  resets the password to `12345678` in Admin Web, and the app requires a new
  password on the next sign-in.
- Existing account migration preserves IDs/passwords and changes eligible
  member Auth emails to phone-derived aliases while normalizing unique phones.
  The migration tool is dry-run by default and routes conflicts, missing
  profiles and Admin/dual-access accounts to manual review.
- Supabase Auth remains the source of truth for login phones: profile and Admin
  forms are read-only for phone, the mobile sync allowlist excludes it, and the
  snapshot RPC strips it before invoking the existing server-side sync logic.
- Production Phone Auth and email-confirmation settings are not changed. Signup
  uses an IP limit and a private service-role RPC. Current code changes and
  verification are tracked in the 2026-10-14 worklogs. The following update
  records the later production migration/deployment and remaining device gap.

## Implementation Update 2026-10-14 — Simplified Password Recovery

- Removed the member password-request queue and its tables/RPCs. Members change
  their password directly in Settings; Forgot Password directs them to Admin.
- Super Admin can reset a member password from the user list after confirming
  the registered phone. The server sets `12345678`, audits the action, and the
  app requires a new password on the next sign-in.
- Production migrations `20261014090000` and `20261014110000` were applied to
  the explicitly requested project. The five related Edge Functions deployed;
  API signup and password login passed for a synthetic test profile ending in
  `6453`. The test profile remains in production.
- Seven pre-existing Auth identities were still on their previous email
  identities after the smoke; they need the guarded alias migration before
  existing members can sign in with phone.
- Focused Flutter, Edge Function and Admin Web tests pass. Android hot reload
  succeeded; interactive device acceptance remains unverified because the
  Flutter driver extension is not enabled in the running app.
