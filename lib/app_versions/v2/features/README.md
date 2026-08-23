# V2 Features

Lifecycle: `Current`. Baseline: `25018e8`.

V2 là lớp authenticated capability trên trải nghiệm user dùng chung, không
thay thế V1. `v2RouterProvider` compose `v1Routes`, `v2Routes` và `v3Routes`.

## Trạng thái theo source

| Feature folder | Implementation | Ghi chú |
| --- | --- | --- |
| `auth` | `Implemented` | Login, register, verify, recovery/reset, callback, controller, repository và Supabase datasource có route runtime. |
| `cloud_sync` | `Implemented/Partial` | Local/remote datasource, merge repository và sync controller có consumer; E2E cần backend. |
| `health_modules` | `Placeholder` | Access resolver + coming-soon UI cho catalog M20-M29; chưa có business implementation từng module. |
| `health_scoring` | `Implemented` | SQLite data, calculator, providers và route `/v2/health-score`. |
| `home` | `Implemented` shell | Route `/v2`; shell không chứng minh mọi child feature hoàn chỉnh. |
| `membership_entitlement` | `Implemented` | Effective access đọc trusted Supabase contract. |
| `payments` | `Partial` | Manual membership payment/VietQR request flow; approval thuộc backend/Admin. |
| `personal_schedule_quota` | `Source-only` marker | Marker class vẫn `planned`; guard thật nằm ở `GeneratedPlanService` và trusted quota gateway. |
| `usage_quota` | `Implemented` contract | Trusted check/commit quota gateway được AI chat/plan runtime dùng. |
| `wellness_rewards` | `Partial` | Route, repository, local/remote datasource và secure voucher storage có source; RPC runtime chưa được suy ra là PASS. |

## Guardrails

- Feature mới đặt trong `lib/app_versions/v2/features/<feature_name>/`.
- Presentation gọi provider/controller, không gọi SQLite/Supabase trực tiếp.
- V2 không import trực tiếp V1 presentation/controller để tái sử dụng logic.
- Auth, entitlement, quota, payment và reward state phải fail closed khi
  Supabase chưa sẵn sàng.
- Một folder hoặc route tồn tại không đủ để gắn trạng thái `Implemented`.

Verification: static source only; Flutter/device/Supabase sandbox là
`UNVERIFIED` nếu không có command evidence riêng.
