# Import / File Map — M31

## Existing files modified

- `lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart`
- `lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_tracking_page.dart`
- `lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_safety_access_gate.dart`
- `lib/app_versions/v1/features/sleep_tracking/providers/sleep_safety_controller.dart`
- `lib/app_versions/v1/features/sleep_tracking/providers/sleep_safety_providers.dart`
- `lib/app_versions/v1/router/v1_router.dart`
- `lib/app_versions/v1/services/notifications/notification_bootstrap.dart`
- `lib/app_versions/v1/services/notifications/notification_navigation_coordinator.dart`
- `lib/core/storage/localdb/database_service.dart`
- `lib/core/storage/localdb/database_version.dart`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/example/nano_app/MainActivity.kt`
- `ios/Runner/AppDelegate.swift`
- `ios/Runner/Info.plist`
- `tools/build_supabase_rebuild_config.py`
- `docs/supabase/README.md`

## New Flutter source

`lib/app_versions/v1/features/sleep_tracking/`

- domain entities/services/repository
- data model/local/cloud/reminder/native gateway/repository implementation
- Riverpod providers/controller
- access gate, contacts, schedule, history pages
- alert/status/disclaimer/countdown widgets

## New SQLite source

- `tables/sleep_safety_tables.dart`
- `daos/sleep_safety_dao.dart`
- `migrations/migration_v21.dart`

No new pub package is required. Existing `permission_handler`,
`flutter_local_notifications`, Riverpod, GoRouter, sqflite and Supabase are used.

## New Android source

`android/app/src/main/kotlin/com/example/nano_app/sleep_safety/`

- `SleepSafetyNativeEvent.kt`
- `SleepSafetyDetector.kt`
- `SleepSafetyAudioCapture.kt`
- `SleepSafetyNotificationFactory.kt`
- `SleepSafetyForegroundService.kt`
- `SleepSafetyChannelHandler.kt`

No additional Gradle library is required; Android framework audio/service APIs
are used.

## iOS source choice

M31 native bridge/runtime is placed in the existing `ios/Runner/AppDelegate.swift`
in this delivery. This avoids adding Swift source files that would also require
unsafe manual Xcode `project.pbxproj` edits in an environment without Xcode.
A later native refactor may split the classes after Xcode target membership is
verified.

## Supabase / Edge

- `docs/supabase/07_schema_sleep_safety.sql`
- `docs/supabase/08_enable_sleep_safety_rollout.sql`
- generator source order becomes 01→08
- `_shared/sleep_safety_provider.ts`
- `sleep-safety-contact-verification/`
- `sleep-safety-dispatch/`
- `sleep-safety-provider-webhook/`

`config.sql` is generated and must be regenerated from the real checkout after
applying this delivery; it is intentionally not hand-edited.


## Enable-paid / FeatureHub verification files

- `test/app_versions/v1/features/features_hub/sleep_safety_feature_entry_test.dart`
- `test/app_versions/v1/features/sleep_tracking/presentation/sleep_safety_access_gate_test.dart`
- `test/app_versions/v1/features/sleep_tracking/providers/sleep_safety_controller_test.dart`
- `test/docs/supabase_numbered_rebuild_contract_test.dart`

No new package is introduced by the rollout/FeatureHub activation delta.
