# Domain - Notification / Reminder

## Source

- `lib/app_versions/v1/services/notifications/`
- `lib/app_versions/v1/features/lifestyle_schedule/`
- Related DAOs: notifications, meal plans, daily health tasks, lifestyle schedule items.
- Tests: `test/services/notifications/`, `test/features/lifestyle_schedule/`.

## Rules

- Initialize timezone before scheduling.
- Notification IDs must be stable and avoid unintended collisions.
- Payloads must include enough type/id/version data and invalid payload must not crash.
- Background actions cannot depend on `BuildContext`.
- Complete/skip actions update DB through service/DAO abstractions.
- Unit tests should cover mapper/payload/id/service logic, not real plugin delivery.

## Search

```powershell
rg "Notification|notification|payload|timezone|reminder|complete|skip|AndroidNotificationAction|background" lib/app_versions/v1/services/notifications lib/app_versions/v1/features test
```
