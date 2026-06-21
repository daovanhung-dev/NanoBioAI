# DD-PRODUCT-FLOW-CTR-001 - Flutter Layer Contracts

**BD nguồn:** Section 9.1, all feature DDs  
**Status:** Draft  
**Dependencies:** 03, 05, 06, 13, `docs/DD/authentication/14_FLUTTER_LAYER_CONTRACTS.md`  

## 1. Mục tiêu

Ràng buộc cách Flutter triển khai product flow/membership/Sale để giữ Clean Architecture hiện có và không quyết định quyền ở presentation.

## 2. Scope / Out of scope

- In scope: route guard, provider/controller, repository/datasource boundary, state invalidation, copy/loading/error/empty.
- Out of scope: concrete widget design, paid purchase UI, payment provider SDK.

## 3. Actors và thành phần

| Layer | Responsibility | Không được làm |
|---|---|---|
| Presentation | Render state, collect input, call controller/provider | Không query SQLite/Supabase trực tiếp |
| Controller/provider | Validate state, call use-case/repository, expose typed state | Không hard-code membership/Sale truth |
| Repository | Domain contract for access/quota/sale/schedule | Không giữ UI state |
| Datasource | Call SQLite/Supabase/AI/notification services | Không map user-facing copy |
| Domain service | Effective access, quota result, score formula | Không phụ thuộc Flutter widgets |

## 4. Kiến trúc / flow tổng quát

```text
Widget/Page
-> Provider/Controller
-> Repository
-> Datasource
-> SQLite/Supabase/AI/Notification
```

## 5. Invariants / business rules

1. Route guard phải kiểm tra quyền cho module ngoài V1.
2. Use-case/controller phải kiểm tra quyền/quota trước tác vụ tốn AI hoặc paid feature.
3. Presentation không import DAO, datasource hoặc `core/storage/localdb`.
4. V2/v3 feature không import trực tiếp v1 presentation/controller.
5. Sale/referral nằm ở `lib/sale_referral/`, không trộn vào membership tier.
6. `core/` không import `app_versions/*`.

## 6. Data ownership và security

| Concern | Contract |
|---|---|
| Membership access | Read through repository/datasource backed by Supabase |
| Quota | Consume through trusted RPC/Edge/backend abstraction |
| Guest schedule | Local V1 only until auth/sync decision |
| Family subject | subjectId must be verified by data layer/RLS |
| Sale/payment/commission | read-only client access unless trusted backend endpoint |

## 7. Dependencies / integration points

- `lib/app_versions/v1/router/`, `lib/app_versions/v2/router/`, `lib/app_versions/v3/router/`
- `lib/app_versions/v2/features/membership_entitlement/`
- `lib/app_versions/v2/features/usage_quota/`
- `lib/app_versions/v3/features/*`
- `lib/sale_referral/`

## 8. Acceptance / links to test

- TC-PF-36: Static architecture checks find no presentation import of DAO/datasource/localdb.
- TC-PF-37: V2/V3/sale boundaries do not import forbidden presentation layers.
- TC-PF-38: Route + use-case both block unauthorized access.

## 9. Open decisions

- Concrete interfaces for quota consume RPC and Sale backend endpoints remain Draft until backend contract is approved.

