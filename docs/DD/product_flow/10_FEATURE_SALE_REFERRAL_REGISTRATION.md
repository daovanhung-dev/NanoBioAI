# DD-PRODUCT-FLOW-FR-007 - Sale Referral Registration

**BD nguồn:** Section 7.1..7.3, UC-12, UC-13  
**Status:** Draft  
**Dependencies:** 03, 05, 11, 13, 14, 15  

## 1. Mục tiêu và outcome

Thiết kế trục Sale/referral độc lập với membership để user có Sale status, referral code và quan hệ giới thiệu tối đa tính commission 2 tầng.

## 2. Trigger / Preconditions

- User đã tạo tài khoản thành công.
- Người được giới thiệu nhập referral code theo flow được duyệt.
- Người giới thiệu có Sale active theo trusted source.

## 3. Input contract

| Field | Required | Type | Validation | Sensitive? |
|---|---:|---|---|---|
| referralCode | Yes for referred flow | text | Active code, not self, not already bound | Yes |
| referrerUserId | Derived | UUID | From referral code server-side | Yes |
| referredUserId | Yes | UUID | Current auth user | Yes |
| saleStatus | Yes | enum | From `sale_profiles`/trusted source | No |

## 4. Output / Postconditions

- Referred user có tối đa một referral relationship.
- Sale active có thể xem referral data được phép.
- Referral relationship dùng cho payment commission DD-PRODUCT-FLOW-FR-008.
- Sale role không mở thêm membership features.

## 5. Happy path

```text
1. User tạo tài khoản và nhập referral code.
2. Backend/RPC kiểm tra code active và referrer Sale active.
3. Backend/RPC tạo referral relationship idempotent.
4. App đọc Sale/referral state liên quan.
5. Commission chỉ phát sinh khi có payment success theo DD-PRODUCT-FLOW-FR-008.
```

## 6. Alternative and error flows

| Case | Detection | UI behavior | Technical behavior | Retry |
|---|---|---|---|---|
| Invalid/revoked code | server validation | Báo mã chưa hợp lệ | Không tạo relationship | Nhập mã khác |
| Self-referral | server validation/constraint | Báo không thể dùng mã này | Reject | No |
| Referred already bound | unique constraint | Hiển thị quan hệ đã ghi nhận | No overwrite unless policy exists | No |
| Sale suspended | sale status | Báo mã không khả dụng | Reject | Sau khi active |

## 7. Persistence and ownership

| Action | Target | Actor allowed | RLS/constraint |
|---|---|---|---|
| Read own sale profile | `sale_profiles` | sale user | own row |
| Read own referral code | `referral_codes` | sale user | own active/revoked codes |
| Create relationship | `referral_relationships` | trusted backend/RPC | no self, one referred user |
| Read relationship | `referral_relationships` | referrer or referred | related only |

## 8. Layer responsibilities / affected files

| Layer | Responsibility | Proposed file |
|---|---|---|
| Presentation | Referral code input/status, Sale dashboard entry | `lib/sale_referral/features/*` |
| Controller/provider | Sale/referral state | sale_referral providers |
| Repository/datasource | Trusted backend/Supabase calls | sale_referral data layer |
| Domain | Relationship validation result | sale_referral domain |

## 9. Security / privacy

- Không ghi referral relationship trực tiếp từ Flutter table insert.
- Không hiển thị thông tin PII của referral tree nếu policy chưa duyệt.
- Không log mã/referral tree nhạy cảm.

## 10. Acceptance tests

- TC-PF-21: Active Sale code gắn được relationship tầng 1.
- TC-PF-22: Self-referral bị chặn.
- TC-PF-23: Sale suspended/revoked code không tạo relationship.

## 11. Non-goals

- Không định nghĩa quy trình duyệt Sale hoặc điều kiện duy trì Sale nếu Q-08 chưa chốt.
- Không định nghĩa edit/change referral code nếu Q-09 chưa chốt.

## 12. Open decisions

| ID | Question | Owner | Impact |
|---|---|---|---|
| Q-08 | Điều kiện trở thành Sale và duy trì/khóa Sale? | Product Owner / Ops | Sale approval/suspension |
| Q-09 | Referral code có đổi sau khi gắn không; anti-fraud/self/duplicate/refund policy? | Product Owner / Ops | Relationship immutability, fraud controls |

