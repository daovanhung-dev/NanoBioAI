# CHANGELOG — ADMIN_OPS / Admin quản lý hệ thống

## [v1.3] - 2026-07-13
### Changed
- Added audited offer upsert, bulk code import, inventory/redemption listing and idempotent cancellation/refund contracts under `wellness_rewards.write`.
- Recorded that cancelled codes are discarded permanently and plaintext unissued inventory is never listed.

### Validation
- SQL/client contract source is ready; migration 16, RLS, concurrency and audit behavior are not yet verified in sandbox.

## [v1.2] - 2026-06-30
### Changed
- Marked ADMIN_OPS DD docs as `Approved - DD docs complete`.
- Separated runtime/test/sandbox evidence into the Implementation Evidence Backlog.
- Converted unchecked DD requirement lists into documented acceptance/evidence requirement tables without claiming tests were executed.

### Validation
- Docs-only change; runtime code, SQL, Supabase config, and tests were not changed.

## [v1.1] - 2026-06-30
### Changed
- Recorded accepted product decisions Q-12, Q-13, Q-17, Q-18 in README, Overall, Import_File, and checklist traceability.
- Reclassified prior question rows as answered decisions; remaining gaps are implementation evidence, sandbox/RLS/API verification, or planned assets.

### Decisions
- Q-12: All Admin groups exist: Super Admin, Finance Admin, Support Admin, and Content Admin.
- Q-13: Admin has broad operational power, but only Super Admin can edit sensitive data, perform full-data edits, or make manual Sale point adjustments. Each action requires reason, idempotency, and audit.
- Q-17: All payments and transfers are manually reviewed and manually approved by Admin. Trusted recorder may only create pending evidence; only Admin approval creates payment_approved.
- Q-18: Sale may see customer phone number and basic profile information for customer care, but cannot see health data, AI data, secrets, or raw payment payloads.

### Validation
- Docs-only change; runtime code was not changed.

## [v1.0] - 2026-06-28
### Added
- Initial DD created from docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), scope BD sections 11.3..11.7, 16.3 AC-20..AC-24, Appendix A UC-21.
- Created README, Overall, List_Features, Function_List, Views, Import_File, diagrams README, assets README, and changelog.

### Impact
- Affected module: M16 / ADMIN_OPS.
- Migration required: No runtime migration in this docs-only pass.
- Regression test required: Yes when implementation starts; see module test checklist and BD section 17.2.

### Historical Decisions - answered 2026-06-30
- Q-12: Admin có bao nhiêu nhóm quyền?
- Q-13: Admin có được điều chỉnh thủ công Điểm Sale và cần hai người duyệt không?
- Q-17: Payment phải duyệt thủ công toàn bộ hay webhook tự động có thể tạo payment_approved?
- Q-18: Sale xem được định danh nào của khách hay chỉ số liệu tổng hợp?
