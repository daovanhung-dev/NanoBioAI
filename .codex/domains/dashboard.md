# Domain - Dashboard / Health Score

## Source

- `lib/app_versions/v1/features/dashboard/`
- Related: `daily_health_tracking/`, `lifestyle_schedule/`, `meal_plan/`, `lib/app_versions/v1/services/notifications/`
- Tests: `test/features/dashboard/`, related tracking/schedule tests.

## Rules

- Dashboard must read real data through provider/repository/datasource, not mock production data.
- Score/progress/timeline come from SQLite/Supabase-owned data; show empty state when data is missing.
- If completion/skip/write actions change data, refresh affected providers.
- Health score by membership must follow access rules from `access-membership-referral.md`.

## Search

```powershell
rg "dashboardProvider|dashboardDynamicProvider|DashboardHealthCalculator|timeline|dailyScore" lib/app_versions/v1/features/dashboard test/features/dashboard
rg "HealthTrackingLogsDao|DailyHealthTasksDao|LifestyleScheduleItemsDao|MealPlansDao|NotificationsDao" lib test
```
