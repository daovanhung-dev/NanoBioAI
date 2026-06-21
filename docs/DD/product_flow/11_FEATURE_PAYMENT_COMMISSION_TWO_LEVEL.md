# DD-PRODUCT-FLOW-FR-008 - Payment Commission Hai Tầng

**BD nguồn:** Section 7.4..7.6, UC-14, UC-15, AC-08, AC-09, AC-10, AC-11  
**Status:** Draft  
**Dependencies:** 03, 10, 13, 15  

## 1. Mục tiêu và outcome

Khi payment mua/duy trì gói thành công từ trusted source, hệ thống tạo commission tối đa 2 tầng: 10% cho referrer trực tiếp và 5% cho referrer gián tiếp. Không tạo commission tầng 3.

## 2. Trigger / Preconditions

- Payment event từ backend/webhook/admin được xác nhận `succeeded`.
- Payer có referral relationship.
- Receiver Sale ở tầng tương ứng có status active theo policy.

## 3. Input contract

| Field | Required | Type | Validation | Sensitive? |
|---|---:|---|---|---|
| paymentEventId | Yes | UUID/provider event id | Unique, trusted source only | Yes |
| payerUserId | Yes | UUID | Existing user | Yes |
| amount/currency | Yes | integer/text | amount >= 0 | Yes |
| payment status | Yes | enum | `succeeded` with paid timestamp | Yes |
| referral chain | Derived | relationship rows | Max 2 commission levels | Yes |

## 4. Output / Postconditions

- Tầng 1: referrer trực tiếp nhận commission 10% nếu eligible.
- Tầng 2: referrer của referrer trực tiếp nhận 5% nếu eligible.
- Không tạo commission cho tầng 3 trở đi.
- Nếu B không thanh toán nhưng C thanh toán, commission từ C vẫn tạo cho B và A theo tầng 1/2.

## 5. Happy path

```text
1. Trusted payment source ghi payment event succeeded.
2. Backend/trigger tìm direct referral của payer.
3. Nếu direct Sale eligible, tạo commission level 1 với rate 10%.
4. Backend/trigger tìm indirect referral của direct referrer.
5. Nếu indirect Sale eligible, tạo commission level 2 với rate 5%.
6. Client chỉ đọc commission records liên quan.
```

## 6. Alternative and error flows

| Case | Detection | UI behavior | Technical behavior | Retry |
|---|---|---|---|---|
| Payment pending/failed | payment status | Không hiển thị commission mới | No commission | Khi succeeded |
| No referral | no relationship | Không có commission | Return no-op | No |
| Level 3 exists | depth > 2 | Không hiển thị payout beyond level 2 | No commission beyond level 2 | No |
| Duplicate webhook | unique provider event/idempotency | Không nhân đôi | Conflict/no-op | Safe retry |
| Refund/chargeback | future event | TBD | Requires reversal policy | Q-10 |

## 7. Persistence and ownership

| Action | Target | Actor allowed | RLS/constraint |
|---|---|---|---|
| Write payment event | `payment_events` | trusted backend/webhook/admin | client denied |
| Create commission | `commission_records` | trigger/backend/admin | unique per payment/receiver/level |
| Read commission | `commission_records` | receiver user | receiver only |
| Read payment | `payment_events` | payer user | payer only |

## 8. Layer responsibilities / affected files

| Layer | Responsibility | Proposed file |
|---|---|---|
| Backend/Supabase | Payment event ingestion, commission creation | Supabase SQL/Edge/backend |
| Repository/datasource | Read related commission summaries | `lib/sale_referral/*` |
| Presentation | Sale dashboard summary/history | `sale_dashboard` |
| Domain | Commission display model | sale_referral commission domain |

## 9. Security / privacy

- Flutter không được tự báo payment success.
- Không log raw payment webhook, PII, bank details hoặc payout info.
- Commission visibility phải giới hạn theo receiver.

## 10. Acceptance tests

- TC-PF-24: A giới thiệu B, B payment succeeded tạo 10% cho A.
- TC-PF-25: B giới thiệu C, C payment succeeded tạo 10% cho B và 5% cho A.
- TC-PF-26: Tầng 3 payment không tạo commission ngoài hai tầng.
- TC-PF-27: B không payment nhưng C payment vẫn tạo commission từ C cho B/A.
- TC-PF-28: Duplicate payment event không nhân đôi commission.

## 11. Non-goals

- Không định nghĩa payout/rút tiền.
- Không định nghĩa refund/chargeback reversal nếu Q-10 chưa chốt.

## 12. Open decisions

| ID | Question | Owner | Impact |
|---|---|---|---|
| Q-09 | Anti-fraud/refund/chargeback liên quan referral? | Product Owner / Ops | Commission validity |
| Q-10 | Ghi nhận chuyển khoản, đối soát, hủy hoa hồng, payout, báo cáo doanh thu? | Product Owner / Finance/Ops | Payment pipeline and commission lifecycle |

