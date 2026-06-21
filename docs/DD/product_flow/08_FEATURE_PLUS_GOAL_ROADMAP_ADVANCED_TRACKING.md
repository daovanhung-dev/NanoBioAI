# DD-PRODUCT-FLOW-FR-005 - Plus Goal Roadmap và Advanced Tracking

**BD nguồn:** BR-06, UC-09, UC-10, AC-06  
**Status:** Draft  
**Dependencies:** 03, 05, 06, 07, 13, 14, 15  

## 1. Mục tiêu và outcome

Plus kế thừa Free, bỏ quota AI Chat/tạo lịch trình Free, và mở planned capabilities: lộ trình riêng theo mục tiêu, tính toán cao hơn, theo dõi sức khỏe nâng cao.

## 2. Trigger / Preconditions

- User đã đăng nhập.
- Effective membership là Plus hoặc FamilyPlus.
- BD/DD bổ sung đã chốt chi tiết từng capability nâng cao trước implementation.

## 3. Input contract

| Field | Required | Type | Validation | Sensitive? |
|---|---:|---|---|---|
| Membership plan | Yes | enum | `plus` hoặc `family_plus` từ Supabase | No |
| Goal roadmap input | TBD | TBD | Cần BD/DD riêng | Yes |
| Advanced tracking input | TBD | TBD | Cần BD/DD riêng | Yes |

## 4. Output / Postconditions

- Plus không bị chặn bởi quota `ai_chat_message` và `personal_schedule_generation` của Free.
- Plus chỉ mở UI/route/use-case đã có DD Ready.
- FamilyPlus kế thừa Plus behavior nhưng thêm family boundary theo DD-PRODUCT-FLOW-FR-006.

## 5. Happy path

```text
1. App đọc effective access từ Supabase.
2. Nếu plan là Plus, gate cho phép feature Plus đã Ready.
3. AI Chat/schedule generation bỏ qua quota Free nhưng vẫn qua technical safety limit.
4. Roadmap/advanced tracking chỉ chạy khi DD chi tiết có Ready status.
```

## 6. Alternative and error flows

| Case | Detection | UI behavior | Technical behavior | Retry |
|---|---|---|---|---|
| Free mở Plus feature | access gate false | Mời nâng cấp | Chặn route/use-case | Sau upgrade |
| Plus subscription expired | effective access downgrade | Hiển thị theo plan mới | Server source wins | Refresh |
| Capability chưa có DD Ready | docs gate | Không code production | Block implementation | Tạo BD/DD |

## 7. Persistence and ownership

| Action | Target | Actor allowed | RLS/constraint |
|---|---|---|---|
| Read Plus entitlement | Supabase membership/entitlements | authenticated own access | server source |
| Write advanced data | TBD | Plus owner/family allowed | needs feature DD |

## 8. Layer responsibilities / affected files

| Layer | Responsibility | Proposed file |
|---|---|---|
| Router/access gate | Allow Plus route | v3 router/app shell |
| Provider/controller | Check effective access | membership/access providers |
| Domain feature | Goal roadmap/advanced tracking | `lib/app_versions/v3/features/*` |
| Data layer | Persist advanced data | TBD per feature DD |

## 9. Security / privacy

- Không mở Plus bằng local flag.
- Không thêm health tracking nâng cao khi chưa có privacy/security spec.
- Không đưa paid logic vào v1 guest/basic hoặc v2 Free.

## 10. Acceptance tests

- TC-PF-12: Plus không bị quota Free cho AI Chat/schedule.
- TC-PF-16: Free bị chặn khi mở Plus planned route/use-case.
- TC-PF-17: Expired/downgraded Plus không còn access khi Supabase trả Free.

## 11. Non-goals

- Không định nghĩa chi tiết medical/advanced tracking fields.
- Không định nghĩa billing/downgrade lifecycle ngoài Q-06.

## 12. Open decisions

| ID | Question | Owner | Impact |
|---|---|---|---|
| Q-06 | Plus/FamilyPlus kỳ hạn và hết hạn gói xử lý thế nào? | Product Owner | Access downgrade, quota migration |
| Q-05 | Score/advanced tracking formula nếu dùng score nâng cao? | Product Owner / Health Lead | Calculator và UI |

