# Implementation Delta — M15 khu Điểm chăm sóc trong Admin

| Thuộc tính | Giá trị |
|---|---|
| Module | M15 `ADMIN_DASHBOARD` |
| Trạng thái DD gốc | Approved — giữ nguyên |
| Nguồn bổ sung | `BD-BIOAI-WELLNESS-REWARDS-001` |
| Ngày | 2026-07-13 |

## 1. Delta điều hướng và quyền xem

Admin có section riêng `Điểm chăm sóc` tại route
`/admin/wellness-rewards`. Section chỉ xuất hiện khi actor có
`wellness_rewards.read` hoặc quyền ghi tương ứng; route/backend vẫn phải từ chối
khi thiếu quyền, không dựa vào việc ẩn navigation.

Panel đọc dữ liệu tổng hợp an toàn cho:

- catalog ưu đãi và trạng thái mở/tắt;
- tồn kho tổng/khả dụng/đã cấp/đã loại;
- giao dịch đổi, trạng thái `Đã cấp`/`Đã hủy`;
- drill-down sang thao tác M16 khi có `wellness_rewards.write`.

Không trả mã voucher chưa cấp, raw proof path của người dùng khác, health data,
secret hoặc raw payload qua summary/Admin list.

## 2. Contract và implementation map

| ID delta | Contract/source |
|---|---|
| M15-DELTA-V01 | `AdminPanelSection.wellnessRewards`, label/summary/icon/route bằng tiếng Việt trong Admin shell. |
| M15-DELTA-FN01 | `admin_list_wellness_rewards(p_query, p_limit)` trả row phân loại offer/redemption và aggregate tồn kho an toàn. |
| M15-DELTA-PERM01 | `wellness_rewards.read` là quyền đọc độc lập; `wellness_rewards.write` mở các mutation M16. |
| M15-DELTA-UI01 | Stable code/permission/action/audit target được map sang tiếng Việt; unknown dùng fallback an toàn. |

Source-ready nằm trong Admin route/panel model/controller/datasource, feature
`lib/app_versions/admin/features/wellness_rewards/` và migration 16.

## 3. Bằng chứng và phần còn thiếu

- Reward client/Admin/cache/gateway tests: 38/38 PASS.
- Targeted analyze reward client/Admin: PASS.
- Localization/settings/image bundles và contract scan: PASS theo evidence phiên.
- Supabase static contract bundle 40 test, full `config.sql` rebuild trên
  PostgreSQL 18 tạm và local RLS/direct-ledger smoke: PASS.

Chưa có evidence từ dự án Supabase sandbox thật cho role matrix, bucket runtime,
audit-safe DTO hoặc dữ liệu tồn kho thật. Không claim dashboard/section này
production-ready trước khi migration 16 được deploy với feature flag tắt và smoke
bằng tối thiểu hai Admin role.
