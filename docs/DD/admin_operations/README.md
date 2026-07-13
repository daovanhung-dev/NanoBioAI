# DD — Admin quản lý hệ thống

| Attribute | Value |
|---|---|
| Module Code | ADMIN_OPS |
| BD Module | M16 |
| Version | v1.3 |
| Status | Approved - DD docs complete |
| Owner | Product Owner / Tech Lead |
| Created Date | 2026-06-28 |
| Last Updated | 2026-07-13 |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 11.3..11.7, 16.3 AC-20..AC-24, Appendix A UC-21 |
| Approved Addendum | docs/BD/wellness_rewards/BD_BioAI_Daily_Proof_Wellness_Rewards_v1.0.md (BD-BIOAI-WELLNESS-REWARDS-001) |

## Purpose
Quản trị người dùng, gói, Sale, payment, conversion, nội dung, cấu hình và vận hành sản phẩm.

## Documents in This Module
- [Overall](./Overall.md)
- [Feature List](./List_Features.md)
- [Function List](./Function_List.md)
- [Views](./Views.md)
- [Import and File Mapping](./Import_File.md)
- [Diagrams](./diagrams/README.md)
- [Assets](./assets/README.md)
- [Change History](./history/CHANGELOG.md)
- [Implementation Delta 2026-07-13](./Implementation_Delta_2026-07-13.md)

## Traceability Summary
- ADMIN_OPS-F01: Quản lý người dùng/gói/Sale/config
- ADMIN_OPS-F02: Quản lý tài chính hỗ trợ
- Delta 2026-07-13: quản trị catalog, kho mã, giao dịch và hủy/refund Điểm chăm sóc.

## Dependent Modules
- AUDIT_SECURITY: audit/permissions.
- PAYMENT_MEMBERSHIP: payment ops.
- REFERRAL_DIRECT: Sale ops.
- SALE_POINTS: conversion/adjustment.

## Answered Questions
| ID | Question | Decision | Status |
|---|---|---|---|
| Q-12 | Which Admin groups exist? | All Admin groups exist: Super Admin, Finance Admin, Support Admin, and Content Admin. | Answered - User decision 2026-06-30 |
| Q-13 | Who can edit sensitive data and Sale points? | Admin has broad operational power, but only Super Admin can edit sensitive data, perform full-data edits, or make manual Sale point adjustments. Each action requires reason, idempotency, and audit. | Answered - User decision 2026-06-30 |
| Q-17 | Can webhook/trusted recorder approve payments automatically? | All payments and transfers are manually reviewed and manually approved by Admin. Trusted recorder may only create pending evidence; only Admin approval creates payment_approved. | Answered - User decision 2026-06-30 |
| Q-18 | What customer information may Sale see? | Sale may see customer phone number and basic profile information for customer care, but cannot see health data, AI data, secrets, or raw payment payloads. | Answered - User decision 2026-06-30 |

## Product Decisions Applied (2026-06-29)
- Q-12: Admin active has full audited operational CRUD capability through Admin RPC/backend, not direct Flutter writes to every Supabase table.
- Q-13: Manual Sale point adjustment is allowed and requires exactly one Admin approval with reason/idempotency/audit.
- Q-17: Payment approval is mandatory manual; trusted recorder only creates pending payment evidence for Admin review.
- Q-18: Admin/Sale may see customer name and basic profile/contact/status summaries; health data, AI content, secrets, and raw payment payloads stay hidden.

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
