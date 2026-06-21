# DD-PRODUCT-FLOW-FR-002 - Auth Membership Access Gate

**BD nguồn:** BR-04, UC-05, Section 9.1  
**Status:** Draft  
**Dependencies:** 03, 06, 08, 09, 10, 13, 14, `docs/DD/authentication/*`  

## 1. Mục tiêu và outcome

Sau đăng nhập, app đọc trạng thái membership từ Supabase/trusted source, dựng quyền hiệu lực cho Free/Plus/FamilyPlus và Sale status độc lập, rồi dùng quyền đó cho route, UI, use-case và quota.

## 2. Trigger / Preconditions

- Supabase Auth có session hợp lệ.
- `public.users`/membership rows đã được bootstrap.
- App cần mở route/module ngoài Guest V1 hoặc cần kiểm tra quota.

## 3. Input contract

| Field | Required | Type | Validation | Sensitive? |
|---|---:|---|---|---|
| Auth user id | Yes | UUID string | Must equal current Supabase session user | Yes |
| Membership plan | Yes | enum `free|plus|family_plus` | From Supabase only | No |
| Product access status | Yes | enum `guest|free|plus|family_plus` | Derived from auth + membership | No |
| Sale status | Yes | enum | From Supabase/server only | No |

## 4. Output / Postconditions

- App có `effective access` dùng chung cho route/UI/use-case/quota.
- Guest không được xem như Free nếu chưa có session.
- Sale status không thay đổi membership feature access.
- Local cache chỉ được dùng để hiển thị tạm, không quyết định quyền cao cấp.

## 5. Happy path

```text
1. User login/signup thành công.
2. Auth controller refreshes account state.
3. Repository/datasource đọc profile + membership từ Supabase.
4. Domain mapper dựng effective access.
5. Router/use-case/UI dùng effective access.
6. Nếu cần quota, chuyển sang DD Free quota.
```

## 6. Alternative and error flows

| Case | Detection | UI behavior | Technical behavior | Retry |
|---|---|---|---|---|
| Session missing/expired | Auth state | Đưa về đăng nhập | Clear user-scoped cache | Login lại |
| Membership read fails | Supabase error | Hiện lỗi thử lại | Không mở Plus/FamilyPlus | Retry refresh |
| Local cache says Plus but server says Free | Server response | Hiển thị theo server | Override cache | No |
| Sale active but Free plan | Effective access has both axes | Sale UI only if sale route allowed | Không mở Plus feature | No |

## 7. Persistence and ownership

| Action | Target | Actor allowed | RLS/constraint |
|---|---|---|---|
| Read own membership | `membership_subscriptions`, `effective_user_access` | authenticated user | own rows only |
| Update tier/status | membership tables/users read-model | trusted backend/admin | client denied |
| Cache display info | local provider/cache | client | not source of truth |

## 8. Layer responsibilities / affected files

| Layer | Responsibility | Proposed file |
|---|---|---|
| Presentation | Show friendly gate/upgrade/login entry | V1/V2 pages and shared widgets |
| Controller/provider | Account state and access state | `v2/features/auth`, `membership_entitlement` |
| Repository/datasource | Read Supabase membership/access | `lib/services/supabase`, v2 data layer |
| Domain | Effective access mapper | v2 membership/access domain |
| Router | Route guard by effective access | `v1_router`, `v2_router`, future `v3_router` |

## 9. Security / privacy

- Không trust route param, local SQLite, SharedPreferences hoặc UI hidden state.
- Không đưa service role key vào Flutter.
- Error UI không tiết lộ table/query/RLS details.

## 10. Acceptance tests

- TC-PF-05: Free/Plus/FamilyPlus accounts map đúng effective access.
- TC-PF-06: Guest mở route ngoài V1 bị đưa tới auth entry.
- TC-PF-07: Local cache cao hơn server không mở paid feature.
- TC-PF-08: Sale active không làm thay đổi membership feature access.

## 11. Non-goals

- Không triển khai payment/subscription purchase flow.
- Không định nghĩa giá, kỳ hạn, downgrade policy; phụ thuộc Q-06.

## 12. Open decisions

| ID | Question | Owner | Impact |
|---|---|---|---|
| Q-06 | Plus/FamilyPlus theo tháng/năm/hình thức khác; hết hạn thì quyền đổi thế nào? | Product Owner | Subscription lifecycle, downgrade, quota reset |

