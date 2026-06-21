# Domain - Daily Health Tracking

## Source

- `lib/app_versions/v1/features/daily_health_tracking/`
- `lib/core/storage/localdb/daos/health_tracking_logs_dao.dart`
- `lib/core/storage/localdb/tables/health_tracking_logs_table.dart`
- Tests: `test/features/daily_health_tracking/`.

## Rules

- Validate ranges for weight, sleep, water, steps, stress and related metrics.
- Avoid duplicate logs for the same metric/date when business rules expect one per day.
- Timestamp/date format must be consistent and timezone-aware.
- Dashboard must read real logs/tasks and not invent tracking data.

## Search

```powershell
rg "dailyHealthTracking|health_tracking|tracking_logs|weight|sleep|water|steps|stress|DailyHealthTasksDao|HealthTrackingLogsDao" lib/app_versions lib/core/storage/localdb test
```
