# Overall — PAYMENT_MEMBERSHIP / Thanh toán, xác minh và quyền gói

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | PAYMENT_MEMBERSHIP |
| BD Module | M13 |
| Version | v1.3 |
| Status | Approved - DD docs complete |
| Source BD | docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), BD sections 8/M13, 14.4, 15, 16.1 AC-07/AC-08, 16.3 AC-20/AC-21, Appendix A UC-15/UC-16 |
| Created Date | 2026-06-28 |
| Last Updated | 2026-07-31 |
| Release Scope | Project DD baseline for M01-M19 |

## 2. Business Goal
Module này đảm bảo yêu cầu thanh toán VietQR không mở gói trước khi được duyệt, Admin approval có lý do/audit, refund/cancel tạo adjustment thay vì sửa lịch sử.

## 3. Module Scope

### In Scope
- Tạo yêu cầu thanh toán VietQR Vietcombank với mã đối soát do server sinh.
- Khách xác nhận “Đã chuyển khoản” để chuyển yêu cầu vào hàng chờ duyệt.
- Admin có quyền payments.write xem thanh thông báo và duyệt/từ chối sau khi tự đối chiếu trong ứng dụng VCB.
- Kích hoạt/gia hạn entitlement sau approved.
- Refund/cancel/duplicate handling.

### Out of Scope
- Tích hợp API ngân hàng, webhook, tự động đối soát, hoặc hiển thị số dư ngân hàng.
- Tải biên lai/chứng từ chuyển khoản.
- Payout Sale.
- Provider-specific chargeback integration details beyond the accepted 24h refund/cancel policy.

## 4. Roles and Permissions

| Role | Permissions in This Module | Limitations |
|---|---|---|
| Member, Admin | Use module features according to BD sections 3, 5, and BD sections 8/M13, 14.4, 15, 16.1 AC-07/AC-08, 16.3 AC-20/AC-21, Appendix A UC-15/UC-16. | Must not bypass entitlement, ownership, family consent, Sale/Admin scope, or audit rules. |
| System | Validate state, apply business rules, write events/audit where required. | Must be idempotent and must follow accepted product decisions. |
| Admin/Super Admin | Operate only where BD grants admin responsibility. | Backend/API must reject missing permission; UI hiding is not sufficient. |

## 5. Primary Entities/Data

| Entity ID | Entity | Purpose | Important Attributes | Relationships |
|---|---|---|---|---|
| PAYMENT_MEMBERSHIP-E-payment_transaction | Payment Transaction | Giao dịch gói | user, plan, amount, status, transaction reference | Source for entitlement and commission |
| PAYMENT_MEMBERSHIP-E-payment_approval | Payment Approval | Lịch sử duyệt payment | payment, admin, decision, reason, time | Audit and entitlement source |
| PAYMENT_MEMBERSHIP-E-membership_entitlement | Membership Entitlement | Quyền gói | plan, start/end, source payment | Used by access gates |

## 6. States and State Transitions

| Entity / Group | States | Notes |
|---|---|---|
| Payment / Entitlement | Payment: awaiting_transfer → pending_review → succeeded hoặc failed; bản ghi pending cũ vẫn để Admin xử lý. Entitlement: pending, active, expired, suspended, cancelled | Chỉ succeeded sau Admin approval mới kích hoạt quyền. |

## 7. Business Rules

| ID | Rule | Applied At | Criticality |
|---|---|---|---|
| PAYMENT_MEMBERSHIP-BR01 | Không kích hoạt Plus/FamilyPlus chỉ vì khách tạo yêu cầu thanh toán. | Payment creation, approval, entitlement activation, refund/cancel | Mandatory |
| PAYMENT_MEMBERSHIP-BR02 | Chỉ payment_approved mới làm quyền gói hiệu lực và có thể kích hoạt Sale points. | Payment creation, approval, entitlement activation, refund/cancel | Mandatory |
| PAYMENT_MEMBERSHIP-BR03 | Mã giao dịch là NB + 12 ký tự hex do Supabase sinh, duy nhất và bất biến. Nội dung chuyển khoản là mã đứng đầu, kèm tên khách chuẩn hóa ASCII không dấu, tối đa 25 ký tự. | Payment creation/retry | Mandatory |
| PAYMENT_MEMBERSHIP-BR04 | Nút “Đã chuyển khoản” chỉ chuyển awaiting_transfer thành pending_review; không kích hoạt quyền và chỉ được dùng cho yêu cầu của chính khách. | Member confirmation | Mandatory |
| PAYMENT_MEMBERSHIP-BR05 | Admin phải tự kiểm tra ứng dụng VCB theo mã giao dịch và số tiền trước khi duyệt. Không dùng số dư, webhook hoặc API ngân hàng trong NanoBio. | Admin review | Mandatory |

