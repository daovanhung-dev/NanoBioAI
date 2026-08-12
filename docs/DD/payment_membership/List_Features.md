# List Features — PAYMENT_MEMBERSHIP / Thanh toán, xác minh và quyền gói

## 0. Document Information

| Field | Value |
|---|---|
| Module | PAYMENT_MEMBERSHIP |
| Overall | [Overall.md](Overall.md) |
| Version | v1.4 |
| Last Updated | 2026-08-12 |

## 1. Feature Inventory

| ID | Feature | Goal | Actor | Trigger | Functions | Views | Status |
|---|---|---|---|---|---|---|---|
| PAYMENT_MEMBERSHIP-F01 | VietQR mua/gia hạn gói | Shared upgrade CTA -> request VietQR -> optional cancel / confirm -> pending review; không cấp quyền trước approve. | Member | Quota/gate hoặc mở payment | FN01, FN03, FN04 | V01 | Source-ready; sandbox/UAT pending |
| PAYMENT_MEMBERSHIP-F02 | Manual payment review | Finance/Super đối chiếu VCB rồi approve/reject có audit; finite renewal/switch. | Finance Admin / Super Admin | pending_review alert/queue | FN02 | V02 | Source-ready; sandbox/UAT pending |

## 2. Dependencies Between Features

| Source | Target | Data/state | Rule |
|---|---|---|---|
| Plus/FamilyPlus gate | F01 | canonical plan query | Route param chỉ chọn UI; backend quyết định price/access. |
| F01 confirm | F02 | pending_review payment | Không cấp quyền. |
| F02 approve | Membership/Quota | succeeded + subscription | Trusted backend activates access. |
| F02 approve | Auth profile sync / Dashboard | server user projection | Cloud pull updates SQLite label; client không tự set plan. |

## 3. PAYMENT_MEMBERSHIP-F01 — VietQR mua/gia hạn gói

### Main flow

1. Entry point dùng shared `buildMembershipUpgradeRoute`; invalid plan fallback Plus.
2. User chọn plan/cycle; local profile phải có full name.
3. Backend lock payer và nếu đã có open request thì trả conflict để UI load request hiện tại.
4. Backend đọc server config, sinh exact `NB + 12 hex`; memo bằng đúng reference.
5. UI render server-owned amount/bank/account/name/reference và QR.
6. `awaiting_transfer`: cho phép `Hủy yêu cầu` hoặc `Đã chuyển khoản`.
7. Cancel -> `canceled`; confirm -> `pending_review`.
8. Pending review refresh khi resume + 30 giây khi screen mở.
9. Chỉ khi response thành `succeeded` mới refresh trusted access và local read-model.

### Alternative/error cases

| Case | Expected behavior |
|---|---|
| Missing payer name | Không tạo QR; hướng dẫn cập nhật profile. |
| Invalid/non-canonical reference | Không render confirmable QR / không copy legacy memo. |
| Existing open request | Load request hiện tại; không tạo song song. |
| Cancel after confirmation | Backend reject; UI không có cancel CTA. |
| Pending/rejected/canceled | Không mở paid access. |

## 4. PAYMENT_MEMBERSHIP-F02 — Finance/Super manual review

### Main flow

1. Chỉ Finance/Super nhận pending-review alert và mở `/admin/payments`.
2. Queue hiển thị payer snapshot, plan/cycle, amount, NB reference/memo và transfer-confirmed time.
3. Admin đối chiếu mã NB + số tiền + nội dung trong VCB.
4. Approve bắt buộc checkbox reconciliation + reason; reject bắt buộc reason.
5. Backend review idempotent, ghi actor/time/reason/audit.
6. Approve: same-plan renewal nối từ active expiry hoặc cross-plan switch ngay; tháng/năm theo Asia/Ho_Chi_Minh.
7. Legacy active paid thiếu `ends_at`: block approval để controlled data repair.

### Permission cases

| Role | Queue/alert/review |
|---|---|
| finance_admin | Allow |
| super_admin | Allow |
| support_admin | Deny |
| content_admin | Deny |
| operations_admin | Deny |

## 5. Acceptance Evidence

Automated source covers canonical route/reference, cancel/poll, trusted refresh, Admin permission and SQL contract. `test/docs/fixtures/supabase_membership_payment_hardening_smoke.sql` provides rollback-only executable acceptance; actual Supabase sandbox execution, two-session concurrency and VCB UAT remain pending.
