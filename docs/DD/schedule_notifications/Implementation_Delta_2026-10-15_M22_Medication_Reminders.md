# M09 Implementation Delta — M22 Local Medication Reminders

## Decision and boundary

This delta connects the user-approved M22-F01/F02 local Guest reminder slice
to the existing M09 notification bootstrap and OS scheduler. M22 remains the
owner of the medicine schedule records; M09 only reconciles daily OS alerts.

The schedule is local to the active device owner, repeats at each distinct
enabled minute of day, and coalesces multiple medicines at the same minute into
one notification. Title/body are generic and payload contains only the owner,
minute, type, and settings route. A valid tap opens Notification Settings after
checking the current owner and enabled local row. No `notifications` history,
SyncOutbox, cloud snapshot, Supabase table, or action event is created.

The existing notification master switch pauses OS delivery without changing
per-medicine enabled state. Permission is requested after onboarding saves the
first schedule. Denial keeps the local row and is recoverable from Settings.
Scheduling uses the initialized device timezone and existing
`Asia/Ho_Chi_Minh` fallback.

## Source map

- `lib/app_versions/v1/services/notifications/reminder_notification_scheduler.dart`
- `lib/app_versions/v1/services/notifications/medication_reminder_coordinator.dart`
- `lib/app_versions/v1/services/notifications/notification_bootstrap.dart`
- `lib/app_versions/v1/features/medication_reminders/`
- `lib/app_versions/v1/features/settings/presentation/pages/notification_settings_page.dart`

## Verification

- Source analysis: PASS for affected Flutter/Dart modules.
- Medication coordinator tests: PASS for coalescing, generic payload, refresh,
  owner validation, and settings navigation.
- SQLite migration/repository/onboarding/sync tests: authored but could not run
  in this environment because `sqflite_common_ffi` cannot load `libsqlite3.so`.
- Real-device notification delivery and permission behavior: UNVERIFIED.

No M09 cloud or server contract changes are introduced.
