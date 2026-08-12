# Views — PAYMENT_MEMBERSHIP / Thanh toán, xác minh và quyền gói

## 0. View Inventory

| ID | View | Route | Actor | Data Source | Status |
|---|---|---|---|---|---|
| PAYMENT_MEMBERSHIP-V01 | Payment checkout | `/v2/payments?plan=plus|family_plus` | Member | Payment controller/RPC + local payer name | Implemented |
| PAYMENT_MEMBERSHIP-V02 | Payment review queue | `/admin/payments` + Admin alert | Finance/Super Admin | Admin payment RPC | Implemented |

## 1. Navigation Map

- Free AI Chat quota exceeded -> `Nâng cấp Plus` -> `/v2/payments?plan=plus`.
- Free schedule quota exceeded -> prompt `Nâng cấp Plus` -> same route.
- Plus-required gates -> Plus preselected.
- FamilyPlus locked surface -> FamilyPlus preselected.
- Unknown/malformed plan query -> Plus preselected.
- UI navigation never establishes paid access.

## 2. PAYMENT_MEMBERSHIP-V01 — Payment checkout

### Components

- Plan: Plus / FamilyPlus.
- Cycle: monthly / yearly.
- Create QR action.
- Server response details: payer full name snapshot, plan, cycle, amount, currency, bank, account, account owner, status.
- Canonical reconciliation key: exact NB + 12 hex.
- QR + copy action only use canonical NB reference; legacy/free-form `transfer_memo` is ignored for QR/copy.
- `Hủy yêu cầu` only when `awaiting_transfer`.
- `Đã chuyển khoản` only when awaiting + valid QR details.

### Required states

| State | UI behavior |
|---|---|
| Missing payer name | Block create and guide profile update. |
| Awaiting transfer | Show QR/details/copy/cancel/confirm. |
| Pending review | Hide QR/cancel/confirm; show waiting status; refresh on app resume and every 30 seconds while open. |
| Succeeded | Show approved status; trusted access refresh + cloud projection refresh runs outside UI. |
| Failed/rejected | Show review reason safely; allow new request when backend state permits. |
| Canceled | Show terminal canceled state; user may create a new request. |
| Invalid transfer reference/details | Fail closed: no QR and no confirm action. |

## 3. PAYMENT_MEMBERSHIP-V02 — Payment review queue

### Authorization

Only Finance/Super sees payment navigation/alert/queue. Support/Content/Operations do not get payment section even if a historical role mapping contains wildcard permission.

### Components

- Pending review alert count; refresh every 30 seconds, resume and manual refresh.
- Queue/detail: NB reference/memo, payer snapshot, plan/cycle, amount/currency, transfer-confirmed timestamp.
- Approve / reject actions only for reviewable state.
- Reason field required for both decisions.
- Approve dialog includes mandatory checkbox:
  `Đã đối chiếu giao dịch trong ứng dụng VCB` and explicitly covers NB code, amount and transfer content.

### Safety

- UI checkbox is not sufficient: backend also requires Finance/Super reviewer role and `p_transfer_verified=true` for approve.
- No bank API/balance/receipt is displayed or fetched.

## 4. View Acceptance Evidence

- Route/gate source contract tests cover Plus/FamilyPlus preselection.
- Payment widget tests cover canonical QR/copy, cancellation, pending polling/resume and non-canonical fail-closed behavior.
- Admin widget/model tests cover Finance/Super allow and non-financial role denial + VCB confirmation payload.
- Real VCB scan/manual reconciliation remains UAT pending.
