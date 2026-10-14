# CHANGELOG — AUTH_PROFILE_SYNC / Xác thực, hồ sơ và đồng bộ Guest

## [v1.6] - 2026-10-14
### Changed
- Removed the password request queue. Members change their password directly in Settings; Forgot Password tells them to contact Admin.
- Added a Super Admin reset action on the user list; after verifying the registered phone it sets `12345678` and requires a new password at next sign-in.
- Applied both additive migrations and deployed the phone signup, member password-change, Admin reset, and single/bulk Admin account functions to the authorized production project.

### Validation
- Flutter analyze and 44 focused tests passed; Admin Web typecheck and 67 tests passed; 14 Edge Function tests passed.
- Production API signup and password login passed for a synthetic test account; Android UI login/reset remains unverified because Flutter Driver is not enabled.

## [v1.5] - 2026-10-14
### Changed
- Kept Supabase Phone Auth disabled and added a server-created Auth email alias for member phone/password sessions.
- Simplified forgotten-password recovery to a Super Admin reset from the user list; the password is `12345678` and the member must change it at next sign-in.
- Members can change their password directly in Settings; Forgot Password directs them to contact Admin.
- Changed guarded legacy migration from Auth phone assignment to phone-derived Auth aliases, preserving IDs/passwords/contact email.
- Added private signup IP rate limiting and matching seed/auth contracts.

### Removed
- Removed the password request queue, approval workflow, related database tables/RPCs, and request-rate-limit state.

### Validation
- Source implementation is in progress. Hosted migration/deployment and production account acceptance are not claimed.

## [v1.4] - 2026-10-14
### Changed
- Switched member signup/sign-in to normalized Vietnam phone and password; kept email login for Admin staff and legacy contact email data.
- Added Admin-reviewed password-change requests from Settings and Forgot Password, one-time random temporary passwords, a forced-change gate, and server-side audit/rate limits.
- Added guarded legacy phone migration tooling and canonical/additive Supabase SQL contracts.
- Kept login phone Auth-owned by removing it from Admin/profile updates and mobile snapshot writes; the additive migration wraps the current snapshot RPC to strip legacy client phone data.

### Validation
- Focused Flutter, Admin Web, Deno handler/migration review tests, analyzer, and Deno checks passed locally.
- Hosted Supabase Auth configuration, sandbox migration/RLS, function deployment, and device acceptance remain unverified.

## [v1.3] - 2026-07-12
### Changed
- Implemented Auth V2 callback/session lifecycle, Guest consent and push-before-pull authenticated sync.
- Restored `personal_schedule_ai_requests` snapshot mapping by `request_id` and added a transaction guard against in-flight local writes.
- Added atomic signup/referral migration, separate Admin session storage and `AdminAccessState` gate.
- Updated regression/acceptance evidence backlog without claiming sandbox/device production acceptance.

### Validation
- Static source/YAML/import/SQL checks pass in the available environment.
- Flutter analyze/test/build, Supabase sandbox and Android device evidence remain blocked/pending.

## [v1.2] - 2026-06-30
### Changed
- Marked AUTH_PROFILE_SYNC DD docs as `Approved - DD docs complete`.
- Separated runtime/test/sandbox evidence into the Implementation Evidence Backlog.
- Converted unchecked DD requirement lists into documented acceptance/evidence requirement tables without claiming tests were executed.

### Validation
- Docs-only change; runtime code, SQL, Supabase config, and tests were not changed.

## [v1.1] - 2026-06-30
### Changed
- Recorded accepted product decisions Q-08, Q-16 in README, Overall, Import_File, and checklist traceability.
- Reclassified prior question rows as answered decisions; remaining gaps are implementation evidence, sandbox/RLS/API verification, or planned assets.

### Decisions
- Q-08: Referral code is accepted only during registration. Any post-registration correction requires audited Super Admin override.
- Q-16: Use Vietnam timezone, Asia/Ho_Chi_Minh.

### Validation
- Docs-only change; runtime code was not changed.

## [v1.0] - 2026-06-28
### Added
- Initial DD created from docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), scope BD sections 6/M05, 13, Appendix A UC-05.
- Created README, Overall, List_Features, Function_List, Views, Import_File, diagrams README, assets README, and changelog.

### Impact
- Affected module: M05 / AUTH_PROFILE_SYNC.
- Migration required: No runtime migration in this docs-only pass.
- Regression test required: Yes when implementation starts; see module test checklist and BD section 17.2.

### Historical Decisions - answered 2026-06-30
- Q-08: Mã giới thiệu nhập ở bước nào và Admin có được sửa hậu kiểm không?
- Q-16: Múi giờ chuẩn cho reset quota, thời hạn gói, báo cáo và duyệt payment là gì?
