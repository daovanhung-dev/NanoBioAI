# TODO — Fix NanoBio project-wide audit

## Source issue

- `docs/issues/project-wide-audit/001-issue-project-wide-audit.md`
- Baseline: `7b2b90d5e0946721c2ac78363100e48a09f2032a`

## Fix goal

Close all seven confirmed findings without introducing unrelated product behavior.
Preserve the project dependency direction `Presentation -> Provider/Controller -> Repository -> Datasource -> DAO/API` and existing completion/reward guards.

## Product decisions locked for this fix

- NB-AUD-005 uses **Defer/Snooze**, not true skip.
- User-facing action remains **“Để sau”**.
- Defer duration is **30 minutes**.
- Source schedule/task remains pending and receives no Health Score or Wellness Point from defer.
- Legacy notification action id `skipped` is accepted only as backward-compatible input and normalized to `defer`.
- M30 Nabi notification defer remains its existing 24-hour behavior and is independent from M09 schedule-reminder defer.

## Ordered checklist

- [x] NB-AUD-001: remove identity-by-recency from Daily Routine and use canonical `LocalSubjectResolver`.
- [x] NB-AUD-002: make load error distinct from empty state; never expose Save on load failure.
- [x] NB-AUD-003: invalidate meal/schedule/dashboard projections after successful meal replacement.
- [x] NB-AUD-004: require explicit replacement candidate selection in Today Tasks.
- [x] NB-AUD-005: implement 30-minute defer with durable notification state and legacy compatibility.
- [x] NB-AUD-007: persist M30 secondary non-defer terminal status and block duplicate taps.
- [x] NB-AUD-006: document current Daily Routine onboarding implementation and ownership rule.
- [x] Add focused regression tests for identity, notification defer, and Nabi secondary actions.
- [ ] Run Flutter targeted tests/analyze/build in an environment that has the Flutter SDK.

## Files to inspect/change

### Daily Routine / onboarding
- `lib/app_versions/v1/features/daily_routine/data/datasources/daily_routine_preferences_local_datasource.dart`
- `lib/app_versions/v1/features/daily_routine/domain/repositories/daily_routine_preferences_repository_impl.dart`
- `lib/app_versions/v1/features/daily_routine/providers/daily_routine_preferences_provider.dart`
- `lib/app_versions/v1/features/daily_routine/presentation/pages/daily_routine_preferences_page.dart`
- `test/features/daily_routine/daily_routine_preferences_test.dart`

### Meal / schedule / dashboard
- `lib/app_versions/v1/features/meal_plan/presentation/controllers/meal_plan_controller.dart`
- `lib/app_versions/v1/features/meal_plan/presentation/widgets/meal_replacement_picker.dart`
- `lib/app_versions/v1/features/today_tasks/presentation/widgets/today_task_card.dart`

### M09 notifications
- `lib/app_versions/v1/services/notifications/notification_constants.dart`
- `lib/app_versions/v1/services/notifications/notification_action_handler.dart`
- `lib/app_versions/v1/services/notifications/notification_bootstrap.dart`
- `lib/app_versions/v1/services/notifications/reminder_notification_scheduler.dart`
- `lib/app_versions/v1/services/notifications/reminder_schedule_service.dart`
- `lib/core/storage/localdb/models/notification_model.dart`
- `lib/core/storage/localdb/daos/notifications_dao.dart`
- `test/services/notifications/notification_action_handler_test.dart`

### M30 Nabi
- `lib/features/nabi/application/notifications/nabi_notification_controller.dart`
- `test/features/nabi/application/nabi_notification_controller_test.dart`

### DD / evidence
- `docs/DD/onboarding_profile/Implementation_Delta_2026-08-17_Daily_Routine_Onboarding.md`
- `docs/DD/onboarding_profile/README.md`
- `docs/DD/schedule_notifications/Implementation_Delta_2026-08-17_Notification_Defer.md`
- `docs/DD/schedule_notifications/README.md`
- `docs/fixbug/project-wide-audit/001-fixbug-project-wide-audit.md`
- `docs/worklog/2026-08-17/002-worklog-fix-project-wide-audit.md`

## Verification commands

```powershell
dart format <touched-dart-files>
flutter analyze <touched-source-and-test-paths>
flutter test test/features/daily_routine/daily_routine_preferences_test.dart
flutter test test/services/notifications/notification_action_handler_test.dart
flutter test test/features/nabi/application/nabi_notification_controller_test.dart
flutter test test/architecture_version_boundary_test.dart
flutter test test/architecture_preservation_property_test.dart
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_check.ps1 -BuildApk
```

## Risks

- Native Android/iOS notification rescheduling still requires device smoke validation.
- Broad repo checks may expose unrelated pre-existing analyzer/format drift.
- This execution environment does not contain Dart/Flutter, so Flutter validation must be run after applying the ZIP on a development machine.
