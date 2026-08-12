# Overall — PAYMENT_MEMBERSHIP / Thanh toán, xác minh và quyền gói

## 1. Document Information

| Attribute | Value |
|---|---|
| Module Code | PAYMENT_MEMBERSHIP |
| BD Module | M13 |
| Version | v1.4 |
| Status | Approved - DD docs complete; sandbox/UAT acceptance pending |
| Source BD | BD-BIOAI-PRODUCT-FLOW-002 + approved M13 VietQR hardening delta 2026-08-12 |
| Last Updated | 2026-08-12 |

## 2. Business Goal

Hoàn thiện luồng nâng cấp Plus/FamilyPlus qua VietQR mà không tạo gói “VIP” mới. Quyền trả phí chỉ đến từ Supabase sau Finance/Super Admin review thành công.

Luồng chuẩn:

`Chạm giới hạn/quyền -> gợi ý nâng cấp -> QR Vietcombank -> khách xác nhận đã chuyển -> Finance/Super Admin đối chiếu VCB -> duyệt -> quyền gói có hiệu lực`

## 3. Module Scope

### In Scope

- Shared upgrade CTA cho quota/gate Plus/FamilyPlus hiện có.
- `/v2/payments?plan=plus|family_plus`, invalid value fallback Plus ở UI.
- Server-owned price/bank/reference; VietQR memo chỉ chứa mã NB bất biến.
- Create/get/confirm/cancel owner-scoped payment request.
- Một open request trên mỗi user với lock + unique constraint.
- Poll/resume refresh khi chờ duyệt; trusted access + local membership projection refresh sau `succeeded`.
- Finance/Super-only Admin alert/queue/review, VCB verification confirmation, reason/idempotency/audit.
- Finite subscription: same-plan renewal, immediate Plus ↔ FamilyPlus switch, calendar month/year.
- Non-destructive Supabase migration + `config.sql` rebuild contract + acceptance tests.

### Out of Scope

- Bank API, webhook, balance integration, automatic payment confirmation.
- Upload receipt/biên lai.
- Production rollout trong đợt này.
- Tự sửa/đoán hạn cho legacy paid subscription thiếu `ends_at`.

## 4. Roles and Permissions

| Role | Permission in M13 | Limitation |
|---|---|---|
| Member | Tạo/đọc/xác nhận/hủy request của chính mình. | Không ghi trực tiếp payment/subscription/quota; không tự cấp quyền. |
| Finance Admin | Xem alert/queue, đối chiếu VCB, approve/reject. | Bắt buộc reason; approve bắt buộc xác nhận reconciliation. |
| Super Admin | Như Finance Admin. | Bắt buộc cùng backend policy/audit. |
| Support Admin | Không xem/không review payment. | Backend và UI đều deny. |
| Content Admin | Không xem/không review payment. | Backend và UI đều deny. |
| Operations Admin | Không xem/không review payment. | Backend và UI đều deny. |
| System | Enforce ownership, transition, idempotency, finite access, audit. | Không tin route/local metadata để cấp quyền. |

## 5. Primary Entities/Data

| Entity | Purpose | Important attributes |
|---|---|---|
| Payment Event | Bằng chứng/yêu cầu thanh toán | payer, plan, cycle, amount, status, immutable NB reference, payer snapshot, bank snapshot |
| Membership Subscription | Nguồn quyền trả phí | plan, status, starts_at, ends_at, current_period_start/end, source payment |
| Admin Audit Event | Truy vết review | actor, decision, reason, payment, transition, superseded subscriptions, time |
| Effective User Access | Trusted read-model | current membership plan / product access |

## 6. States and State Transitions

### Payment

`awaiting_transfer -> pending_review -> succeeded | failed`

`awaiting_transfer -> canceled` chỉ do owner trước khi xác nhận chuyển khoản.

Legacy `pending` vẫn review được để tương thích migration, nhưng request mới không tạo trạng thái này.

### Subscription

- New purchase: tạo `active` với finite period.
- Same plan: gia hạn row hiện tại từ expiry còn hiệu lực.
- Cross plan: cancel/supersede active khác plan ngay lúc duyệt rồi activate plan mới.
- Legacy active paid + `ends_at IS NULL`: block approval.

## 7. Business Rules

