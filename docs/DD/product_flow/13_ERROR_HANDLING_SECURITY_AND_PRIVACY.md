# DD-PRODUCT-FLOW-CROSS-001 - Error Handling, Security và Privacy

**BD nguồn:** Section 9, Section 12, all BR/AC  
**Status:** Draft  
**Dependencies:** 03, all feature DDs, `.codex/playbooks/ui_nami.md`  

## 1. Mục tiêu

Đặt rule chung cho lỗi, quyền, dữ liệu nhạy cảm và copy Nami trong product flow/membership/Sale để implementation không mở sai quyền hoặc lộ dữ liệu.

## 2. Scope / Out of scope

- In scope: route/use-case guard, quota fail closed, Supabase/RLS source of truth, safe logging, user-facing error copy, health/payment/referral privacy.
- Out of scope: legal policy chi tiết, consent text pháp lý, refund/payout accounting workflow.

## 3. Actors và thành phần

| Actor/component | Responsibility | Boundary |
|---|---|---|
| UI | Hiển thị lỗi thân thiện, không lộ technical terms | Không quyết định quyền |
| Controller/use-case | Chặn trước tác vụ tốn tài nguyên/paid | Không bypass server source |
| Repository/datasource | Map lỗi typed/safe | Không swallow lỗi dữ liệu quan trọng |
| Supabase/backend | RLS, quota, payment, commission | Không lộ service role |

## 4. Kiến trúc / flow tổng quát

```text
UI action
-> controller validates local state
-> effective access/quota check
-> repository/datasource call
-> typed success/error
-> Nami copy + safe logging
```

## 5. Invariants / business rules

1. Paid/Sale/payment action fail closed khi không đọc được trusted source.
2. UI ẩn nút không thay thế route/use-case/backend guard.
3. Client không chứa API key secret, service role, payment success override hoặc commission override.
4. Error copy không nói `database`, `table`, `query`, `RLS`, `exception`, `stack trace`, `parser`.
5. Logs chỉ ghi prefix/module, status, error type; không ghi health profile, payment raw event, referral tree raw data.

## 6. Data ownership và security

| Data | Risk | Rule |
|---|---|---|
| Health profile/schedule | Sensitive health data | Subject/user boundary and minimal logging |
| Membership/quota | Paid access abuse | Server source only |
| Referral tree | PII/business sensitive | Related-user visibility only |
| Payment event | Financial sensitive | Trusted backend only |
| Commission | Financial sensitive | Receiver visibility only |

## 7. Dependencies / integration points

- `docs/supabase/06-rls-policy-matrix.md`
- `docs/DD/authentication/13_ERROR_HANDLING_AND_DATA_RECOVERY.md`
- `.codex/playbooks/ui_nami.md`
- `.codex/playbooks/access_membership_referral.md`

## 8. Acceptance / links to test

- TC-PF-33: Access/quota source unavailable blocks paid/resource action.
- TC-PF-34: Logs do not contain raw health/payment/referral data.
- TC-PF-35: User-facing errors do not expose internal technical terms.

## 9. Open decisions

- Q-07, Q-09, Q-10 require privacy/legal/ops decisions before FamilyPlus sharing and payment/commission production launch.