## 8. Overall Operational Flow

1. Member chọn gói và chu kỳ tại /v2/payments.
2. Ứng dụng lấy họ tên từ SQLite theo Supabase user ID; nếu chưa có tên thì hướng dẫn cập nhật hồ sơ và không tạo QR.
3. Supabase xác thực auth.uid(), tự tính giá theo gói, sinh/trả mã NB, nội dung chuyển khoản và cấu hình nhận tiền Vietcombank (BIN 970436, tài khoản 1026806174, Lê Phú Thạch).
4. Ứng dụng dựng QR VietQR; khách chuyển tiền và bấm “Đã chuyển khoản”.
5. Supabase chỉ chuyển trạng thái sang pending_review và lưu thời điểm xác nhận; quyền gói vẫn chưa thay đổi.
6. Thanh thông báo của Admin có quyền payments.write hiển thị số yêu cầu pending_review. Admin mở hàng chờ, tự đối chiếu VCB theo mã/số tiền/nội dung rồi duyệt hoặc từ chối có lý do.
7. Chỉ quyết định duyệt mới dùng logic kích hoạt gói hiện có; từ chối không kích hoạt quyền và lý do được trả cho khách.

## 9. Integrations and Dependencies

| Dependency | Type | Purpose | Failure Behavior |
|---|---|---|---|
| Auth/Profile | Internal/Supabase planned | Identify actor and ownership. | Block action or request login. |
| SQLite profile | Internal/local | Provide customer full_name only for transfer-memo display. | Missing name blocks QR creation; local data never establishes payment ownership or access. |
| VietQR/NAPAS payload | Client-side QR encoding | Present Vietcombank account, amount, reference and ASCII memo for bank transfer. | QR generation failure does not create rights; member can retry the same request. |
| Membership/Entitlement | Internal/trusted backend planned | Apply Free/Plus/FamilyPlus access and quotas. | Keep previous state; do not grant paid access. |
| Audit/Security | Cross-cutting | Trace sensitive changes. | Sensitive writes must fail or be queued safely if audit cannot be recorded. |
| Module-specific dependencies | Internal | MEMBERSHIP_QUOTA: entitlement activation., REFERRAL_DIRECT: source referral., SALE_POINTS: points after approval., ADMIN_OPS/AUDIT_SECURITY: approval/audit. | Follow dependency owner DD and record conflict as an implementation issue or accepted exception. |

## 10. Non-Functional Requirements

| Category | Requirement |
|---|---|
| Security | Enforce UI, route, use-case/API, and database/RLS layers for sensitive data and paid/Sale/Admin access. |
| Data Integrity | Use unique business keys/idempotency for writes, especially payment, quota, point, family, notification, and admin actions. |
| Privacy | Minimize health, family, payment, and referral data exposure by role. |
| Observability | Log safe module status, correlation id, actor type, and audit-relevant changes only. |
| Resilience | Dependency failures must not create duplicate rights, duplicate points, incorrect quota, or partial financial state. |

## 11. Risks, Assumptions, and Decisions

| ID | Type | Content | Impact | Status |
|---|---|---|---|---|
| PAYMENT_MEMBERSHIP-RISK01 | Implementation evidence backlog | Runtime/sandbox evidence, final wireframes, and production acceptance remain outside DD completeness. | Implementation must produce evidence before production release. | Tracked |
| PAYMENT_MEMBERSHIP-ASSUMPTION01 | Assumption | BD v2.0 plus user decisions from 2026-06-30 are the source of truth; legacy conflicting Sale/Admin logic is not implementation source. | Implementation must migrate or reject old behavior such as Sale tree, tier-2 commission, or 5 percent rules. | Active |
| PAYMENT_MEMBERSHIP-Q-03 | Answered decision | What is the 10 percent commission base? | Commission is calculated from the listed package price. | Accepted - User decision 2026-06-30 |
| PAYMENT_MEMBERSHIP-Q-04 | Answered decision | How do package periods and renewals work? | Plus and FamilyPlus support monthly and yearly plans. Early renewal extends from current expiry; late renewal starts from Admin approval time; pending payment never grants rights. | Accepted - User decision 2026-06-30 |
| PAYMENT_MEMBERSHIP-Q-05 | Answered decision | How are refund, cancel, and chargeback handled after points are credited? | Refund/cancel is allowed only within 24 hours after purchase. Points are reversed immediately in that window. Because conversion is also locked for 24 hours, there is no converted-then-reversed case. | Accepted - User decision 2026-06-30 |
| PAYMENT_MEMBERSHIP-Q-11 | Answered decision | How is FamilyPlus commission calculated? | FamilyPlus commission is calculated only on the package owner portion. | Accepted - User decision 2026-06-30 |
| PAYMENT_MEMBERSHIP-Q-17 | Answered decision | Can webhook/trusted recorder approve payments automatically? | All payments and transfers are manually reviewed and manually approved by Admin. Trusted recorder may only create pending evidence; only Admin approval creates payment_approved. | Accepted - User decision 2026-06-30 |
| PAYMENT_MEMBERSHIP-Q-18 | Answered decision | What is the VietQR payment and approval flow? | Member scans Vietcombank QR, confirms the transfer, then an Admin with payments.write manually compares the reference and amount in VCB before approving or rejecting. No receipt, bank API, webhook, or in-app balance is used. | Accepted - User decision 2026-07-31 |

