# Fix report — NanoBio project-wide audit

## Baseline

- Repository: `daovanhung-dev/NanoBioAI`
- Baseline commit: `7b2b90d5e0946721c2ac78363100e48a09f2032a`
- Source issue: `docs/issues/project-wide-audit/001-issue-project-wide-audit.md`
- Todo: `docs/todo/project-wide-audit/001-todo-project-wide-audit.md`

## Resolution summary

| Finding | Resolution |
|---|---|
| NB-AUD-001 | Daily Routine no longer resolves identity by latest `users.created_at`; current-user APIs use canonical `LocalSubjectResolver` and fail closed. |
| NB-AUD-002 | Load error renders Retry-only error state; defaults are available only after successful empty load; Save refuses loading/error state. |
| NB-AUD-003 | Successful meal replacement centrally invalidates meal, lifestyle-schedule, and dashboard projections. |
| NB-AUD-004 | Today Tasks uses an explicit candidate picker + `replaceMealByCatalogCode`; no auto-first replacement path is used by that view. |
| NB-AUD-005 | “Để sau” is durable 30-minute defer; source remains pending; legacy `skipped` input normalizes to `defer`; no points/completion writes. |
| NB-AUD-006 | Added M01 Daily Routine implementation delta documenting step order, ownership, persistence, error semantics and schedule impact. |
| NB-AUD-007 | M30 secondary non-defer actions persist `actioned`/`failed`, retain bubble on failure, and guard duplicate taps. |

## Regression coverage added/updated

- Daily Routine canonical subject resolution and ambiguous/missing subject failure.
- Multi-local-user routine save targets resolved guest rather than newest row.
- Meal replacement controller dispatches the centralized dependent-projection invalidator only after successful mutation.
- Notification defer at +30 minutes.
- Legacy `skipped` compatibility.
- Stale duplicate defer callback guard.
- Repeated valid deferred delivery can defer another +30 minutes.
- Native reschedule failure -> `schedule_failed` while source stays pending.
- Nabi secondary success -> `actioned`.
- Nabi secondary failure -> `failed`.
- Nabi secondary double tap -> single navigation dispatch.

## Validation evidence in this execution environment

Static/structural checks were performed on the changed-files workspace: Dart delimiter/string/comment balance, trailing-whitespace scan, issue invariants, absence of identity-by-users-recency in Daily Routine, absence of deprecated Today Tasks auto-replacement, presence of all three cross-view invalidation targets, 30-minute defer wiring, terminal Nabi states, and no v21 migration/version artifact. The environment used to assemble this fix does **not** provide Dart or Flutter binaries, therefore it cannot truthfully claim `dart format`, `flutter analyze`, `flutter test`, APK build, or device delivery smoke as executed.

Required validation after applying the ZIP to the project checkout:

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

Native Android/iOS reminder defer should additionally be smoke-tested on a device: trigger reminder -> “Để sau” -> verify redelivery approximately 30 minutes later and confirm source task remains pending.
