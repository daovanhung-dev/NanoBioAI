# Domain - Lifestyle Schedule / Timeline

## Source

- `lib/app_versions/v1/features/lifestyle_schedule/`
- `lib/app_versions/v1/services/notifications/` when reminder/action changes.
- Meal/daily task DAO/service when schedule is built from those sources.
- Tests: `test/features/lifestyle_schedule/`, `test/services/notifications/`.

## Rules

- Schedule items need clear date/time, source type, status, and sort order.
- Status flow is `pending -> completed` or `pending -> skipped`.
- Refresh/regeneration must avoid duplicate items for the same date/time/source.
- Notification ID should map stably from schedule item or deterministic source.
- Timeline is sorted by time and must not invent data.

## Search

```powershell
rg "lifestyleSchedule|lifestyle_schedule|schedule_items|TimelineBuilder|pending|completed|skipped|hydrate|sleep" lib/app_versions lib/services test
```