| ID | Rule | Criticality |
|---|---|---|
| PAYMENT_MEMBERSHIP-BR01 | Create/confirm/pending request không kích hoạt Plus/FamilyPlus. | Mandatory |
| PAYMENT_MEMBERSHIP-BR02 | Chỉ Admin approve làm payment `succeeded` và tạo/gia hạn/chuyển subscription. Reject không tạo quyền. | Mandatory |
| PAYMENT_MEMBERSHIP-BR03 | `transfer_reference` phải khớp `^NB[0-9A-F]{12}$`; `transfer_memo = transfer_reference`. Payer name/plan/cycle không nằm trong memo. | Mandatory |
| PAYMENT_MEMBERSHIP-BR04 | “Đã chuyển khoản” chỉ owner gọi được và chỉ `awaiting_transfer -> pending_review`. | Mandatory |
| PAYMENT_MEMBERSHIP-BR05 | Chỉ Finance/Super review; approve bắt buộc xác nhận đã đối chiếu mã NB, số tiền, nội dung trong VCB; mọi quyết định có reason/audit. | Mandatory |
| PAYMENT_MEMBERSHIP-BR06 | Owner chỉ hủy được `awaiting_transfer`; `canceled` replay idempotent; pending_review không hủy được. | Mandatory |
| PAYMENT_MEMBERSHIP-BR07 | Mỗi payer tối đa một open manual membership request (`awaiting_transfer`/`pending_review`); lock transaction + partial unique index là backstop. | Mandatory |
| PAYMENT_MEMBERSHIP-BR08 | Tháng = 1 tháng lịch, năm = 1 năm lịch theo `Asia/Ho_Chi_Minh`; same-plan renewal nối từ active `ends_at`; cross-plan switch hiệu lực ngay; legacy thiếu `ends_at` fail closed. | Mandatory |
| PAYMENT_MEMBERSHIP-BR09 | Client không ghi trực tiếp payment/subscription/quota và không hard-code giá làm nguồn quyết định. | Mandatory |

## 8. Overall Operational Flow

1. Gate/quota xác định plan đề xuất và điều hướng bằng shared upgrade helper.
2. Payment screen chuẩn hóa `plan`; người dùng chọn Plus/FamilyPlus và monthly/yearly.
3. App đọc họ tên local chỉ để gửi snapshot hiển thị; backend vẫn dùng `auth.uid()` làm owner.
4. `create_membership_payment_request` lock payer, chặn open request khác, đọc giá/ngân hàng server config, sinh `NB + 12 hex`, đặt memo đúng bằng reference.
5. UI dựng VietQR từ response server; chỉ mã NB được copy/encode.
6. Owner có thể hủy khi `awaiting_transfer`, hoặc chuyển tiền và bấm “Đã chuyển khoản” để sang `pending_review`.
7. Khi pending_review, payment screen refresh khi resume và mỗi 30 giây khi đang mở.
8. Chỉ Finance/Super thấy alert/queue. Admin xem payer/gói/cycle/amount/reference/confirmed time, tự đối chiếu VCB rồi nhập reason; approve phải tick reconciliation.
9. Backend review idempotent: reject -> failed; approve -> finite subscription và payment succeeded + audit.
10. Client thấy `succeeded` thì invalidate trusted effective access; sau đó dùng authenticated cloud-sync hiện có kéo `users.subscription_tier` về SQLite và invalidate Dashboard. Client không tự set plan.

## 9. Integrations and Dependencies

| Dependency | Purpose | Failure Behavior |
|---|---|---|
| Supabase Auth | Owner/Admin actor | Fail closed. |
| System config | Price + Vietcombank recipient | Missing/invalid config blocks create. |
| SQLite profile | Payer full name prerequisite/display snapshot | Missing name blocks QR creation; không tạo quyền. |
| Membership entitlement | Trusted access | Pending/cancel/reject không đổi quyền. |
| Cloud sync + Dashboard | Đồng bộ local subscription label sau succeeded | Trusted effective access vẫn là authority; projection sync retry được. |
| Admin/Audit | Reconciliation/review trace | Sensitive review must fail if backend policy/audit fails. |
| VietQR | Client-side QR encoding từ server response | Invalid/non-canonical reference fail closed, không render confirmable QR. |