## 12. ADR Summary

| ID | Decision | Context | Status |
|---|---|---|---|
| PAYMENT_MEMBERSHIP-ADR01 | Approve this module DD as docs-complete and track runtime/sandbox evidence separately. | The user requested DD docs 100 percent without changing runtime code or claiming sandbox evidence. | Accepted |
| PAYMENT_MEMBERSHIP-ADR02 | Keep accepted product decisions as the module business contract. | Q-01..Q-18 are closed by user decision and recorded in the DD registry. | Accepted |
| PAYMENT_MEMBERSHIP-ADR03 | Use a server-generated immutable reference and manual VCB review for VietQR payments. | It gives Admin a stable reconciliation key while avoiding bank credentials, balance access, webhooks, and receipt collection. | Accepted |

## 13. Traceability Matrix

| BD/Requirement | Feature | Function | View | API | Test |
|---|---|---|---|---|---|
| BD sections 8.2, UC-15 | PAYMENT_MEMBERSHIP-F01 | PAYMENT_MEMBERSHIP-FN01 | PAYMENT_MEMBERSHIP-V01 | PAYMENT_MEMBERSHIP-API01 | PAYMENT_MEMBERSHIP-TC01 |
| BD sections 8.4, AC-07/AC-08/AC-20/AC-21, UC-16 | PAYMENT_MEMBERSHIP-F02 | PAYMENT_MEMBERSHIP-FN02 | PAYMENT_MEMBERSHIP-V02 | PAYMENT_MEMBERSHIP-API02 | PAYMENT_MEMBERSHIP-TC02 |

## 14. Approval Checklist

- [x] Scope and out-of-scope reviewed for DD docs completeness.
- [x] Business rules reviewed for DD docs completeness.
- [x] UI states reviewed for DD docs completeness.
- [x] API/schema/RLS contracts documented for implementation planning.
- [x] Product decisions answered or accepted as explicit implementation policy.

## 15. Accepted Product Decision Contract

| ID | Accepted Policy | Implementation Contract | Source |
|---|---|---|---|
| Q-03 | Commission is calculated from the listed package price. | Commission ledger stores listed_price, commission_rate_version, computed_points, payment_id, and immutable formula version. | User decision 2026-06-30 |
| Q-04 | Plus and FamilyPlus support monthly and yearly plans. Early renewal extends from current expiry; late renewal starts from Admin approval time; pending payment never grants rights. | Entitlement activation is created only by approved payment and calculates start/end from current active expiry or approval time. | User decision 2026-06-30 |
| Q-05 | Refund/cancel is allowed only within 24 hours after purchase. Points are reversed immediately in that window. Because conversion is also locked for 24 hours, there is no converted-then-reversed case. | Refund/cancel RPC requires approved payment age <= 24 hours, creates reversal ledger, and blocks conversion while payment is inside the hold window. | User decision 2026-06-30 |
| Q-11 | FamilyPlus commission is calculated only on the package owner portion. | Payment line items separate owner portion from dependent member portions; commission uses owner portion only. | User decision 2026-06-30 |
| Q-17 | All payments and transfers are manually reviewed and manually approved by Admin. Trusted recorder may only create pending evidence; only Admin approval creates payment_approved. | Payment write path separates evidence capture from approval; payment_approved requires Admin actor, reason/reference, idempotency, and audit. | User decision 2026-06-30 |
| Q-18 | Member scans Vietcombank QR, confirms the transfer, then an Admin with payments.write manually compares the reference and amount in VCB before approving or rejecting. No receipt, bank API, webhook, or in-app balance is used. | Supabase creates immutable NB + 12 uppercase hex reference, snapshots the ≤25-character ASCII transfer memo and recipient details, accepts confirmation only from auth.uid(), and activates entitlement only in Admin approval. | User decision 2026-07-31 |

### Implementation Evidence Backlog

| Evidence Area | Required evidence before production acceptance | DD blocker? |
|---|---|---|
| Runtime/test/sandbox | Sandbox payment approval, entitlement activation, idempotency, and provider evidence. | No - tracked outside DD completeness |
| Coding progress | Update only when code, tests, SQL/RPC, or sandbox evidence changes. | No |
| Production acceptance | Requires implementation workflow evidence and worklog command output. | No |
