# V3 Feature Registry

Lifecycle: `Current`. Baseline: `25018e8`.

| Folder | Status | Reachability |
| --- | --- | --- |
| `advanced_tracking` | `Partial` | Route `/v3/advanced-tracking`; provider/repository/datasource active behind paid gate. |
| `familyplus` | `Partial` | Route `/v3/familyplus`; provider/repository/datasource active behind FamilyPlus gate. |
| `home` | `Placeholder` | Route `/v3`; catalog “Sắp có”. |
| `advanced_health_tracking` | `Source-only` | `status = 'planned'`; không có consumer. |
| `family_members` | `Source-only` | `status = 'planned'`; không có consumer riêng. |
| `family_onboarding` | `Source-only` | `status = 'planned'`; không có consumer riêng. |
| `family_schedule` | `Source-only` | `status = 'planned'`; không có consumer riêng. |
| `goal_roadmap` | `Source-only` | `status = 'planned'`; không có consumer. |
| `premium_ai` | `Source-only` | `status = 'planned'`; không có consumer. |

Không dùng marker class làm evidence của business implementation. Khi một
planned module được nối runtime, cập nhật route/provider/repository/test và
registry này trong cùng thay đổi.