## 10. Non-Functional Requirements

- Security: owner scope + Admin role scope + RLS/table grants + RPC validation.
- Integrity: idempotency + payer lock + unique open-request index + finite subscription periods.
- Privacy: payer name là display/reconciliation metadata, không nằm trong memo; không lộ raw technical data cho UI không cần thiết.
- Resilience: projection refresh failure không biến client thành authority; effective access luôn reload từ trusted backend.
- Auditability: decision, actor, time, reason, reconciliation flag, transition và superseded subscription IDs được lưu/audit.

## 11. Risks, Assumptions, and Decisions

| ID | Type | Content | Status |
|---|---|---|---|
| PAYMENT_MEMBERSHIP-RISK01 | Acceptance | Supabase sandbox/RLS/two-session concurrency chưa có evidence trong phiên patch này. | Open |
| PAYMENT_MEMBERSHIP-RISK02 | UAT | Chưa quét/đối soát QR bằng app VCB trong phiên patch này. | Open |
| PAYMENT_MEMBERSHIP-ASSUMPTION01 | Product | Không webhook/API ngân hàng/upload receipt; manual VCB review là canonical flow. | Active |
| PAYMENT_MEMBERSHIP-Q18 | Decision | Mã NB là reconciliation key duy nhất và memo duy nhất; Finance/Super review. | Accepted 2026-08-12 |

## 12. ADR Summary

| ID | Decision | Status |
|---|---|---|
| PAYMENT_MEMBERSHIP-ADR01 | Không tạo plan VIP; chỉ Plus/FamilyPlus. | Accepted |
| PAYMENT_MEMBERSHIP-ADR02 | Reference-only VietQR memo; payer name tách khỏi transfer content. | Accepted |
| PAYMENT_MEMBERSHIP-ADR03 | Finance/Super-only payment review cả backend/UI. | Accepted |
| PAYMENT_MEMBERSHIP-ADR04 | Paid access finite và calendar-based; legacy missing expiry không được đoán. | Accepted |
| PAYMENT_MEMBERSHIP-ADR05 | Sau approve, client refresh trusted access + existing cloud projection, không tự cấp quyền. | Accepted |

## 13. Traceability Matrix

| Requirement | Runtime / SQL | Test evidence source |
|---|---|---|
| Shared upgrade route | core membership helper + V1/V2/V3 gates | membership_upgrade_route_test + membership_upgrade_gate_contract_test |
| Exact NB-only QR | payment model + M13 SQL | membership_payment_test/page_test + Supabase contract/smoke |
| Cancel/open-request | payment controller/repository + cancel/create RPC | controller tests + rollback SQL smoke |
| Pending-review refresh | payment page lifecycle/timer | payment page widget test |
| Trusted access refresh | payment controller + cloud sync + Dashboard provider | payment controller test |
| Finance/Super-only review | Admin model/UI + reviewer SQL functions | Admin tests + rollback SQL smoke |
| Renewal/switch/finite period | admin_review_payment | Supabase contract + rollback SQL smoke |
| RLS/direct writes | grants/RLS | rollback SQL smoke; sandbox execution pending |

## 14. Approval Checklist

- [x] Product decisions closed for coding.
- [x] Source/SQL contract defined.
- [x] Static/widget/unit test source added for hardening delta.
- [x] Rollback-only executable SQL acceptance script added.
- [ ] Run targeted Flutter tests/analyze in a full checkout.
- [ ] Execute SQL smoke in disposable Supabase local/sandbox.
- [ ] Run true two-session concurrent create test.
- [ ] Run VCB QR scan/manual reconciliation UAT.
- [ ] Production rollout — explicitly out of scope for this iteration.

## 15. Implementation Evidence Backlog

| Evidence Area | Required before production acceptance |
|---|---|
| Flutter | Targeted format/analyze/test PASS on full checkout. |
| Supabase | Migration/config execution, RLS/direct-write/reviewer/transition smoke PASS in disposable sandbox. |
| Concurrency | Two authenticated sessions prove only one open request per payer. |
| Bank UAT | QR resolves correct VCB account/amount and exact NB-only content; Finance/Super can manually reconcile and approve. |
| Docs/worklog | Record exact commands/results; keep NB-RISK-001 open until external evidence exists. |
